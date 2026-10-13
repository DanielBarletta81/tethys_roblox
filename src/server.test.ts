import request from 'supertest';
import express, {Application} from 'express';
import { app } from './server.js';

describe('LiveOps Sync API', () => {
    it('should successfully sync with valid payload', async () => {
        const payload = {
            universeId: 29847104,
            globalSeaLevel: 120,
            segments: [
                {
                    id: "seg_watcher_volcano",
                    name: "The Isolated Watcher Island",
                    targetMaterial: "Basalt",
                    hexMaskColor: "#2B2B2B",
                    centerStuds: { x: -8000, y: 500, z: -8000 },
                    sizeStuds: { x: 4000, y: 1762, z: 4000 },
                    loadPriority: 2
                },
                {
                    id: "seg_cimmerian_ridge",
                    name: "Cimmerian Mainland Shield Wall",
                    targetMaterial: "Rock",
                    hexMaskColor: "#8A857B",
                    centerStuds: { x: 4000, y: 800, z: 4000 },
                    sizeStuds: { x: 12000, y: 2500, z: 8000 },
                    loadPriority: 1
                }
            ]
        };

        const response = await request(app)
            .post('/api/v1/liveops/sync-override')
            .send(payload)
            .set('Accept', 'application/json');

        expect(response.status).toBe(200);
        expect(response.body.success).toBe(true);
    });

    it('should return an error for invalid payload', async () => {
        const invalidPayload = {};

        const response = await request(app)
            .post('/api/v1/liveops/sync-override')
            .send(invalidPayload)
            .set('Accept', 'application/json');

        expect(response.status).toBe(400);
        expect(response.body.success).toBe(false);
    });
});