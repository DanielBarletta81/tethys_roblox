local Style = require(script.Parent.Parent.UIStyle)
local Data = require(script.Parent.Parent.RuntimeData)
local Inventory = {}
Inventory.__index = Inventory

function Inventory.new(player, ui)
	local self = setmetatable({ player = player, ui = ui, items = {}, slots = {}, watchers = {}, selectedId = nil }, Inventory)
	self.quickbar = ui.InventoryUI.FR_Quickbar
	self.quickbar.UL_Slots:Destroy() -- Only this runtime clone; radial slots use Scale.
	Style.New("UIAspectRatioConstraint", "AR_Radial", self.quickbar, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width })
	self.center = Style.Text("TL_QuickCenter", self.quickbar, "+", UDim2.fromScale(0.32, 0.38), UDim2.fromScale(0.36, 0.24), 12)
	self.center.TextXAlignment = Enum.TextXAlignment.Center
	for _, frame in ipairs(self.quickbar:GetChildren()) do
		if frame:IsA("Frame") and frame.Name:match("^FR_Slot_") then table.insert(self.slots, frame) end
	end
	table.sort(self.slots, function(a, b) return a.Name < b.Name end)
	while #self.slots > 4 do table.remove(self.slots).Visible = false end
	for index, slot in ipairs(self.slots) do
		slot:SetAttribute("WB_QuickDirection", ({ "Up", "Left", "Right", "Down" })[index])
		Style.Panel(slot)
		slot:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0.5,0)
		slot.BackgroundTransparency = 0.68
		local name = Style.Text("TL_Name", slot, "", UDim2.fromScale(0.06, 0.04), UDim2.fromScale(0.88, 0.65), 11)
		name.TextXAlignment = Enum.TextXAlignment.Center
		name.TextTruncate = Enum.TextTruncate.AtEnd
		slot.TL_Count.Position, slot.TL_Count.Size = UDim2.fromScale(0.4, 0.72), UDim2.fromScale(0.54, 0.24)
		slot.TL_Count.TextSize = 10
		Style.Text("TL_Key", slot, tostring(index), UDim2.fromScale(0.06, 0.72), UDim2.fromScale(0.3, 0.24), 10).TextColor3 = Style.Theme.Colors.Ash
		Style.Button(slot, function() self:SelectQuick(index) end)
	end

	self.panel = Style.New("Frame", "FR_InventoryPanel", ui.InventoryUI, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.82, 0.72), Visible = false, ZIndex = 60,
	})
	Style.Panel(self.panel)
	Style.Scene(self.panel, "IL_InventoryScene", "Archyda", 0.9)
	Style.Fit(self.panel, 520, 470)
	Style.Icon("Inventory", "IL_TitleGlyph", self.panel, UDim2.fromOffset(14, 10), UDim2.fromOffset(34, 34))
	Style.Text("TL_Title", self.panel, "CARRIED ITEMS", UDim2.fromOffset(56, 14), UDim2.new(1, -140, 0, 26), 21).Font = Style.Theme.Typography.TitleFont
	self.close = Style.New("TextButton", "TB_Close", self.panel, {
		Position = UDim2.new(1, -72, 0, 12), Size = UDim2.fromOffset(56, 32), Text = "Close",
		Font = Style.Theme.Typography.BodyFont, TextSize = 12, TextColor3 = Style.Theme.Colors.Bone,
		BackgroundColor3 = Style.Theme.Colors.WetStone, BorderSizePixel = 0, ZIndex = 62,
	})
	Style.Button(self.close, function() self:SetOpen(false) end)
	self.list = Style.New("ScrollingFrame", "SF_Items", self.panel, {
		Position = UDim2.fromOffset(18, 54), Size = UDim2.new(1, -36, 1, -112),
		BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ZIndex = 61,
		ScrollBarImageColor3 = Style.Theme.Colors.Bronze,
	})
	Style.New("UIListLayout", "UL_Items", self.list, { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
	self.detail = Style.Text("TL_Detail", self.panel, "", UDim2.new(0, 18, 1, -50), UDim2.new(1, -36, 0, 38), 12)
	self.detail.TextColor3 = Style.Theme.Colors.Ash
	self:_watch("inventory", player:FindFirstChild("Inventory"))
	self:_watch("backpack", player:FindFirstChild("Backpack"))
	self:_watch("character", player.Character)
	player.ChildAdded:Connect(function(child)
		if child.Name == "Inventory" then self:_watch("inventory", child)
		elseif child:IsA("Backpack") then self:_watch("backpack", child) end
	end)
	player.ChildRemoved:Connect(function(child)
		if child.Name == "Inventory" then self:_watch("inventory", nil)
		elseif child:IsA("Backpack") then self:_watch("backpack", nil) end
	end)
	player.CharacterAdded:Connect(function(character) self:_watch("character", character) end)
	ui:GetAttributeChangedSignal("WB_PresentationProfile"):Connect(function() self:_refreshQuickVisibility() end)
	ui:GetAttributeChangedSignal("WB_MenuOpen"):Connect(function() self:_refreshQuickVisibility() end)
	ui:GetAttributeChangedSignal("WB_IntroActive"):Connect(function() self:_refreshQuickVisibility() end)
	self:Refresh()
	return self
end

function Inventory:_refreshQuickVisibility()
	local quiet = self.ui:GetAttribute("WB_PresentationProfile") == "Game1"
	self.quickbar.Visible = #self.items > 0 and self.ui:GetAttribute("WB_IntroActive") ~= true and self.ui:GetAttribute("WB_MenuOpen") ~= true
		and (not quiet or os.clock() < (self.quickExpires or 0))
end

function Inventory:_queueRefresh()
	if self.queued then return end
	self.queued = true
	task.defer(function() self.queued = false; self:Refresh() end)
end

function Inventory:_watch(key, container)
	for _, connection in ipairs(self.watchers[key] or {}) do connection:Disconnect() end
	local connections = {}
	self.watchers[key] = connections
	if container then
		local values = {}
		local function watch(child)
			if child:IsA("IntValue") then values[child] = child.Changed:Connect(function() self:_queueRefresh() end); table.insert(connections, values[child]) end
		end
		for _, child in ipairs(container:GetChildren()) do watch(child) end
		table.insert(connections, container.ChildAdded:Connect(function(child) watch(child); self:_queueRefresh() end))
		table.insert(connections, container.ChildRemoved:Connect(function(child)
			if values[child] then values[child]:Disconnect(); values[child] = nil end
			self:_queueRefresh()
		end))
	end
	self:_queueRefresh()
end

function Inventory:Refresh()
	self.items = Data.Inventory(self.player)
	self.quickItems = Data.QuickItems(self.items)
	self.quickbar:SetAttribute("WB_VisibleSlots", math.min(#self.items, 4))
	Style.Layout(self.ui, self.ui.AbsoluteSize)
	self:_refreshQuickVisibility()
	for index, slot in ipairs(self.slots) do
		local item = self.quickItems[index]
		slot.Visible = item ~= nil
		if item then
			slot:SetAttribute("WB_ItemId", item.Id)
			slot.TL_Name.Text, slot.TL_Count.Text = item.Label, "x" .. item.Count
			local selected = item.Id == self.selectedId or (item.Tool and item.Tool.Parent == self.player.Character)
			slot.US_Border.Color = selected and Style.Theme.Colors.BronzeBright or Style.Theme.Colors.Bronze
			slot.US_Border.Transparency = selected and 0 or 0.28
		else
			slot:SetAttribute("WB_ItemId", nil)
			slot.TL_Name.Text, slot.TL_Count.Text = "", ""
		end
	end
	if self.panel.Visible then self:_renderList() end
end

function Inventory:SelectQuick(index)
	local item = self.quickItems[index]
	if not item then return end
	self.quickExpires = os.clock() + 1.8
	self.quickbar:SetAttribute("WB_LastQuickItem", item.Id)
	self.quickbar:SetAttribute("WB_LastQuickDirection", index)
	for itemIndex, candidate in ipairs(self.items) do
		if candidate.Id == item.Id then self:Select(itemIndex); break end
	end
	self.centerToken = (self.centerToken or 0) + 1
	local token = self.centerToken
	self.center.Text = item.Label
	task.delay(1.8, function()
		if token == self.centerToken then self.center.Text = "+"; self:_refreshQuickVisibility() end
	end)
end

function Inventory:SetInputMode(mode)
	for index, slot in ipairs(self.slots) do
		slot.TL_Key.Text = mode == "Controller" and ({ "↑", "←", "→", "↓" })[index] or mode == "Touch" and "" or tostring(index)
	end
end

function Inventory:_renderList()
	local guiService = game:GetService("GuiService")
	local selected = guiService.SelectedObject
	local focusedList = selected and selected:IsDescendantOf(self.list)
	local focusedId = focusedList and selected:GetAttribute("WB_ItemId")
	local canvasPosition = self.list.CanvasPosition
	local navigation, byId = { self.close }, {}
	for _, child in ipairs(self.list:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
	if #self.items == 0 then Style.Text("TL_Empty", self.list, "No carried items yet.", UDim2.new(), UDim2.new(1, -8, 0, 44), 14) end
	for index, item in ipairs(self.items) do
		local row = Style.New("Frame", "FR_Item_" .. index, self.list, { Size = UDim2.new(1, -8, 0, 48), LayoutOrder = index, ZIndex = 62 })
		Style.Panel(row)
		Style.Text("TL_Name", row, item.Label, UDim2.fromOffset(10, 0), UDim2.new(0.72, -10, 1, 0), 14)
		local count = Style.Text("TL_Count", row, "x" .. item.Count, UDim2.fromScale(0.72, 0), UDim2.new(0.28, -10, 1, 0), 13)
		count.TextXAlignment = Enum.TextXAlignment.Right
		local button = Style.Button(row, function() self:Select(index) end)
		button:SetAttribute("WB_ItemId", item.Id)
		byId[item.Id] = button
		table.insert(navigation, button)
		if item.Id == self.selectedId then row.US_Border.Color, row.US_Border.Transparency = Style.Theme.Colors.BronzeBright, 0 end
	end
	Style.VerticalNavigation(navigation)
	self.list.CanvasPosition = canvasPosition
	if focusedList then guiService.SelectedObject = byId[focusedId] or self.close end
	self.detail.Text = #self.items == 0 and "Supplies appear here when acquired." or "Select a carried item to inspect it; select a tool to equip it."
	for _, item in ipairs(self.items) do
		if item.Id == self.selectedId then self.detail.Text = item.Label .. " · " .. item.Count .. " carried"; break end
	end
end

function Inventory:Select(index)
	local item = self.items[index]
	if not item then return end
	self.selectedId = item.Id
	local character = self.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if item.Tool and humanoid then
		if item.Tool.Parent == character then humanoid:UnequipTools()
		elseif item.Tool.Parent == self.player:FindFirstChild("Backpack") then humanoid:EquipTool(item.Tool) end
	end
	self:Refresh()
	self.detail.Text = item.Label .. " · " .. item.Count .. " carried"
end

function Inventory:SetOpen(open)
	if open and (self.ui:GetAttribute("WB_ReturnNoticeActive") or self.ui:GetAttribute("WB_IntroActive")) then return end
	self.panel.Visible = open == true
	if open then self:_renderList() end
	if self.onOpenChanged then self.onOpenChanged(open == true) end
end

return Inventory
