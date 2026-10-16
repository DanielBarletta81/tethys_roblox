import type { Request, Response, NextFunction } from 'express';
import crypto from 'node:crypto';

// Only the trusted CLI/backend holds this secret. Never replicate it to Roblox clients.
export function verifyCloudSignature(req: Request, res: Response, next: NextFunction) {
    const secret = process.env.ELO_SYSTEM_HMAC_SECRET;
    if (!secret) return res.status(503).json({ success: false, error: 'Gateway authentication is not configured.' });
    const bearer = req.get('authorization');
    if (bearer?.startsWith('Bearer ')) {
        const actual = Buffer.from(bearer.slice(7));
        const expected = Buffer.from(secret);
        if (actual.length === expected.length && crypto.timingSafeEqual(actual, expected)) return next();
        return res.status(401).json({ success: false, error: 'Invalid gateway credentials.' });
    }
    const signature = req.get('x-elo-signature') || '';
    const timestamp = req.get('x-elo-timestamp') || '';
    if (!/^\d{10}$/.test(timestamp) || !/^[a-f\d]{64}$/i.test(signature)) {
        return res.status(401).json({ success: false, error: 'Missing or malformed authentication headers.' });
    }
    if (Math.abs(Math.floor(Date.now() / 1000) - Number(timestamp)) > 300) {
        return res.status(403).json({ success: false, error: 'Signature expired.' });
    }
    const expected = crypto.createHmac('sha256', secret).update(`${timestamp}.${JSON.stringify(req.body)}`).digest();
    if (!crypto.timingSafeEqual(Buffer.from(signature, 'hex'), expected)) {
        return res.status(403).json({ success: false, error: 'Invalid signature.' });
    }
    next();
}
