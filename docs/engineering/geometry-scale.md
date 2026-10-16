# Geometry scale before Terrain integration

Direct user direction, 2026-10-09: Daniel is moving mountain geometry and will build into native Roblox Terrain mountains. Focus on the scale of the geometry. Spawn anomalies during this work are provisional, not an instruction to repair spawn logic or restore previous mountain placements.

The landscape can remain monumental while passages and interaction spaces retain a consistent character scale. Review those two scales separately. Terrain should support the accepted structures, routes and water levels, with open volumes for passages and camera movement.

The supplied [world-scale terrain references](world-scale-terrain.md) add the larger geographic frame: regional mountain belts, coasts, water connections and potential civilization cradles around the existing build.

## Read-only Studio snapshot

This earlier snapshot predates Daniel's subsequent upper-start/river blockout update. Use the [later authored-layout survey](authored-opening-layout.md) when mapping opening systems; these historical dimensions are not an instruction to restore previous placements.

Measured in the Edit DataModel of **World of Tethys | Wildbound**, place `72645647440721`, on 2026-10-09. Values are in studs. Group bounds enclose the transformed corners of visible BaseParts; they exclude fully transparent markers and native Terrain. These are scene extents, not walked distances or a collision acceptance result. Mesh rendering can differ from Part bounds. No Humanoid was present in Edit, so the existing reference figure is not a measurement of the actual player avatar.

| Geometry | Measured scale | Implication for authoring |
| --- | --- | --- |
| `World.City_Man_Ref` | 4 × 6 × 4 | Existing six-stud height reference; verify the playable avatar separately |
| `World.02_Upper_City.Upper_Tier_Core` | 624 × 104 × 149.6 overall X/Y/Z bounds | Broad civic footprint; selected main floor tiles measure 22.79 × 22.79 |
| `World.02_Upper_City.Upper_Terrace` | 326 × 163 footprint; floor top approximately Y 777.8 | Preserve the terrace elevation when shaping its supporting shelf |
| `World.Arnn_Ridge_Joined` | 5,579 × 2,181.2 × 2,268.2 overall X/Y/Z bounds | Regional landform extent, not a single playable corridor or a required Terrain footprint |
| Ordovic Hidden Vein entry | 26 long; 9 clear width × 9 clear height | Inner wall faces and floor/roof faces define the gap; keep Terrain out of this opening |
| Hidden Vein main floor | 52 × 50 footprint; top Y 1,185 | Main roof underside is 33 above this floor; the lower brow reduces local clearance to 26.5 |
| Intake-to-cave connector | 12 wide; Part length 53.34; pitch approximately 3.49° | Check floor continuity and camera clearance where Terrain meets the connector |
| Hidden Vein lower passage | 8 clear width × 10 clear height before rubble | Preserve the deliberate blocked route and its observation sightline |
| Cordge proxy | Approximately 7.6 tall | A staged proxy, not final character art or a validated player size |

The sampled city stair treads are 12 wide × 3 deep. Their top-to-top rises are 1–2 studs on East Ascent and 2 studs on West Ascent. This establishes the current authored dimensions; character traversal and camera behavior still need a live check before embedding these stairs in Terrain.

## Integration priorities

1. Keep the current authored mountain arrangement as the reference. Judge silhouettes and city shelves independently of doorways, stairs and cave clearances.
2. Shape Terrain support beneath terraces and around cave shells while preserving passage interiors, sightlines, exposed ledges and intentional drops.
3. Check a continuous route with the actual avatar: footing, stair rises, camera clearance, entrances and transitions between Parts and Terrain. Dimension checks alone do not prove it is playable.
4. Reconcile water surfaces and intake/outfall elevations across each accepted route. The existing 28-stud opening channel represents a route within the mighty Ordovic, not the final river width.
5. Review spawn and Rest landing positions after the relevant landform stabilizes. Preserve the reserved Ordovic upstream connection and collapsed deeper cave.

The Stratum R1B single-guide limit of 2,048 studs is a tool boundary, not a world-scale target. The measured ridge exceeds it; future regional coverage needs tiled guides. Do not shrink the world to fit the current plugin.

This pass changed documentation only. It did not reshape Terrain, move structures, change spawns or retest traversal. Related: [tool suite](tool-suite-roadmap.md), [water-surface integration](raised-routes.md).
