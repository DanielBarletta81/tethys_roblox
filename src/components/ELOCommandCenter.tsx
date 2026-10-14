// ELOCommandCenter.tsx
// Production-grade TypeScript/React for the Roblox Experience LiveOps Dashboard
import React, { useState, useMemo } from 'react';

export type MapToolId = 'volcano_scaler' | 'ridge_curler' | 'cliff_sharpener' | 'basin_smoother' | 'sea_level_dial' | 'predator_guard' | 'seam_welder';

interface MapTool {
    id: MapToolId;
    name: string;
    description: string;
    icon: string;
    category: 'Erosion' | 'Tectonics' | 'Hydrology' | 'Safety';
}

interface Vector3Input {
    x: number;
    y: number;
    z: number;
}

const SYSTEM_TOOLS: MapTool[] = [
    { id: 'volcano_scaler', name: 'Watcher Caldera Igniter', description: 'Modifies magma core radius and eruption vectors', icon: '🌋', category: 'Tectonics' },
    { id: 'ridge_curler', name: 'Cimmerian Ridge Loom', description: 'Sweeps and wraps the coastal mountain shield walls', icon: '⛰️', category: 'Tectonics' },
    { id: 'cliff_sharpener', name: 'Prehistoric Erosion Eraser', description: 'Hardens limestone faces into sheer vertical cliffs', icon: '🔪', category: 'Erosion' },
    { id: 'basin_smoother', name: 'Sky City Bed Placer', description: 'Flattens internal valley basins for city infrastructure', icon: '🚜', category: 'Erosion' },
    { id: 'sea_level_dial', name: 'Mesozoic Water Lock', description: 'Alters global sea level and trench depth variables', icon: '🌊', category: 'Hydrology' },
    { id: 'predator_guard', name: 'Apex Prevention Barrier', description: 'Adjusts environmental spawn zones for security', icon: '🦖', category: 'Safety' },
    { id: 'seam_welder', name: 'Voxel Crack Stitcher', description: 'Ensures perfect pixel alignment across Mac boundaries', icon: '⚡', category: 'Hydrology' }
];

