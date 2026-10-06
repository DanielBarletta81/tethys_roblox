# Tethys Terrain 0.1

A local Roblox Studio terrain-authoring plugin for the Mac workflow. It generates small editable Terrain patches without external software, asset downloads, HTTP access or runtime gameplay scripts.

## Authoring workflow

1. Open **Tethys → Terrain** in Studio's Plugins toolbar.
2. Choose RiverValley, Mountains or Island. Set seed, dimensions, relief, feature scale, thermal passes and optional water.
3. Set the box's minimum X/Y/Z coordinates. Dimensions and origins must align to the 4-stud Terrain grid. Alternatively, select one unrotated bounds-guide Part with aligned dimensions/edges and click **Use selected box bounds**. The guide is read and preserved.
4. Click **Preview landscape**. This creates a plan view in the dock panel and changes no world instances or Terrain.
5. Review the displayed seed and box coordinates, then click **Apply preview to empty patch**. Existing solid terrain, water or queryable Parts block Apply. The selected bounds guide is the sole Part exception.
6. Use native Sculpt/Paint for gameplay details. Studio Undo/Redo owns the complete edit. **Clear latest unchanged pass** restores the empty patch only when every voxel channel still matches the generated result and ownership metadata is present.

The default is a 128 × 96 × 128-stud RiverValley box using seed `20261005`. Box height is a vertical budget, not the peak elevation. The maximum box is 256 × 192 × 256 studs, or 196,608 voxels. This bound keeps generation synchronous and prevents yielding midway through a terrain transaction.

River beds are recut after thermal relaxation to preserve a continuous channel. Water has a flat datum 12 studs above the box floor. This tool authors geometry and water occupancy; the Ordovic flow system remains responsible for gameplay forces. Patches are generated in local coordinates, so moving a box preserves its shape. Separate adjacent boxes are not seamless tiles.

## Install locally

Build the model from inspectable sources:

```sh
python3 tools/package_terrain_plugin.py
```

The artifact is `output/terrain-plugin/TethysTerrain.rbxmx`, excluded from version control. It contains one Script and eight child ModuleScripts, rather than a monolithic bundled script.

The same source is staged at **ServerStorage.TethysTerrainPlugin** in the working Wildbound place. Select that Script in Explorer, then use **Plugins → Save as Local Plugin**. Alternatively, insert the built model in an expendable place and save its top-level Script as a local plugin. Local installation is separate from Creator Store publication. [Roblox local plugin instructions](https://create.roblox.com/docs/studio/plugins).

Do not run the entry point as a gameplay Script. The `plugin` context supplies the toolbar, dock widget and recording ownership. The ServerStorage copy is an authoring source container; this service does not run its Script.

## Modules and transaction boundary

| Module | Responsibility |
| --- | --- |
| [Config](../../plugins/TethysTerrain/Modules/Config.luau) | Validate finite settings, grid alignment and budget |
| [Noise](../../plugins/TethysTerrain/Modules/Noise.luau) | Seeded value/fractal/ridged noise |
| [Erosion](../../plugins/TethysTerrain/Modules/Erosion.luau) | Simultaneous mass-conserving talus transfer |
| [Heightfield](../../plugins/TethysTerrain/Modules/Heightfield.luau) | Domain warp, preset masks, channel carving and slope calculation |
| [Voxelizer](../../plugins/TethysTerrain/Modules/Voxelizer.luau) | Partial solid occupancy, liquid channel and slope/depth materials |
| [EditSession](../../plugins/TethysTerrain/Modules/EditSession.luau) | Preflight, one recording per edit, ownership and guarded Clear |
| [RobloxBackend](../../plugins/TethysTerrain/Modules/RobloxBackend.luau) | Terrain channels, native recording, bounds queries and metadata |
| [Panel](../../plugins/TethysTerrain/Modules/Panel.luau) | Native dock controls and read-only plan preview |

Apply rechecks the box inside the recording, writes the channels, reads the engine's quantized result and creates metadata. Failures cancel that plugin's recording. No global history reset, Terrain.Clear, project capability changes, source injection or original-asset modifications are used. Production recording follows [ChangeHistoryService](https://create.roblox.com/docs/reference/engine/classes/ChangeHistoryService).

SolidMaterial, SolidOccupancy and LiquidOccupancy are separate. This preserves partial solid/water cells, using [Terrain voxel channels](https://create.roblox.com/docs/reference/engine/classes/Terrain). Surface materials use Grass, Rock, Mud, Sand or Snow; deeper voxels use Rock. Native terrain interpolation can shift a raycast surface from the analytical height within a voxel, so inspect narrow banks and steep steps in Studio.

Each pass creates only **Workspace.Generated.TethysTerrain.Pass_&lt;guid&gt;**, with attributes `Generator`, `Version`, `PassId`, `Seed`, `Preset`, `Category`, `Settings`, `BoundsMin` and `BoundsSize`. Terrain voxels themselves cannot carry per-pass attributes. Keep the metadata alongside the region; deleting it disables that session's Clear.

Clear owns only the latest pass in the current plugin session. It compares all channels to the post-write snapshot and refuses to remove later sculpting. Session snapshots are held in memory; after reloading Studio/plugin, use native Undo or Terrain's normal editing tools. Metadata is provenance, not a persistent voxel backup. Undoing generation removes its metadata; Clear then refuses. Undoing Clear restores Terrain/metadata through Studio, while the cleared session intentionally drops its Clear target.

## Validation on 2026-10-06

- **15 portable groups pass** against production modules: invalid settings, deterministic seeds, preset bounds, river continuity, water-off behavior, erosion mass conservation, occupancy constraints, immutable previews, Clear, solid/water conflicts, Part/play/busy guards, refused recordings, rollback and sculpt protection.
- **9 Studio engine groups pass** in an initially empty box at `(8000, 0, 8000)`: native solid/liquid channels, metadata ownership, actual Terrain water/bed raycasts, existing-terrain rejection, exact Clear restoration, deterministic quantized regeneration, manual-edit protection, water-only conflict and Part bounds guard.
- Seed `20261005` generated **6,915 solid cells and 356 liquid cells** within a 24,576-voxel box. The engine fixture measured approximately **0.038 seconds** for Apply, including preflight, channels and metadata; this is an isolated authoring call, not a frame-rate benchmark.
- Water raycast hit Y = **12**; the riverbed hit Y = **7.162** at the sampled cross section. Native collision updates on a later frame; the engine fixture waits before raycasting.
- The fixture restored its original channels and removed its test metadata and Part. No test terrain remains in the opening.
- Model packaging verifies exact source round-trip. Luau compilation checks syntax, not Studio rendering or engine types.

**Native dock interaction and plugin-owned Undo/Redo still require an installed-plugin check.** The MCP runner cannot begin a plugin recording. The engine fixture uses an explicit test transaction adapter and does not claim to validate production recording. The portable tests validate edit-policy behavior with a journal fixture.

## Deliberate limits

No hydraulic erosion, sediment flow, cave carving, node graph, existing-terrain blending, heightmap file import/export, cross-patch stitching, biome painting controls or Scatter integration yet. Thermal transfer is a small slope-relaxation stage, not a Gaea equivalent. Queryable Parts are checked; nonqueryable Parts are not covered by this engine spatial query. Preview shows sampled plan-view height/materials, not a rendered camera image.

Keep early passes small. Author and review a useful river valley before expanding tools around a concrete environment need.
