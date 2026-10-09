# Reproducing checks

## Portable checks on macOS or Linux

Python 3 is needed for the repository checks. The installer downloads official Luau 0.741 tools into `.tooling/`, verifies the release archive SHA-256, and leaves existing system tools unchanged.

```sh
python3 tools/install_luau.py
python3 tools/ci_checks.py --luau-dir .tooling/luau-0.741
```

CI runs the same commands on Linux. Compilation is a syntax check, not Roblox type analysis or an engine playtest. The six existing CordgePolicy cases are adapted to require the same source modules from disk; the Studio test itself remains unchanged.

## Roblox Studio checks

This repository is a selective source export. It does not contain the complete working place, StarterGui template, original nature packs, existing inventory/runtime services, voxel backups or approved capability settings as a ready-to-run package.

Use a local copy of the matching development place when running engine tests. Preserve existing owners and sandboxes. Import individual sources into the matching service paths; `.luau` alone does not imply a LocalScript class. In particular, WildboundUIRuntimeBinder, the Codex/debug clients and StarterCharacter HUD scripts are LocalScripts; Ordovic Bootstrap and SymbolCatalogPublisher are Scripts; service/config/controller files are ModuleScripts. Read `.integration.txt` files as edit recipes for their named existing owners, not executable Luau.

The HUD also requires the existing `StarterGui.TethysUI` hierarchy. Theme and InputMode are included in this export. AssetCatalog references existing published image IDs, whose access/moderation can affect another place; source textures are not bundled.

| Test | Studio context | What it needs |
| --- | --- | --- |
| NatureScatter.spec.luau / TerrainPass.audit.luau | Edit | Approved Scatter library/driver, copied source assets, real Terrain fixture |
| Stratum.spec.luau | Standalone Luau | Real codec, grid, R1B plan and session modules; included in portable CI |
| Stratum.studio.luau | Edit | Stratum Modules folder and two initially empty native Terrain boxes; restores channels and fixtures |
| OrdovicOpening.spec.luau / CordgePolicy.spec.luau / OrdovicDryLanding.spec.luau | Edit or appropriate server harness | Opening modules and their documented detached fixtures |
| CordgeRuntime.playtest.luau / OrdovicWaterSurface.playtest.luau | Server Play | Built opening, live player, server runtime; read test prerequisites |
| UIRuntime.spec.luau / UIRuntime.art.spec.luau | Edit | Existing UI hierarchy and modules; detached GUI fixtures |
| UIRuntime.effects.playtest.luau / layout / profile / bindings | Client Play | Initialized TethysUI and real runtime binder |

Tests label synthetic attributes, fixtures and assisted moves. Restore temporary state and return to Edit afterward. Do not interpret a passing fixture as full-route or physical-controller acceptance. Avoid running build/capability tools merely to read the code.

For the local Stratum package and its separate installed-plugin acceptance steps, see the [plugin guide](stratum.md). Packaging keeps the entry and eleven modules separate; it does not install runtime scripts or publish a plugin.
