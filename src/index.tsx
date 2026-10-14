// src/index.tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import { ELOCommandCenter } from './components/ELOCommandCenter.js';
import { TethysTelemetryDashboard } from './components/TethysTelemetryDashboard.js';
import { TethysPredatorDash } from './components/TethysPredatorDash.js';
import { TethysProfileEditor } from './components/TethysProfileEditor.js';
import { TethysMetricsTracker } from './components/TethysMetricsTracker.js';
import { TethysClusterTopography } from './components/TethysClusterTopography.js';
// IMPORT CHECK: Insert our newly compiled map customizer widget
import { TethysMapCustomizer } from './components/TethysMapCustomizer.js';

const App: React.FC = () => {
    return (
        <div style={{ backgroundColor: '#030712', minHeight: '100vh', padding: '24px', display: 'flex', flexDirection: 'column', gap: '24px' }}>
            {/* Primary Control Vector Matrix Desk */}
            <ELOCommandCenter />

            {/* Live Ops Spatial Geometry Customizer Tool Override Panel */}
            <TethysMapCustomizer />

            {/* Global Container Infrastructure Table Workspace Expansion */}
            <TethysClusterTopography />

            {/* Split Diagnostics Grid View */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px' }}>
                <TethysTelemetryDashboard />
                <TethysPredatorDash />
            </div>

            {/* DataStore Administration and Live Telemetry Monitors */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px' }}>
                <TethysProfileEditor />
                <TethysMetricsTracker />
            </div>
        </div>
    );
};

const rootElement = document.getElementById('root');
if (!rootElement) {
    throw new Error("🚨 [Vite Mount Failure] Could not locate HTML mounting anchor layer with element ID: 'root'.");
}

const root = ReactDOM.createRoot(rootElement);
root.render(
    <React.StrictMode>
        <App />
    </React.StrictMode>
);