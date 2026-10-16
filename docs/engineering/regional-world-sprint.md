# Regional world sprint alignment

Context supplied by Daniel on 2026-10-09: `Wildbound_RegionalWorld_Coding_Handoff.md`. This review synchronizes that handoff with the existing code and connected Studio place. It does not implement its services, publish new Places or claim any regional acceptance result.

## Target and ownership

**One Experience, multiple Places. First proof: Sky City -> wilderness trail -> Rest -> shortcut discovery -> regional exit -> Watcher arrival -> return.** Neighboring geography can use lightweight vista art while the playable region lives in another Place.

Daniel owns geography, terrain, architecture, story and visual art. Coding supplies reusable configuration, marker validation, travel, durable knowledge, route eligibility and Rest integration. The existing Ordovic opening and reserved upstream/deeper cave remain intact. Starting a developer travel test at a Sky City arrival is separate from changing the live game's join spawn.

Daniel's subsequent blockout update places the Game 1 entry high on the mountain, First Sort/Intake a little lower, and river/ridge continuations toward the city or down toward Watcher. The [authored-layout survey](authored-opening-layout.md) identifies those references and separates them from older generated anchors. This local opening layout is the physical lead-in to regional travel; the old refusal landing is not automatically a Watcher Place exit.

## Existing-owner audit

Read-only repository inspection and Studio connector inspection in **World of Tethys | Wildbound**, place `72645647440721`, on 2026-10-09:

| Owner / capability | What exists | Regional integration needed |
| --- | --- | --- |
| `ServerScriptService.TethysServer.Services.KnowledgeService` | PlayerSphere domains, observations, novelty and theories; explicitly runtime-only | Stable discovery mapping and snapshot/load integration; preserve existing knowledge semantics |
| `TethysServer.Services.SaveService` | Version-1 PlayerSphere snapshot; `DurableWritesEnabled=false`; `Save()` returns failure | Reconcile this owner with one versioned save envelope and migration/load strategy |
| `WildboundServer.Services.KnowledgeService` | Updates predefined boolean knowledge keys through RuntimeService | An adapter to the same durable record, rather than another independent discovery store |
| `WildboundServer.Services.RouteService` | Current intake/capture/refusal actions | Preserve those decisions; regional route eligibility is an additional responsibility |
| `WildboundServer.Services.CheckpointService` | Runtime checkpoint state | Keep separate from established Rest and cross-Place arrival records |
| [DeathExperience RestService](https://github.com/DanielBarletta81/tethys_roblox/blob/25162ac/src/ServerScriptService/DeathExperience/RestService.luau) | Registered built camps, claims, ownership/condition/ground/cover/resource validation and pending-death return | Region-aware stable Rest IDs and providers for natural shelters; retain camp-specific validity checks |
| [DeathExperience Service](https://github.com/DanielBarletta81/tethys_roblox/blob/25162ac/src/ServerScriptService/DeathExperience/Service.luau) | Contextual death XP and existing server-only integration endpoint | Preserve current balance and establish one coordinated respawn decision path |
| [CordgeController](../../src/ServerScriptService/OrdovicOpening/CordgeController.luau) | Validated once-per-session clues, attributes and sparse authored speech | Map relevant observations into durable knowledge without bypassing inspection validation |
| `ReplicatedStorage.Tethys.Config` | `OpeningConfig` only in the inspected folder | Central region/route/arrival/place configuration |
| Travel / durable backend | Studio script searches found no `TeleportService` or `DataStoreService` references | New bounded travel backend and a separately validated persistence backend |

The legacy Studio services are external dependencies of this curated export. Their names do not prove a general regional framework exists. The audit read their knowledge/save/route/checkpoint modules; it was not an exhaustive review of every legacy gameplay script or world marker.

Only the connected Wildbound PlaceId is verified here. Watcher's PlaceId and shared Experience membership remain unverified. Do not invent destination IDs or mark the two-Place setup complete.

## Integration decisions to carry forward

- Use stable region, route, arrival, discovery and Rest IDs with tags/attributes. Physical marker names and positions may change during terrain authoring. Reject duplicate IDs rather than picking an arbitrary marker.
- Keep destination PlaceIds in server-approved config. Begin with native exit prompts, validated life/range/state and bounded per-player travel attempts. The proposed remote list is a suggestion; it is not a reason to add redundant remotes.
- Treat teleport metadata as a routing hint. Destination configuration and saved server-owned knowledge determine eligibility; metadata never awards discoveries, repairs, XP or an established Rest. Roblox distinguishes teleport data from secure persistent state. [Teleport documentation](https://create.roblox.com/docs/projects/teleport).
- Design one versioned durable envelope with namespaced regional fields and mappings for existing knowledge/experience state. Define migrations, malformed-data handling, read failures, retry budgets, autosave/shutdown behavior and concurrent source/destination ownership before live writes. A failed load must not overwrite valid data with defaults. Places in one Experience can share DataStores. [DataStore documentation](https://create.roblox.com/docs/cloud-services/data-stores).
- Persist stable Rest identity and establishment, then revalidate the current site's availability when returning. Existing camp fuel timestamps use `os.clock()` and cannot be copied unchanged into a cross-server durable state. Natural shelter providers should not be forced to satisfy the built-camp construction recipe.
- Coordinate arrival, Rest return and the Ordovic checkpoint owner through one decision path. Resolve established Rest in the current region, safe arrival, then regional fallback, with explicit handling for fresh arrival versus death. Do not add competing unconditional character teleports.
- Keep the existing contextual death-XP system. The handoff's instruction to defer final balance does not remove the already implemented and tested behavior.

## Coding order and evidence

| Stage | Concrete next work | Acceptance evidence |
| --- | --- | --- |
| A: regional foundation | Config/types, tagged-marker resolver/validator, source-owner adapters, mockable travel and destination arrival policy; define persistence ownership in parallel | Config and marker fixtures, invalid IDs, duplicate/missing arrivals, spam, disconnects, immediate and delayed teleport failure, safe fallback |
| B: knowledge and routes | Main/Exposed/Historical records, validated discoveries and repair dependencies, machine-readable route results; connect the durable record | Once-only discovery, known versus usable route, missing knowledge/repair reasons, reload and two-server write-conflict cases |
| C: Rest and recovery | Natural shelter and existing Fieldhold adapters, discovered/established/unavailable state, coordinated respawn | Death/rejoin recovery, damaged/removed/foreign-region Rest, missing arrival, valid regional fallback; existing camp checks preserved |
| D: geographic continuity | Vista config/tags and transition hooks; creator supplies art and marker locations | Neighboring region represented by lightweight art, no duplicated playable region, minimal presentation and production-disabled debug tools |

Studio fixtures can prove policies and simulated travel failures. **Actual Place-to-Place teleport acceptance requires published Places and the Roblox client**, because TeleportService does not support Studio playtesting. [Teleport testing requirements](https://create.roblox.com/docs/projects/teleport). No publication or live save setting was changed during this review.

The human-side placement card remains: two Sky City arrivals, a Watcher exit, one route Rest, one Watcher vista and one lift clue; Watcher needs its main/from-city arrivals and a return exit. Positions are authored by Daniel. A missing PlaceId should produce a clear developer diagnostic and leave live travel unavailable.

For each implementation card, report files, exact setup/config, reproducible tests, expected diagnostics, limits and next work. The current deliverable is this audit and the updated roadmap only; regional services and their acceptance tests remain future coding work.

Related: [architecture](architecture.md), [roadmap](roadmap.md), [world-scale references](world-scale-terrain.md), [geometry snapshot](geometry-scale.md).
