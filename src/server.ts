// server.ts
// Production-grade Node.js/Express Core Server with Experimentation and Cloud Auth
import 'dotenv/config';
import express, { Request, Response } from 'express';
import crypto from 'crypto';
import cors from 'cors';
import  { liveOpsABExperimentMatrix } from '../src/worldConfigSchema.js';
import { verifyCloudSignature } from '../src/authMiddleware.js';

export const app = express();
const PORT = process.env.PORT || 3030; 

app.use(cors({ origin: 'http://localhost:3000' }));
app.use(express.json());

// ============================================================================
// 1. GLOBAL STATE INITIALIZATION & TELEMETRY SAFETY COUNTERS
// ============================================================================
let currentExperimentMatrix = { ...liveOpsABExperimentMatrix };
let isExperimentCircuitBreakerTripped = false;
let globalPerformanceInfractionsCount = 0;
const MAX_ALLOWED_INFRACTIONS = 3; 

// Historical performance buffer tracking live server frames and memory allocations
interface ServerMetricsTelemetry {
    jobId: string;
    fps: number;
    memoryMb: number;
    activePlayerCount: number;
    ashSaturationPercent: number;
    regionId: string;
}
let historicalServerPerformanceLog: ServerMetricsTelemetry[] = [];

// Player Profile Schema Definitions
interface PlayerProfileMutationPayload {
    userId: string;
    username: string;
    guildAlignment: 'None' | 'Creature' | 'Mystic' | 'Triumvirate';
    lastSavedTimestamp: string;
}
const livePlayerAccountRegistry = new Map<string, PlayerProfileMutationPayload>();

// ============================================================================
// 2. READ-ONLY INBOUND CONVERSIONS (PUBLIC RUNTIME ROUTING)
// ============================================================================

/**
 * @route   GET /api/v1/liveops/variant-stream
 * @desc    Serves active experiment vectors back to your Luau engine instances
 */
app.get('/api/v1/liveops/variant-stream', (req: Request, res: Response) => {
    const serverJobId = (req.query.jobId as string) || "fallback_studio_session_local";
    const experiment = currentExperimentMatrix.activeExperiment;
    
    // SAFETY CHECK: Force dynamic rollback to safe control group if breaker trips
    if (isExperimentCircuitBreakerTripped) {
        return res.status(200).json({
            success: true,
            experimentActive: false,
            circuitBreakerEnforced: true,
            variantAssigned: "Control_A",
            segments: currentExperimentMatrix.variantA_Segments
        });
    }

    // MD5 Slotting algorithm to deterministically bucket the client runtimes
    const hash = crypto.createHash('md5').update(serverJobId).digest('hex');
    const slot = parseInt(hash.substring(0, 8), 16) % 100;
    
    let assignedVariant = "Control_A";
    if (slot < (experiment.variants["Control_A"].weight * 100)) {
        assignedVariant = "Control_A";
    } else {
        assignedVariant = "Volcanic_B";
    }

    const targetSegments = assignedVariant === "Volcanic_B" 
        ? currentExperimentMatrix.variantB_Segments 
        : currentExperimentMatrix.variantA_Segments;

    res.status(200).json({
        success: true,
        experimentId: experiment.experimentId,
        variantAssigned: assignedVariant,
        segments: targetSegments
    });
});

/**
 * @route   GET /api/v1/tethys/weather
 * @desc    Delivers synchronized environmental atmospheric profiles to game servers
 */
interface WeatherProfile {
    profileId: string;
    atmosphereDensity: number;
    fogColorHex: string;
    skyColorHex: string;
    lightningFrequency: number;
    windSpeed: number;
}

const WEATHER_PROFILES: Record<string, WeatherProfile> = {
    Mesozoic_Calm: {
        profileId: "calm_sun",
        atmosphereDensity: 0.25,
        fogColorHex: "#99B2A4",
        skyColorHex: "#D1E2D3",
        lightningFrequency: 0,
        windSpeed: 8
    },
    Tethys_Superstorm: {
        profileId: "volcanic_storm",
        atmosphereDensity: 0.65,
        fogColorHex: "#2C232B",
        skyColorHex: "#130E14",
        lightningFrequency: 0.85,
        windSpeed: 45
    }
};

