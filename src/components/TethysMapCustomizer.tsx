// TethysMapCustomizer.tsx
// Administrative Real-Time Map Structural Override Console for World of Tethys
import React, { useState } from 'react';

interface Vector3Input {
    x: number;
    y: number;
    z: number;
}

export const TethysMapCustomizer: React.FC = () => {
    // 1. CHUNK RECONSTRUCTION STATE LOOPS
    const [volcanoSize, setVolcanoSize] = useState<Vector3Input>({ x: 4000, y: 1762, z: 4000 });
    const [ridgeSize, setRidgeSize] = useState<Vector3Input>({ x: 12000, y: 2500, z: 8000 });
    const [isUpdating, setIsUpdating] = useState<boolean>(false);

    // 2. DISPATCH OVERRIDE TO EXPRESS SERVICE
    const handlePushMapOverride = async () => {
        setIsUpdating(true);

        const customPayload = {
            universeId: 29847104,
            globalSeaLevel: 120,
            variantA_Segments: [
                {
                    id: "seg_watcher_volcano",
                    name: "The Isolated Watcher Island",
                    targetMaterial: "Basalt",
                    hexMaskColor: "#2B2B2B",
                    centerStuds: { x: -8000, y: 500, z: -8000 },
                    sizeStuds: volcanoSize, // Dynamic coordinate override mapping
                    loadPriority: 2
                },
                {
                    id: "seg_cimmerian_ridge",
                    name: "Cimmerian Mainland Shield Wall",
                    targetMaterial: "Rock",
                    hexMaskColor: "#8A857B",
                    centerStuds: { x: 4000, y: 800, z: 4000 },
                    sizeStuds: ridgeSize,  // Dynamic coordinate override mapping
                    loadPriority: 1
                }
            ],
            variantB_Segments: [
                {
                    id: "seg_watcher_volcano",
                    name: "Watcher Island (VOLCANIC AGGRESSOR VARIANT)",
                    targetMaterial: "Basalt",
                    hexMaskColor: "#2B2B2B",
                    centerStuds: { x: -5000, y: 900, z: -5000 }, 
                    sizeStuds: { x: 7500, y: 2800, z: 7500 }, 
                    loadPriority: 2
                }
            ]
        };

        try {
            const response = await fetch('http://localhost:3030/api/v1/liveops/sync-override', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(customPayload)
            });
            const result = await response.json();
            
            if (result.success) {
                alert(`🏗️ MAP SYNCED: Voxel bounding coordinates committed to cloud memory.`);
            } else {
                alert(`⚠️ Sync Rejection: ${result.error}`);
            }
        } catch (error) {
            console.error("Map matrix push failed:", error);
            alert("🚨 Critical Core Gateway Connection Timeout.");
        } finally {
            setIsUpdating(false);
        }
    };

    return (
        <div style={{ backgroundColor: '#070C14', color: '#E2E8F0', padding: '24px', fontFamily: 'monospace', borderRadius: '8px', border: '1px solid #00FFCC', boxShadow: '0 0 20px rgba(0, 255, 204, 0.05)' }}>
            
            {/* Header branding block */}
            <header style={{ borderBottom: '1px solid #1E293B', paddingBottom: '14px', marginBottom: '20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                    <h2 style={{ margin: 0, fontSize: '16px', letterSpacing: '1px', textTransform: 'uppercase', color: '#00FFCC' }}>
                        🗺️ Terrain Matrix Customizer & Spatial Modifier
                    </h2>
                    <small style={{ color: '#64748B' }}>Live Voxel Partition Bounds Overwrite Deck</small>
                </div>
                <button
                    onClick={handlePushMapOverride}
                    disabled={isUpdating}
                    style={{ backgroundColor: isUpdating ? '#1E293B' : '#00FFCC', color: '#070C14', border: 'none', padding: '8px 16px', fontWeight: 'bold', borderRadius: '4px', cursor: 'pointer', textTransform: 'uppercase', fontSize: '11px' }}
                >
                    {isUpdating ? 'Modifying...' : 'Stitch Grid New Size'}
                </button>
            </header>

            {/* Inputs Panel Deck */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                
                {/* Volcano Bounds Customization Area */}
                <div style={{ background: '#0F172A', padding: '16px', borderRadius: '6px', border: '1px solid #1E293B' }}>
                    <h3 style={{ fontSize: '12px', textTransform: 'uppercase', color: '#FFB800', margin: '0 0 14px 0' }}>🌋 Watcher Island Volume (Studs)</h3>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                        {(Object.keys(volcanoSize) as Array<keyof Vector3Input>).map((axis) => (
                            <label key={axis} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                                <span style={{ textTransform: 'uppercase', color: '#88A2AA', fontSize: '11px' }}>{axis}-Axis Size:</span>
                                <input 
                                    type="number"
                                    value={volcanoSize[axis]}
                                    onChange={(e) => setVolcanoSize(prev => ({ ...prev, [axis]: Number(e.target.value) }))}
                                    style={{ backgroundColor: '#020617', border: '1px solid #334155', padding: '6px 10px', color: '#00FFCC', borderRadius: '4px', width: '120px', textAlign: 'right', fontSize: '12px' }}
                                />
                            </label>
                        ))}
                    </div>
                </div>

                {/* Ridge Bounds Customization Area */}
                <div style={{ background: '#0F172A', padding: '16px', borderRadius: '6px', border: '1px solid #1E293B' }}>
                    <h3 style={{ fontSize: '12px', textTransform: 'uppercase', color: '#38BDF8', margin: '0 0 14px 0' }}>⛰️ Cimmerian Mainland Bounds (Studs)</h3>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                        {(Object.keys(ridgeSize) as Array<keyof Vector3Input>).map((axis) => (
                            <label key={axis} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                                <span style={{ textTransform: 'uppercase', color: '#88A2AA', fontSize: '11px' }}>{axis}-Axis Size:</span>
                                <input 
                                    type="number"
                                    value={ridgeSize[axis]}
                                    onChange={(e) => setRidgeSize(prev => ({ ...prev, [axis]: Number(e.target.value) }))}
                                    style={{ backgroundColor: '#020617', border: '1px solid #334155', padding: '6px 10px', color: '#38BDF8', borderRadius: '4px', width: '120px', textAlign: 'right', fontSize: '12px' }}
                                />
                            </label>
                        ))}
                    </div>
                </div>

            </div>
        </div>
    );
};