# Player UI artwork layers — 2026-10-10

The player UI now has separate native meter fills, item images and text objects.
Item images are wired to existing inventory/tool data. Menu and notification
headings use the bone-colored serif face; labels, quantities and controls retain
the clean utility font.

**The six newly supplied decorative PNGs have not been imported.** Only inline
chat references are available to this task. No matching files are present in the
workspace and Finder currently has no inspectable window. The prepared
[PlayerArtwork registry](../../src/ReplicatedStorage/WildboundUI/PlayerArtwork.luau)
deliberately contains empty image IDs, so the current UI uses its existing
decoration. Do not describe this checkpoint as a completed frame-art import or
live visual signoff.

## Live item images

[RuntimeData](../../src/ReplicatedStorage/WildboundUI/RuntimeData.luau) projects the
existing inventory count and tool ownership. An `IntValue` or `Tool` can carry
replicated `WB_InventoryImage` string metadata such as `rbxassetid://12345`.
An ordinary tool's `TextureId` supplies the fallback when explicit metadata is
absent. Existing counts and equip behavior are preserved.

The image parser accepts Roblox asset IDs and normalizes the legacy Roblox
asset URL format. External URLs, zero asset IDs and invalid types produce no
image. No new remote, inventory award or server progression owner is added.

[InventoryController](../../src/ReplicatedStorage/WildboundUI/Controllers/InventoryController.luau)
renders `IL_ItemImage`, `TL_Name` and `TL_Count` separately in each quick slot
and inventory row. Image metadata and tool texture changes refresh independently
of quantity changes. Names remain visible when an image is unavailable or
unloaded. Removing an item clears its image, identity, count and name. Teardown
disconnects watchers and prevents deferred updates to a destroyed UI.

## Prepared frame adapters

[ArtworkLayers](../../src/ReplicatedStorage/WildboundUI/ArtworkLayers.luau)
uses normalized clipping windows around full images, preserving the end caps
while stretching only the middle of long frames. It does not depend on
Roblox's served image resolution and does not edit the supplied bitmap.
Meter decoration shares the row, while `FR_BarBack.FR_BarFill`, `TL_Label` and
`TL_Value` remain independent live objects. A missing or unloaded skin keeps
the existing meter layout.

The supplied references have hooks for hydration, health, the second meter,
the quickbar chassis, menu button frames and the masthead. The second meter is
provisionally keyed as Stamina; confirm its intended meaning from the original
filename or design direction before activating the sun/current artwork. This
work does not invent a heat or weather statistic to match an illustration.

The quickbar adapter preserves four existing controls. Three positions use the
chassis's outer rings; a fourth stays in the open center with its own native
ring. Whole-image masthead rendering preserves native text as a loading
fallback. Decorative frames apply to menu actions; discovery cards remain
borderless. All Wildbound skins are guarded by the variant selection.

The registry's normalized frame bounds are provisional measurements from chat
references. Inspect original alpha channels, refine bounds and assess the
fourth quick slot before treating this skin as usable. The source registry
contains no fabricated Roblox IDs and none of these inactive skins have been
claimed as rendered.

Roblox exposes [image loading state](https://create.roblox.com/docs/reference/engine/classes/ImageLabel)
through `IsLoaded`; the UI retains readable fallbacks rather than waiting
indefinitely for an unavailable image.

## Verification and remaining work

- `UIRuntime.spec`: 15 passed, 0 failed, including image projection and validation.
- `UIRuntime.art.spec`: 11 passed, 0 failed, including stale crop/identity removal.
- [InventoryLayers.spec](../../tests/InventoryLayers.spec.luau): six passed,
  0 failed. Detached Edit fixtures exercise real property/attribute callbacks,
  separate icon/count layers, missing-image names, inventory rows, item removal
  and teardown. Fixture image IDs test properties, not successful texture loads.
- The prior Studio Play/capture timeouts remain unresolved. No new Client
  texture loading, skin geometry, device acceptance or save confirmation is
  claimed here.
- Seven installed module sources were read back and match the repository.
  Portable CI checks 189 tracked files, compiles 137 Luau files and passes the
  existing policy/plugin suites. Compilation does not verify Roblox rendering.

Place the six exact originals in the ignored `output/ui-art/player` folder or
provide their accessible filenames. Then inspect transparency and dimensions,
import them, fill the registry with returned asset IDs, refine clipping bounds,
and run Client layout/loading checks against all four viewports. Verify the
sun/current meter's meaning and the center quick slot visually. Return to Edit
and confirm Save to Roblox once Studio is responsive.
