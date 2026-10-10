-- Saved authoring templates carry layout and art, never example gameplay state.
-- Run once before binding controllers, or on the Edit template while it is idle.
local TemplateState = {}

local function clearText(root)
	for _, object in ipairs(root:GetDescendants()) do
		if object:IsA("TextLabel") or object:IsA("TextButton") then object.Text = "" end
	end
end

function TemplateState.Prepare(ui)
	assert(ui:GetAttribute("WB_RuntimeBound") ~= true, "Cannot reset a bound HUD")
	ui.Enabled = false
	local route = ui.QuestUI.FR_QuestTracker
	route.Visible = false
	clearText(route)
	route.FR_Optional.Visible = false
	local stack = ui.Notifications.SF_ToastStack
	stack.Visible = false
	for _, template in ipairs(stack:GetChildren()) do
		if template:IsA("GuiObject") then template.Visible = false; clearText(template) end
	end
	local banner = ui.LocationUI.FR_LocationBanner
	banner.Visible = false
	clearText(banner)
	local promptBar = ui.InteractionUI.FR_PromptBar
	promptBar.Visible = false
	for _, template in ipairs(promptBar:GetChildren()) do
		if template:IsA("GuiObject") then template.Visible = false; clearText(template) end
	end
	local quickbar = ui.InventoryUI.FR_Quickbar
	quickbar.Visible = false
	for _, slot in ipairs(quickbar:GetChildren()) do
		if slot:IsA("GuiObject") and slot.Name:match("^FR_Slot_") then
			slot.Visible = false
			slot.TL_Count.Text = ""
		end
	end
	for _, name in ipairs({ "Health", "Stamina", "Thirst", "Exposure" }) do
		local row = ui.HUD.FR_StatusPanel["FR_" .. name]
		row.Visible = false
		row.TL_Value.Text = ""
	end
	ui.MapUI.FR_Minimap.Visible = false
	ui.Menus.FR_PauseMenu.Visible = false
	ui.LoadingUI.FR_LoadingScreen.Visible = false
	for _, template in ipairs(ui.Shared.Templates:GetChildren()) do
		if template:IsA("GuiObject") then template.Visible = false; clearText(template) end
	end
	ui:SetAttribute("WB_TemplateVersion", "HUD1.4")
end

return TemplateState
