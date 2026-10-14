// server.ts
// Production-grade Node.js/Express Core Server with Experimentation, Cloud Auth, and Headless GraphQL CMS
import 'dotenv/config';
import express, { Request, Response, NextFunction } from 'express';
import crypto from 'crypto';
import cors from 'cors';
import axios from 'axios';
import { liveOpsABExperimentMatrix } from './worldConfigSchema.js';
import { verifyCloudSignature } from './authMiddleware.js';

const app = express();
const PORT = process.env.PORT || 3030; 

app.use(cors({ origin: 'http://localhost:3000' }));
app.use(express.json());

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
                compiledNodes.push({
                    nodeId: parseInt(node.id, 10) || Math.floor(Math.random() * 1000),
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
synchronizeHeadlessWpLore();

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
app.post('/api/v1/liveops/sync-override', verifyCloudSignature, (req: Request, res: Response) => {
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
const serverInstance = app.listen(PORT, () => {
console.log(`================================================================`);
console.log(`🚀 ELO CORE ENGINE ONLINE: SERVICE LISTENING ON PORT ${PORT}`);
console.log(`================================================================`);
});
const executeGracefulShutdown = (signalName: string) => {
console.log(`\n🚨 [OS Signal Received] ${signalName}: Dropping port locks...`);
serverInstance.close(() => {
console.log('🔒 [Network] Express gateway successfully unlinked from Port 3030.');
process.exit(0);
});
setTimeout(() => process.exit(1), 2000);
};
process.on('SIGINT', () => executeGracefulShutdown('SIGINT'));
process.on('SIGTERM', () => executeGracefulShutdown('SIGTERM'));