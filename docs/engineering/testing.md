# Validation and acceptance

Recorded Studio checkpoints were completed on 2026-10-06. `validation.json` preserves aggregate scope and source hashes without local machine paths or full player attribute dumps. The CI workflow performs portable checks separately; it does not replay these historical Studio results.

## What has evidence

The latest HUD checkpoint passed 15 effects/portrait groups, four viewports, three profiles, eleven data/style groups and seven art/semantic groups. It also compared/compiled nine changed sources and exercised the actual settings button. A native intake choice plus an assisted physical touch of an existing captured-route title trigger demonstrated the server cue reaching the quiet client HUD with its ContextId caption.

Scatter checked category slope rejection separately, bounded random scale, seed-repeat signatures, footprint spacing, metadata, real Terrain, owned-pass Clear and Studio Undo/Redo. Initial Undo testing exposed destroyed Parent links; the final implementation detaches owned previous folders so history can restore them.

Opening tests covered flow math, capture/release, branch checkpoints and a living grounded dry landing. Cordge exercised absent actors, wall/range/ownership checks, priority interruption, one-shot behavior and cleanup. Water cues sampled actual Terrain water and suppressed gaps.

## What is still acceptance work

- Complete unassisted river/rapids/cascade travel and recovery; prototype timings are not established play-session pacing.
- First civic reveal placement on the new route. The old trigger handoff test proves transport/presentation, not geographic placement.
- Physical Xbox, actual touch input and five-new-player direction study. Virtual ButtonB is reserved by Roblox's simulator.
- Finished character visuals, animation and audio. The menu portrait adapter was exercised with a sanitized synthetic model.
- Multi-client latency and streaming checks, then persistence failure/concurrency tests when those systems are implemented.

Existing missing water-audio and an unrelated AlphaGameplayController wait warning were observed at the HUD checkpoint. The later 26G camp adapter fixes that specific missing-guide wait; the audio warnings remain. No published release or production reliability signoff is inferred from these checks.

## CI boundary

Portable CI compiles all `.luau` files and reuses the existing six Cordge policy cases against the real modules. It also checks the curated file selection, high-confidence credential patterns and relative documentation links. These checks run without Roblox credentials. Engine tests remain explicit Studio steps because Terrain, Instances, prompts, physics and rendering are not the standalone Luau runtime.

## Death experience and Rest

The 26G checkpoint is recorded separately in [death-experience-validation.json](death-experience-validation.json), with implementation and acceptance boundaries in [the build notes](death-experience.md). It includes 21 portable policy groups, 16 physical Rest groups, seven client cue groups and assisted native movement/death/respawn checks. It does not infer an unassisted opening run or persistent saves.
