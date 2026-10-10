-- Run in Studio Edit. Only unparented fixtures and a detached GUI clone are used.
-- The Studio connector cannot require the legacy library's saved capability set.
-- Evaluate only these pure presentation modules in the caller's existing scope.
local function readModule(module)
	assert(module:IsDescendantOf(game.ReplicatedStorage.WildboundUI))
	local chunk = assert(loadstring(module.Source))
	local environment = setmetatable({ script = module, require = readModule }, { __index = getfenv() })
	setfenv(chunk, environment)
	return chunk()
end
local Data = readModule(game.ReplicatedStorage.WildboundUI.RuntimeData)
local Style = readModule(game.ReplicatedStorage.WildboundUI.UIStyle)
local TemplateState = readModule(game.ReplicatedStorage.WildboundUI.TemplateState)
local result = { passed = {}, failed = {} }
local fixtures = Instance.new("Folder")
local gui = game.StarterGui.TethysUI:Clone()
local attributes = {}
local character = Instance.new("Model")
character.Parent = fixtures
local mock = { Character = character }
function mock:GetAttribute(name) return attributes[name] end
function mock:FindFirstChild(name) return fixtures:FindFirstChild(name) end
local function test(name, callback)
	local ok, message = pcall(callback)
	table.insert(ok and result.passed or result.failed, ok and name or { name = name, error = tostring(message) })
end

