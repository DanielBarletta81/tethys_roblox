// server.ts
// Production-grade Node.js/Express Core Server with Experimentation, Cloud Auth, and Headless GraphQL CMS
import 'dotenv/config';
import express, { Request, Response, NextFunction } from 'express';
import crypto from 'crypto';
import axios from 'axios';
import { liveOpsABExperimentMatrix } from './worldConfigSchema.js';
import { verifyCloudSignature } from './authMiddleware.js';

export const app = express();
const PORT = process.env.PORT || 3030;

app.use(express.json({ limit: '256kb' }));
app.use('/api/v1', (req, res, next) => {
    if (req.method === 'GET') return next();
    return verifyCloudSignature(req, res, next);
});

// ============================================================================
// 1. GLOBAL INFRASTRUCTURE STATE TYPE DEFINITIONS & SCHEMAS
// ============================================================================
interface ServerMetricsTelemetry {
    jobId: string;
    fps: number;
    memoryMb: number;
    activePlayerCount: number;
    ashSaturationPercent: number;
    regionId: string;
}

interface PlayerProfileMutationPayload {
    userId: string;
    username: string;
    guildAlignment: 'None' | 'Creature' | 'Mystic' | 'Triumvirate';
    lastSavedTimestamp: string;
}

interface LiveServerInstanceMetadata {
    jobId: string;
    serverPlaceId: number;
    activePlayerCount: number;
    maxPlayersCapacity: number;
    assignedTestingCell: string;
    serverUptimeSeconds: number;
    lastPingTimestamp: string;
}
interface FlightTelemetryInput {
    serverJobId: string;
    altitudeStuds: number;
    coordinateX: number;
    coordinateZ: number;
    currentSpeedKnots: number;
}

interface FlightAeroMetricsResponse {
    success: boolean;
    thermalUpdraftForce: number; // -- Upward velocity booster multiplier
    ashTurbulenceVector: { x: number; y: number; z: number };
    emberDensitySpawnRate: number;// -- Scales local screen particle effects
    vestigeWardenHarpoonActive: boolean;// -- Triggers capture alert sequences
    skyCityExitVisible: boolean;   //
}

interface PlayerSurvivalSession {
    userId: string;
    currentZone: 'Arnn_Ridge_Cave' | 'Ordovic_Rapids' | 'Riverbank_Shallows' | 'First_Sort_Decision' | 'Lower_Tiers_Gate';
    hasTorchesLit: boolean;
    isFireDampenedWithAlgae: boolean;
    fireSkillLevel: number;
    healthPoints: number;
    inventory: string[];
    chosenRoute: 'None' | 'Human_Rescue_Cage' | 'Ordovic_River_Deep_Run';
}

const activeSurvivalRegistries = new Map<string, PlayerSurvivalSession>();

interface CityQuotaCheckInput {
    userId: string;
    vinesCollectedCount: number;
    basaltCoreTokens: number;
    laborHoursElapsed: number;
}

interface CityQuotaResponse {
    success: boolean;
    workWeightScore: number;
    isPassPassed: boolean;
    assignedState: 'Citizen_Worker' | 'Condemned_Exile';
    announcementMessage: string;
}

/**
 * @route   POST /api/v1/wildbound/city/verify-weight
 * @desc    Authoritatively checks player survival metrics against Triumvirate quotas.
 *          If metrics fail thresholds, forces transition to the execution loop.
 */
