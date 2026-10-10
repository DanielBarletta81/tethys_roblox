# HUD1.4 template cleanup — 2026-10-10

The saved `StarterGui.TethysUI` still displayed the original demonstration
quest, item/discovery/danger cards, fake vital values, quickbar quantities and
Gather/Pickup/Craft prompts in Edit. Runtime styling hid most examples, but
could not keep them out of the authoring viewport or early loading frames.

[TemplateState](../../src/ReplicatedStorage/WildboundUI/TemplateState.luau)
clears example text and quantities from the existing template and hides
unbound controls. It preserves all instances, layout and imagery, and refuses
to reset a bound HUD. The saved ScreenGui is disabled. The
[runtime binder](../../src/StarterPlayer/StarterPlayerScripts/WildboundUIRuntimeBinder.luau)
reveals it after template preparation, profile selection, controller creation
and layout. Existing owners still supply vitals, inventory, route context,
native prompts, titles and speech.

Use the bounded [Edit recipe](../../tools/ui/prepare_template_in_studio.luau)
after installing the module and binder in another copy of the existing place.
This selective export does not include the authored StarterGui hierarchy.
No capability settings, gameplay state owners or world geometry changed.

Validation in Wildbound place `72645647440721`:

- 13 [Edit fixture groups](../../tests/UIRuntime.spec.luau) passed, including
  removal of injected sample content, repeated preparation and refusal to
  erase a bound HUD.
- 16 [Client presentation groups](../../tests/UIRuntime.effects.playtest.luau)
  passed. These include reduced motion, notice expiry/deduplication, speech
  priority, title captions, actual imagery loading and live template cleanup.
  Item receipts and title transitions in this suite use isolated GUI fixtures.
- The fresh Play HUD enabled once and displayed only Health, Hydration and
  Menu; the legacy HUD and hint overlay remained suppressed.
- After assisted placement at the authored masonry clue, native E/Inspect
  produced `CAVE_MASONRY_01` and “That isn't cavework.” through the real
  server/Cordge/client path. No quest or location card accompanied it.
  Leaving the clue hid the prompt; the subtitle expired normally.
- Native M opened the menu. Native I opened the inventory with the accurate
  “No carried items yet.” state, with no sample items or quantities.
- The runtime console had no new errors; two existing missing lower-tier
  water-audio warnings remained.

Observed Play views: [quiet opening](../media/hud14-quiet-opening.jpg) and
[Cordge inspection](../media/hud14-cordge-inspection.jpg). These are cropped
Studio observations, not mockups. The cave check used assisted placement;
no new end-to-end traversal or physical controller/touch acceptance is claimed.

GUI Edit Undo restored the original visible demo cards; Redo restored the
clean template. Its 440 descendants were preserved, and both changed Studio
sources matched the repository after Redo. File → Save to Roblox saved the
existing Wildbound place; the tab's edit timestamp cleared and no save error
appeared. This was a save, not a public release; no cloud reopen/read-back
verification was performed.

Portable CI also passed: 171 curated files, 128 Luau syntax checks, the existing
6 Cordge / 21 death-experience / 15 Terrain / 22 Stratum groups, and both plugin
source round trips. These checks do not replace Roblox type analysis or the
Studio presentation tests above.
