-- Run in Studio Client after asset loading. No gameplay state is changed.
local ui = game.Players.LocalPlayer.PlayerGui.TethysUI
local codex = game.Players.LocalPlayer.PlayerGui.WOTSymbolCodexGui
-- Hidden panels defer image loading. Render only for this bounded audit, then restore.
local visibility = {}
for _, panel in ipairs({ ui.InventoryUI.FR_InventoryPanel, ui.Menus.FR_PauseMenu,
	ui.Menus.FR_Settings, ui.LocationUI.FR_LocationBanner }) do
	visibility[panel] = panel.Visible
	panel.Visible = true
end
task.wait(0.3)
local result = { passed = {}, failed = {} }
local function test(name, callback)
	local ok, message = pcall(callback)
	table.insert(ok and result.passed or result.failed, ok and name or { name = name, error = tostring(message) })
end
test("Live status glyphs load the uploaded Wildbound atlas", function()
	for _, name in ipairs({ "Health", "Stamina", "Thirst", "Exposure" }) do
		local icon = ui.HUD.FR_StatusPanel["FR_" .. name].IL_StatusGlyph
		assert(icon.IsLoaded and icon.Image == "rbxassetid://132772321322120", name)
		assert(icon.ImageRectSize.X == 256 and icon.ImageRectSize.Y == 256)
	end
end)
test("Inventory, Settings, menu and Codex art load without replacing controls", function()
	for _, icon in ipairs({ ui.InventoryUI.FR_InventoryPanel.IL_TitleGlyph, ui.Menus.FR_Settings.IL_TitleGlyph,
		ui.Menus.FR_PauseMenu.SF_MenuActions.TB_MenuItem_Inventory.IL_MenuGlyph, ui.Menus.FR_PauseMenu.SF_MenuActions.TB_MenuItem_Settings.IL_MenuGlyph,
		codex.Toggle.IL_CodexGlyph }) do assert(icon.IsLoaded, icon:GetFullName()) end
	assert(codex.Toggle.TL_ToggleCaption.Text == codex.Toggle.Text)
	assert(ui.Menus.FR_PauseMenu.SF_MenuActions.TB_MenuItem_Inventory.TB_Activate.Selectable)
end)
test("Health glyph and native text occupy separate readable areas", function()
	local row = ui.HUD.FR_StatusPanel.FR_Health
	assert(row.TL_Label.AbsolutePosition.X >= row.IL_StatusGlyph.AbsolutePosition.X + row.IL_StatusGlyph.AbsoluteSize.X)
	assert(row.TL_Value.Text:find("/", 1, true))
	assert(row.TL_Label.TextBounds.X <= row.TL_Label.AbsoluteSize.X)
end)
test("Location badge and missing stamina preserve existing gameplay meaning", function()
	assert(ui.LocationUI.FR_LocationBanner.IL_RegionBadge:GetAttribute("UI_IconKey") == "SkyCity")
	assert(ui.LocationUI.FR_LocationBanner.IL_RegionBadge.IsLoaded)
	if game.Players.LocalPlayer:GetAttribute("OL_Stamina") == nil then assert(not ui.HUD.FR_StatusPanel.FR_Stamina.Visible) end
end)
for panel, wasVisible in pairs(visibility) do panel.Visible = wasVisible end
return result
