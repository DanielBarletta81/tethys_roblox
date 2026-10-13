// src/scripts/deploy-liveops.ts
console.log("🔥 [SMOKE TEST 2] Top-level compilation verified. Loading modules...");

import 'dotenv/config'; 
import axios from 'axios';
import crypto from 'crypto';
import { liveOpsABExperimentMatrix } from '../worldConfigSchema.js';


console.log("📦 [Modules Loaded] Schema successfully linked. Configuring target routes...");

const TARGET_API_URL = 'http://localhost:3030/api/v1/liveops/sync-override';
const GATEWAY_SECRET_KEY = process.env.ELO_SYSTEM_HMAC_SECRET || 'SECRET_SAN_MATEO_TOKEN_KEY_5548';

// OUTBOUND TRACER: Validates connection parameters before dropping onto network
axios.interceptors.request.use(request => {
    console.log('\n📡 [Axios Pipeline] Initializing secure data transaction...');
    return request;
});

function runPreflightChecks(payload: typeof liveOpsABExperimentMatrix): boolean {
    console.log('🔍 [Pipeline] Initiating preflight experiment checks...');
    
    if (!payload.variantA_Segments || !payload.variantB_Segments) {
        console.error('❌ [Preflight Error] Missing experiment variant configuration blocks.');
        return false;
    }

    if (!Array.isArray(payload.variantA_Segments) || !Array.isArray(payload.variantB_Segments)) {
        console.error('❌ [Preflight Error] Experiment segments must be structured as valid arrays.');
        return false;
    }

    console.log('✅ [Preflight Success] Layout payload structures verified.');
    return true;
}

async function executeLiveOpsDeployment() {
    console.log('\n================================================================');
    console.log('📡 INITIALIZING OPEN CLOUD DEPLOYMENT ROUTINE: WORLD OF TETHYS');
    console.log('================================================================');

    if (!runPreflightChecks(liveOpsABExperimentMatrix)) {
        console.error('🚨 [Deployment Aborted] Preflight validation failed. Network transmission blocked.');
        process.exit(1);
    }

    const timestamp = Math.floor(Date.now() / 1000).toString();
    const messagePayload = `${timestamp}.${JSON.stringify(liveOpsABExperimentMatrix)}`;
    
    const hmacSignature = crypto
        .createHmac('sha256', GATEWAY_SECRET_KEY)
        .update(messagePayload)
        .digest('hex');

    console.log(`🔒 [Security] Generated SHA256 HMAC Signature footprint: ${hmacSignature.substring(0, 16)}...`);

    try {
        console.log(`🚀 [Network] Pushing active layout vectors to ELO API Gateway...`);
        
        const response = await axios.post(TARGET_API_URL, liveOpsABExperimentMatrix, {
            headers: {
                'Content-Type': 'application/json',
                'x-elo-signature': hmacSignature,
                'x-elo-timestamp': timestamp
            }
        });

        if (response.status === 200) {
            console.log('\n================================================================');
            console.log('🎉 [DEPLOYMENT SUCCESSFUL] LiveOps configuration pushed live!');
            console.log(`💬 Gateway Response: ${JSON.stringify(response.data.message)}`);
            console.log('================================================================\n');
        }
    } catch (error: any) {
        console.error('\n================================================================');
        console.error('🚨 [DEPLOYMENT CRITICAL FAILURE] Remote API rejected transaction!');
        if (error.response) {
            console.error(`❌ Status: ${error.response.status} - ${error.response.statusText}`);
            console.error(`❌ Error Details: ${JSON.stringify(error.response.data)}`);
        } else {
            console.error(`❌ Connection Error: ${error.message}`);
        }
        console.error('================================================================');
        process.exit(1);
    }
}

// FORCE WRAPPER: Resolves top-level async execution patterns cleanly
executeLiveOpsDeployment()
    .then(() => {
        console.log("🏁 [Pipeline] Execution lifecycle finished cleanly.");
        process.exit(0);
    })
    .catch((error) => {
        console.error("🚨 [Pipeline Critical Failure] Unhandled exception breached execution bounds:", error);
        process.exit(1);
    });