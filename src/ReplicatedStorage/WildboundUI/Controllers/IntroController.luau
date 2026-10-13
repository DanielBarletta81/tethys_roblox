-- A once-per-session presentation gate. Never changes spawn, physics or progress.
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Style = require(script.Parent.Parent.UIStyle)
local Effects = require(script.Parent.Parent.UIEffects)
local Intro = {}
Intro.__index = Intro

function Intro.new(player, ui, inputMode)
	if ui:GetAttribute("WB_IntroSeen") == true then return nil end
	local self = setmetatable({UI = ui, Connections = {}}, Intro)
	self.Screen = Style.New("ScreenGui", "WOTIntro", player.PlayerGui, {
		ResetOnSpawn = false, DisplayOrder = 110, ScreenInsets = Enum.ScreenInsets.None,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	self.Root = Style.New("Frame", "FR_Intro", self.Screen, {
		Size = UDim2.fromScale(1,1), BackgroundColor3 = Style.Theme.Colors.Obsidian, BorderSizePixel = 0,
	})
	self.Scene = Style.Scene(self.Root, "IL_IntroScene", "SkyCity", 0.05)
	Style.Assets.ApplyIntroScene(self.Scene)
	self.Scene.UG_Atmosphere.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),
		NumberSequenceKeypoint.new(0.5,0.05),NumberSequenceKeypoint.new(1,0.85)})
	self.Shade = Style.New("Frame", "FR_Shade", self.Root, {
		Size = UDim2.fromScale(1,1), BackgroundColor3 = Style.Theme.Colors.Obsidian,
		BackgroundTransparency = 0.18, BorderSizePixel = 0, ZIndex = 2,
	})
	Style.New("UIGradient", "UG_Shade", self.Shade, {
		Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.45),
			NumberSequenceKeypoint.new(0.5,0.25),NumberSequenceKeypoint.new(1,0.02)}),
	})
	self.LeftContrast = Style.New("Frame", "FR_LeftContrast", self.Root, {
		Size = UDim2.new(0.7, 0, 1, 0), BackgroundColor3 = Style.Theme.Colors.Obsidian,
		BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 2,
	})
	Style.New("UIGradient", "UG_LeftContrast", self.LeftContrast, {
		Rotation = 0, Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.05),
			NumberSequenceKeypoint.new(0.55, 0.58),
			NumberSequenceKeypoint.new(1, 1),
		}),
	})
	self.Logo = Style.New("ImageLabel", "IL_TethysMasthead", self.Root, {
		AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.26),
		Size = UDim2.new(0.74,0,0,176), BackgroundTransparency = 1, ZIndex = 3,
	})
	Style.Fit(self.Logo, 480, 216)
	if not Style.Assets.ApplyBrand(self.Logo) then
		local brand = Style.Brand(self.Root)
		brand.AnchorPoint, brand.Position = Vector2.new(0.5,0.5), UDim2.fromScale(0.5,0.26)
	end
	self.TitleCard = Style.New("Frame", "FR_TitleCard", self.Root, {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.new(0.74, 0, 0, 170),
		BackgroundColor3 = Style.Theme.Colors.Obsidian, BackgroundTransparency = 0.22,
		BorderSizePixel = 0, ZIndex = 3,
	})
	Style.Panel(self.TitleCard)

	self.Kicker = Style.OutlinedText(Style.Text("TL_Kicker", self.TitleCard,
		"WORLD OF TETHYS", UDim2.fromOffset(16, 12), UDim2.new(1, -32, 0, 20), 14))
	self.Kicker.Font = Style.Theme.Typography.StrongFont
	self.Kicker.TextColor3 = Style.Theme.Colors.BronzeBright
	self.Kicker.TextXAlignment, self.Kicker.ZIndex = Enum.TextXAlignment.Center, 4

	self.Divider = Style.New("Frame", "FR_TitleDivider", self.TitleCard, {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(1, -46, 0, 1),
		BackgroundColor3 = Style.Theme.Colors.Bronze, BackgroundTransparency = 0.34,
		BorderSizePixel = 0, ZIndex = 4,
	})
	self.Divider.Position = UDim2.fromOffset(23, 30)

	self.Motto = Style.OutlinedText(Style.Text("TL_Motto", self.TitleCard,
		"WILDBOUND", UDim2.fromOffset(16, 36), UDim2.new(1, -32, 0, 54), 42))
	self.Motto.Font = Style.Theme.Typography.TitleFont
	self.Motto.TextXAlignment, self.Motto.ZIndex = Enum.TextXAlignment.Center, 4

	self.Context = Style.OutlinedText(Style.Text("TL_Context", self.TitleCard,
		"WESTERN WORLD OF TETHYS", UDim2.fromOffset(16, 95), UDim2.new(1, -32, 0, 24), 16))
	self.Context.Font = Style.Theme.Typography.StrongFont
	self.Context.TextXAlignment, self.Context.ZIndex = Enum.TextXAlignment.Center, 4

	self.ContextHint = Style.OutlinedText(Style.Text("TL_ContextHint", self.TitleCard,
		"The world remains playable. This is a title presentation, not a location lock.",
		UDim2.fromOffset(16, 120), UDim2.new(1, -32, 0, 24), 13))
	self.ContextHint.TextColor3 = Style.Theme.Colors.Ash
	self.ContextHint.TextXAlignment, self.ContextHint.ZIndex = Enum.TextXAlignment.Center, 4

	self.Enter = Style.New("TextButton", "TB_EnterTethys", self.Root, {
		AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.84),
		Size = UDim2.new(0.64,0,0,52), Text = "ENTER WILDBOUND", Font = Style.Theme.Typography.TitleFont,
		TextSize = 27, TextColor3 = Style.Theme.Colors.Bone, BackgroundTransparency = 0.08,
		BorderSizePixel = 0, ZIndex = 4,
	})
	Style.Fit(self.Enter, 300, 52)
	Style.OutlinedText(self.Enter)
	Style.Button(self.Enter, function() self:Continue() end)
	self.Enter.NextSelectionUp, self.Enter.NextSelectionDown = self.Enter, self.Enter
	self.Enter.NextSelectionLeft, self.Enter.NextSelectionRight = self.Enter, self.Enter
	self.Hint = Style.Text("TL_Input", self.Root, "", UDim2.fromScale(0.1,0.92), UDim2.new(0.8,0,0,30), 14)
	self.Hint.TextXAlignment, self.Hint.TextColor3, self.Hint.ZIndex = Enum.TextXAlignment.Center, Style.Theme.Colors.Ash, 4
	local function inputHint(mode)
		self.Hint.Text = mode == "Controller" and "A · Enter" or mode == "Touch" and "Tap to enter" or "Enter · Begin"
		if mode == "Controller" then task.spawn(function()
			game:GetService("RunService").Heartbeat:Wait()
			if not self.Dead and not self.Closing and self.Enter.AbsoluteSize.X > 0 then GuiService.SelectedObject = self.Enter end
		end) end
	end
	inputHint(inputMode:GetMode())
	table.insert(self.Connections, inputMode:ModeChangedSignal():Connect(inputHint))
	local function layout()
		local short = self.Screen.AbsoluteSize.Y < 590
		local narrow = self.Screen.AbsoluteSize.X < 760
		self.Logo.Size = UDim2.new(narrow and 0.9 or 0.74,0,0,short and 136 or 176)
		self.Logo.Position = UDim2.fromScale(0.5, short and 0.24 or 0.26)
		self.TitleCard.Size = UDim2.new(narrow and 0.9 or 0.74, 0, 0, short and 146 or 160)
		self.TitleCard.Position = UDim2.fromScale(0.5, short and 0.45 or 0.48)
		self.Motto.TextSize = narrow and 32 or short and 36 or 42
		self.Context.TextSize = narrow and 13 or 16
		self.ContextHint.Visible = not short
		self.Enter.Size = UDim2.new(narrow and 0.82 or 0.64, 0, 0, 52)
		self.Enter.Position = UDim2.fromScale(0.5, short and 0.8 or 0.84)
		self.Hint.Position = UDim2.fromScale(0.1, short and 0.9 or 0.92)
	end
	table.insert(self.Connections, self.Screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout))
	layout()
	self.PreviousMouse = UserInputService.MouseBehavior
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	ContextActionService:BindActionAtPriority("WB_IntroMovement", function() return Enum.ContextActionResult.Sink end, false, 4000,
		Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward, Enum.PlayerActions.CharacterLeft,
		Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump)
	ContextActionService:BindActionAtPriority("WB_IntroContinue", function(_, state)
		if UserInputService:GetFocusedTextBox() or GuiService.MenuIsOpen then return Enum.ContextActionResult.Pass end
		if state == Enum.UserInputState.Begin then self:Continue() end
		return Enum.ContextActionResult.Sink
	end, false, 4100, Enum.KeyCode.Return, Enum.KeyCode.ButtonA)
	ui:SetAttribute("WB_IntroActive", true)
	self.Effects = Effects.new(self.Root, ui)
	table.insert(self.Connections, ui.Destroying:Connect(function() self:Destroy() end))
	self.Screen:SetAttribute("WB_IntroReady", true)
	return self
end

function Intro:Continue()
	if self.Dead or self.Closing then return end
	self.Closing = true
	self.UI:SetAttribute("WB_IntroSeen", true)
	local duration = Effects.Reduced(self.UI) and 0 or 0.3
	self.Effects:Fade(1, duration)
	task.delay(duration, function()
		if self.Dead then return end
		self.Screen.Enabled = false
		self:_release()
	end)
end

function Intro:_release()
	ContextActionService:UnbindAction("WB_IntroMovement")
	ContextActionService:UnbindAction("WB_IntroContinue")
	if GuiService.SelectedObject == self.Enter then GuiService.SelectedObject = nil end
	UserInputService.MouseBehavior = self.PreviousMouse
	self.UI:SetAttribute("WB_IntroActive", false)
end

function Intro:Destroy()
	if self.Dead then return end
	self.Dead = true
	self:_release()
	for _, connection in ipairs(self.Connections) do connection:Disconnect() end
	self.Effects:Cancel()
	self.Screen:Destroy()
end

return Intro
