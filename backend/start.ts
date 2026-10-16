import { app, synchronizeHeadlessWpLore } from './server.js';

const port = Number(process.env.PORT || 3030);
const host = process.env.HOST || '127.0.0.1';
const server = app.listen(port, host, () => console.log(`Tethys API listening at http://${host}:${port}`));
void synchronizeHeadlessWpLore();

function shutdown() {
    server.close(() => process.exit(0));
    setTimeout(() => process.exit(1), 5000).unref();
}
process.once('SIGINT', shutdown);
process.once('SIGTERM', shutdown);
