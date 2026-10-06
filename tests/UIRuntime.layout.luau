-- Run as a temporary Client LocalScript after HUD1.0 starts.
-- Exercise actual Roblox layout under isolated viewport-sized Frames.
local live = game.Players.LocalPlayer.PlayerGui.TethysUI
local Style = require(game.ReplicatedStorage.WildboundUI.UIStyle)
local host = Instance.new("ScreenGui")
host.Name, host.Enabled, host.Parent = "WB_LayoutAudit", false, game.Players.LocalPlayer.PlayerGui
local frame = Instance.new("Frame")
frame.Name, frame.Parent = "FR_Viewport", host
local clone = live:Clone()
for _, child in ipairs(clone:GetChildren()) do child.Parent = frame end
clone:Destroy()
local codexToggle = game.Players.LocalPlayer.PlayerGui.WOTSymbolCodexGui.Toggle:Clone()
codexToggle.Parent = frame.MapUI
frame.InventoryUI.FR_Quickbar:SetAttribute("WB_VisibleSlots", 4)
for _, slot in ipairs(frame.InventoryUI.FR_Quickbar:GetChildren()) do
	if slot:IsA("Frame") and slot.Name:match("^FR_Slot_") then slot.Visible = true end
end
local function overlaps(a, b)
	local ap, bp, as, bs = a.AbsolutePosition, b.AbsolutePosition, a.AbsoluteSize, b.AbsoluteSize
	return ap.X < bp.X + bs.X and bp.X < ap.X + as.X and ap.Y < bp.Y + bs.Y and bp.Y < ap.Y + as.Y
end
local result = { passed = {}, failed = {} }
for _, viewport in ipairs({ Vector2.new(1920, 1080), Vector2.new(1280, 720), Vector2.new(854, 480), Vector2.new(390, 844) }) do
	frame.Size = UDim2.fromOffset(viewport.X, viewport.Y)
	Style.Layout(frame, viewport)
	task.wait(0.1)
	local failures = {}
	local origin = frame.AbsolutePosition
	for _, panel in ipairs({ frame.HUD.FR_StatusPanel, frame.QuestUI.FR_QuestTracker, frame.InventoryUI.FR_Quickbar,
		frame.InteractionUI.FR_PromptBar, frame.InteractionUI.FR_Subtitle, frame.MapUI.FR_Compass,
		frame.Menus.FR_PauseMenu, frame.InventoryUI.FR_InventoryPanel, frame.Menus.FR_Settings,
		frame.Menus.TB_MenuToggle, codexToggle, frame.LocationUI.FR_LocationBanner, frame.MapUI.FR_Minimap, frame.MapUI.TL_TimeIndicator }) do
		local position, size = panel.AbsolutePosition - origin, panel.AbsoluteSize
		if position.X < -1 or position.Y < -1 or position.X + size.X > viewport.X + 1 or position.Y + size.Y > viewport.Y + 1 then
			table.insert(failures, panel.Name .. " exceeds viewport")
		end
	end
	local prompt, quickbar = frame.InteractionUI.FR_PromptBar, frame.InventoryUI.FR_Quickbar
	if overlaps(prompt, quickbar) then table.insert(failures, "Prompt overlaps radial items") end
	if overlaps(quickbar, frame.Menus.TB_MenuToggle) then table.insert(failures, "Quickbar overlaps Menu control") end
	if overlaps(quickbar, codexToggle) then table.insert(failures, "Quickbar overlaps Codex control") end
	local visibleSlots = {}
	for index = 1, 8 do
		local slot = quickbar:FindFirstChild(string.format("FR_Slot_%02d", index)) or quickbar:FindFirstChild("FR_Slot_" .. index)
		if slot and slot.Visible then
			for _, previousSlot in ipairs(visibleSlots) do if overlaps(previousSlot, slot) then table.insert(failures, "Radial slots overlap") end end
			if slot.TL_Name.TextSize < 11 then table.insert(failures, "Quickbar label too small") end
			table.insert(visibleSlots, slot)
		end
	end
	if #visibleSlots ~= 4 then table.insert(failures, "Expected four radial slots") end
	local status, compass = frame.HUD.FR_StatusPanel, frame.MapUI.FR_Compass
	if overlaps(status, compass) then table.insert(failures, "Status overlaps compass") end
	local banner = frame.LocationUI.FR_LocationBanner
	if overlaps(status, banner) then table.insert(failures, "Location banner overlaps vitals") end
	if overlaps(prompt, banner) then table.insert(failures, "Location banner overlaps prompt") end
	if overlaps(prompt, frame.MapUI.FR_Minimap) then table.insert(failures, "Prompt overlaps learned map") end
	if overlaps(quickbar, frame.InteractionUI.FR_Subtitle) then table.insert(failures, "Subtitles overlap radial items") end
	if overlaps(frame.MapUI.FR_Minimap, codexToggle) or overlaps(frame.MapUI.TL_TimeIndicator, codexToggle) then table.insert(failures, "Map/time overlaps Codex control") end
	for _, name in ipairs({ "FR_Health", "FR_Thirst", "FR_Exposure" }) do
		local row = status[name]
		if row.TL_Label.TextBounds.X > row.TL_Label.AbsoluteSize.X + 1 then table.insert(failures, name .. " label clips") end
	end
	local key = tostring(viewport.X) .. "x" .. tostring(viewport.Y)
	if #failures == 0 then table.insert(result.passed, key) else table.insert(result.failed, { viewport = key, errors = failures }) end
end
host:Destroy()
return result
