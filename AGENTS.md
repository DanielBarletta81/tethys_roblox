# Tethys-Roblox development guidance

- Build complete playable slices: environment, traversal, character observation and restrained UI should work together. Current slice: Ordovic opening and Cordge cave.
- Preserve the water-surface design: the Ordovic guides through visible water and terrain; the leaf lesson belongs to later Sky City. Do not open the reserved upstream or collapsed deeper passage automatically.
- Keep responsibilities in small Luau modules. Use object instances when they own state; pure policy/data modules when they do not. Avoid large installers or adding frameworks just to decorate the portfolio.
- Keep gameplay choices, observations, inventory and progression server-owned. Validate life, range, target ownership and relevant state before accepting player actions. UI displays existing state and does not award knowledge or checkpoints.
- Add remotes or custom replication only for a demonstrated gameplay requirement. Keep native prompts and their validated handlers where they suffice.
- Persistence remains planned. Before shipping it, specify the save schema, migrations, retry/failure behavior and concurrency tests. Do not describe session-only state as a DataStore implementation.
- Preserve reviewed sandbox boundaries, existing owners, original assets and generated-pass ownership. Do not broaden capabilities to get a test to pass.
- Mac terrain workflow: Blender or native Studio terrain/heightmaps. Heightmaps enter through Terrain Editor -> Import; meshes use the appropriate 3D import workflow. Optional paid add-ons are not required dependencies.
- Tethys Terrain is a local Studio authoring plugin. Preserve its read-only preview, bounded empty-patch rule, separate water channel, owned metadata and sculpt-safe Clear. Keep thermal erosion claims distinct from hydraulic erosion. Do not publish/install unrelated tooling or alter project capabilities for its tests.
- Maintain quiet Game1 presentation, contextual exploration later, sparse authored speech and reduced-motion behavior. Do not turn an ambiguous Stryker appearance into a confirmed predator alert.
- Death is experience, not a primary progression strategy: keep the contextual bonus capped, diminish repeated circumstances, preserve knowledge and homes, and revalidate Rest before returning. Keep player XP, observed knowledge and access distinct. As progression increases, expand possibility more than power.
- Test the relevant behavior and record what was actually exercised. Separate portable CI, Studio fixtures, assisted integration checks and unassisted/controller acceptance. Do not combine historical counts into an invented current total.
- Keep the public portfolio curated: source, tests, engineering docs and selected evidence. Leave private design PDFs, place backups, original asset packs, local baselines and credentials out of Git.
- Document design choices, unresolved defects, AI assistance and future work honestly. Recruiter-facing claims must link to inspectable code or evidence.