let activeGlobalWeather = WEATHER_PROFILES.Tethys_Superstorm;

app.get('/api/v1/tethys/weather', (req: Request, res: Response) => {
    res.status(200).json({
        success: true,
        timestamp: new Date().toISOString(),
        currentWeather: activeGlobalWeather
    });
});

/**
 * @route   GET /api/v1/tethys/stream-chunks
 * @desc    Evaluates player coordinate context and dynamically serves regional asset vectors
 */
const TETHYS_CHUNK_SIZE = 2048;

app.get('/api/v1/tethys/stream-chunks', (req: Request, res: Response) => {
    const playerX = parseFloat(req.query.x as string) || 0;
    const playerZ = parseFloat(req.query.z as string) || 0;
    const streamingRadius = 3000; 

    const gridX = Math.floor(playerX / TETHYS_CHUNK_SIZE);
    const gridZ = Math.floor(playerZ / TETHYS_CHUNK_SIZE);

    const regionalChunksToLoad: any[] = [];

    for (let dx = -1; dx <= 1; dx++) {
        for (let dz = -1; dz <= 1; dz++) {
            const targetX = gridX + dx;
            const targetZ = gridZ + dz;
            
            const chunkCenterX = (targetX * TETHYS_CHUNK_SIZE) + (TETHYS_CHUNK_SIZE / 2);
            const chunkCenterZ = (targetZ * TETHYS_CHUNK_SIZE) + (TETHYS_CHUNK_SIZE / 2);

            const distance = Math.sqrt(Math.pow(playerX - chunkCenterX, 2) + Math.pow(playerZ - chunkCenterZ, 2));
            
            if (distance <= streamingRadius) {
                const isVolcanoZone = targetX <= -2 && targetZ <= -2;
                
                regionalChunksToLoad.push({
                    chunkId: `chunk_${targetX}_${targetZ}`,
                    worldCenterStuds: { x: chunkCenterX, z: chunkCenterZ },
                    environmentalLOD: distance < 1200 ? 'High' : 'Medium', 
                    terrainMaterialData: isVolcanoZone ? "Basalt" : "Grass",
                    hasActiveVolcanicVents: isVolcanoZone
                });
            }
        }
    }

    res.status(200).json({
        success: true,
        playerGridContext: { gridX, gridZ },
        returnedChunksCount: regionalChunksToLoad.length,
        activeDataStream: regionalChunksToLoad
    });
});

/**
 * @route   GET /api/v1/tethys/telemetry/dashboard-stream
 * @desc    Serves compiled metric logs over to our React control deck panel interface
 */
app.get('/api/v1/tethys/telemetry/dashboard-stream', (req: Request, res: Response) => {
    res.status(200).json({
        success: true,
        metricsHistory: historicalServerPerformanceLog
    });
});

// ============================================================================
// 3. SECURED ALTERATION CONVERSIONS (LIVE OPERATIONAL PIPELINES)
// ============================================================================

/**
 * @route   POST /api/v1/liveops/sync-override
 * @desc    Updates map layouts across A/B cells. Protected via HMAC Signatures.
 */
app.post('/api/v1/liveops/sync-override', verifyCloudSignature, (req: Request, res: Response) => {
    const { variantA_Segments, variantB_Segments } = req.body;

    if (!variantA_Segments || !variantB_Segments || !Array.isArray(variantA_Segments) || !Array.isArray(variantB_Segments)) {
        return res.status(400).json({
            success: false,
            error: 'Inbound validation failed: Experiment variant blocks must be valid arrays.'
        });
    }

    currentExperimentMatrix.variantA_Segments = variantA_Segments;
    currentExperimentMatrix.variantB_Segments = variantB_Segments;
    
    console.log(`[ELO System Sync] Cryptographically authorized update pushed successfully to configuration arrays.`);

    res.status(200).json({
        success: true,
        message: 'LiveOps remote experiment variants securely distributed to Cloud cache memory.',
        syncedMatrix: currentExperimentMatrix
    });
});

/**
 * @route   POST /api/v1/liveops/telemetry/report-harm
 * @desc    Receives performance metrics from active game servers and checks for infractions.
 */
