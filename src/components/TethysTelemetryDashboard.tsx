// TethysTelemetryDashboard.tsx
// Production-grade React Telemetry Interface connecting directly to our server.ts API
import React, { useState, useEffect, useMemo } from 'react';

// Structuring exact typings to match our Node Express response payloads
interface TelemetryMetricFrame {
    jobId: string;
    fps: number;
    memoryMb: number;
    activePlayerCount: number;
    ashSaturationPercent: number;
    regionId: string;
}

export const TethysTelemetryDashboard: React.FC = () => {
    const [metricsLog, setMetricsLog] = useState<TelemetryMetricFrame[]>([]);
    const [isConnected, setIsConnected] = useState<boolean>(true);

    // 1. DYNAMIC HEARTBEAT POLLING IMPLEMENTATION
    useEffect(() => {
        const fetchLatestTelemetryData = async () => {
            try {
                // Hits your Express backend metrics route on Port 3030
                const response = await fetch('http://localhost:3030/api/v1/tethys/telemetry/dashboard-stream');
                const result = await response.json();
                
                if (result.success && Array.isArray(result.metricsHistory)) {
                    setMetricsLog(result.metricsHistory);
                    setIsConnected(true);
                }
            } catch (err) {
                console.error('🚨 [Dashboard Link Error] Unable to connect to ELO Backend Gateway:', err);
                setIsConnected(false); // Flag system connection drops visually
            }
        };

        // Fire request immediately on mount, then poll every 3 seconds
        fetchLatestTelemetryData();
        const pollingIntervalId = setInterval(fetchLatestTelemetryData, 3000);
        
        return () => clearInterval(pollingIntervalId);
    }, []);

    // 2. USEMEMO CALCULUS: Compute derived performance metrics to isolate re-renders
    const liveFrame = useMemo((): TelemetryMetricFrame => {
        if (metricsLog.length === 0) {
            return { jobId: "OFFLINE_SANDBOX", fps: 60, memoryMb: 1150, activePlayerCount: 0, ashSaturationPercent: 0, regionId: "SKY_CITY_TIER_7" };
        }
        return metricsLog[metricsLog.length - 1]; // Pull latest incoming telemetry frame
    }, [metricsLog]);

    const runtimeStatus = useMemo(() => {
        if (!isConnected) return { label: 'OFFLINE_DISCONNECTED', color: '#FF3344' };
        if (liveFrame.fps < 45) return { label: 'PERFORMANCE_CRITICAL_HARM', color: '#FF3344' };
        if (liveFrame.ashSaturationPercent > 70) return { label: 'MAX_WATCHER_ASH_FALLOUT', color: '#FFB800' };
        return { label: 'GRID_OPTIMIZED_STABLE', color: '#00FFCC' };
    }, [liveFrame, isConnected]);

    return (
        <div style={{ backgroundColor: '#070C14', color: '#E2E8F0', padding: '24px', fontFamily: 'monospace', borderRadius: '8px', border: `1px solid ${runtimeStatus.color}`, boxShadow: `0 0 20px ${runtimeStatus.color}15`, minHeight: '400px' }}>
            
            {/* Dashboard Controls Header */}
            <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #1E293B', paddingBottom: '16px', marginBottom: '20px' }}>
                <div>
                    <h2 style={{ margin: 0, fontSize: '18px', letterSpacing: '1px', textTransform: 'uppercase', color: '#FFF' }}>
                        🌋 Tethys Environment & Voxel Telemetry Desk
                    </h2>
                    <small style={{ color: '#64748B' }}>Container Cluster Signature: <span style={{ color: '#00FFCC' }}>{liveFrame.jobId.substring(0, 16)}</span></small>
                </div>
                <span style={{ fontSize: '11px', fontWeight: 'bold', color: runtimeStatus.color, backgroundColor: `${runtimeStatus.color}10`, padding: '6px 12px', borderRadius: '4px', border: `1px solid ${runtimeStatus.color}33` }}>
                    STATUS: {runtimeStatus.label}
                </span>
            </header>

            {/* Telemetry Visual Cards Grid */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '16px', marginBottom: '24px' }}>
                <div style={{ background: '#0F172A', padding: '16px', borderRadius: '6px', border: '1px solid #1E293B' }}>
                    <span style={{ fontSize: '11px', color: '#94A3B8', display: 'block', marginBottom: '4px' }}>CLIENT ENGINE SPEED</span>
                    <strong style={{ fontSize: '26px', color: liveFrame.fps < 45 ? '#FF3344' : '#00FFCC' }}>{liveFrame.fps} FPS</strong>
                </div>

                <div style={{ background: '#0F172A', padding: '16px', borderRadius: '6px', border: '1px solid #1E293B' }}>
                    <span style={{ fontSize: '11px', color: '#94A3B8', display: 'block', marginBottom: '4px' }}>VOXEL RAM OVERHEAD</span>
                    <strong style={{ fontSize: '26px', color: '#FFF' }}>{liveFrame.memoryMb} MB</strong>
                </div>

                <div style={{ background: '#0F172A', padding: '16px', borderRadius: '6px', border: '1px solid #1E293B' }}>
                    <span style={{ fontSize: '11px', color: '#94A3B8', display: 'block', marginBottom: '4px' }}>WATCHER ASH INTENSITY</span>
                    <strong style={{ fontSize: '26px', color: '#FFB800' }}>{liveFrame.ashSaturationPercent}%</strong>
                    <div style={{ width: '100%', height: '4px', backgroundColor: '#1E293B', borderRadius: '2px', marginTop: '6px', overflow: 'hidden' }}>
                        <div style={{ width: `${liveFrame.ashSaturationPercent}%`, height: '100%', backgroundColor: '#FFB800', transition: 'width 0.3s ease' }} />
                    </div>
                </div>

                <div style={{ background: '#0F172A', padding: '16px', borderRadius: '6px', border: '1px solid #1E293B' }}>
                    <span style={{ fontSize: '11px', color: '#94A3B8', display: 'block', marginBottom: '4px' }}>ACTIVE SECTOR LOCALIZATION</span>
                    <strong style={{ fontSize: '14px', color: '#38BDF8', display: 'block', marginTop: '8px', textTransform: 'uppercase' }}>{liveFrame.regionId}</strong>
                    <span style={{ fontSize: '10px', color: '#64748B' }}>Players: {liveFrame.activePlayerCount}</span>
                </div>
            </div>

            {/* Ingestion Stream Console */}
            <section style={{ background: '#020617', border: '1px solid #1E293B', borderRadius: '6px', padding: '16px' }}>
                <h4 style={{ margin: '0 0 10px 0', fontSize: '11px', color: '#94A3B8', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                    📟 Open Cloud Telemetry Data Ingestion Stream
                </h4>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', maxHeight: '120px', overflowY: 'auto', fontSize: '11px', color: '#88A2AA' }}>
                    {metricsLog.slice(-4).reverse().map((frame, index) => (
                        <div key={index} style={{ borderBottom: '1px solid #0F172A', paddingBottom: '4px' }}>
                            [{new Date().toLocaleTimeString()}] INGESTION_OK: Node [{frame.jobId.substring(0,6)}] reported {frame.fps} FPS | {frame.memoryMb}MB Memory Overhead inside region {frame.regionId}.
                        </div>
                    ))}
                    {metricsLog.length === 0 && (
                        <div style={{ color: '#64748B', textAlign: 'center', padding: '8px' }}>Awaiting connection handshake from active Roblox engine instances...</div>
                    )}
                </div>
            </section>
        </div>
    );
};