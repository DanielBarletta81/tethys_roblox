-- Live presentation checks. Restore every synthetic player/UI attribute.
local player = game.Players.LocalPlayer
local ui = player.PlayerGui.TethysUI
local result = { passed = {}, failed = {} }
local function test(name, callback)
	local ok, message = pcall(callback)
	table.insert(ok and result.passed or result.failed, ok and name or { name = name, error = tostring(message) })
end
local keys = { "SC_OnboardingStage", "HW_Complete", "WT_WaterStageIndex", "OL_Hydration", "OL_Stamina",
	"OL_PrettyWaterExposure", "OL_LastHintTick", "OL_LastHintKey", "OL_LastHintText", "SC_Message" }
local old = {}
for _, key in ipairs(keys) do old[key] = player:GetAttribute(key) end
local profile, numeric = ui:GetAttribute("WB_HUDProfile"), ui:GetAttribute("WB_NumericVitals")
local prompt = ui.InteractionUI.FR_PromptBar.Visible
ui:SetAttribute("WB_HUDProfile", "Game1")
player:SetAttribute("OL_Hydration", 53)
player:SetAttribute("OL_Stamina", 61)
player:SetAttribute("OL_PrettyWaterExposure", 0.2)
player:SetAttribute("WT_WaterStageIndex", 2)
task.wait(0.2)
test("Quiet Game1 keeps necessities and hides navigation, tracking and extra meters", function()
	local status = ui.HUD.FR_StatusPanel
	assert(ui:GetAttribute("WB_PresentationProfile") == "Game1")
	assert(status.FR_Health.Visible and status.FR_Thirst.Visible and status.FR_Thirst.TL_Value.Text == "53%")
	assert(not status.FR_Stamina.Visible and not status.FR_Exposure.Visible)
	assert(not ui.MapUI.FR_Compass.Visible and not ui.MapUI.FR_Minimap.Visible and not ui.MapUI.TL_TimeIndicator.Visible)
	assert(not ui.QuestUI.FR_QuestTracker.Visible and not ui.InventoryUI.FR_Quickbar.Visible)
	ui.InteractionUI.FR_PromptBar.Visible = true
	ui:SetAttribute("WB_NumericVitals", true); task.wait(0.05)
	assert(status.FR_Health.TL_Value.Visible and status.FR_Thirst.TL_Value.Visible)
	assert(not status.FR_Exposure.Visible and ui.InteractionUI.FR_PromptBar.Visible)
end)
test("Quiet Game1 retains authored speech while suppressing field-observation toasts", function()
	player:SetAttribute("OL_LastHintTick", 2000000)
	player:SetAttribute("OL_LastHintKey", "UIQuietAudit")
	player:SetAttribute("OL_LastHintText", "Quiet profile audit observation")
	player:SetAttribute("SC_Message", "Quiet profile audit dialogue")
	task.wait(0.1)
	assert(ui.InteractionUI.FR_Subtitle.TL_Subtitle.Text == "Quiet profile audit dialogue")
	for _, toast in ipairs(ui.Notifications.SF_ToastStack:GetChildren()) do
		if toast:IsA("Frame") and toast.Name:match("^FR_ToastRuntime_") then
			assert(toast.TL_Message.Text ~= "Quiet profile audit observation")
		end
	end
end)
test("Real CityOpen progression restores exploration without rewriting learned visits", function()
	assert(game.ReplicatedStorage.WildboundUI:GetAttribute("HUDProfile") == "Game1")
	ui:SetAttribute("WB_HUDProfile", nil)
	player:SetAttribute("SC_OnboardingStage", "Intake")
	player:SetAttribute("HW_Complete", false); task.wait(0.05)
	assert(ui:GetAttribute("WB_PresentationProfile") == "Game1")
	player:SetAttribute("SC_OnboardingStage", "CityOpen"); task.wait(0.2)
	assert(ui:GetAttribute("WB_PresentationProfile") == "Exploration" and ui.MapUI.FR_Compass.Visible)
	assert(ui.MapUI.FR_Minimap.Visible and ui.MapUI.FR_Minimap.FR_Known_GIVERS_FALLS.Visible)
	assert(not ui.QuestUI.FR_QuestTracker.Visible and player:GetAttribute("WT_WaterStageIndex") == 2)
end)
for _, key in ipairs(keys) do player:SetAttribute(key, old[key]) end
ui:SetAttribute("WB_HUDProfile", profile)
ui:SetAttribute("WB_NumericVitals", numeric)
ui.InteractionUI.FR_PromptBar.Visible = prompt
return result
