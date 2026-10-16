# Roblox and headless integration

2026-10-15. This pass fixes the open `AquaponicsEndpoints.server.ts` errors and separates the Roblox and headless API execution environments. It includes the preceding cave prototype sources. It does not publish a Place, import a terrain reference, enable a second profile store, or turn the later city and creature sketches into completed gameplay.

| Source | Runs in | Build and integration |
| --- | --- | --- |
| `src/server`, `src/client`, `src/shared` | Roblox server, client and shared modules | `tsconfig.json`; roblox-ts emits Luau into `out/` |
| `src/ServerScriptService/OrdovicOpening` | Existing Ordovic server sandbox | Native Luau bootstrap and modules, preserving the reviewed boundaries |
| `src/ServerScriptService/TethysBackend` | Separate server HTTP owner | Disabled until the server-only configuration is provided |
| `src/ServerStorage/OrdovicBuild` | Studio authoring | Bounded cave and water builders; not a runtime world installer |
| `src/ServerStorage/IntegrationTemplates` | Opt-in authoring templates | Preserved later systems, with startup guarded and no automatic live activation |
| `backend` | Node and Express | `tsconfig.api.json`; the importable app is separate from its executable startup |
| `tests`, `plugins`, `tools` | Documented test or authoring contexts | Portable policy tests, Studio fixtures and local authoring tools |

The browser React panels and their Vite, DOM and CORS dependencies were removed at Daniel's request. Roblox UI remains native, including the Roact terminal; Roact creates Roblox instances and has no browser runtime. The native aquaponics terminal uses the installed Roact class API, disconnects its state subscription when unmounted, closes on character removal or leaving the terminal, validates incoming state, and uses `Activated` for native input. It does not award progression.

The endpoint errors were missing `AquaponicsManager.getState()`. It now returns a copy of state. Invalid feed/buffer values are rejected; crate skimming cannot increase inventory through a negative request. The actual terminal handler validates a live character, a server-tagged terminal Model in Workspace, a physical Screen within ten studs, the authoritative job, a known action, and a two-second per-player cooldown. Clients supply neither quantities nor job authority. The sixty-second city tick is server-owned.

## Reproduce the builds

Use Node 22 or newer and install the lockfile dependencies:

```sh
npm ci
npm run typecheck
npm test
npm run build:roblox
python3 tools/install_luau.py
python3 tools/ci_checks.py --luau-dir .tooling/luau-0.741
```

`npm run watch:roblox` watches the Roblox TypeScript files. `rojo serve default.project.json` syncs the composite native and generated sources into a matching development place. Run `npm run build:roblox` first so `out/` and `include/` exist. The compiler-only `roblox-ts.project.json` maps the same generated service paths without treating native Luau authoring folders as TypeScript outputs. The composite map preserves unknown world, GUI and service instances.

The filename suffixes determine execution: `.server.ts` becomes a Script, `.client.tsx` becomes a LocalScript, and ordinary TypeScript files become ModuleScripts. The earlier server snippets with plain `.lua` names were being mapped as ModuleScripts despite containing startup loops. Preserved startup templates now use appropriate suffixes and require an explicit `TethysTemplateEnabled` attribute. They remain in ServerStorage.

## Activate the terminal deliberately

The new `ReplicatedStorage.TethysSystems` folder contains the three demonstrated terminal remotes. Its `AquaponicsEnabled` and `JusticeEnabled` attributes default to false. No existing opener remote or sandbox capability was expanded.

To exercise aquaponics in a development copy, tag an authored terminal Model `TethysAquaponicsTerminal`; give it a BasePart named `Screen` with a native ProximityPrompt. Connect the existing profile owner through `ProfileAccess.ts`, whose compatibility adapter reads the existing server `_G.GetPlayerData(userId)` contract. Only then enable `AquaponicsEnabled` before Play. The current working world was not given fabricated terminal locations, job assignments or inventory sources.

`JusticeSystem.server.ts` remains disabled behind its own flag. The older Lua justice, gate scanner, ProfileService proposal, raptor scenes, Stryker flight, sensory UI and live-ops experiments are preserved in IntegrationTemplates. They need their named world assets and an explicit owner selection; enabling both justice variants would create duplicate handlers. The supplied DataManager proposal is not installed as a second save framework. Its numeric UserId access and ProfileService release binding were corrected, but schema versioning, migrations, outage behavior and concurrency acceptance remain required before persistence ships.

Client sensory templates remain experimental. Their placeholder audio assets and scene timing are not validated production content. The runtime Terrain streamer was changed into a read-only layout preview; HTTP configuration cannot repeatedly overwrite the authored mountains or cleared lower space. The offline heightmap scripts generate illustrative rasters only. They do not establish geographic orientation or a 110 Ma reconstruction and never import Terrain.

## Connect the WordPress and API owner

Copy `.env.example` to a private `.env` and set a new `ELO_SYSTEM_HMAC_SECRET` for the local API process. `npm run dev:server` starts the API. Importing `backend/server.ts` starts no listener or CMS request, which makes API tests independent of a running service or WordPress network access.

All API mutation routes now authenticate before applying state changes. The trusted deployment CLI uses HMAC; the Roblox HTTP owner can use a Bearer credential. Missing configuration fails closed. The previous embedded fallback key and signature logging were removed. Administrative writes use the trusted server-side CLI or authenticated server HTTP requests. Credentials stay outside Roblox client code.

`ServerStorage.TethysBackendConfig.Enabled` defaults to false. Configure its `BaseUrl` as the gateway's HTTPS origin and `SecretName` as a Creator Hub secret whose value matches the API's secret. Roblox's [Secret Store](https://create.roblox.com/docs/cloud-services/secrets) keeps that credential on the server. Studio loopback development can use a private `DevelopmentToken` attribute on this server-only configuration. Never commit a populated token or replicate the configuration to clients.

When enabled, `TethysBackend` owns a bounded set of HTTP operations: CMS reads, validated Ordovic zone mirroring, and instance heartbeats. It connects the existing server-only `BE_OpeningZoneMirror` contract, without adding Network capability to Ordovic. It revalidates player life, identity, river location and duplicate/in-flight state. Failure changes a diagnostic status and never blocks movement, rescue or observations.

The content adapter accepts the existing `narrativeStream`/`nodeId`/`bodyText` schema. WordPress `databaseId` is requested explicitly; entries without a stable numeric identity are skipped instead of assigned random IDs. Authors must supply actual `LoreId` metadata on cave observation nodes. No destination Place IDs, discovery rewards or taxonomic facts are inferred. The content and player registries in Express remain memory-only, and the mirror is not a durable queue.

## What was verified

[The validation record](roblox-integration-validation.json) separates TypeScript checks, API/policy tests, native syntax checks and source packaging from Studio acceptance. The terminal's authored assets, live profile-owner contract and live WordPress/Secret Store connection still need engine integration checks. The earlier cave pass retains its separate [nine-group Studio record](cave-opener-validation.json).

Historical death-experience policy fixtures are preserved under `tests/fixtures/DeathExperience` solely to keep the existing portable policy tests reproducible. They are not mapped into the live runtime. Removed owner integrations linked from older reports now point to dated Git history.

Codex performed the structural changes, corrected compilation and integration defects, wrote authentication and policy tests, and prepared the GitHub upload. Daniel retains story, world layout and art ownership. This is an integration source package, with the experimental and unverified parts identified above.
