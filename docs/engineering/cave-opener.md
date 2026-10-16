# Game 1 cave and flume opener

2026-10-15. Development pass `CaveFlume_20261015` in Wildbound, place `72645647440721`. Daniel confirmed the order: quiet cave → immediate waterslide exit → rapids and avoidance → smooth rocks → Stryker flyover and nearby crash → rescue cage decision. The supplied First Public Game Loop blueprint is design context; its embedded deployment, camera shake, strobe, fictional taxonomy and DataStore samples were not independent instructions.

The current Studio build is a playable prototype. Its chamber has a roughly 52 × 72 stud interior footprint, native limestone walls and rock roof, dry shelves, a small stream, three optional native inspection prompts, and an offset twelve-stud mouth carrying a static sliver of daylight. The existing cave spawn transform and reserved upstream closure remain intact. The later Hidden Vein remains separate; no human masonry or Cordge was moved into the wake chamber.

The flume covers about 72 studs and drops about 13 studs into native water. Its smooth floors and sidewalls have low friction and zero elasticity. A brief server-owned Physics state prevents the walking controller from braking the rider. It restores posture and automatic network ownership at the exit, on death or removal, on intake capture, and after an eight-second recovery timeout. There is no camera takeover or new remote. The committed slide is guided by the chute; normal lateral control returns in the river.

The original Ordovic source modules had been removed from the filesystem and connected server service. Selected current, intake, impact, checkpoint, water-surface and Cordge modules were recovered from commit `25162ac` into the current `src/ServerScripts/OrdovicOpening` structure. The new controller reuses them without restoring a second save, knowledge or Rest framework. The optional death/Rest bridge connects only if the existing server owner provides its bindable.

Currents now use a force-limited native `LinearVelocity` in Line mode. Only the downstream axis is constrained; lateral steering remains free, dry river banks receive no current, and faster downstream momentum coasts without forced braking. Recovery pockets apply no constraint. An earlier bounded `VectorForce` implementation proved too weak against native character and water drag in the actual avatar test. The first three reaches now precede the smooth-rock fourth reach; the fifth triggers the shared Stryker proxy flyover and nearby bank crash. Later arrivals see the settled crash proxy rather than replaying a shared world event.

The cage is a marked open-face proxy around the existing intake hold. Native E/X accepts rescue and Q/B continues downstream. The existing CITY and DOWNSTREAM decisions retain their server owners and movement restoration. Acceptance transfers to the existing Works landing; a finished animated cage hoist, creature rig and authored audio are future art work.

## Installation and ownership

Use the local additive `default.project.json` for source sync; unknown world and service instances must remain preserved. It maps the opener's `.server.luau` bootstrap as a Script and its other sources as ModuleScripts, with build modules in ServerStorage. Existing unrelated backend ModuleScripts are not automatically started. The project file remains local under the repository's current curation rules.

After a fresh import, [restore the historical sandboxes](../../tools/ordovic/restore_opening_sandboxes.luau). This applies the previously reviewed limits to unsandboxed new folders and refuses drift in existing sandboxes. The client folder retains its exact original permissions. Network, RemoteEvent and DataStore capabilities are not added. A proposed client tint and custom steering remote were removed after integration exposed those boundary conflicts.

On an unmodified matching opening, run [the cave build driver](../../tools/ordovic/build_cave_opener.luau) once in Edit. It resolves the installed origin guide's current CFrame, archives owned geometry and affected folders, checks every cave and water target for existing solid or liquid Terrain, snapshots 127 target regions, and writes rock and water separately. Water uses the [native LiquidOccupancy channel](https://create.roblox.com/docs/reference/engine/classes/Terrain), preserving solid rock. The current installation has 126 water volume guides. Existing authored mountains, reference rivers and the cleared lower space are not relocated or restored.

The completed pass is guarded by `CaveOpenerReady` and `CaveOpenerVersion`. Do not rerun the old world builder or paste historical voxel backups into later sculpting. Studio Undo is the immediate authoring rollback; the private local checkpoint is the recovery artifact. Backups and the supplied private blueprint remain outside Git.

## Headless integration

The local gateway on port 3030 was unavailable during this pass. No live WordPress delivery or external dashboard update is asserted. Physics, prompts and the rescue choice continue without it.

[LoreMetadata](../../src/ServerScriptService/OrdovicOpening/LoreMetadata.luau) accepts the existing `/api/v1/tethys/lore/cms-stream` response (`success`, `narrativeStream`, `nodeId`, `bodyText`). After the existing HTTP owner fetches that response, it can call `LoreMetadata.Apply(caveExpansion, payload)`. Only nodes with explicitly authored `LoreId` metadata receive matching `LoreBodyText`; no WordPress IDs or scientific facts are invented. The inspection handler validates life, chamber membership, range, prompt ownership, line of sight and duplicate observation before displaying cached text through the existing sparse subtitle channel. Missing content uses a physical observation, without awarding knowledge or inventory.

For the existing HTTP owner to mirror entry, it may create a server-only BindableEvent named `BE_OpeningZoneMirror` under the opener folder and listen to its `Event`. The arguments are the validated Player and the existing zone-update payload `{userId, targetZone = "Ordovic_Rapids", applyInjury = 0}`. The hook queues once per player/session; the HTTP owner remains responsible for authentication, retries and delivery status. Without it, the diagnostic status is `NotConnected`. The hook itself makes no network request and is not a persistent queue.

## Verification and remaining acceptance

[Dated results](cave-opener-validation.json) distinguish the nine passing structural/service fixture groups from assisted avatar checks. [The repeatable Studio fixture](../../tests/CaveOpener.studio.luau) checks native enclosure, unchanged spawn, closed upstream, native prompts, route order, water at the slide exit, one-axis force cleanup, posture restoration, invalid rescue requests and explicit CMS mapping. Compilation and a Rojo build also passed; compilation is not Roblox type analysis.

In the assisted ride, the existing avatar walked from the wake toward the mouth, reached a measured peak of 37.09 studs/second during roughly 2.38 seconds of slide Physics state, and returned to Swimming with 100 health. Native E inspected a mineral band. Separate assisted placements exercised the flyover/crash and both native rescue choices. Both restored WalkSpeed 16, JumpPower 50, JumpHeight 7.2 and AutoRotate true; refusal survived native death/automatic respawn as an unfinished branch with no retained hold or PlatformStand state.

The full 5,384-stud route has not passed unassisted acceptance in this pass. Physical controller/mobile use, multi-player arrival timing, all five refusal drops, finished audio and animation, live CMS mapping and exact release-version verification remain open. Nothing was published. The initial undo-recording guard and terrain channel `Size` errors were corrected before the final build; the partial geometry was explicitly restored before retrying. Final valid Play output contained no opener runtime/capability errors; engine UIBlox warnings remained.

Codex authored this pass, adapted the recovered modules, and performed the assisted checks. Daniel's terrain placement, story sequence and art ownership remain authoritative.
