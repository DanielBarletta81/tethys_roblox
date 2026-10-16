import request from 'supertest';
import crypto from 'node:crypto';
import { app } from './server.js';

const key = 'unit-test-only-gateway-key';
const savedKey = process.env.ELO_SYSTEM_HMAC_SECRET;
beforeEach(() => { process.env.ELO_SYSTEM_HMAC_SECRET = key; });
afterAll(() => {
    if (savedKey === undefined) delete process.env.ELO_SYSTEM_HMAC_SECRET;
    else process.env.ELO_SYSTEM_HMAC_SECRET = savedKey;
});
const segment = { id: 'fixture', name: 'Fixture', targetMaterial: 'Rock',
    centerStuds: { x: 0, y: 200, z: 0 }, sizeStuds: { x: 32, y: 32, z: 32 }, loadPriority: 1 };
const payload = { variantA_Segments: [segment], variantB_Segments: [segment] };
const path = '/api/v1/liveops/sync-override';

it('imports the app without opening a listener or contacting WordPress', () => expect(typeof app).toBe('function'));
it('fails closed when authentication is not configured', async () => {
    delete process.env.ELO_SYSTEM_HMAC_SECRET;
    expect((await request(app).post(path).send(payload)).status).toBe(503);
});
it('rejects unsigned mutations', async () => expect((await request(app).post(path).send(payload)).status).toBe(401));
it('rejects a malformed timestamp', async () => {
    const response = await request(app).post(path).set('x-elo-timestamp', 'not-a-time').set('x-elo-signature', 'a'.repeat(64)).send(payload);
    expect(response.status).toBe(401);
});
it('rejects expired signatures', async () => {
    const timestamp = String(Math.floor(Date.now()/1000)-600);
    const signature = crypto.createHmac('sha256',key).update(`${timestamp}.${JSON.stringify(payload)}`).digest('hex');
    expect((await request(app).post(path).set('x-elo-timestamp',timestamp).set('x-elo-signature',signature).send(payload)).status).toBe(403);
});
it('accepts a valid HMAC request', async () => {
    const timestamp = String(Math.floor(Date.now()/1000));
    const signature = crypto.createHmac('sha256',key).update(`${timestamp}.${JSON.stringify(payload)}`).digest('hex');
    expect((await request(app).post(path).set('x-elo-timestamp',timestamp).set('x-elo-signature',signature).send(payload)).status).toBe(200);
});
it('accepts the server-only bearer credential used by Roblox Secret Store', async () => {
    expect((await request(app).post(path).auth(key,{type:'bearer'}).send(payload)).status).toBe(200);
});
it('rejects an invalid bearer credential', async () => {
    expect((await request(app).post(path).auth('wrong',{type:'bearer'}).send(payload)).status).toBe(401);
});
it('validates the actual variant schema after authentication', async () => {
    expect((await request(app).post(path).auth(key,{type:'bearer'}).send({segments:[segment]})).status).toBe(400);
});
it('protects the player-zone mutation route too', async () => {
    expect((await request(app).post('/api/v1/wildbound/survival/zone-update').send({userId:'42',targetZone:'Ordovic_Rapids'})).status).toBe(401);
});
it('keeps the CMS read endpoint available without credentials', async () => {
    expect((await request(app).get('/api/v1/tethys/lore/cms-stream')).status).toBe(200);
});
it('rejects an unknown zone without corrupting session state', async () => {
    const response=await request(app).post('/api/v1/wildbound/survival/zone-update').auth(key,{type:'bearer'}).send({userId:'42',targetZone:'invented'});
    expect(response.status).toBe(400);
});
it('accepts a validated server-authored river entry', async () => {
    const response=await request(app).post('/api/v1/wildbound/survival/zone-update').auth(key,{type:'bearer'}).send({userId:'42',targetZone:'Ordovic_Rapids',applyInjury:0});
    expect(response.status).toBe(200);expect(response.body.currentSession.currentZone).toBe('Ordovic_Rapids');
});
