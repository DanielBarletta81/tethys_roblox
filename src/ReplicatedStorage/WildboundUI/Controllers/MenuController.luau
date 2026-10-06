local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Style = require(script.Parent.Parent.UIStyle)
local Menu = {}
Menu.__index = Menu

function Menu.new(ui, inventory, inputMode)
	local self = setmetatable({ ui = ui, inventory = inventory, inputMode = inputMode, open = false }, Menu)
	self.panel = ui.Menus.FR_PauseMenu
	self.panel.Size, self.panel.Position = UDim2.fromScale(0.8, 0.7), UDim2.fromScale(0.5, 0.5)
	Style.Fit(self.panel, 380, 360)
	self.panel.ZIndex = 70
	Style.Panel(self.panel)
	Style.Panel(self.panel.FR_MenuPanel)
	self.panel.FR_MenuPanel.LayoutOrder = -1
	self.panel.FR_MenuPanel.Visible = false
	self.panel.UL_MenuButtons.HorizontalAlignment = Enum.HorizontalAlignment.Center
	self.panel.UL_MenuButtons.SortOrder = Enum.SortOrder.LayoutOrder
	self.panel.UL_MenuButtons.VerticalAlignment = Enum.VerticalAlignment.Center
	self.panel.UL_MenuButtons.Padding = UDim.new(0, 12)
	self.buttons = {}
	for index, name in ipairs({ "Resume", "Inventory", "Codex", "Settings" }) do
		local frame = self.panel:FindFirstChild("TB_MenuItem_" .. name)
		if not frame then
			frame = Style.New("Frame", "TB_MenuItem_" .. name, self.panel)
			Style.Text("TL_Label", frame, "CODEX")
		end
		frame.Size, frame.LayoutOrder, frame.ZIndex = UDim2.new(0.9, 0, 0, 48), index, 71
		Style.Panel(frame)
		frame.TL_Label.ZIndex, frame.TL_Label.TextSize = 72, 16
		if name ~= "Resume" then
			Style.Icon(name == "Codex" and "Journal" or name, "IL_MenuGlyph", frame, UDim2.fromOffset(12, 8), UDim2.fromOffset(32, 32))
			frame.TL_Label.Position, frame.TL_Label.Size = UDim2.fromOffset(54, 0), UDim2.new(1, -66, 1, 0)
			frame.TL_Label.TextXAlignment = Enum.TextXAlignment.Left
		end
		self.buttons[name] = Style.Button(frame, function()
			if name == "Resume" then self:SetOpen(false)
			elseif name == "Inventory" then self:SetOpen(false); inventory:SetOpen(true)
			elseif name == "Settings" then self:ShowSettings() end
			if name == "Codex" then self:SetOpen(false); if self.onOpenCodex then self.onOpenCodex() end end
		end)
	end
	local navigation = { self.buttons.Resume, self.buttons.Inventory, self.buttons.Codex, self.buttons.Settings }
	Style.VerticalNavigation(navigation)
	self.panel.TB_MenuItem_LeaveWorld.Visible = false
	Style.Text("TL_LeaveHint", self.panel, "Use the Roblox menu to leave the world.", UDim2.new(0.08, 0, 1, -38), UDim2.new(0.84, 0, 0, 28), 11).LayoutOrder = 5
	self.shade = Style.New("TextButton", "TB_MenuBackdrop", ui.Menus, {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Style.Theme.Colors.Obsidian,
		BackgroundTransparency = 0.38, Text = "", Visible = false, ZIndex = 55,
		Selectable = false, AutoButtonColor = false, Modal = true,
	})
	self.shade.Activated:Connect(function() self:CloseAll() end)
	self.toggle = Style.New("TextButton", "TB_MenuToggle", ui.Menus, {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0.02, 0.98), Size = UDim2.fromOffset(110, 36),
		Text = "MENU [M]", Font = Style.Theme.Typography.BodyFont, TextSize = 12,
		TextColor3 = Style.Theme.Colors.Bone, ZIndex = 40,
	})
	Style.Panel(self.toggle)
	Style.Button(self.toggle, function() self:SetOpen(not self.open) end)
	ui:SetAttribute("WB_SubtitlesEnabled", true)
	ui:SetAttribute("WB_RouteHintsEnabled", true)
	ui:SetAttribute("WB_NumericVitals", false)
	if ui:GetAttribute("WB_ReducedMotion") == nil then ui:SetAttribute("WB_ReducedMotion", false) end
	self:_buildSettings()
	inventory.onOpenChanged = function(isOpen)
		if isOpen then
			self.externalOpen = false
			if self.onBeforeOpen then self.onBeforeOpen() end
		end
		self:_syncOverlay()
		if isOpen then GuiService.SelectedObject = inventory.close
		elseif GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(inventory.panel) then GuiService.SelectedObject = nil end
	end
	inputMode:ModeChangedSignal():Connect(function(mode)
		self.toggle.Text = mode == "Controller" and "MENU" or mode == "Touch" and "MENU" or "MENU [M]"
	end)
	self.toggle.Text = inputMode:GetMode() == "KeyboardMouse" and "MENU [M]" or "MENU"
	self.panel.Visible = false
	return self
