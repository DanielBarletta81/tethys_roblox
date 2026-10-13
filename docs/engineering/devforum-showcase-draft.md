# Tethys Terrain showcase draft

Local draft based on the implementation and [recorded validation](tethys-terrain-validation.json). This is an early preview, not a tested public release announcement. The installed-plugin dock/Undo acceptance check, public source link and licensing decision remain pending. Nothing has been posted to DevForum.

**Proposed title:** [WIP] Tethys Terrain — Seeded Terrain Authoring with Preview and Guarded Clear

## Draft post

I'm building World of Tethys: Wildbound on a Mac and wanted a reproducible way to shape small landscapes directly in Roblox Studio. Tethys Terrain is my first local authoring plugin for that workflow.

Version 0.1 generates editable native Terrain. You can choose a river valley, ridged mountains or an island, set a seed, adjust relief and feature scale, add thermal relaxation, and preview the result before writing it to the world.

The emphasis is predictable authoring and preserving existing work. Apply accepts only an empty, bounded voxel box. Clear compares the generated channels against the current patch and refuses to erase later sculpting. Each pass carries seed, preset, bounds and ownership metadata.

### Current features

- Seeded value/fractal/ridged noise with domain warping.
- River channel carving, mountain and island presets.
- Mass-conserving thermal slope relaxation. This is not hydraulic erosion.
- A read-only plan preview; changing settings requires a fresh preview before Apply.
- Separate native solid and liquid channels, with slope/depth-based materials.
- Validation of finite inputs, 4-stud alignment and a 196,608-voxel budget.
- Existing solid terrain and water protection; queryable Part bounds checks.
- Per-pass metadata and Clear protection for later voxel edits.

The plugin has one entry Script and eight separate modules. Generation, voxel conversion, transaction policy and UI responsibilities stay separate. It adds no gameplay remotes or runtime streaming system.

### What I've tested

| Scope | Recorded result |
| --- | --- |
| Portable production-module tests | 15 groups pass: seed reproduction, input limits, river continuity, erosion conservation, occupancy, rollback and edit protection |
| Studio engine fixture | Nine groups pass against actual Terrain, including solid/liquid channels, water and riverbed raycasts, quantized regeneration, conflict rejection and Clear restoration |
| Luau syntax | All 85 repository Luau files compile with Luau 0.741; this is not a strict-type analysis result |
| Model packaging | The entry point and eight module sources round-trip exactly through the generated model |

In one Studio Edit-mode fixture, seed `20261005` applied a **128 × 96 × 128-stud** box containing **24,576 voxels** in approximately **0.038 seconds**, including voxel preflight, writing and metadata. This is one isolated authoring measurement, not a multiplayer benchmark, a cross-device performance claim or an FPS guarantee.

The fixture sampled native water at Y = 12 and the riverbed at approximately Y = 7.162. It restored the original channels and removed its own test metadata and Part afterward.

### Current limits

The native dock workflow and plugin-owned Undo/Redo acceptance test are still pending local installation. The production backend uses ChangeHistoryService recordings, but the command-runner Terrain fixture uses a test transaction adapter and does not validate those recordings.

Clear owns the latest unchanged pass in the current plugin session. Its snapshot is held in memory; provenance metadata is not a persistent voxel backup. Query checks cover queryable Parts. Adjacent generated patches do not stitch seamlessly, and the preview is a sampled plan view rather than a rendered 3D image.

There is no hydraulic erosion, node graph, heightmap file import/export, cave carving, custom replication or Actor worker pool in this version. Native Terrain remains available for manual sculpting and painting after generation.

### Local setup

Build the model from the source checkout:

```sh
python3 tools/package_terrain_plugin.py
```

Insert `output/terrain-plugin/TethysTerrain.rbxmx` into an expendable Studio place, select its top-level Script, and use **Plugins → Save as Local Plugin**. Then open **Tethys → Terrain**, choose an empty box, generate a preview and inspect it before Apply. Keep early patches small.

**Public source/download link:** pending verified publication.

**License:** not selected. This preview does not claim an MIT release or grant redistribution rights.

World direction and design are mine; implementation and review include Codex assistance. I'm interested in feedback on riverbank readability, useful authoring controls, native voxel edge behavior and concrete failure cases.

## Authoring references

[Plugin guide and evidence](tethys-terrain.md) · [Plugin entry point](../../plugins/TethysTerrain/init.server.luau) · [Heightfield](../../plugins/TethysTerrain/Modules/Heightfield.luau) · [Edit policy](../../plugins/TethysTerrain/Modules/EditSession.luau)
