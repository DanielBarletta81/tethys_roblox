// TethysClusterTopography.tsx
// Administrative Live Ops Infrastructure Monitoring Component for World of Tethys
import React, { useState, useEffect, useMemo } from 'react';

interface LiveServerInstanceMetadata {
    jobId: string;
    serverPlaceId: number;
    activePlayerCount: number;
    maxPlayersCapacity: number;
    assignedTestingCell: string;
    serverUptimeSeconds: number;
    lastPingTimestamp: string;
}

export const TethysClusterTopography: React.FC = () => {
    const [clusterData, setClusterData] = useState<LiveServerInstanceMetadata[]>([]);
    const [isFetchHealthy, setIsFetchHealthy] = useState<boolean>(true);

    // 1. DYNAMIC HEARTBEAT NETWORK SAMPLER
    useEffect(() => {
        const fetchClusterTopography = async () => {
            try {
                const response = await fetch('http://localhost:3030/api/v1/tethys/instances/cluster-metrics');
                const result = await response.json();
                
                if (result.success && Array.isArray(result.clusterTopography)) {
                    setClusterData(result.clusterTopography);
                    setIsFetchHealthy(true);
                }
            } catch (err) {
                console.error("🚨 [Cluster Tracking Dropout] Unable to resolve infrastructure map:", err);
                setIsFetchHealthy(false);
            }
        };

        fetchClusterTopography();
        const telemetryTimerId = setInterval(fetchClusterTopography, 4000); // Sample infrastructure arrays every 4 seconds
        return () => clearInterval(telemetryTimerId);
    }, []);

    // 2. USEMEMO METRIC CALCULUS: Extract operational capacities lazily
    const clusterAggregates = useMemo(() => {
        if (clusterData.length === 0) return { totalPlayers: 0, criticalLoadServers: 0 };
        
        return clusterData.reduce((acc, current) => {
            acc.totalPlayers += current.activePlayerCount;
            // Flag a server container if it breaches 85% of maximum network player cap thresholds
            const loadRatio = current.activePlayerCount / (current.maxPlayersCapacity || 1);
            if (loadRatio >= 0.85) {
                acc.criticalLoadServers += 1;
            }
            return acc;
        }, { totalPlayers: 0, criticalLoadServers: 0 });
    }, [clusterData]);

    // Parse seconds nicely into structural runtime stamps
    const formatUptime = (seconds: number): string => {
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        const s = seconds % 60;
        return `${h}h ${m}m ${s}s`;
    };

    return (
        <div style={{ backgroundColor: '#070C14', color: '#E2E8F0', padding: '24px', fontFamily: 'monospace', borderRadius: '8px', border: isFetchHealthy ? '1px solid #38BDF8' : '1px solid #FF3344', boxShadow: '0 0 20px rgba(56, 189, 248, 0.05)' }}>
            
            {/* Component Header Metadata */}
            <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #1E293B', paddingBottom: '14px', marginBottom: '20px' }}>
                <div>
                    <h2 style={{ margin: 0, fontSize: '16px', letterSpacing: '1px', textTransform: 'uppercase', color: '#38BDF8' }}>
                        📡 Global Container Infrastructure & Server Topography
                    </h2>
                    <small style={{ color: '#64748B' }}>Live Cluster Scaling: <strong style={{ color: '#00FFCC' }}>{clusterData.length} Active Nodes</strong></small>
                </div>
                <div style={{ display: 'flex', gap: '12px', fontSize: '11px' }}>
                    <span style={{ background: '#1E293B', padding: '6px 12px', borderRadius: '4px' }}>
                        TOTAL POPULATION: <strong style={{ color: '#FFF' }}>{clusterAggregates.totalPlayers} Explore</strong>
                    </span>
                    {clusterAggregates.criticalLoadServers > 0 && (
                        <span style={{ background: 'rgba(255, 51, 68, 0.15)', border: '1px solid #FF3344', color: '#FF3344', padding: '6px 12px', borderRadius: '4px', fontWeight: 'bold' }}>
                            ⚠️ {clusterAggregates.criticalLoadServers} INSTANCES AT CAPACITY
                        </span>
                    )}
                </div>
            </header>

            {/* Core Data Presentation Grid Layout */}
            <div style={{ overflowX: 'auto' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '12px', textAlign: 'left' }}>
                    <thead>
                        <tr style={{ borderBottom: '2px solid #1E293B', color: '#64748B', textTransform: 'uppercase' }}>
                            <th style={{ padding: '10px 6px' }}>Container JobId</th>
                            <th>PlaceId Context</th>
                            <th>Active Node Load</th>
                            <th>A/B Deployment Cohort</th>
                            <th>Operational Uptime</th>
                            <th style={{ textAlign: 'right', paddingRight: '6px' }}>Telemetry Link</th>
                        </tr>
                    </thead>
                    <tbody>
                        {clusterData.map((node) => {
                            const isAtCapacity = node.activePlayerCount / (node.maxPlayersCapacity || 1) >= 0.85;
                            return (
                                <tr key={node.jobId} style={{ borderBottom: '1px solid #0F172A', background: isAtCapacity ? 'rgba(255, 51, 68, 0.04)' : 'transparent', transition: 'background 0.2s' }}>
                                    <td style={{ padding: '12px 6px', color: '#38BDF8', fontWeight: 'bold' }}>
                                        {node.jobId === 'local_studio_development_sandbox' ? 'LOCAL_STUDIO_DEV' : `${node.jobId.substring(0, 12)}...`}
                                    </td>
                                    <td style={{ color: '#88A2AA' }}>{node.serverPlaceId}</td>
                                    <td>
                                        <span style={{ color: isAtCapacity ? '#FF3344' : '#FFF', fontWeight: 'bold' }}>
                                            {node.activePlayerCount}
                                        </span>
                                        <span style={{ color: '#64748B' }}>/{node.maxPlayersCapacity} Plrs</span>
                                    </td>
                                    <td>
                                        <span style={{ backgroundColor: node.assignedTestingCell === 'Volcanic_B' ? 'rgba(255, 184, 0, 0.1)' : 'rgba(0, 255, 204, 0.1)', color: node.assignedTestingCell === 'Volcanic_B' ? '#FFB800' : '#00FFCC', padding: '3px 8px', borderRadius: '4px', fontSize: '11px', fontWeight: 'bold' }}>
                                            {node.assignedTestingCell}
                                        </span>
                                    </td>
                                    <td style={{ color: '#E2E8F0' }}>{formatUptime(node.serverUptimeSeconds)}</td>
                                    <td style={{ textAlign: 'right', paddingRight: '6px', color: '#00FFCC', fontSize: '10px', fontWeight: 'bold' }}>
                                        ● ONLINE_CONNECTED
                                    </td>
                                </tr>
                            );
                        })}
                        {clusterData.length === 0 && (
                            <tr>
                                <td colSpan={6} style={{ padding: '32px', textAlign: 'center', color: '#64748B', fontStyle: 'italic', borderBottom: 'none' }}>
                                    No operational server clusters currently checking into the orchestration gateway. Spin up Roblox Studio connections to register hardware nodes.
                                </td>
                            </tr>
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
};