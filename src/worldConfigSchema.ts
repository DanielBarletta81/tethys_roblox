// worldConfigSchema.ts (Upgraded for A/B Testing)
// Production-grade spatial telemetry and experiment schemas for World of Tethys

// ============================================================================
// 1. STRICTOR TYPE DEFINTIONS FOR CORE ENGINE INTEGRITY
// ============================================================================
export type RobloxVoxelMaterial = 'Basalt' | 'Rock' | 'Grass' | 'Water' | 'Sand';

export interface Vector3Schema {
    x: number;
    y: number;
    z: number;
}

export interface TerrainSegment {
    id: string;
    name: string;
    targetMaterial: RobloxVoxelMaterial;
    hexMaskColor: string; 
    centerStuds: Vector3Schema;
    sizeStuds: Vector3Schema;
    loadPriority: number; // Lowest priority loads first (e.g. base layers)
}

export interface VariantMetadata {
    weight: number; // Decimal percentage (e.g., 0.50 for a 50/50 distribution split)
    globalSeaLevel: number;
    description: string;
}

export interface ExperimentMetadata {
    experimentId: string;
    experimentName: string;
    isActive: boolean;
    variants: {
        Control_A: VariantMetadata;
        Volcanic_B: VariantMetadata;
        [variantId: string]: VariantMetadata; // Extensible lookup signature
    };
}

// Full schema structure payload required by our Open Cloud pipeline
export interface LiveOpsWorldPayload {
    experienceId: string;
    universeId: number;
    activeOverrideId: string;
    globalSeaLevel: number;
    segments: TerrainSegment[];
}

export interface LiveOpsExperimentPayload {
    experienceId: string;
    universeId: number;
    activeExperiment: ExperimentMetadata;
    variantA_Segments: TerrainSegment[];
    variantB_Segments: TerrainSegment[];
}

// ============================================================================
// 2. EXPORTED OPERATIONAL DATA MATRIX PACKAGES
// ============================================================================

/**
 * Baseline Cretaceous Layout Target Specs
 * Exported directly to deploy-liveops.ts for automated builds
 */
export const cretaceousEarthscapeConfig: LiveOpsWorldPayload = {
    experienceId: "exp_cretaceous_sky_city_01",
    universeId: 29847104,
    activeOverrideId: "override_island_mainland_split_v2",
    globalSeaLevel: 120,
    segments: [
        {
            id: "seg_watcher_volcano",
            name: "The Isolated Watcher Island",
            targetMaterial: "Basalt",
            hexMaskColor: "#2B2B2B",
            centerStuds: { x: -8000, y: 500, z: -8000 }, // NW Quadrant Island position
            sizeStuds: { x: 4000, y: 1762, z: 4000 },
            loadPriority: 2
        },
        {
            id: "seg_cimmerian_ridge",
            name: "Cimmerian Mainland Shield Wall",
            targetMaterial: "Rock",
            hexMaskColor: "#8A857B",
            centerStuds: { x: 4000, y: 800, z: 4000 }, // SE Quadrant sweeping center
            sizeStuds: { x: 12000, y: 2500, z: 8000 },
            loadPriority: 1 // Drawn first as the structural landscape foundation
        },
        {
            id: "seg_sky_city_basin",
            name: "Sky City Protected Sanctuary",
            targetMaterial: "Grass",
            hexMaskColor: "#1E3F20",
            centerStuds: { x: 5000, y: 200, z: 5000 }, // Safely nested behind the protective crescent ridge
            sizeStuds: { x: 3500, y: 100, z: 3500 },
            loadPriority: 3 // High priority overrides base ridge voxels to sweep out valley floors
        }
    ]
};

/**
 * A/B Testing Configuration Context Payload
 * Ingested by the Express backend database matrix router
 */
export const liveOpsABExperimentMatrix: LiveOpsExperimentPayload = {
    experienceId: "exp_cretaceous_sky_city_01",
    universeId: 29847104,
    activeExperiment: {
        experimentId: "exp_m7_volcanic_tension_v1",
        experimentName: "Mesozoic Volcanic Eruption Radius Stress Test",
        isActive: true,
        variants: {
            "Control_A": { weight: 0.50, globalSeaLevel: 120, description: "Standard isolated NW island parameters" },
            "Volcanic_B": { weight: 0.50, globalSeaLevel: 105, description: "Aggressive volcanic protrusion with narrowed ocean straits" }
        }
    },
    variantA_Segments: cretaceousEarthscapeConfig.segments, // Variant A defaults cleanly to baseline config
    variantB_Segments: [
        {
            id: "seg_watcher_volcano",
            name: "Watcher Island (VOLCANIC AGGRESSOR VARIANT)",
            targetMaterial: "Basalt",
            hexMaskColor: "#2B2B2B",
            // The volcano shifts 3000 studs closer East-Southeast directly threatening Sky City
            centerStuds: { x: -5000, y: 900, z: -5000 }, 
            sizeStuds: { x: 7500, y: 2800, z: 7500 }, // Volcano significantly scaled up to verify client stress limits
            loadPriority: 2
        },
        {
            id: "seg_cimmerian_ridge",
            name: "Cimmerian Mainland Shield Wall",
            targetMaterial: "Rock",
            hexMaskColor: "#8A857B",
            centerStuds: { x: 4000, y: 800, z: 4000 },
            sizeStuds: { x: 12000, y: 2500, z: 8000 },
            loadPriority: 1
        }
    ]
};
export default liveOpsABExperimentMatrix;