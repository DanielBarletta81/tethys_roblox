# World of Tethys — Roblox engineering

A Luau code portfolio for **Wildbound**, a prehistoric exploration and survival game set around a powerful river, human waterworks, and buried history. The current Studio prototype connects the Ordovic opening to an intake choice and a cave where Cordge responds to what the player observes.

The [2026-10-15 cave and flume pass](docs/engineering/cave-opener.md) enlarges the natural wake chamber, adds three observations, restores native water at the moved route, and connects a short slide to rapids, smooth rocks, a Stryker crash proxy and the rescue choice. [Its validation record](docs/engineering/cave-opener-validation.json) separates assisted Studio checks from pending full-route and device acceptance.

The [Roblox/headless integration guide](docs/engineering/roblox-integration.md) explains the Roblox and headless API builds, the guarded terminal integration, and the GitHub verification commands.

**Status:** active prototype. This repository contains selected systems and tests from the working Studio place; it is not a complete, independently runnable game export. Finished character art, full-route acceptance and production persistence remain in progress.

## Start with the code

| System | Engineering problem | Read first |
| --- | --- | --- |
| Nature Scatter v1 | Repeatable environment placement that can be safely regenerated and cleared | [NatureScatter](src/ReplicatedStorage/Tethys/WorldModules/Scatter/NatureScatter.luau), [asset placement](src/ReplicatedStorage/Tethys/WorldModules/Scatter/AssetPlacement.luau), [Studio tests](tests/NatureScatter.spec.luau) |
| Tethys Terrain 0.1 | Seeded terrain authoring with a read-only preview, bounded edits and sculpt-safe cleanup | [heightfield](plugins/TethysTerrain/Modules/Heightfield.luau), [edit policy](plugins/TethysTerrain/Modules/EditSession.luau), [plugin guide](docs/engineering/tethys-terrain.md) |
| Stratum 0.1 | Preserve solid/water voxel data in bounded archives and preview authored R1B landform guides | [codec](plugins/Stratum/Modules/VoxelCodec.luau), [capture lifecycle](plugins/Stratum/Modules/Session.luau), [plugin guide](docs/engineering/stratum.md) |
| Ordovic opening | Apply downstream force while preserving lateral steering; hold and release a deliberate intake choice | [FlowService](src/ServerScriptService/OrdovicOpening/FlowService.luau), [IntakeService](src/ServerScriptService/OrdovicOpening/IntakeService.luau), [Controller](src/ServerScriptService/OrdovicOpening/Controller.luau) |
| Raised route integration | Refit the water spine to moved authoring anchors, connect broad dry routes and validate actual arrivals through the existing owner | [ConnectionBuilder](src/ServerStorage/OrdovicBuild/ConnectionBuilder.luau), [arrival adapter](https://github.com/DanielBarletta81/tethys_roblox/blob/25162ac/src/ServerScriptService/WildboundServer/Services/RaisedRouteAdapter.luau), [installed layout and limits](docs/engineering/raised-routes.md) |
| Cordge observations | Reject invalid inspections and control one-shot dialogue, priority and per-player state | [CordgeController](src/ServerScriptService/OrdovicOpening/CordgeController.luau), [policy](src/ServerScriptService/OrdovicOpening/CordgePolicy.luau), [policy tests](tests/CordgePolicy.spec.luau) |
| Death as experience | Reward meaningful exploration without spawn farming; return through one validated Rest owner | [policy](https://github.com/DanielBarletta81/tethys_roblox/blob/25162ac/src/ServerScriptService/DeathExperience/Policy.luau), [ledger](https://github.com/DanielBarletta81/tethys_roblox/blob/25162ac/src/ServerScriptService/DeathExperience/Ledger.luau), [build notes](docs/engineering/death-experience.md) |
| Contextual HUD | Keep gameplay authoritative while presenting prompts, bounded notices and accessible transitions | [runtime binder](src/StarterPlayer/StarterPlayerScripts/WildboundUIRuntimeBinder.client.luau), [NoticeController](src/ReplicatedStorage/WildboundUI/Controllers/NoticeController.luau), [effects tests](tests/UIRuntime.effects.playtest.luau) |

The module layout follows Roblox services. Stateful services use small object instances; math, configuration and presentation policy remain separate. Existing owner integrations are provided as `.integration.txt` recipes, not substitutes for complete scripts.

## Inspectable behavior

- Scatter uses a stable asset ordering, seed `20261005`, category slope limits, scaled footprints and pass metadata. Replacement preserves the old pass on failure; Clear requires matching ownership. Spacing is within a pass, so interactions with other passes still need visual review.
- Native intake holds reach existing server handlers. Movement is restored on release, and unfinished rejection has its own session respawn destination.
- Cordge checks distance, walls, life, target ownership and duplicates. Observations support sparse authored speech without introducing quest rewards.
- Death experience adds a contextual bonus capped at 18 XP per life and 36 per ten minutes. Valid Rest takes precedence over the opening fallback; knowledge and homes survive death. Ordinary route XP still contributes to the player total.
- HUD1.6 registers seven supplied location images, starts with Ordovic River from Arnn Ridge and binds Intake to existing opening phases. Borderless reveals share a 0.65-second fade in, 1.5-second hold and 0.85-second fade out; speech/prompts have priority and reduced motion is supported. Saved demo content stays cleared and the restrained life-ending cue preserves learned experience. Live validation of the new images is pending Studio responsiveness; see the [artwork checkpoint](docs/engineering/location-artwork.md) and earlier [PlayerGUI audit](docs/engineering/player-gui-audit.md). Approved 3D portraits have a static menu adapter; no finished models are bundled.

## Validation

| Scope | Recorded result | Limit |
| --- | --- | --- |
| Player UI live layers | 15 UI / 11 art / 6 inventory Edit groups passed; separate item images/counts, readable fallbacks and serif headings installed | [Layer checkpoint](docs/engineering/player-artwork-layers.md); six new decorative PNG imports and live skin validation await accessible originals |
| HUD1.6 location artwork | Seven uploads and matching installed sources; 13 UI / 10 art Edit groups passed | [Dated checkpoint](docs/engineering/location-artwork.md); Play entry and capture timed out, so Client loading/layout checks and save confirmation remain pending |
| HUD1.5 PlayerGUI pass | 13 Edit / 16 effects / 8 GUI audit / 4 layout / 4 focus / 8 return-cue groups passed; native intro, cave prompt, title fixture and respawn checked | [Dated audit and screenshots](docs/engineering/player-gui-audit.md); assisted placement and virtual input do not establish unassisted route or physical device acceptance |
| Scatter v1 | 14 Studio test groups; seeded Terrain placement and Clear/Undo checked | Cross-pass exclusion and clustering are deferred |
| Opening/Cordge | 23 unit groups, 11 live Cordge groups, two subtitle ownership checks | Assisted checks do not establish a complete unassisted route |
| Raised routes | 12 structural groups, three guided native avatar walks, both intake choices, five-drop refusal, all five cave clues and checkpoint death returns | [Dated evidence](docs/engineering/raised-routes-validation.json); full unassisted river and device acceptance remain open |
| Water readability | Eight live groups; 102 cues sampled actual Terrain water | A route prototype, not a watershed simulation |
| Death/Rest 26G | 21 portable policy groups, 16 Rest engine groups, seven return-UI groups and assisted native death/return checks | Session persistence; Rock Ledge awaits ground correction; see the build notes |
| Death/Rest polish | Eight cue groups, five camp-prompt groups, four native prompt-priority groups; menu-key/button recovery and visual cave preview | [Checkpoint](docs/engineering/death-rest-polish-validation.json); controller mappings inspected, device acceptance remains open |
| Portable CI | Reuses the six Cordge policy cases and 21 death-experience groups; compiles all Luau sources/tests/tools; checks repository contents and links | Engine, Terrain, prompts and UI rendering require Studio |
| Terrain plugin 0.1 | 15 portable groups and nine native Terrain groups; model source round-trip | Dock interaction and plugin-owned Undo/Redo await local installation; see the plugin guide |
| Stratum 0.1 | 22 portable groups, 12 native engine groups and 12 assisted installed-plugin checks; source/model round-trip | Native save/create/remove Undo/Redo verified; regional orientation and large-world profiling remain separate. See the [checkpoint](docs/engineering/stratum-validation.json) |

These are separate dated checkpoints, not one combined test total. See [testing and evidence](docs/engineering/testing.md), [recorded validation](docs/engineering/validation.json), and [setup](docs/engineering/setup.md).

![Wildbound intro in Studio](docs/media/hud15-intro.jpg)

*Supplied Tethys artwork with a native entry action before the playable scene.*

![Wildbound borderless title presentation](docs/media/hud15-title.jpg)

*Controlled UI preview over the Ordovic graybox. It demonstrates artwork and layout; the real Wake does not award or display Sky City discovery.*

![Cordge cave observation](docs/media/hud15-cordge.jpg)

*Studio prototype: a native inspection prompt and sparse authored speech at the blocked cave route. Proxy art remains visible.*

## Development

[Architecture](docs/engineering/architecture.md) · [Setup](docs/engineering/setup.md) · [Roadmap](docs/engineering/roadmap.md) · [Mac terrain pipeline](docs/engineering/art-pipeline.md) · [Tool suite](docs/engineering/tool-suite-roadmap.md)

World direction, design decisions and asset selection: **Daniel Barletta**. Implementation and review developed with Codex assistance. The code and validation limits are available for inspection; this baseline imports the existing prototype rather than inventing a historical commit timeline.

Public material is limited to code, tests, engineering documentation and selected screenshots. Private design PDFs, place backups and original asset packs remain outside version control. No open-source license has been selected; publishing this portfolio does not grant an asset or source redistribution license. Nature Scatter is a candidate for a separately licensed tool later.
