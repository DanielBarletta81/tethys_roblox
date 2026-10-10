# Terrain tool suite and R1B milestone

Priority chosen on 2026-10-08: **Studio terrain tools + R1B planning**. Tools should help author a playable Wildbound environment and later support other creators through separately reviewed releases.

## Current tools

| Tool | Implemented responsibility | Boundary |
| --- | --- | --- |
| [Tethys Terrain 0.1](tethys-terrain.md) | Seeded bounded native Terrain generation, thermal relaxation and guarded Clear | Existing-terrain blending, stitching and installed-plugin acceptance remain separate |
| [Stratum 0.1](stratum.md) | Bounded solid/water archives and authored R1B planning outlines | Archives do not modify or stream runtime Terrain; guides do not build the city |
| Nature Scatter v1 | Deterministic categorized source-asset placement and owned-pass cleanup | Cross-pass clustering/exclusion remain deferred |

These tools retain separate responsibilities and module trees. No giant installer, required paid add-on or new runtime framework is introduced.

The [regional-world handoff](regional-world-sprint.md) now supplies the runtime architecture direction: multiple Places within one Experience and lightweight vistas between regions. Terrain authoring tools remain separate from regional travel; the archive codec is not a substitute for that architecture.

## Next environment card: site-specific R1B

Current authoring direction, 2026-10-09: Daniel will add native Terrain mountains around the geometry and has moved mountain blocks. Start with [geometry scale and clearances](geometry-scale.md) and the supplied [world-scale geographic references](world-scale-terrain.md); current spawn placement is provisional. Existing R1B sketches do not override these authored mountain positions.

1. Survey the current Sky City/Weep build, water levels, shoreline and reserved routes. Choose an actual regional footprint and orient the provisional sketch.
2. Preserve the working place; use an expendable empty authoring patch for the first macro landform. A Stratum archive is inspectable data, not a complete place backup or a shipped terrain-restore operation.
3. Author the broad Cimmerian backbone and a protected city cradle. Test the Weep corridor from inland gathering through practical working slopes to its seaward spill.
4. Cut sheltered, exposed, working and hidden routes; keep future upland markers reserved. Test slopes, landing/collision and water readability before detailing.
5. Place ruins and human engineering in response to the land. Review one environment + traversal + observation slice, then integrate its accepted geometry without replacing existing systems.

The Ordovic opening remains water-surface led and connects to its inaccessible upstream later. R1B does not open that upstream, introduce a player-followed leaf, or bypass Cordge's blocked cave.

## Later tools from the supplied proposal

**Legacy script report:** begin with a read-only inventory of script classes, owners, deprecated API usage and narrowly defined findings. Export reviewable suggestions. Any fixes should be exact scoped patches with preservation/rollback evidence; do not apply regex-wide rewrites or alter original asset packs automatically.

**Runtime chunk framework:** first measure a demonstrated problem under native `StreamingEnabled`. Establish terrain/collision ownership, limits, lifecycle, rate budgets and client/server failure tests. Compare named workloads before considering custom replication or Parallel Luau. The archive codec alone proves none of those runtime requirements.

**Larger terrain authoring:** choose a useful environment need before hydraulic erosion, seam stitching, tiled regional guides, node editing or Scatter v2. A 2,048-stud native Part limit is now enforced for R1B; larger guide coverage needs tiling, not silent clamping.

## Release gate for other creators

Finish installed toolbar/dock and native Undo/Redo acceptance, preserve honest test/benchmark boundaries, choose the source license and asset dependencies, and provide a clean standalone demonstration place. Creator Store/DevForum/GitHub publication is a separate authorized task. Do not carry the supplied MIT, 86.4%, zero-GC or guaranteed-60-FPS claims into a release without matching implementation and evidence.

World direction and tool requirements are Daniel Barletta's; implementation/review used Codex assistance. Engineering credibility comes from inspectable behavior, reproducible checks and stated limits.
