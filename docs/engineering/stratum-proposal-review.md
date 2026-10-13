# Stratum showcase claim review

The supplied post describes a proposed runtime streaming framework. The implemented project is [Tethys Terrain 0.1](tethys-terrain.md), a local Studio authoring plugin. The supplied copy is not evidence that the named modules, performance results or public license exist, and it is not authorization to publish or install a new runtime networking system.

## Claims against the current source

| Supplied claim | Verified current state |
| --- | --- |
| Stratum Engine runtime lifecycle/sharding | No Stratum implementation. The current tool authors bounded native Terrain in Edit mode |
| Strict-typed Luau | Plugin modules are not annotated `--!strict`; recorded compilation checks syntax |
| VoxelSerializer / binary compression | No serializer or `buffer` encoding. The backend uses native voxel-channel tables |
| Parallel Actor workers | No Actor pool or desynchronized workload |
| RequestChunkData / NetworkDispatcher | No chunk request remote or dispatcher |
| Managed 0.33-second position tracking | No runtime chunk tracking pipeline |
| Complete scraping/flooding prevention | No such implementation or verification; distance checks alone would not establish this |
| 145 KB → 19.6 KB / 86.4% reduction | No encoding, workload, payload captures or comparative benchmark supporting these figures |
| Zero GC / guaranteed 60 FPS | No allocation or frame-time evidence supporting these guarantees |
| MIT / open-source release | No license selected; no GitHub remote or verified public source link configured locally |
| Installation by runtime service folders | Incorrect for this tool. It is saved as a local Studio plugin with eight modules |

The concrete evidence is **15 portable groups**, **nine native Terrain fixture groups**, exact model source round-trip and **85 repository files compiled for syntax**. One authoring fixture measured approximately **0.038 seconds** for a **128 × 96 × 128-stud** box containing **24,576 voxels**. That observation does not measure multiplayer streaming or establish plugin-owned Undo acceptance. See the [recorded results](tethys-terrain-validation.json).

## Technical corrections for a future runtime proposal

Binary encoding and compression are separate operations. A fixed-width layout can reduce representation overhead, but the buffer length depends on the format. For example, `32 × 32 × 32 = 32,768` voxels at **two bytes per voxel** require **65,536 bytes (64 KiB)** before headers or compression. A third byte for liquid occupancy would make that example **96 KiB**. These are calculations under an assumed layout, not project benchmarks.

Preallocation does not demonstrate zero allocations or zero garbage collection. Matrix reconstruction must account for its actual output allocations. Roblox also documents that buffers passed through its APIs are copied; their identity is not preserved across Actors. [Buffer reference](https://create.roblox.com/docs/reference/engine/libraries/buffer).

Parallel Luau requires Actor-owned execution and attention to engine API thread-safety. Actor boundaries do not by themselves make code parallel or guarantee frame rates. Require modules before entering a parallel phase, and return to serial execution for APIs that require it. A round-robin pool and a desynchronization snippet are not measured evidence of a useful speedup. [Parallel Luau](https://create.roblox.com/docs/scripting/multithreading), [task API](https://create.roblox.com/docs/reference/engine/libraries/task).

Server-side request validation and server-enforced rate limits are distinct controls. A distance fence does not set a per-player request budget, bound in-flight work, validate chunk IDs or limit queued/decompression work. Data already delivered to a client cannot be treated as a server secret. Claim bounded abuse resistance only for defined, tested controls. [Securing the client-server boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary).

Roblox has native instance streaming. A custom streaming/replication layer needs a measured problem and an ownership plan for its interactions with native streaming, replicated Terrain, client-written Terrain and server collision. Evaluate the built-in system before choosing an additional runtime framework. [Instance streaming](https://create.roblox.com/docs/workspace/streaming).

If Stratum becomes a separate task, begin with one bounded codec and round-trip tests covering solid/liquid fidelity, malformed/truncated input, decompression limits, versioning and deterministic chunk coordinates. Measure bytes and decode/write time using named datasets before introducing Actors or network dispatch. Compare runtime behavior with native streaming before building a replacement lifecycle.

The [corrected showcase draft](devforum-showcase-draft.md) describes the current authoring plugin and labels the remaining checks explicitly.