end

function Menu:_buildSettings()
	self.settings = Style.New("Frame", "FR_Settings", self.ui.Menus, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.8, 0, 0, 380), Visible = false, ZIndex = 70,
	})
	Style.Panel(self.settings)
	Style.Fit(self.settings, 380, 400)
	Style.Icon("Settings", "IL_TitleGlyph", self.settings, UDim2.fromOffset(14, 10), UDim2.fromOffset(34, 34))
	Style.Text("TL_Title", self.settings, "DISPLAY", UDim2.fromOffset(56, 14), UDim2.new(1, -74, 0, 30), 22).Font = Style.Theme.Typography.TitleFont
	self.settingButtons = {}
	for index, definition in ipairs({ { "Subtitles", "WB_SubtitlesEnabled" }, { "Route hints", "WB_RouteHintsEnabled" }, { "Numeric vitals", "WB_NumericVitals" }, { "Reduced motion", "WB_ReducedMotion" } }) do
		local button = Style.New("TextButton", "TB_Setting_" .. index, self.settings, {
			Position = UDim2.new(0, 18, 0, 54 + (index - 1) * 54), Size = UDim2.new(1, -36, 0, 46),
			Text = definition[1] .. (definition[2] == "WB_ReducedMotion" and GuiService.ReducedMotionEnabled and ": On (Roblox)" or self.ui:GetAttribute(definition[2]) and ": On" or ": Off"), TextColor3 = Style.Theme.Colors.Bone, TextSize = 14,
			Font = Style.Theme.Typography.BodyFont, ZIndex = 71,
		})
		Style.Panel(button)
		Style.Button(button, function()
			local nextValue = not self.ui:GetAttribute(definition[2])
			self.ui:SetAttribute(definition[2], nextValue)
			button.Text = definition[1] .. (definition[2] == "WB_ReducedMotion" and GuiService.ReducedMotionEnabled and ": On (Roblox)" or nextValue and ": On" or ": Off")
		end)
		table.insert(self.settingButtons, button)
	end
	GuiService:GetPropertyChangedSignal("ReducedMotionEnabled"):Connect(function()
		local button = self.settingButtons[4]
		button.Text = "Reduced motion" .. (GuiService.ReducedMotionEnabled and ": On (Roblox)" or self.ui:GetAttribute("WB_ReducedMotion") and ": On" or ": Off")
	end)
	local back = Style.New("TextButton", "TB_Back", self.settings, {
		Position = UDim2.new(0, 18, 1, -60), Size = UDim2.new(1, -36, 0, 42),
		Text = "Back", TextColor3 = Style.Theme.Colors.Bone, TextSize = 14, Font = Style.Theme.Typography.BodyFont, ZIndex = 71,
	})
	Style.Panel(back)
	Style.Button(back, function() self.settings.Visible = false; self:SetOpen(true) end)
	Style.VerticalNavigation({ self.settingButtons[1], self.settingButtons[2], self.settingButtons[3], self.settingButtons[4], back })
end

function Menu:_syncOverlay()
	local shown = self.open or self.settings.Visible or self.inventory.panel.Visible or self.externalOpen
	if shown and not self.overlayShown then
		self.previousMouseBehavior = UserInputService.MouseBehavior
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	elseif not shown and self.overlayShown and self.previousMouseBehavior then
		UserInputService.MouseBehavior = self.previousMouseBehavior
	end
	self.overlayShown = shown
	self.shade.Visible = shown
	self.ui:SetAttribute("WB_MenuOpen", shown)
	-- Block movement locally while a panel has focus; simulation keeps running.
	if shown then
		ContextActionService:BindActionAtPriority("WB_MenuMovement", function() return Enum.ContextActionResult.Sink end, false, 3000,
			Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward, Enum.PlayerActions.CharacterLeft,
			Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump)
	else ContextActionService:UnbindAction("WB_MenuMovement") end
end

function Menu:SetOpen(open)
	if open then
		self.externalOpen = false
		if self.onBeforeOpen then self.onBeforeOpen() end
		self.inventory:SetOpen(false); self.settings.Visible = false
	end
	self.open, self.panel.Visible = open == true, open == true
	self.panel.TB_MenuItem_LeaveWorld.TL_Label.Text = "LEAVE WORLD"
	self:_syncOverlay()
	if open then
		GuiService.SelectedObject = self.buttons.Resume
	else
		local selected = GuiService.SelectedObject
		if selected and selected:IsDescendantOf(self.panel) then GuiService.SelectedObject = nil end
	end
end

function Menu:ShowSettings()
	self.open, self.panel.Visible, self.settings.Visible = false, false, true
	self:_syncOverlay()
	GuiService.SelectedObject = self.settingButtons[1]
end

function Menu:CloseAll()
	self.externalOpen = false
	if self.onBeforeOpen then self.onBeforeOpen() end
	self.settings.Visible = false
	self.inventory:SetOpen(false)
	self:SetOpen(false)
	GuiService.SelectedObject = nil
end

return Menu