app.post('/api/v1/wildbound/city/verify-weight', (req: Request, res: Response) => {
    const { userId, vinesCollectedCount, basaltCoreTokens, laborHoursElapsed } = req.body as CityQuotaCheckInput;

    if (!userId) return res.status(400).json({ success: false, error: 'Missing UserId tracking registration.' });

    // THE TRIUMVIRATE QUOTA CALCULUS: Requires balanced contributions to stay in the city
    const calculatedWeightScore = (vinesCollectedCount * 10) + (basaltCoreTokens * 25) + (laborHoursElapsed * 5);
    const STRICT_PASS_THRESHOLD = 150; // Must gather enough resources to clear inspection

    const isCleared = calculatedWeightScore >= STRICT_PASS_THRESHOLD;
    const assignedState = isCleared ? 'Citizen_Worker' : 'Condemned_Exile';

    let alertMessage = "";
    if (isCleared) {
        alertMessage = "🟢 PASSED. Identification metrics confirmed. Proceed cleanly through the Lower Tiers Gate for labor redistribution.";
    } else {
        alertMessage = "❌ WEIGHT INSIGNIFICANT. You have failed to carry your mass inside the city. By decree of the Iron Fleet, you are condemned to the grace of exile. Face The Weep.";
    }

    // Force synchronize the state directly into our master player tracking registries
    const existingSession = activeSurvivalRegistries.get(userId);
    if (existingSession) {
        existingSession.currentZone = isCleared ? 'Lower_Tiers_Gate' : 'First_Sort_Decision';
        activeSurvivalRegistries.set(userId, existingSession);
    }

    return res.status(200).json({
        success: true,
        workWeightScore: calculatedWeightScore,
        isPassPassed: isCleared,
        assignedState,
        announcementMessage: alertMessage
    } as CityQuotaResponse);
});

/**
 * @route   POST /api/v1/wildbound/survival/fire-ignite
 * @desc    Processes hyper-oxygenated fire-lighting mechanics.
 *          If players are impatient or forget algae oil, a flash fire kills them.
 */
app.post('/api/v1/wildbound/survival/fire-ignite', (req: Request, res: Response) => {
    const { userId, useAlgaeOil, patienceTicks } = req.body;

    if (!userId) return res.status(400).json({ success: false, error: 'Missing UserId tracking registration.' });

    let playerSession = activeSurvivalRegistries.get(userId) || {
        userId, currentZone: 'Arnn_Ridge_Cave', hasTorchesLit: false, isFireDampenedWithAlgae: false,
        fireSkillLevel: 1, healthPoints: 100, inventory: [], chosenRoute: 'None'
    };

    // HYPER-OXYGENATED COMBUSTION LOGIC
    if (!useAlgaeOil) {
        playerSession.healthPoints = 0; // FLASH FIRE FATALITY
        activeSurvivalRegistries.set(userId, playerSession);
        return res.status(200).json({
            success: false,
            fatalityTriggered: true,
            error: "💥 FLASH FIRE! The hyper-oxygenated atmosphere exploded the open spark. Flame suppressed failure."
        });
    }

    if (patienceTicks < 3) {
        playerSession.healthPoints -= 45; // Severe burn injury
        activeSurvivalRegistries.set(userId, playerSession);
        return res.status(200).json({
            success: false,
            fatalityTriggered: false,
            healthDamage: 45,
            error: "🔥 IMPATIENT IGNITION: The flame flared violently before the algae oil could suppress the combustion."
        });
    }

    playerSession.hasTorchesLit = true;
    playerSession.isFireDampenedWithAlgae = true;
    playerSession.fireSkillLevel += 1;
    activeSurvivalRegistries.set(userId, playerSession);

    return res.status(200).json({
        success: true,
        fatalityTriggered: false,
        message: "🟢 Fire Stabilized. The algae oil gives the flame a peculiar, emerald-tinted prehistoric glow.",
        updatedSession: playerSession
    });
});

/**
 * @route   POST /api/v1/wildbound/survival/zone-update
 * @desc    Tracks player state transitions across cinematic sequences
 */
