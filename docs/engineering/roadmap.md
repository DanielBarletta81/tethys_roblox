# Engineering roadmap

## Complete the current vertical slice

1. Place the first civic reveal after readable human engineering, at an actual inhabited view. Keep recovery and capture free of a success/title banner.
2. Validate unassisted Ordovic travel, lateral steering, intake choices, cave traversal and refusal recovery with real controller/touch input.
3. Replace marked character proxies with approved finished models, then add animation/audio without changing observation ownership or dialogue semantics.
4. Connect later civic sorting/maintenance through a visible validated action. Preserve the player's inaccessible upstream connection for later authoring.

## Production foundations

Design persistence around actual save needs. Specify schema/version migration, session ownership, retry/backoff, shutdown behavior and recovery from failed writes. Test failures before enabling live persistence. Current checkpoints/choices are session-only.

Audit existing remotes and prompts under multi-client latency. Keep server validation and bounded client payloads. Do not build custom replication merely to make the codebase appear complex; add it for a measured requirement.

Profile the complete slice for instance counts, frame time, server work and streaming behavior. Earlier generation-call timings are tooling timings, not game performance budgets.

## Tool publication and later features

Nature Scatter v1 is a candidate for a separately licensed standalone tool, after clarifying source-asset dependencies and producing a clean demonstration fixture. A DevForum release would be a separate publication task with documentation and limitations.

Scatter v2 clustering, exclusion zones, biome presets and density falloff follow the playable cave slice. Adventures has distinct prepared UI symbols; its separate place and gameplay bindings are not installed by this repository.

For recruiting, add evidence as work lands: a short playable-slice video, reproducible failure cases, measured performance and clear design decisions. Do not imply a current apprenticeship application window from an archived announcement; verify the official listing when applying.
