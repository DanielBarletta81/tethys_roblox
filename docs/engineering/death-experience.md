# Death as experience — build card 26G

Death carries a modest exploration bonus forward. The implementation follows the camp notes' Rest requirements and preserves the opening's branch fallbacks. It does not implement the complete Fieldhold construction, weather or Kith cards.

Player experience, observed knowledge and access are separate responsibilities. `WB_PlayerXP` combines existing earned route XP (`SC_XP`) with `WB_ExplorationDeathXP`; `WB_PlayerLevel` describes accumulated experience. The new service never writes access flags, knowledge facts, MaxHealth, damage or movement stats. Legacy mission gates still use their existing counter; the death component cannot advance it. Expanding routes, equipment and interpretation remains the direction for later progression work.

## Reward policy

| Guard | Default |
| --- | --- |
| Required active travel outside safety | 30 seconds, 96 studs, three 32-stud cells |
| Maximum bonus per death | 18 XP |
| Rolling death bonus budget | 36 XP over ten minutes |
| Minimum interval between deaths | 45 seconds |
| Similar circumstances | Same recent hazard within 80 studs, over ten minutes |
| Repeated unchanged attempts | Multipliers 1, 0.35, 0.1, then zero |
| A changed attempt | New terrain cells, observation, area or first hazard can retain a 0.65 multiplier |

Distance and active time provide the base. New observations, areas, meaningful interactions and first hazards add capped context. A new observation alone cannot bypass the travel requirements. Deaths with zero rewards also enter the history; spawn spam cannot evict paid rewards from the rolling budget.

The server samples at 0.5-second intervals. It measures plausible displacement while running, climbing or swimming, with an eight-second grace for brief observation pauses. Long jumps and delayed samples rebase without counting travel. Freefall alone and stationary idling do not establish activity. This is a contextual reward guard, not a general movement anti-cheat or an inference of player intent.

Knowledge comes from existing owners: validated Cordge inspection and server observation/knowledge records. New XP does not invent an insight or disclose a hidden region. Rest settling is a validated interaction. The current hazard vocabulary covers swimming/current exposure and actual rapids impacts; it does not identify a distant Stryker as a predator.

## Owners and hierarchy

```text
ServerScriptService
  DeathExperience
    Config / Policy / Ledger
    Service / WorldContext
    RestService / CampRestKit
  OrdovicOpening
    ExperienceBridge
    BF_DeathExperience                 [created at runtime]
ReplicatedStorage.WildboundUI.Controllers
  ReturnController
```

The existing Wildbound bootstrap starts the service. Existing Ordovic Controller, HazardService and CordgeController use a server-only bindable bridge. The endpoint lives inside the already approved Ordovic sandbox; its callback accepts only observation, rapids-hazard and Rest-return operations. Existing sandbox and capability settings remain unchanged. This follows Roblox's [container communication model](https://create.roblox.com/docs/scripting/capabilities).

Apply the two adjacent `.integration.txt` recipes to the named existing bootstrap/camp owners. They are patches, not additional Scripts or a combined installer:

- [Wildbound bootstrap](../../src/ServerScriptService/DeathExperience/WildboundBootstrap.server.luau.integration.txt)
- [Existing camp owner](../../src/ServerScriptService/DeathExperience/AlphaGameplayController.server.luau.integration.txt)

## Rest adapter

The existing shared camps have six build choices: covered shelter, raised sleep, storage, boundary, water basin and heat pit. F builds or tends supplies; R settles Rest, separate from existing E observations. Native holds reach server handlers that validate life, distance, solid occlusion and available resources.

Anchors sample nearby real ground. Cover, platform condition, ground support, stored water and warm heat are checked again when claiming and returning. Private ownership is respected when `OwnerUserId` is set. The shared camps otherwise remain shared. Rest affects the return destination and reward safety classification; it does not suppress world damage.

The supply model is deliberately small: one `WaterSkin` inventory unit is treated as a filled water ration for the basin; one Fiber fuels ten minutes of heat. This prototype does not model reusable containers, water plumbing, rain extinguishing or structural weather simulation. Construction spends materials voluntarily; death adds no new resource penalty.

Creek Shelf and Root Rise have usable nearby floor. Rock Ledge's current guide has no nearby stable support, so its build prompts are disabled. Its original geometry remains intact. The prior camp script's missing SweepR wait now uses the existing CityEdge-to-first-camp guide.

Death never deletes a home. A valid claimed Rest takes priority through the Ordovic spawn owner. Missing, cold, damaged or unsupported Rest falls back to the existing cave/intake/downstream destination. The old delayed Alpha teleport is removed to avoid competing spawn owners. Reserved upstream and deeper routes stay under their existing locks.

## Quiet presentation

One six-second card says **Tethys got you.** followed by the awarded exploration amount, or **Experience carried forward.** for zero awards. It closes open menus, captures no input and gives the cue priority over speech, toasts and location cards. The 0.2-second fades respect reduced motion. Duplicate revisions cannot replay the card, and an older timer cannot hide a newer cue. No permanent XP gauge was added.

## Evidence and limits

See [the recorded checkpoint](death-experience-validation.json). Portable policy tests cover thresholds, idle/safe rejection, teleport/pause rejection, one award per life, stale callbacks, evidence uniqueness, caps, repeat taper, changed attempts, location boundaries, rolling-budget eviction and ordinary earned XP composition.

Studio fixtures test physical Rest and the client cue. Four native bridge checks confirm that validated inspection earns contextual ledger credit once, without awarding immediate XP or formal knowledge. Assisted native checks used supplied materials, actual prompt holds, a three-leg Humanoid walk and real `Humanoid.Died`/respawn events. The final walk earned 11 death XP after approximately 54 active seconds and 728 studs. An 18-XP ordinary reward produced a 29-XP player total while the legacy counter stayed at 18. Knowledge and the home survived; cooling the Rest caused fallback, and the next spawn death awarded zero.

These checks do not establish a complete unassisted route, multi-client reliability or mobile/controller acceptance. XP, evidence history and Rest claims survive character deaths within a server session. Rejoin persistence remains planned, matching the existing prototype's knowledge/home state. No live DataStore or production persistence claim is made.

For the native probe, invoke [the fixture](../../tests/DeathExperience.playtest.luau) from the existing server bootstrap with its actual Service/Rest/Kit instances in a disposable Studio session. A connector command can have a separate module cache. Remove the temporary invocation and fixture module afterward; neither remains installed in the development place. [Rest fixtures](../../tests/Rest.studio.luau) create fresh module instances, and [UI fixtures](../../tests/DeathReturnUI.playtest.luau) use a private attribute source without granting player XP.
