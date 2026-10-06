-- Run in Studio Client with inventory open (I). Temporary inventory fixtures are removed.
local player = game.Players.LocalPlayer
local ui = player.PlayerGui.TethysUI
local panel = ui.InventoryUI.FR_InventoryPanel
assert(panel.Visible, "Open inventory with I before running the focus audit")
local guiService = game:GetService("GuiService")
local result = { passed = {}, failed = {} }
local function test(name, callback)
	local ok, message = pcall(callback)
	table.insert(ok and result.passed or result.failed, ok and name or { name = name, error = tostring(message) })
end
local fixtures = {}
local function item(name)
	local value = Instance.new("IntValue")
	value.Name, value.Value, value.Parent = name, 3, player.Inventory
	table.insert(fixtures, value)
	return value
end
local resource = item("UIFocusResource")
task.wait(0.1)
local function button(id)
	for _, row in ipairs(panel.SF_Items:GetChildren()) do
		local activation = row:FindFirstChild("TB_Activate")
		if activation and activation:GetAttribute("WB_ItemId") == id then return activation end
	end
end
local function assertCycle(first, count)
	local current, seen = first, {}
	for _ = 1, count do
		assert(current and not seen[current] and current.Selectable)
		seen[current] = true
		assert(current.NextSelectionLeft == current and current.NextSelectionRight == current)
		assert(current.NextSelectionDown.NextSelectionUp == current)
		current = current.NextSelectionDown
	end
	assert(current == first, "Focus escapes the intended panel")
end
test("Inventory navigation includes Close and every item in one bounded cycle", function()
	local count = 1
	for _, row in ipairs(panel.SF_Items:GetChildren()) do if row:FindFirstChild("TB_Activate") then count += 1 end end
	assertCycle(panel.TB_Close, count)
end)
test("Focused inventory item survives quantity updates and sorted insertions", function()
	guiService.SelectedObject = assert(button(resource.Name))
	resource.Value = 6
	task.wait(0.1)
	assert(guiService.SelectedObject:GetAttribute("WB_ItemId") == resource.Name)
	item("AAA_UIFocusInsertion")
	task.wait(0.1)
	assert(guiService.SelectedObject:GetAttribute("WB_ItemId") == resource.Name)
	assert(guiService.SelectedObject.Parent.TL_Count.Text == "x6")
end)
test("Removing the focused item returns focus to Close", function()
	resource:Destroy()
	task.wait(0.1)
	assert(guiService.SelectedObject == panel.TB_Close)
end)
test("Menu and Settings keep vertical and sideways focus inside each panel", function()
	assertCycle(ui.Menus.FR_PauseMenu.TB_MenuItem_Resume.TB_Activate, 4)
	assertCycle(ui.Menus.FR_Settings.TB_Setting_1, 4)
end)
for _, value in ipairs(fixtures) do value:Destroy() end
task.wait(0.1)
guiService.SelectedObject = panel.TB_Close
return result
