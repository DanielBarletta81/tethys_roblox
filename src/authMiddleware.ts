// authMiddleware.ts
import { Request, Response, NextFunction } from 'express';
import crypto from 'crypto';

const GATEWAY_SECRET_KEY = process.env.ELO_SYSTEM_HMAC_SECRET || 'SECRET_SAN_MATEO_TOKEN_KEY_5548';
/**
 * Production-Grade Security Middleware
 * Mandates cryptographic authorization for any pipeline data alterations
 */
export const verifyCloudSignature = (req: Request, res: Response, next: NextFunction) => {
    const signature = req.headers['x-elo-signature'] as string;
    const clientTimestamp = req.headers['x-elo-timestamp'] as string;

    console.log('\n📥 [EXPRESS FIREWALL INGESTION LOG] Inspecting Request Metrics...');
    console.log(`➡️ Inbound Signature  : ${signature}`);
    console.log(`➡️ Inbound Timestamp  : ${clientTimestamp}`);

    if (!signature || !clientTimestamp) {
        console.error('❌ VALIDATION DROPPED: Missing cryptographic signature parameters in request headers.');
        return res.status(401).json({ success: false, error: 'Missing security validation headers.' });
    }

    const serverTime = Math.floor(Date.now() / 1000);
    const timeDelta = Math.abs(serverTime - parseInt(clientTimestamp, 10));
    console.log(`➡️ Calculated Clock Delta : ${timeDelta} seconds (Max permitted window: 300s)`);

    if (timeDelta > 300) {
        console.error(`❌ VALIDATION DROPPED: Replay attack barrier triggered. Clock discrepancy too wide.`);
        return res.status(403).json({ success: false, error: 'Cryptographic execution window expired.' });
    }

    // Local Signature Construction tracking
    const messagePayload = `${clientTimestamp}.${JSON.stringify(req.body)}`;
   // Ensure the locally built comparison token checks against this exact variable:
const expectedSignature = crypto
    .createHmac('sha256', GATEWAY_SECRET_KEY)
    .update(messagePayload)
    .digest('hex');

    console.log(`➡️ Expected Clear Token : ${expectedSignature}`);

    if (signature !== expectedSignature) {
        console.error('❌ VALIDATION DROPPED: Token mismatched. Request signatures do not match.');
        return res.status(403).json({ success: false, error: 'Invalid cryptographic authentication signature.' });
    }

    console.log('✅ ACCESS GRANTED: Signatures match. Routing transaction safely to operational cache memory.');
    next();
};