export const ELOCommandCenter: React.FC = () => {
    const [volcanoPos, setVolcanoPos] = useState<Vector3Input>({ x: -8000, y: 500, z: -8000 });
    const [ridgeSize, setRidgeSize] = useState<Vector3Input>({ x: 12000, y: 2500, z: 8000 });
    const [activeTool, setActiveTool] = useState<MapToolId>('volcano_scaler');
    const [isSyncing, setIsSyncing] = useState<boolean>(false);
    
    const [toolUsage, setToolUsage] = useState<Record<MapToolId, number>>({
        volcano_scaler: 12,
        ridge_curler: 9,
        cliff_sharpener: 4,
        basin_smoother: 2,
        sea_level_dial: 1,
        predator_guard: 0,
        seam_welder: 7
    });

    const handleToolSelect = (toolId: MapToolId) => {
        setActiveTool(toolId);
        setToolUsage(prev => ({
            ...prev,
            [toolId]: prev[toolId] + 1
        }));
    };

    const topMagnifiedTools = useMemo(() => {
        return [...SYSTEM_TOOLS]
            .sort((a, b) => toolUsage[b.id] - toolUsage[a.id])
            .slice(0, 5);
    }, [toolUsage]);

    const syncToRobloxServers = async () => {
        setIsSyncing(true);
        const updatedPayload = {
            universeId: 29847104,
            globalSeaLevel: 120,
            variantA_Segments: [
                {
                    id: "seg_watcher_volcano",
                    name: "The Isolated Watcher Island",
                    targetMaterial: "Basalt",
                    hexMaskColor: "#2B2B2B",
                    centerStuds: volcanoPos,
                    sizeStuds: { x: 4000, y: 1762, z: 4000 },
                    loadPriority: 2
                },
                {
                    id: "seg_cimmerian_ridge",
                    name: "Cimmerian Mainland Shield Wall",
                    targetMaterial: "Rock",
                    hexMaskColor: "#8A857B",
                    centerStuds: { x: 4000, y: 800, z: 4000 },
                    sizeStuds: ridgeSize,
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
                body: JSON.stringify(updatedPayload)
            });
            const result = await response.json();
            if (result.success) {
                alert(`📡 Command Center Connected: ${result.message}`);
            } else {
                alert(`⚠️ LiveOps Server Rejection: ${result.error}`);
            }
        } catch (error) {
            console.error("Network synchronization failed:", error);
            alert("🚨 Critical Core Gateway Connection Timeout.");
        } finally {
            setIsSyncing(false);
        }
    };

   return (
        <div style={{ backgroundColor: '#0A0F14', color: '#00FFCC', padding: '24px', fontFamily: 'monospace', minHeight: '100vh' }}>
            {/* Header Telemetry Grid */}
            <header style={{ borderBottom: '2px solid #00FFCC', paddingBottom: '12px', marginBottom: '24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                    <h1 style={{ fontSize: '24px', margin: 0, textTransform: 'uppercase', letterSpacing: '2px' }}>🌌 ELO Command Matrix: Sky City</h1>
                    <small style={{ color: '#88A2AA' }}>Roblox Experience LiveOps Platform Environment</small>
                </div>
                <button 
                    onClick={syncToRobloxServers}
                    disabled={isSyncing}
                    style={{ backgroundColor: isSyncing ? '#334440' : '#00FFCC', color: '#0A0F14', border: 'none', padding: '10px 20px', fontWeight: 'bold', cursor: 'pointer', borderRadius: '4px', textTransform: 'uppercase' }}
                >
                    {isSyncing ? '⚡ Syncing Core Grid...' : '📡 Push Config to Servers'}
                </button>
            </header>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 350px', gap: '24px' }}>
                
                {/* Main Control Vector Desk */}
                <main>
                    {/* STAR WARS COMMAND CENTER COMPONENT: MAGNIFIED TOOL ARSENAL */}
                    <section style={{ background: '#111822', border: '1px solid #00AA99', padding: '20px', borderRadius: '8px', marginBottom: '24px' }}>
                        <h2 style={{ fontSize: '14px', textTransform: 'uppercase', color: '#FFB800', marginTop: '0', marginBottom: '16px' }}>
                            🔴 Tactical Quick-Swap Deck (Top 5 Highly Magnified Controls)
                        </h2>
                        <div style={{ display: 'flex', gap: '16px', alignItems: 'flex-end', minHeight: '120px' }}>
                            {topMagnifiedTools.map((tool) => {
                                const isCurrent = activeTool === tool.id;
                                const totalUses = toolUsage[tool.id];
                                
                                return (
                                    <button
                                        key={tool.id}
                                        onClick={() => handleToolSelect(tool.id)}
                                        style={{
                                            flex: 1,
                                            background: isCurrent ? '#00332B' : '#16222F',
                                            border: isCurrent ? '2px solid #00FFCC' : '1px solid #224455',
                                            borderRadius: '6px',
                                            padding: '16px 8px',
                                            color: '#FFF',
                                            cursor: 'pointer',
                                            transition: 'transform 0.2s ease, all 0.2s',
                                            transform: isCurrent ? 'scale(1.12)' : 'scale(1.0)',
                                            boxShadow: isCurrent ? '0 0 15px rgba(0, 255, 204, 0.4)' : 'none',
                                        }}
                                    >
                                        <div style={{ fontSize: '28px', marginBottom: '4px' }}>{tool.icon}</div>
                                        <div style={{ fontSize: '11px', fontWeight: 'bold', textOverflow: 'ellipsis', overflow: 'hidden', whiteSpace: 'nowrap' }}>{tool.name}</div>
                                        <div style={{ fontSize: '9px', color: '#00FFCC', marginTop: '4px' }}>{totalUses} Cycles</div>
                                    </button>
                                );
                            })}
                        </div>
                    </section>

                    {/* Vector Coordinates Parameter Arrays */}
                    <section style={{ background: '#111822', border: '1px solid #224455', padding: '20px', borderRadius: '8px' }}>
                        <h3 style={{ textTransform: 'uppercase', fontSize: '16px', marginBottom: '16px' }}>🛰️ Active Coordinates Manipulation Console</h3>
                        
                        <div style={{ marginBottom: '20px' }}>
                            <h4>🌋 Watcher Volcano Origin Grid (NW Island Anchor)</h4>
                            <div style={{ display: 'flex', gap: '12px' }}>
                                {(Object.keys(volcanoPos) as Array<keyof Vector3Input>).map((axis) => (
                                    <label key={axis} style={{ flex: 1 }}>
                                        <span style={{ textTransform: 'uppercase', color: '#88A2AA' }}>{axis} Node:</span>
                                        <input 
                                            type="number" 
                                            value={volcanoPos[axis]} 
                                            onChange={(e) => setVolcanoPos(prev => ({ ...prev, [axis]: Number(e.target.value) }))}
                                            style={{ width: '100%', background: '#0A0F14', border: '1px solid #224455', padding: '8px', color: '#00FFCC', borderRadius: '4px', marginTop: '4px' }}
                                        />
                                    </label>
                                ))}
                            </div>
                        </div>

                        <div>
                            <h4>⛰️ Cimmerian Mainland Ridge Volume (Shield Volume)</h4>
                            <div style={{ display: 'flex', gap: '12px' }}>
                                {(Object.keys(ridgeSize) as Array<keyof Vector3Input>).map((axis) => (
                                    <label key={axis} style={{ flex: 1 }}>
                                        <span style={{ textTransform: 'uppercase', color: '#88A2AA' }}>{axis} Bounds:</span>
                                        <input 
                                            type="number" 
                                            value={ridgeSize[axis]} 
                                            onChange={(e) => setRidgeSize(prev => ({ ...prev, [axis]: Number(e.target.value) }))}
                                            style={{ width: '100%', background: '#0A0F14', border: '1px solid #224455', padding: '8px', color: '#00FFCC', borderRadius: '4px', marginTop: '4px' }}
                                        />
                                    </label>
                                ))}
                            </div>
                        </div>
                    </section>
                </main>

                {/* Left Master Tool Matrix Sub-panel */}
                <aside style={{ background: '#111822', border: '1px solid #224455', padding: '20px', borderRadius: '8px' }}>
                    <h3 style={{ fontSize: '14px', textTransform: 'uppercase', marginTop: '0', color: '#88A2AA' }}>🌌 System Manifest</h3>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', marginTop: '16px' }}>
                        {SYSTEM_TOOLS.map((tool) => (
                            <div 
                                key={tool.id}
                                onClick={() => handleToolSelect(tool.id)}
                                style={{
                                    padding: '12px',
                                    background: activeTool === tool.id ? '#1A2936' : '#0A0F14',
                                    borderLeft: activeTool === tool.id ? '4px solid #00FFCC' : '4px solid transparent',
                                    cursor: 'pointer',
                                    borderRadius: '0 4px 4px 0',
                                    transition: 'background 0.2s'
                                }}
                            >
                                <div style={{ display: 'flex', justifyContent: 'space-between', fontWeight: 'bold' }}>
                                    <span>{tool.icon} {tool.name}</span>
                                    <span style={{ fontSize: '10px', color: '#FFB800' }}>{tool.category}</span>
                                </div>
                                <p style={{ fontSize: '11px', color: '#88A2AA', margin: '6px 0 0 0' }}>{tool.description}</p>
                            </div>
                        ))}
                    </div>
                </aside>
            </div>
        </div>
    );
};

export default ELOCommandCenter;    