app.post('/api/v1/wildbound/survival/zone-update', (req: Request, res: Response) => {
    const { userId, targetZone, applyInjury, routeSelection } = req.body;

    const zones = ['Arnn_Ridge_Cave', 'Ordovic_Rapids', 'Riverbank_Shallows', 'First_Sort_Decision', 'Lower_Tiers_Gate'];
    const routes = ['None', 'Human_Rescue_Cage', 'Ordovic_River_Deep_Run'];
    if (typeof userId !== 'string' || !/^\d{1,20}$/.test(userId) || !zones.includes(targetZone)
        || (applyInjury !== undefined && (typeof applyInjury !== 'number' || !Number.isFinite(applyInjury) || applyInjury < 0 || applyInjury > 100))
        || (routeSelection !== undefined && !routes.includes(routeSelection))) {
        return res.status(400).json({ success: false, error: 'Invalid survival zone update.' });
    }

    let playerSession = activeSurvivalRegistries.get(userId) || {
        userId, currentZone: 'Arnn_Ridge_Cave', hasTorchesLit: false, isFireDampenedWithAlgae: false,
        fireSkillLevel: 1, healthPoints: 100, inventory: [], chosenRoute: 'None'
    };

    playerSession.currentZone = targetZone;
    if (applyInjury) playerSession.healthPoints = Math.max(10, playerSession.healthPoints - applyInjury);
    if (routeSelection) playerSession.chosenRoute = routeSelection;

    activeSurvivalRegistries.set(userId, playerSession);
    return res.status(200).json({ success: true, currentSession: playerSession });
});

/**
 * @route   POST /api/v1/tethys/flight/aero-calculate
 * @desc     Computes aerodynamic stress forces for Stryker's flight live over the wire
 *           Bypasses Roblox server CPU processing completely
 */
app.post('/api/v1/tethys/flight/aero-calculate', (req: Request, res: Response) => {
    const { serverJobId, altitudeStuds, coordinateX, coordinateZ, currentSpeedKnots } = req.body as FlightTelemetryInput;

    if (altitudeStuds === undefined || coordinateX === undefined) {
        return res.status(400).json({ success: false, error: 'Missing core flight coordinates matrix.' });
    }

    // 1. THERMAL LIFTOFF CALCULUS: The closer Stryker flies to the hot Watcher Volcano, the higher the thermal lift
    const distanceToVolcano = Math.sqrt(Math.pow(coordinateX - (-8000), 2) + Math.pow(coordinateZ - (-8000), 2));
    let thermalLift = 0;

    if (distanceToVolcano < 4000 && altitudeStuds < 5000) {
        // Massive thermal elevator vector pumping velocity upward near the volcanic chimney core
        thermalLift = Math.max(10, 50 - (distanceToVolcano / 100));
    }

    // 2. ASH TURBULENCE NOISE FLUIDITY: High speed + high altitude triggers severe buffeting
    const turbulenceIntensity = (altitudeStuds > 2000 ? (altitudeStuds / 100) : 5) * (currentSpeedKnots / 30);
    const ashTurbulence = {
        x: (Math.random() - 0.5) * turbulenceIntensity,
        y: (Math.random() - 0.5) * (thermalLift > 0 ? turbulenceIntensity * 2 : turbulenceIntensity),
        z: (Math.random() - 0.5) * turbulenceIntensity
    };

    // 3. VESTIGE WARDEN HARPOON RANGE MATRIX: Guard forces near Sky City try to pull him back
    const distanceToSkyCity = Math.sqrt(Math.pow(coordinateX - 5000, 2) + Math.pow(coordinateZ - 5000, 2));
    const harpoonThreat = distanceToSkyCity < 2500 && altitudeStuds < 1500;

    // 4. LORE EXIT DISCOVERY HORIZON SIGNALS
    // Once Stryker reaches a critical high scouting altitude, he spots the hidden path
    const targetExitAltitudeBreached = altitudeStuds >= 3500;

    return res.status(200).json({
        success: true,
        thermalUpdraftForce: thermalLift,
        ashTurbulenceVector: ashTurbulence,
        emberDensitySpawnRate: altitudeStuds > 2500 ? Math.min(100, (altitudeStuds - 2000) / 10) : 0,
        vestigeWardenHarpoonActive: harpoonThreat,
        skyCityExitVisible: targetExitAltitudeBreached
    } as FlightAeroMetricsResponse);
});

export interface SanitizedTethysLoreNode {
    nodeId: number;
    title: string;
    bodyText: string;
    quadrant: string;
    eraYear: number;
    faction: string;
}

interface WpGraphQlLoreNode {
    id: string;
    databaseId?: number;
    title: string;
    content: string;
    tethysLoreFields?: {
        geographicQuadrant: string;
        historicalEraYear: number;
        associatedFaction: string;
    };
}

interface GraphQlApiResponse {
    data: {
        posts: {
            nodes: WpGraphQlLoreNode[];
        };
    };
}

