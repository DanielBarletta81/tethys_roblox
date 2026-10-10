-- Run in Studio Client after HUD1.0 starts. All synthetic state is restored.
local player = game.Players.LocalPlayer
local ui = player.PlayerGui.TethysUI
local result = { passed = {}, failed = {} }
local function test(name, callback)
	local ok, message = pcall(callback)
	table.insert(ok and result.passed or result.failed, ok and name or { name = name, error = tostring(message) })
end
test("One HUD owns the runtime and legacy overlays are suppressed", function()
	local count = 0
	for _, child in ipairs(player.PlayerGui:GetChildren()) do if child.Name == "TethysUI" then count += 1 end end
	assert(count == 1 and player.PlayerScripts.WildboundUIRuntimeBinder:GetAttribute("WB_RuntimeBinderActive"))
	assert(not player.PlayerGui.WildboundRuntimeDebug.Enabled)
	for _, name in ipairs({ "WildboundHUD", "PC01_AdventureHintHUD", "FirstDayQuietCue", "IgziersLeapHUD", "HatcheryWatchHUD" }) do
		assert(not player.PlayerGui:FindFirstChild(name), name .. " duplicated")
	end
end)
local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
local oldHealth = humanoid.Health
test("Humanoid health and max-health changes reach the live meter", function()
	local oldMaximum = humanoid.MaxHealth
	if humanoid.Health > 0 then humanoid.Health = math.min(82, oldMaximum) end
	humanoid.MaxHealth = oldMaximum + 50
	local expected, received
	local deadline = os.clock() + 1
	repeat
		task.wait(0.05)
		expected = string.format("%d / %d", math.floor(humanoid.Health + 0.5), math.floor(humanoid.MaxHealth + 0.5))
		received = ui.HUD.FR_StatusPanel.FR_Health.TL_Value.Text
	until received == expected or os.clock() >= deadline
	humanoid.MaxHealth = oldMaximum
	assert(received == expected and expected:find(tostring(math.floor(oldMaximum + 50 + 0.5)), 1, true), "Expected " .. expected .. "; received " .. received)
end)
humanoid.Health = oldHealth
local oldHydration, oldExposure, oldStamina = player:GetAttribute("OL_Hydration"), player:GetAttribute("OL_PrettyWaterExposure"), player:GetAttribute("OL_Stamina")
test("Replicated vital bindings use correct units and conditional stamina", function()
	player:SetAttribute("OL_Hydration", 53)
	player:SetAttribute("OL_PrettyWaterExposure", 0.2)
	player:SetAttribute("OL_Stamina", 61)
	task.wait(0.2)
	local status = ui.HUD.FR_StatusPanel
	assert(status.FR_Thirst.TL_Value.Text == "53%" and status.FR_Exposure.TL_Value.Text == "20%")
	assert(status.FR_Stamina.Visible and status.FR_Stamina.TL_Value.Text == "61%")
	assert(math.abs(status.FR_Thirst.FR_BarBack.FR_BarFill.Size.X.Scale - 0.53) < 0.01)
end)
player:SetAttribute("OL_Hydration", oldHydration)
player:SetAttribute("OL_PrettyWaterExposure", oldExposure)
player:SetAttribute("OL_Stamina", oldStamina)
local resource = Instance.new("IntValue")
resource.Name, resource.Value, resource.Parent = "UI_ValidationResource", 3, player.Inventory
test("Inventory quantity updates and removal reach the quickbar", function()
	task.wait(0.1)
	local slot
	for _, child in ipairs(ui.InventoryUI.FR_Quickbar:GetChildren()) do
		if child:IsA("Frame") and child.Visible and child.TL_Name.Text:find("Validation", 1, true) then slot = child end
	end
	assert(slot and slot.TL_Count.Text == "x3")
	resource.Value = 5
	task.wait(0.1)
	assert(slot.TL_Count.Text == "x5")
	resource:Destroy()
	task.wait(0.1)
	for _, child in ipairs(ui.InventoryUI.FR_Quickbar:GetChildren()) do
		if child:IsA("Frame") and child.Visible then assert(not child.TL_Name.Text:find("Validation", 1, true)) end
	end
end)
resource:Destroy()
test("Route hints respond to their display setting", function()
	local subtitleWasVisible = ui.InteractionUI.FR_Subtitle.Visible
	ui.InteractionUI.FR_Subtitle.Visible = false
	ui:SetAttribute("WB_RouteHintsEnabled", false)
	task.wait(0.05)
	assert(not ui.QuestUI.FR_QuestTracker.Visible)
	ui:SetAttribute("WB_RouteHintsEnabled", true)
	task.wait(0.05)
	assert(ui.QuestUI.FR_QuestTracker.Visible)
	assert(ui.QuestUI.FR_QuestTracker.FR_Objectives.FR_ObjectiveTemplate.TL_Text.TextWrapped)
	ui.InteractionUI.FR_Subtitle.Visible = subtitleWasVisible
end)
local oldMessage = player:GetAttribute("SC_Message")
test("Authored cue channel reaches subtitles and respects its setting", function()
	player:SetAttribute("SC_Message", "UI validation cue")
	task.wait(0.05)
	assert(ui.InteractionUI.FR_Subtitle.Visible and ui.InteractionUI.FR_Subtitle.TL_Subtitle.Text == "UI validation cue")
	ui:SetAttribute("WB_SubtitlesEnabled", false)
	task.wait(0.05)
	assert(not ui.InteractionUI.FR_Subtitle.Visible)
	ui:SetAttribute("WB_SubtitlesEnabled", true)
end)
player:SetAttribute("SC_Message", oldMessage)
test("Menu controls are activatable and navigation stays inside the menu", function()
	local resume = ui.Menus.FR_PauseMenu.SF_MenuActions.TB_MenuItem_Resume.TB_Activate
	local inventory = ui.Menus.FR_PauseMenu.SF_MenuActions.TB_MenuItem_Inventory.TB_Activate
	local settings = ui.Menus.FR_PauseMenu.SF_MenuActions.TB_MenuItem_Settings.TB_Activate
	local codex = ui.Menus.FR_PauseMenu.SF_MenuActions.TB_MenuItem_Codex.TB_Activate
	assert(resume:IsA("GuiButton") and resume.NextSelectionDown == inventory and inventory.NextSelectionDown == codex and codex.NextSelectionDown == settings)
	assert(settings.NextSelectionDown == resume and resume.NextSelectionUp == settings)
end)
test("Synthetic sample content is hidden and the compass is live", function()
	assert(ui.MapUI.FR_Compass.TL_Heading.Text ~= "")
	assert(ui.MapUI.FR_Minimap:GetAttribute("WB_MapKind") == "LearnedWaterSketch")
	assert(not ui.MapUI.FR_Minimap.FR_MapViewport.Visible)
	assert(not ui.Notifications.SF_ToastStack.FR_Toast_Discovery.Visible)
	assert(not ui.QuestUI.FR_QuestTracker.FR_Optional.Visible)
end)
local hintAttributes = { "OL_LastHintTick", "OL_LastHintKey", "OL_LastHintText" }
local oldHints = {}
for _, name in ipairs(hintAttributes) do oldHints[name] = player:GetAttribute(name) end
test("Hint batches read completed text and notifications are bounded", function()
	for index = 1, 5 do
		player:SetAttribute("OL_LastHintTick", 1000000 + index)
		player:SetAttribute("OL_LastHintKey", "UIBatchAudit")
		player:SetAttribute("OL_LastHintText", "UI batch audit " .. index)
		task.wait(0.1)
	end
	local count, latest = 0, false
	for _, toast in ipairs(ui.Notifications.SF_ToastStack:GetChildren()) do
		if toast:IsA("Frame") and toast.Name:match("^FR_ToastRuntime_") then
			count += 1
			if toast.TL_Message.Text == "UI batch audit 5" then latest = true end
		end
	end
	assert(count <= 3 and latest)
end)
for _, name in ipairs(hintAttributes) do player:SetAttribute(name, oldHints[name]) end
for _, toast in ipairs(ui.Notifications.SF_ToastStack:GetChildren()) do
	if toast:IsA("Frame") and toast.Name:match("^FR_ToastRuntime_") and toast.TL_Message.Text:find("UI batch audit", 1, true) then toast:Destroy() end
end
return result
