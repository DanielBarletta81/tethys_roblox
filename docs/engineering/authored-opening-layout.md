# Authored Game 1 layout

Direct user update, 2026-10-09: the guides and river Parts are near the high mountain Game 1 entry. First Sort and Intake Works should sit a little lower than the cave start. Follow the first river reach and the authored ridge toward the city, or down toward Watcher.

This establishes the intended physical progression:

```text
High mountain cave entry
  -> first river reach / ridge-guided descent
  -> lower First Sort / Intake Works
  -> continuation toward the city
     or descent toward Watcher
```

This is route topology, not proof that every connection is already traversable. It does not select an exact fork point, safe spawn location or regional teleport boundary. The reserved Ordovic upstream and collapsed deeper cave remain closed. Water surfaces guide the opening; a followed leaf still belongs to the later Sky City lesson.

## References located in Studio

Read-only instance inspection and Edit viewport captures in **World of Tethys | Wildbound**, place `72645647440721`, on 2026-10-09. Coordinates are current scene samples in studs and are not runtime constants.

| Reference | Located instance / measurement | Interpretation |
| --- | --- | --- |
| High Game 1 mountain | `World.05_Mountain_Works.Upper_Cave_Start_Game_1`; five visible Parts enclose approximately X 897..3046, Y 1010..2226, Z -4124..-2764 | Creator's high-start landform reference; no exact cave entrance or safe player landing was inferred from its pivot |
| First Sort | `World.05_Mountain_Works.Givers_Intake.01_GiversFallsIntake.FirstSort.Basin.FirstSort_BasinFloor`; center approximately (-317.8, 1522.7, -1363.5) | The moved basin, with tilted geometry; center Y is not a flat floor elevation |
| Main intake guide | Same FirstSort tree: `MainIntake.GUIDE_MainIntakeFlow`, approximately (-325.5, 1527.1, -1356.6) | Current authored flow reference |
| Living run | `LivingRun.GUIDE_LivingRunEntry` and `GUIDE_LivingRunReturn`, centers around Y 1528.7..1528.9 | Preserve their actual transforms and authored purpose |
| Storm bypass | `StormMouth.GUIDE_StormBypassExit`, approximately (-365.3, 1519.6, -1366.3) | A candidate physical branch reference; its name does not authorize a Watcher teleport |
| Upper city floor | `World.02_Upper_City.Upper_Tier.Upper_Tier_Main`, center approximately (-245.8, 1396.2, -1159.3); horizontal Part top approximately Y 1402.9 | Current city integration reference |
| Watcher landmark | `World.Watcher_Volcano.00_GUIDES.GUIDE_WatcherCenter`, approximately (-3427, 566, -975); `AnchorRole=DistantVolcanoCenter` | Landmark direction, not a safe arrival or an exit marker |

## River authoring Parts

Located **five river models, six Parts each**, beneath:

`Workspace.World.98_MythLegend_Archive.Batch_MysteriousStartMap.Western_Tethys_Plot.02_Waterways`

| Model | Sampled Part center Y |
| --- | --- |
| `Ordovic_River` | 2444 |
| `Ordovic_River1` | 2308 |
| `Ordovic_River2` | 2319 |
| `Ordovic_River3` | 2469 |
| `Ordovic_River_Sky_City_Arrival` | 1616 |

Each model contains `Ord__River_1` and `Ord_River_2` through `Ord_River_6`. Their sampled widths are approximately 57.2 studs and thicknesses 1.56; lengths vary. These are authoring Parts, not a newly verified native Terrain river. Model/Part suffixes do not establish downstream order. Their current transforms are useful references even though the containing folder is named Archive; do not discard or relocate them based on that name.

## Placement reconciliation before wiring

- The installed `WildboundOpening_Ordovic` origin remains approximately (2396, 1346, -2320), its spawn center Y 1352.6 and first river-bed Part center Y 1335.8. Those belong to the earlier tested route and do not establish the new mountain-top entry.
- The older `01_Intake.Intake_Works` channel center remains Y 393, while the moved Giver's FirstSort intake guide is around Y 1527. Bind by reviewed purpose and identity, not the first object containing "Intake".
- The FirstSort basin center is Y 1522.7, while its `MaintenanceWalks.MaintenanceWalk_Cross` center is Y 1398.1, roughly 124.7 studs lower. That separation needs an authored connection or placement reconciliation before treating the assembly as a walkable system.
- The audit guide named `GUIDE_FirstSort_BasinFloor_TOP_Y90` is actually centered at Y 481; the Ordovic guide ending `TOP_Y284` is centered near Y 923.1. Numeric name suffixes and `LM_OrigPos*` attributes are historical labels, not current target coordinates.
- The older generated `GUIDE_WatcherLanding` remains a local refusal checkpoint near Y 1055. Its name does not make it a regional exit, and it is distinct from the distant Watcher landmark.

The intended high-start/lower-works relationship comes from Daniel's direction. The present proxies have mixed elevations and do not yet establish a continuous downhill route. Preserve their layout while resolving the actual entry, water grades, works connection and city/Watcher branch. Then attach stable marker identities and validated system hooks to the accepted sites.

This pass changed documentation only. It did not move Parts, alter Terrain or spawns, add tags/prompts, activate travel or run Play acceptance. Viewport captures included the existing Edit HUD preview; its displayed notices are not evidence of live discoveries or threats.

Related: [regional sprint](regional-world-sprint.md), [geometry snapshot](geometry-scale.md), [water-surface integration](raised-routes.md).