test("Saved templates contain no gameplay examples before controllers bind", function()
	local toast = gui.Notifications.SF_ToastStack.FR_Toast_Item
	local route = gui.QuestUI.FR_QuestTracker
	local label = gui.HUD.FR_StatusPanel.FR_Health.TL_Label
	local count = #gui:GetDescendants()
	toast.Visible, toast.TL_Title.Text, toast.TL_Message.Text = true, "Item Found", "Mushroom collected."
	route.Visible, route.TL_QuestType.Text, route.TL_Title.Text = true, "MAIN QUEST", "Watcher Stirs"
	gui.InventoryUI.FR_Quickbar.FR_Slot_01.TL_Count.Text = "99"
	TemplateState.Prepare(gui)
	assert(not gui.Enabled and not route.Visible and not toast.Visible)
	assert(route.TL_QuestType.Text == "" and route.TL_Title.Text == "" and toast.TL_Message.Text == "")
	assert(gui.InventoryUI.FR_Quickbar.FR_Slot_01.TL_Count.Text == "")
	assert(gui.HUD.FR_StatusPanel.FR_Health.TL_Value.Text == "" and not gui.HUD.FR_StatusPanel.FR_Health.Visible)
	assert(gui.HUD.FR_StatusPanel.FR_Health.TL_Label == label and label.Text == "HEALTH")
	assert(#gui:GetDescendants() == count and gui:GetAttribute("WB_TemplateVersion") == "HUD1.4")
	TemplateState.Prepare(gui) -- Reapplying the Edit recipe is harmless.
	assert(#gui:GetDescendants() == count)
end)
test("Template cleanup refuses to erase a bound HUD", function()
	gui:SetAttribute("WB_RuntimeBound", true)
	gui.Enabled = true
	local ok = pcall(TemplateState.Prepare, gui)
	assert(not ok and gui.Enabled)
	gui:SetAttribute("WB_RuntimeBound", nil)
	gui.Enabled = false
end)

test("Meters reject missing and invalid values and clamp real data", function()
	assert(Data.Percent(nil) == nil and Data.Percent("100") == nil)
	assert(Data.Percent(0 / 0) == nil and Data.Percent(math.huge) == nil)
	assert(Data.Percent(-5) == 0 and Data.Percent(250) == 1)
	assert(Data.Percent(65) == 0.65 and Data.Percent(0.3, 1) == 0.3)
end)
test("Vitals use the existing hydration and water exposure units", function()
	attributes = { OL_Hydration = 42, OL_PrettyWaterExposure = 0.28 }
	local vitals = Data.Vitals(mock)
	assert(vitals.Hydration == 0.42 and vitals.Exposure == 0.28 and vitals.Stamina == nil)
	attributes.OL_Stamina = 61
	assert(Data.Vitals(mock).Stamina == 0.61)
end)
test("Route guidance comes from authored state with no invented quest", function()
	attributes = {}
	assert(Data.Route(mock) == nil)
	attributes.WOT_NextPull = "Existing route hint"
	local title, text, count = Data.Route(mock)
	assert(title == nil) -- Generic free-play hints do not pin a checklist.
	attributes.IL_Active, attributes.IL_Title, attributes.IL_Message = true, "Authored route", "Authored observation"
	attributes.IL_Step, attributes.IL_RouteCount = 3, 7
	title, text, count = Data.Route(mock)
	assert(title == "Authored route" and text == "Authored observation" and count == "3 / 7")
end)
test("Completed routes disappear and water onboarding uses authored guidance", function()
	attributes = { WT_WaterStageIndex = 0, WT_WaterChainComplete = false, WT_WaterObjective = "Start at Ordovic Source." }
	local title, text, count = Data.Route(mock)
	assert(title == "Follow the Water" and text == attributes.WT_WaterObjective and count == "")
	attributes.WT_WaterStageIndex, attributes.WT_WaterChainComplete = 5, true
	attributes.OL_ObjectiveTrack, attributes.OL_ObjectiveDone = "LeaveCity", true
	assert(Data.Route(mock) == nil)
	attributes.WT_WaterStageIndex, attributes.WT_WaterChainComplete = 0, false
	attributes.SC_OnboardingStage = "CityOpen"
	assert(Data.Route(mock) == nil) -- Untraced water is not a mature free-play objective.
end)
test("Radial choices retain food, tools, line and vessel without duplicates", function()
	local tool = Instance.new("Tool")
	local items = { { Id = "FieldBandage", Count = 2 }, { Id = "FiberLine", Count = 1 }, { Id = "SignalFlare", Count = 1 },
		{ Id = "StoneSpear", Count = 1, Tool = tool }, { Id = "TrailRation", Count = 2 }, { Id = "WaterSkin", Count = 1 } }
	local quick = Data.QuickItems(items)
	assert(quick[1].Id == "TrailRation" and quick[2].Tool == tool and quick[3].Id == "FiberLine" and quick[4].Id == "WaterSkin")
	assert(#Data.QuickItems({}) == 0)
	local seen = {}
	for _, item in pairs(Data.QuickItems({ items[1], items[3] })) do assert(not seen[item.Id]); seen[item.Id] = true end
	tool:Destroy()
end)
test("Game1 and exploration profiles resolve without changing progression", function()
	attributes = {}
	gui:SetAttribute("WB_HUDProfile", "Game1")
	assert(Data.Profile(mock, gui) == "Game1")
	attributes.SC_OnboardingStage = "CityOpen"
	assert(Data.Profile(mock, gui) == "Game1") -- Explicit preview remains explicit.
	gui:SetAttribute("WB_HUDProfile", "Exploration")
	assert(Data.Profile(mock, gui) == "Exploration")
	gui:SetAttribute("WB_HUDProfile", nil)
	assert(Data.Profile(mock, gui) == "Exploration" and attributes.SC_OnboardingStage == "CityOpen")
end)
test("Learned map rejects unknown stages and wraps compass bearings", function()
	local Navigation = readModule(game.ReplicatedStorage.WildboundUI.NavigationData)
	attributes = {}; assert(Navigation.KnownCount(mock) == 0)
	attributes.WT_WaterStageIndex = 2; assert(Navigation.KnownCount(mock) == 2)
	attributes.WT_WaterStageIndex = math.huge; assert(Navigation.KnownCount(mock) == 0)
	assert(Navigation.Delta(1, 359) == 2 and Navigation.Delta(359, 1) == -2)
end)
test("Inventory excludes zero quantities and combines tools without double counting", function()
	local inventory = Instance.new("Folder")
	inventory.Name, inventory.Parent = "Inventory", fixtures
	for name, amount in pairs({ FieldBandage = 2, WaterSkin = 0, TrailRation = -1 }) do
		local value = Instance.new("IntValue")
		value.Name, value.Value, value.Parent = name, amount, inventory
	end
	local tool = Instance.new("Tool")
	tool.Name, tool.Parent = "FieldBandage", character
	local items = Data.Inventory(mock)
	assert(#items == 1 and items[1].Count == 2 and items[1].Tool == tool)
	assert(items[1].Label == "Field Bandage")
	inventory.FieldBandage.Value = 0
	assert(Data.Inventory(mock)[1].Count == 1)
	tool:Destroy()
	assert(#Data.Inventory(mock) == 0)
end)
test("Style preserves the existing hierarchy and keeps text readable", function()
	local row = gui.HUD.FR_StatusPanel.FR_Health
	Style.Apply(gui)
	assert(gui.HUD.FR_StatusPanel.FR_Health == row)
	assert(row.TL_Label.TextTransparency == 0 and row.TL_Value.TextSize >= 12)
	assert(gui.ScreenInsets == Enum.ScreenInsets.CoreUISafeInsets and gui.ResetOnSpawn == false)
	assert(gui.HUD.FR_StatusPanel.FR_Thirst.TL_Label.Text == "HYDRATION")
end)
test("Sample notifications, optional quest content and the unwired map stay hidden", function()
	assert(not gui.Notifications.SF_ToastStack.FR_Toast_Item.Visible)
	assert(not gui.QuestUI.FR_QuestTracker.FR_Optional.Visible)
	assert(not gui.MapUI.FR_Minimap.Visible)
	for _, template in ipairs(gui.Shared.Templates:GetChildren()) do
		if template:IsA("GuiObject") then assert(not template.Visible) end
	end
end)
test("Authored Frames gain an actual selectable button", function()
	local frame = gui.Menus.FR_PauseMenu.TB_MenuItem_Resume
	local label = frame.TL_Label
	local button = Style.Button(frame)
	assert(button:IsA("TextButton") and button.Selectable and not frame.Selectable)
	assert(frame.TL_Label == label and frame.US_Focus.Color == Style.Theme.Colors.BronzeBright)
end)
fixtures:Destroy()
gui:Destroy()
return result