app.post('/api/v1/liveops/telemetry/report-harm', (req: Request, res: Response) => {
    const { serverJobId, activeVariant, averageFps, memoryUsageMb } = req.body;

    console.log(`[ELO Telemetry] Health check from Server [${serverJobId}] on Cell [${activeVariant}]: ${averageFps} FPS, ${memoryUsageMb}MB Memory`);

    if (activeVariant === "Volcanic_B" && averageFps < 45) {
        globalPerformanceInfractionsCount++;
        console.warn(`[ELO ALERT] Performance infraction detected on variant Volcanic_B! Total Infractions: ${globalPerformanceInfractionsCount}/${MAX_ALLOWED_INFRACTIONS}`);

        if (globalPerformanceInfractionsCount >= MAX_ALLOWED_INFRACTIONS && !isExperimentCircuitBreakerTripped) {
            isExperimentCircuitBreakerTripped = true;
            console.error(`🚨 [ELO CIRCUIT BREAKER TRIPPED] Variant B breached maximum harm limits! Triggering automated platform-wide rollback to Control_A.`);
        }
    }

    res.status(200).json({
        success: true,
        circuitBreakerTripped: isExperimentCircuitBreakerTripped
    });
});

/**
 * @route   POST /api/v1/tethys/telemetry/heartbeat
 * @desc    Ingests raw engine stress metrics from active Roblox client sessions into dashboard log
 */
app.post('/api/v1/tethys/telemetry/heartbeat', (req: Request, res: Response) => {
    const metrics: ServerMetricsTelemetry = req.body;
    
    historicalServerPerformanceLog.push(metrics);
    if (historicalServerPerformanceLog.length > 20) {
        historicalServerPerformanceLog.shift();
    }
    
    res.status(200).json({
        success: true,
        acknowledgedTimestamp: new Date().toISOString()
    });
});

// ============================================================================
// 4. PLAYER PROFILE DATA OVERRIDES (SYNTAX FULLY PATTERND & REPAIRED)
// ============================================================================

/**
 * @route   POST /api/v1/tethys/profile/mutate
 * @desc    Ingests server-authoritative player path choices from Roblox Luau GUIs.
 */
app.post('/api/v1/tethys/profile/mutate', async (req: Request, res: Response) => {
    const { userId, username, guildAlignment, lastSavedTimestamp } = req.body as PlayerProfileMutationPayload;

    console.log('\n📥 [API Ingestion] Received profile mutation block from Roblox Server Matrix...');
    console.log(`➡️ Target User  : ${username} (ID: ${userId})`);
    console.log(`➡️ Chosen Path : ${guildAlignment}`);

    // 1. Core verification check for layout parameters
    if (!userId || !username || !guildAlignment) {
        return res.status(400).json({
            success: false,
            error: 'Inbound validation failed: Missing userId, username, or guildAlignment parameters.'
        });
    }

    // 2. Enum guardrail validation barrier 
    const validPaths = ['None', 'Creature', 'Mystic', 'Triumvirate'];
    if (!validPaths.includes(guildAlignment)) {
        return res.status(400).json({
            success: false,
            error: `Inbound validation failed: '${guildAlignment}' is not a canonical Tethys Guild path.`
        });
    }

    try {
        // 3. Mutate internal state cache metrics
        const updatedProfileRecord: PlayerProfileMutationPayload = {
            userId,
            username,
            guildAlignment,
            lastSavedTimestamp: lastSavedTimestamp || new Date().toISOString()
        };

        livePlayerAccountRegistry.set(userId, updatedProfileRecord);
        console.log(`💾 [Database Sync] State lock committed successfully for player account: ${userId}.`);

        // 4. Return clean telemetry transaction response
        return res.status(200).json({
            success: true,
            message: `Mesozoic cloud profile synchronization confirmed for path: ${guildAlignment}.`,
            savedRecord: updatedProfileRecord
        });
    } catch (error: any) {
        return res.status(502).json({ 
            success: false, 
            error: 'Database Gateway Exception: Unable to securely serialize profile changes.' 
        });
    }
});
// ============================================================================
// 5. BOOTSTRAP LIFECYCLE
// ============================================================================
app.listen(PORT, () => {
console.log('================================================================');
console.log(`🚀 ELO CORE ENGINE ONLINE: SERVICE LISTENING ON PORT ${PORT}`);
console.log('================================================================');
});