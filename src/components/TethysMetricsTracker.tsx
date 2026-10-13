// TethysMetricsTracker.tsx
// Front-end Live Server Performance Monitoring Console for World of Tethys
import React, { useState, useEffect } from 'react';

interface MetricFrame {
    jobId: string;
    fps: number;
    memoryMb: number;
    activePlayerCount: number;
    ashSaturationPercent: number;
    regionId: string;
}

export const TethysMetricsTracker: React.FC = () => {
    const [metricsHistory, setMetricsHistory] = useState<MetricFrame[]>([]);
    const [systemThreatLevel, setSystemThreatLevel] = useState<string>("GREEN_STABLE");

    useEffect(() => {
        const fetchTelemetryUpdate = async () => {
            try {
                const response = await fetch('http://localhost:3030/api/v1/tethys/telemetry/dashboard-stream');
                const parsed = await response.json();
                if (parsed.success && parsed.metricsHistory.length > 0) {
                    setMetricsHistory(parsed.metricsHistory);
                    
                    // Evaluate latest payload frame to flag environmental ash risks
                    const latestFrame = parsed.metricsHistory[parsed.metricsHistory.length - 1];
                    if (latestFrame.ashSaturationPercent > 70 || latestFrame.fps < 45) {
                        setSystemThreatLevel("CRITICAL_ASH_FALLOUT");
                    } else {
                        setSystemThreatLevel("GREEN_STABLE");
                    }
                }
            } catch (err) {
                console.error("Telemetry link dropout:", err);
            }
        };

        // Standard polling heartbeat interval
        const timerId = setInterval(fetchTelemetryUpdate, 3000);
        return () => clearInterval(timerId);
    }, []);

    const currentFrame = metricsHistory[metricsHistory.length - 1] || {
        fps: 60, memoryMb: 1200, activePlayerCount: 0, ashSaturationPercent: 14, regionId: "Sky_City_Tier_7"
    };

    return (
        <div style={{ backgroundColor: '#060B11', border: '1px solid #FF3344', color: '#FF3344', padding: '20px', fontFamily: 'monospace', borderRadius: '8px', marginTop: '20px' }}>
            <h2 style={{ letterSpacing: '1px', textTransform: 'uppercase', margin: '0 0 12px 0', display: 'flex', justifyContent: 'space-between' }}>
                <span>🛰️ The Watcher Telemetry Core</span>
                <span style={{ color: systemThreatLevel === "GREEN_STABLE" ? '#00FFCC' : '#FF3344' }}>[{systemThreatLevel}]</span>
            </h2>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '16px', marginTop: '16px' }}>
                <div style={{ background: '#0F1622', padding: '12px', borderLeft: '3px solid #00FFCC', borderRadius: '4px' }}>
                    <div style={{ fontSize: '11px', color: '#88A2AA' }}>CLIENT ENGINE SPEED</div>
                    <div style={{ fontSize: '24px', fontWeight: 'bold', color: currentFrame.fps < 45 ? '#FF3344' : '#00FFCC' }}>{currentFrame.fps} FPS</div>
                </div>

                <div style={{ background: '#0F1622', padding: '12px', borderLeft: '3px solid #00FFCC', borderRadius: '4px' }}>
                    <div style={{ fontSize: '11px', color: '#88A2AA' }}>SERVER MEMORY ALLOCATION</div>
                    <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#FFF' }}>{currentFrame.memoryMb} MB</div>
                </div>

                <div style={{ background: '#0F1622', padding: '12px', borderLeft: '3px solid #FFB800', borderRadius: '4px' }}>
                    <div style={{ fontSize: '11px', color: '#88A2AA' }}>VOLCANIC ASH COLUMN PROFILE</div>
                    <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#FFB800' }}>{currentFrame.ashSaturationPercent}% SAT</div>
                </div>

                <div style={{ background: '#0F1622', padding: '12px', borderLeft: '3px solid #00FFCC', borderRadius: '4px' }}>
                    <div style={{ fontSize: '11px', color: '#88A2AA' }}>ACTIVE GEOGRAPHIC ZONE</div>
                    <div style={{ fontSize: '14px', fontWeight: 'bold', color: '#00FFCC', textTransform: 'uppercase', marginTop: '8px' }}>{currentFrame.regionId}</div>
                </div>
            </div>
        </div>
    );
};