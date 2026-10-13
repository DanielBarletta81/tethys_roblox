import React, { useState, useEffect } from 'react';

export const TacticalThreatDisplay: React.FC = () => {
    return (
        <div style={{ background: '#11161F', border: '1px solid #FF3344', padding: '16px', borderRadius: '6px', color: '#FFF', fontFamily: 'monospace' }}>
            <h3 style={{ margin: '0 0 12px 0', textTransform: 'uppercase', color: '#FF3344', fontSize: '14px', letterSpacing: '1px' }}>
                🚨 Live Basin Encounter Radar
            </h3>
            
            <div style={{ border: '1px solid #223344', padding: '10px', background: '#090D14', borderRadius: '4px', marginBottom: '8px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontWeight: 'bold' }}>
                    <span style={{ color: '#FFB800' }}>🐊 SUCHOMIMUS SECTOR</span>
                    <span style={{ color: '#FF3344' }}>HIGH TARGET RISK</span>
                </div>
                <p style={{ fontSize: '11px', color: '#88A2AA', margin: '4px 0 0 0' }}>
                    Active hunting tracks registered inside coordinates [X: 3500, Z: 2500]. Lowland marsh channels heavily weaponized.
                </p>
            </div>

            <div style={{ border: '1px solid #223344', padding: '10px', background: '#090D14', borderRadius: '4px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontWeight: 'bold' }}>
                    <span style={{ color: '#00FFCC' }}>🦕 KRONOSAURUS TRENCH</span>
                    <span style={{ color: '#00FFCC' }}>STABLE BOUNDS</span>
                </div>
                <p style={{ fontSize: '11px', color: '#88A2AA', margin: '4px 0 0 0' }}>
                    Deepwater marine patrol tracking normal migration routes within Northwest Ocean corridor limits [X: -3000, Z: -3000].
                </p>
            </div>
        </div>
    );
};
export const TethysPredatorDash = TacticalThreatDisplay;