// ============================================================================
// 2. GLOBAL STATE CACHES & LIVE OPERATIONAL VARIABLES
// ============================================================================
let currentExperimentMatrix = { ...liveOpsABExperimentMatrix };
let isExperimentCircuitBreakerTripped = false;
let globalPerformanceInfractionsCount = 0;
const MAX_ALLOWED_INFRACTIONS = 3;

// In-memory array storage maps acting as the brain of the ecosystem
let historicalServerPerformanceLog: ServerMetricsTelemetry[] = [];
const livePlayerAccountRegistry = new Map<string, PlayerProfileMutationPayload>();
const activeRobloxServerClusterMap = new Map<string, LiveServerInstanceMetadata>();
let currentTethysLoreCache: SanitizedTethysLoreNode[] = [];

// ============================================================================
// 3. UTILITY LAYER METHODS & CMS CONVERTERS
// ============================================================================

/**
 * Strips raw HTML layout formatting elements natively returned by WordPress fields
 */
function stripHtmlFormattingMarkup(inputHtml: string): string {
    if (!inputHtml) return '';
    return inputHtml
        .replace(/<[^>]*>/g, '') // Strip out standard HTML tags
        .replace(/&nbsp;/g, ' ')
        .replace(/&#8217;/g, "'")
        .replace(/\s+/g, ' ')
        .trim();
}

/**
 * Ingests, structures, and validates narrative post entries via WP GraphQL queries
 */
export async function synchronizeHeadlessWpLore(): Promise<boolean> {
    const GRAPHQL_API_URL = process.env.TETHYS_WP_ENDPOINT;

    console.log(`\n🛰️ [GraphQL CMS] Querying content layers at: ${GRAPHQL_API_URL || 'UNDEFINED'}`);

    if (!GRAPHQL_API_URL) {
        console.warn('⚠️ [Config Drop] TETHYS_WP_ENDPOINT missing in .env. Reverting to baseline defaults.');
        loadFallbackLoreData();
        return false;
    }

    const graphQlQuery = {
        query: `
            query FetchPrehistoricLoreMatrix {
                posts(first: 20) {
                    nodes {
                        databaseId
                        id
                        title
                        content
                        tethysLoreFields {
                            geographicQuadrant
                            historicalEraYear
                            associatedFaction
                        }
                    }
                }
            }
        `
    };

    try {
        const response = await axios.post<GraphQlApiResponse>(GRAPHQL_API_URL, graphQlQuery, {
            headers: { 'Content-Type': 'application/json' },
            timeout: 5000
        });

        const incomingNodes = response.data?.data?.posts?.nodes;

        if (incomingNodes && Array.isArray(incomingNodes)) {
            const compiledNodes: SanitizedTethysLoreNode[] = [];

            for (const node of incomingNodes) {
                const nodeId = node.databaseId ?? (/^\d+$/.test(node.id) ? Number(node.id) : undefined);
                if (!nodeId || !Number.isSafeInteger(nodeId) || nodeId < 1) continue;
                compiledNodes.push({
                    nodeId,
                    title: node.title,
                    bodyText: stripHtmlFormattingMarkup(node.content),
                    quadrant: node.tethysLoreFields?.geographicQuadrant || "Sky_City_Basin",
                    eraYear: Number(node.tethysLoreFields?.historicalEraYear) || 412,
                    faction: node.tethysLoreFields?.associatedFaction || "None"
                });
            }

            currentTethysLoreCache = compiledNodes;
            console.log(`✅ [GraphQL CMS] Sync Confirmed: Successfully cached ${compiledNodes.length} historical nodes.\n`);
            return true;
        }
        return false;
    } catch (error: any) {
        console.error(`❌ [GraphQL CMS Failure] Gateway unreachable: ${error.message}. Loading fallback arrays.`);
        loadFallbackLoreData();
        return false;
    }
}

function loadFallbackLoreData() {
    if (currentTethysLoreCache.length === 0) {
        currentTethysLoreCache = [
            {
                nodeId: 991,
                title: "The Founding Pact of Sky City",
                bodyText: "In the 412th year of the Deep Era, the Bond Mystic Conclave raised the crescent walls above the ashline to shield their political covenants from the toxic columns vented by The Watcher caldera.",
                quadrant: "Sky_City_Protected_Sanctuary",
                eraYear: 412,
                faction: "Mystic_Conclave"
            }
        ];
    }
}

// Initialise background CMS synchronization pass immediately on deployment boot cycles
// CMS synchronization is started explicitly by backend/start.ts.

// ============================================================================
// 4. PUBLIC CONVERSION ROUTING LAYER (GET ENDPOINTS)
// ============================================================================

app.get('/api/v1/liveops/variant-stream', (req: Request, res: Response) => {
    const serverJobId = (req.query.jobId as string) || "fallback_studio_session_local";
    const experiment = currentExperimentMatrix.activeExperiment;

    if (isExperimentCircuitBreakerTripped) {
        return res.status(200).json({
            success: true,
            experimentActive: false,
            circuitBreakerEnforced: true,
            variantAssigned: "Control_A",
            segments: currentExperimentMatrix.variantA_Segments
        });
    }

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

    return res.status(200).json({
        success: true,
        experimentId: experiment.experimentId,
        variantAssigned: assignedVariant,
        segments: targetSegments
    });
});

app.get('/api/v1/tethys/weather', (req: Request, res: Response) => {
    return res.status(200).json({
        success: true,
        timestamp: new Date().toISOString(),
        currentWeather: {
            profileId: "volcanic_storm",
            atmosphereDensity: 0.65,
            fogColorHex: "#2C232B",
            skyColorHex: "#130E14",
            lightningFrequency: 0.85,
            windSpeed: 45
        }
    });
});

app.get('/api/v1/tethys/stream-chunks', (req: Request, res: Response) => {
    const playerX = parseFloat(req.query.x as string) || 0;
    const playerZ = parseFloat(req.query.z as string) || 0;
    const streamingRadius = 3000;
    const chunkSize = 2048;

    const gridX = Math.floor(playerX / chunkSize);
    const gridZ = Math.floor(playerZ / chunkSize);
    const regionalChunksToLoad = [];

    for (let dx = -1; dx <= 1; dx++) {
        for (let dz = -1; dz <= 1; dz++) {
            const targetX = gridX + dx;
            const targetZ = gridZ + dz;
            const chunkCenterX = (targetX * chunkSize) + (chunkSize / 2);
            const chunkCenterZ = (targetZ * chunkSize) + (chunkSize / 2);

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
    return res.status(200).json({ success: true, returnedChunksCount: regionalChunksToLoad.length, activeDataStream: regionalChunksToLoad });
});
app.get('/api/v1/tethys/telemetry/dashboard-stream', (req: Request, res: Response) => {
return res.status(200).json({ success: true, metricsHistory: historicalServerPerformanceLog });
});
app.get('/api/v1/tethys/instances/cluster-metrics', (req: Request, res: Response) => {
return res.status(200).json({ success: true, clusterTopography: Array.from(activeRobloxServerClusterMap.values()) });
});
app.get('/api/v1/tethys/lore/cms-stream', (req: Request, res: Response) => {
return res.status(200).json({ success: true, clusterCount: currentTethysLoreCache.length, narrativeStream: currentTethysLoreCache });
});
// ============================================================================
// 5. SECURED DATA OVERRIDE CONVERSIONS (POST ENDPOINTS)
// ============================================================================
app.post('/api/v1/liveops/sync-override', (req: Request, res: Response) => {
        const { variantA_Segments, variantB_Segments } = req.body;
if (!variantA_Segments || !variantB_Segments || !Array.isArray(variantA_Segments) || !Array.isArray(variantB_Segments)) {
return res.status(400).json({ success: false, error: 'Inbound validation failed: Variant blocks must be valid arrays.' });
}
currentExperimentMatrix.variantA_Segments = variantA_Segments;
currentExperimentMatrix.variantB_Segments = variantB_Segments;
console.log(`[ELO System Sync] Cryptographically authorized update written to matrix caches.`);
return res.status(200).json({ success: true, message: 'Configuration successfully synced.', syncedMatrix: currentExperimentMatrix });
});
app.post('/api/v1/liveops/telemetry/report-harm', (req: Request, res: Response) => {
const { serverJobId, activeVariant, averageFps, memoryUsageMb } = req.body;
console.log(`[ELO Telemetry] Health check: Server [${serverJobId}] on Cell [${activeVariant}] -> ${averageFps} FPS`);
if (activeVariant === "Volcanic_B" && averageFps < 45) {
globalPerformanceInfractionsCount++;
if (globalPerformanceInfractionsCount >= MAX_ALLOWED_INFRACTIONS && !isExperimentCircuitBreakerTripped) {
isExperimentCircuitBreakerTripped = true;
console.error(`🚨 [CIRCUIT BREAKER] Performance limits breached! Triggering automated rollback to Control_A.`);
}
}
return res.status(200).json({ success: true, circuitBreakerTripped: isExperimentCircuitBreakerTripped });
});
app.post('/api/v1/tethys/telemetry/heartbeat', (req: Request, res: Response) => {
const metrics: ServerMetricsTelemetry = req.body;
historicalServerPerformanceLog.push(metrics);
if (historicalServerPerformanceLog.length > 20) historicalServerPerformanceLog.shift();
return res.status(200).json({ success: true, acknowledgedTimestamp: new Date().toISOString() });
});
app.post('/api/v1/tethys/instances/heartbeat-register', (req: Request, res: Response) => {
const { jobId, serverPlaceId, activePlayerCount, maxPlayersCapacity, assignedTestingCell, serverUptimeSeconds } = req.body;
if (!jobId || serverPlaceId === undefined) {
return res.status(400).json({ success: false, error: 'Inbound validation failed: Missing vital server metadata keys.' });
}
activeRobloxServerClusterMap.set(jobId, {
jobId,
serverPlaceId: Number(serverPlaceId),
activePlayerCount: Number(activePlayerCount),
maxPlayersCapacity: Number(maxPlayersCapacity),
assignedTestingCell: assignedTestingCell || 'Control_A',
serverUptimeSeconds: Number(serverUptimeSeconds),
lastPingTimestamp: new Date().toISOString()
});
const thresholdWindow = Date.now() - 30000;
for (const [id, server] of activeRobloxServerClusterMap.entries()) {
if (new Date(server.lastPingTimestamp).getTime() < thresholdWindow) {
activeRobloxServerClusterMap.delete(id);
}
}
return res.status(200).json({ success: true, globalActiveServersCount: activeRobloxServerClusterMap.size });
});
app.post('/api/v1/tethys/profile/mutate', (req: Request, res: Response) => {
const { userId, username, guildAlignment, lastSavedTimestamp } = req.body as PlayerProfileMutationPayload;
if (!userId || !username || !guildAlignment) {
return res.status(400).json({ success: false, error: 'Inbound validation failed: Missing parameters.' });
}
const validPaths = ['None', 'Creature', 'Mystic', 'Triumvirate'];
if (!validPaths.includes(guildAlignment)) {
return res.status(400).json({ success: false, error: 'Invalid path assignment strategy.' });
}
const updatedProfileRecord: PlayerProfileMutationPayload = {
userId, username, guildAlignment, lastSavedTimestamp: lastSavedTimestamp || new Date().toISOString()
};
livePlayerAccountRegistry.set(userId, updatedProfileRecord);
console.log(`💾 [Database Sync] Account State committed successfully for User: ${userId}`);
return res.status(200).json({ success: true, message: 'Cloud profile sync confirmed.', savedRecord: updatedProfileRecord });
});
app.post('/api/v1/tethys/lore/cms-refresh', async (req: Request, res: Response) => {
const success = await synchronizeHeadlessWpLore();
if (success) return res.status(200).json({ success: true, message: "GraphQL CMS cache re-synced live." });
return res.status(502).json({ success: false, error: "Headless CMS API Gateway timeout." });
});
// ============================================================================
// 6. LIFE-CYCLE CLEANUP MANAGERS (PREVENTS MACOS PORT LOCK LOOPS)
// ============================================================================
