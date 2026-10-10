# Wildbound PlayerGUI audit — HUD1.5, 2026-10-10

The opening now presents Daniel's Tethys artwork before showing the playable
scene. Discoveries, location reveals, prompts, subtitles and the life-ending
cue use transparent containers and outlined native text. The menu, inventory
and Codex share the bone, bronze and stone palette. Game1 remains quiet;
contextual navigation continues to use the existing progression profile.

## Presentation and ownership

| Runtime root | Owner and behavior |
| --- | --- |
| `WOTLoading` | New [ReplicatedFirst bootstrap](../../src/ReplicatedFirst/WildboundLoading.client.luau). Covers the world with native Tethys lettering until the intro is ready, then destroys itself and releases its movement binding. A 20-second fallback prevents an indefinite cover if binding fails. |
| `WOTIntro` | New [IntroController](../../src/ReplicatedStorage/WildboundUI/Controllers/IntroController.luau). Supplied Wildbound masthead and a central scene crop without the composition's baked HUD. Enter, controller A and the native button dismiss it; it stays dismissed across respawn. |
| `TethysUI` | One shared [runtime binder](../../src/StarterPlayer/StarterPlayerScripts/WildboundUIRuntimeBinder.luau). The saved 440-descendant template remains disabled until binding; demo quests, counts and notifications stay cleared. Runtime additions provide the branded menu, radial inventory, shared notices and native prompt adapter. |
| `WOTSymbolCodexGui` | Existing symbol owner retained. Its presentation is styled and its unlock receipts enter the shared notice channel. Intro and death block reopening; Game1 hides its standalone toggle. |
| `PC01_RiverCinematicHUD` | Existing visual overlay disabled while the shared HUD owns presentation. Authored cinematic speech uses the shared subtitle channel; audio remains with the existing producer. Reduced motion suppresses its shake/look effects. |
| `WildboundRuntimeDebug` | Remains disabled. |
| `Freecam` | Existing Studio developer GUI; not a player-facing custom HUD. |
| `ScreenGui` | Existing empty StarterGui root: zero children and no rendered content. Preserved rather than deleting an unrelated authored instance. |

Roblox chat and its platform menu retain their native ownership. The custom
HUD replaces the standard health/backpack/player-list displays. No capability
settings, server progression owners, spawn locations or world geometry changed.

The [asset catalog](../../src/ReplicatedStorage/WildboundUI/AssetCatalog.luau)
preserves the prior icon atlases and adds the supplied regional sheet
(`126132122426509`) and opening composition (`78866242256500`). Native rectangles
select the masthead, six regional scenes and the clean central opening scene.
The source sheets are not included in this curated repository. Their served-size
crops were checked visually and for bounds; no privileged image-size capability
was added. Finished 3D characters remain an input to the existing approved-model
portrait adapter; this pass adds no proxy portrait or fabricated character art.

## Restraint and safety

- Location reveals show a glyph, serif name and authored caption, with no outer
  border or miniature landscape rectangle by default. Timing remains 0.65 seconds
  in, 1.5 seconds held and 0.85 seconds out. They pause behind speech or a nearby
  prompt and expire stale queued reveals instead of displaying a backlog.
- Ordinary notices are borderless, bounded and deduplicated. Game1 suppresses
  generic discoveries and displays at most one real item receipt. No new quest
  tracker or leaf instruction is introduced into the water-surface opening.
- Cordge keeps subtitle priority; the old cinematic subtitle panel cannot appear
  beside it. Text outlines fade with their text, preventing leftover outlines.
- The intro hides gameplay controls and captures local movement until dismissal.
  It does not move the avatar, alter physics or award progression. Chat/platform
  menu use cannot accidentally activate its Enter action.
- Menu actions use a bounded scrolling region and 48-pixel buttons; the Menu
  control has a 44-pixel target. Empty radial slots keep no stale label/count.
- A life ends with **“This life has ended.”** and **“What you learned remains.”**
  A positive exploration bonus adds its small XP line; zero awards have no XP
  popup. The six-second cue captures no input and closes custom panels. The
  existing server death/Rest policy is unchanged.

