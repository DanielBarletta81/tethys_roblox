-- Client UI test only. All synthetic attributes are restored before returning.
local player = game.Players.LocalPlayer
local ui = player.PlayerGui.TethysUI
local result = { passed = {}, failed = {} }
local function test(name, callback)
	local ok, message = pcall(callback)
	table.insert(ok and result.passed or result.failed, ok and name or { name = name, error = tostring(message) })
end
local keys = { "WT_WaterStageIndex", "WT_WaterChainComplete", "WT_WaterObjective", "IL_Active", "HW_Status", "HW_Complete", "SC_OnboardingStage", "OL_ObjectiveTrack", "OL_ObjectiveDone", "WOT_NextPull" }
local old = {}
for _, key in ipairs(keys) do old[key] = player:GetAttribute(key) end
local numeric = ui:GetAttribute("WB_NumericVitals")
local subtitle = ui.InteractionUI.FR_Subtitle.Visible
local prompt = ui.InteractionUI.FR_PromptBar.Visible
ui.InteractionUI.FR_Subtitle.Visible, ui.InteractionUI.FR_PromptBar.Visible = false, false
player:SetAttribute("IL_Active", false)
player:SetAttribute("HW_Status", "Briefing")
player:SetAttribute("OL_ObjectiveTrack", "")
test("Learned water sketch hides unvisited places and reveals only ordered visits", function()
	player:SetAttribute("WT_WaterStageIndex", 0); task.wait(0.1)
	assert(not ui.MapUI.FR_Minimap.Visible)
	player:SetAttribute("WT_WaterStageIndex", 2); task.wait(0.1)
	local map = ui.MapUI.FR_Minimap
	assert(map.Visible and map.FR_Known_ORDOVIC_SOURCE.Visible and map.FR_Known_GIVERS_FALLS.Visible)
	assert(not map.FR_Known_THE_WEEP.Visible and not map.FR_Known_HATCHERY_SYSTEM.Visible)
	assert(map.FR_KnownFlow_2.Visible and not map.FR_KnownFlow_3.Visible)
	assert(not map.FR_MapViewport.Visible) -- No sample satellite grid/player marker.
end)
test("Context closes after completion even if generic free-play guidance persists", function()
	player:SetAttribute("WT_WaterStageIndex", 5)
	player:SetAttribute("WT_WaterChainComplete", true)
	player:SetAttribute("OL_ObjectiveTrack", "LeaveCity")
	player:SetAttribute("OL_ObjectiveDone", true)
	player:SetAttribute("WOT_NextPull", "Persistent authored free-play hint")
	task.wait(0.1)
	assert(not ui.QuestUI.FR_QuestTracker.Visible)
	player:SetAttribute("SC_OnboardingStage", "CityOpen")
	player:SetAttribute("WT_WaterStageIndex", 0)
	player:SetAttribute("WT_WaterChainComplete", false)
	task.wait(0.1)
	assert(not ui.QuestUI.FR_QuestTracker.Visible)
end)
test("Accessibility setting shows live numeric vitals without changing their values", function()
	local label = ui.HUD.FR_StatusPanel.FR_Health.TL_Value
	ui:SetAttribute("WB_NumericVitals", true); task.wait(0.05)
	assert(label.Visible and label.Text:find("/", 1, true))
	ui:SetAttribute("WB_NumericVitals", false); task.wait(0.05)
	assert(not label.Visible)
end)
test("The compass offers at most one learned landmark and a real daylight phase", function()
	player:SetAttribute("WT_WaterStageIndex", 5); task.wait(0.2)
	local compass = ui.MapUI.FR_Compass
	assert(compass.TL_LandmarkMarker.Text == "△")
	assert(compass.TL_Landmark.Text == "Hatchery System")
	assert(not compass.TL_Heading.Text:find("°", 1, true))
	assert(({ DAWN = true, DAY = true, DUSK = true, NIGHT = true })[ui.MapUI.TL_TimeIndicator.Text])
end)
for _, key in ipairs(keys) do player:SetAttribute(key, old[key]) end
ui:SetAttribute("WB_NumericVitals", numeric)
ui.InteractionUI.FR_Subtitle.Visible, ui.InteractionUI.FR_PromptBar.Visible = subtitle, prompt
return result
