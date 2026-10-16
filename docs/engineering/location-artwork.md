# Wildbound location artwork — HUD1.6, 2026-10-10

Seven supplied location originals are imported and installed in the connected
Wildbound place (72645647440721). The seven installed sources were read back and
match the repository. Live rendering and final Studio save confirmation remain
pending because Play entry and screen capture each timed out after 300 seconds.

## Artwork and route identity

| Title ID | Supplied original | Intended use |
| --- | --- | --- |
| `ORDOVIC_RIVER` | Basalt Overlook at Dawn-1.png | Opening scene from Arnn Ridge, before playable entry |
| `SKY_CITY_INTAKE` | Sky City's First Sort Intake-4.png | Next location on the opening route; First Sort |
| `LOWER_TIERS` | Beneath the Three Basalt Teeth-3.png | Lower-tier entry |
| `WATCHER_VOLCANO` | The Watcher Beneath Storms-1.png | Watcher region card |
| `THE_LEDGE` | The Ledge_ Sky City to Watcher-2.png | Ledge between the city and Watcher |
| `SILURIA` | Silurian Delta at Dawn.png | Siluria east of Sky City |
| `SKY_CITY` | Sky City Above the Weep-2.png | Sky City arrival |

This working mapping follows the supplied image order, filenames and Daniel's
route clarification. Siluria is separate from Danian Delta and from the reserved
Silurian upstream route. No upstream/deeper passage is opened by this work.

The [asset manifest](location-artwork-assets.json) records each original filename,
1672 × 941 source dimensions, SHA-256 and Roblox image ID. Files were copied and
uploaded unchanged. Raw originals remain outside the public Git export.

## Presentation and wiring

[LocationArtwork](../../src/ReplicatedStorage/WildboundUI/LocationArtwork.luau)
holds the seven images. [AssetCatalog](../../src/ReplicatedStorage/WildboundUI/AssetCatalog.luau)
applies whole-image rectangles; image-backed reveals use `ScaleType.Fit` and
zero atlas crop offsets. A missing image keeps the smaller text presentation
until it loads. Locations without supplied artwork retain text-only reveals.

The once-per-session intro now uses the Arnn Ridge image with native
**ORDOVIC RIVER** and **Arnn Ridge** labels beneath the Tethys masthead. The
existing Enter action and release of movement/input ownership are preserved.
The intro uses viewport cropping to cover the screen; location cards preserve
the whole landscape aspect ratio.

The existing reveal clock remains 0.65 seconds in, 1.5 seconds hold and 0.85
seconds out. The image and outlined text share that fade. The container has no
background or border, and a vertical transparency gradient softens the artwork.
Cards are capped at 680 pixels wide and 32% of viewport height, or 22% in
portrait. There is no extra transition overlay or camera effect.

Cordge speech, active prompts, the intro, menus and the life-ending cue hide
and pause the reveal. The existing queue deadlines and per-session duplicate
suppression still apply. Reduced motion preserves the lifecycle with immediate
alpha changes. A reveal is presentation; it awards no discovery, XP or access.

The [runtime binder](../../src/StarterPlayer/StarterPlayerScripts/WildboundUIRuntimeBinder.client.luau)
requests Intake from the existing server-owned `ENGINEERING_FIRST_READ` and
`INTAKE_WORKS` phases. It does not reveal Intake for cave wake, the held choice
or the rejection cascade. Existing server title cues select the Sky City and
Watcher images through the same allowlisted policy.

Lower Tiers, The Ledge and Siluria have registered artwork and accepted title
IDs. Their physical arrival triggers still need placement against the authored
routes. This change does not place new region volumes or invent progression
owners. Future validated server arrivals can use the existing title service
with these IDs; the client should not create visits to display artwork.

## Recorded verification

| Check | Result | Practical limit |
| --- | --- | --- |
| Upload | Seven successful image imports | Upload success does not prove client texture loading |
| Installed source readback | Seven of seven exact matches | Current Edit datamodel; not cloud save proof |
| [UIRuntime.spec](../../tests/UIRuntime.spec.luau) | 13 passed, 0 failed | Detached Edit fixtures |
| [UIRuntime.art.spec](../../tests/UIRuntime.art.spec.luau) | 10 passed, 0 failed | Includes whole-image properties, allowlist/captions and phase filtering; no texture rendering |
| Portable CI | 185 tracked files checked; 134 Luau files compile; existing policy/plugin suites pass | Compilation does not perform Roblox type or engine analysis |
| [LocationArtwork.playtest](../../tests/LocationArtwork.playtest.luau) | Prepared; not run | Eight Client groups for actual loading, fade, priority, viewport layout, expiry and live intro |
| Updated PlayerGUI/effects/layout checks | Not rerun for HUD1.6 | HUD1.5 results belong to the earlier dated checkpoint |
| Current visual evidence | Pending | Studio window inspection times out; Edit capture also timed out |
| Save confirmation | Pending | The Save shortcut was refused because Computer Use could not obtain a current state for the target window |

When Studio responds, enter Play, verify the Arnn Ridge intro, dismiss it, then
run the location test and the existing PlayerGUI/effects/layout checks in Client.
Exercise the actual Intake approach and existing City/Watcher arrivals separately
from presentation fixtures. Inspect texture readability on desktop and portrait
views, remove temporary fixtures, return to Edit and confirm Save to Roblox.
These tasks remain open; this checkpoint is not a completed live visual signoff.

See the earlier [PlayerGUI audit](player-gui-audit.md) for HUD1.5 evidence and the
restrained life-ending presentation that this update retains.