## Validation

Tests ran in Wildbound place `72645647440721`. These are current, separate
Studio suites; portable CI is recorded separately below.

| Suite | Result | Scope |
| --- | --- | --- |
| [UI Edit fixtures](../../tests/UIRuntime.spec.luau) | 13 passed, 0 failed | Template cleanup, data/profile rules and authored hierarchy preservation. |
| [Presentation effects](../../tests/UIRuntime.effects.playtest.luau) | 16 passed, 0 failed | Priority, expiry, reduced motion, loaded imagery, captions, portrait sanitization and live binding. |
| [PlayerGUI audit](../../tests/PlayerGuiAudit.playtest.luau) | 8 passed, 0 failed | Intro release, singleton roots, borderless containers, text outlines, masks, artwork and bounded actions. Repeated after the final input guards. |
| [Layout](../../tests/UIRuntime.layout.luau) | 4 passed, 0 failed | Native detached viewport fixtures at 1920×1080, 1280×720, 854×480 and 390×844; bounds and overlap checks. |
| [Focus](../../tests/UIRuntime.focus.luau) | 4 passed, 0 failed | Inventory updates/removal and closed navigation cycles for inventory, menu and Settings. |
| [Life-ending cue](../../tests/DeathReturnUI.playtest.luau) | 8 passed, 0 failed | Positive/zero wording, wrapping, duplicate revisions, reduced motion, expiry and destruction. Uses a private attribute source and grants no XP. |

Native checks exercised the actual intro button and virtual controller A. Both
released loading/intro action bindings and restored prompts. Intro J/M/I could
not open custom panels. The virtual D-pad action was rejected by Roblox as a
CoreGUI-reserved key; physical controller and touch-device acceptance remain open.

Assisted placement at the real masonry and observation-slit clues followed by
native E/Inspect produced server-owned clue observations and Cordge speech.
The slit line appeared in the shared borderless subtitle above the native prompt;
moving away hid the prompt. An authored cinematic attribute fixture also used
that same subtitle while the legacy visual GUI stayed disabled.

A server `TITLE` fixture displayed Sky City / “Inside the Machine” without
changing `WB_TitleSeen_SKY_CITY` or awarding knowledge. This is a presentation
check, not evidence that an unassisted player reached the city.

An assisted native death closed inventory/menu, showed the new wording, awarded
zero XP for the test life and respawned with Health 100, one shared HUD, enabled
prompts and no intro replay. J could not reopen Codex during the death cue.
All 15 installed sources matched the local files, with the three final guard
and catalog edits read back again after installation.

Observed defects fixed during this pass: clipped final logo letter; radial/Menu
and radial/subtitle overlaps at smaller widths; an incorrect authored corner
lookup that interrupted startup; controller intro focus before layout; and
Codex reopening during the death cue. Fresh Play has no new runtime errors.
Two pre-existing missing lower-tier water-audio warnings remain.

Observed Studio views: [intro](../media/hud15-intro.jpg),
[location reveal](../media/hud15-title.jpg), [Cordge](../media/hud15-cordge.jpg),
[menu](../media/hud15-menu.jpg) and [life-ending cue](../media/hud15-return.jpg).
These are cropped captures over the working graybox, not a finished environment.
The intro uses the supplied masthead as the available intro-card artwork.

File → Save to Roblox saved the visual pass and cleared its edit timestamp.
After the last two input guards and a catalog comment were installed, Studio's
GUI inspection began timing out. The existing-place Command-S shortcut was sent
successfully, but its completion could not be visually confirmed. The connector
still responds and the installed sources match. This pass did not publish a live
version or reopen the cloud copy for read-back.

Portable CI passed: 181 curated files, 132 Luau syntax checks, the existing
6 Cordge / 21 death-experience / 15 Terrain / 22 Stratum groups, and both plugin
source round trips. These do not replace Roblox type analysis or Studio tests.
