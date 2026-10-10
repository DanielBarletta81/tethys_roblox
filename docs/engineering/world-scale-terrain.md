# World-scale terrain references

Daniel supplied these on 2026-10-09 as **world-scale terrain ideas**, following the direction to build existing geometry into native Terrain mountains. This is a reference handoff, not a selected map extent, a literal historical reconstruction or a live-import instruction.

## Sources inspected

| Source | Verified information | Role in the build |
| --- | --- | --- |
| `2.1 Atlas of Late Cretaceous Paleogeographic Maps (Scotese, 2014).pdf` | 15 pages; introduction lists Maps 16–22, from 65.5 to 96.6 Ma; Mollweide projection | Continental relationships, coasts, broad relief and changing sea extent |
| `06_civilization_cradle_mask_16bit.png`, in `Tethys_110Ma_TerrainKit_v1` | 1024 × 1024; PNG grayscale, 16 bits per sample; no inspected text metadata defining its values | A candidate settlement-suitability layer, subject to confirmation of its semantics |
| `Screenshot 2026-10-08 at 10.44.49 AM.png` | 200 × 150 screenshot; geographic labels and map date are not legible | Visual direction for a connected land-and-sea region; insufficient for coordinate registration |

Atlas attribution: Scotese, C.R., 2014, *Atlas of Late Cretaceous Maps*, PALEOMAP Atlas for ArcGIS, volume 2, *The Cretaceous*, Maps 16–22, Mollweide Projection, PALEOMAP Project, Evanston, IL. Read the introduction and visually inspected the cover and both Map 22 variants. Those maps are labeled Cenomanian, 96.6 Ma, with sea-level variants +120 m and +80 m. These are historical map labels, not Roblox water settings.

The kit's **110 Ma** filename and this atlas represent different time slices. Preserve that distinction in provenance. A map matching the intended time slice would be needed before describing the terrain as a 110 Ma reconstruction. The supplied materials currently support a geographically inspired fictional Wildbound world.

## Translation into Wildbound

Use three scales together:

1. **World geography:** broad land masses, mountain belts, seas, islands and major water connections. These establish how regions relate and why travel or settlement might favor some places.
2. **Regional landforms:** the Cimmerian backbone, contained Ordovic, protected city shelves, Weep corridor, working slopes and seaward drops. Adapt this region to Daniel's current mountain placement and accepted structure elevations.
3. **Playable spaces:** entrances, stairs, cave volumes, overlooks, route choices and observation distances. Preserve character-scale access even when the surrounding mountains are immense.

As a design interpretation, the atlas's broad coasts and interrupted land masses can support sheltered basins, exposed crossings and islands. The cradle mask can help evaluate where human construction might concentrate. Neither establishes the exact position of Sky City, Ordovic or any named fictional region.

Keep these data layers distinct:

| Layer | What it controls | Information still needed |
| --- | --- | --- |
| Elevation / bathymetry | Ground and seabed height | Actual height raster, units and elevation range |
| Water | Sea level, river surfaces and basin connectivity | Land/water classification and authored water elevations |
| Civilization cradle | Preference for settlement locations and shelves | Mask polarity and definition of its values |
| Authored geometry / routes | Structural support, clear interiors and deliberate access | Site registration against the current Studio build |

A provisional interpretation is that brighter cradle values mean stronger suitability. This is **unconfirmed**. Dark values could include sea, steep land or simply excluded areas; they must not automatically become water. Bright values must not automatically flatten the terrain. Even a 16-bit mask remains 1024 samples across; precision of values does not establish geographic detail or alignment.

## Before any regional import

- Establish the intended time slice and region/crop. Confirm whether the square mask corresponds to the screenshot or a different geographic extent; a square raster is not automatically registered to the atlas's full Mollweide map.
- Record orientation, mirroring, world origin, horizontal footprint, elevation range and water levels. The current R1B inland `-Z` / seaward `+Z` orientation remains provisional.
- Register recognizable anchors in the current build: ridge, Ordovic approach, intake, city shelves and Weep outfall. Support those structures while preserving cave airspace and the two reserved routes.
- For a large footprint, author bounded tiles with consistent edge samples and water levels. The current 2,048-stud R1B guide limit does not limit the intended world; tiled regional guidance and seam-aware generation are future implementation work.
- Preview one registered region before a bounded Terrain edit. Keep the existing spawn provisional while the landform is being authored.

This review changed documentation only. The source PDF, mask and screenshot remain local reference assets; no source images were added to the public portfolio and no Studio content was imported or moved.

Related: [geometry measurements](geometry-scale.md), [terrain tool roadmap](tool-suite-roadmap.md), [art pipeline](art-pipeline.md).
