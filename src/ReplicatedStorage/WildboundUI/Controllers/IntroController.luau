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
	self.Scene = Style.Scene(self.Root, "IL_IntroScene", "SkyCity", 0.15)
	Style.Assets.ApplyIntroScene(self.Scene)
	self.Scene.UG_Atmosphere.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),
		NumberSequenceKeypoint.new(0.5,0.05),NumberSequenceKeypoint.new(1,0.85)})
	self.Shade = Style.New("Frame", "FR_Shade", self.Root, {
		Size = UDim2.fromScale(1,1), BackgroundColor3 = Style.Theme.Colors.Obsidian,
		BackgroundTransparency = 0.12, BorderSizePixel = 0, ZIndex = 2,
	})
	Style.New("UIGradient", "UG_Shade", self.Shade, {
		Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.45),
			NumberSequenceKeypoint.new(0.5,0.25),NumberSequenceKeypoint.new(1,0.02)}),
	})
	self.Logo = Style.New("ImageLabel", "IL_TethysMasthead", self.Root, {
		AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.4),
		Size = UDim2.new(0.82,0,0,216), BackgroundTransparency = 1, ZIndex = 3,
	})
	Style.Fit(self.Logo, 480, 216)
	if not Style.Assets.ApplyBrand(self.Logo) then
		local brand = Style.Brand(self.Root)
		brand.AnchorPoint, brand.Position = Vector2.new(0.5,0.5), UDim2.fromScale(0.5,0.4)
	end
	self.Motto = Style.OutlinedText(Style.Text("TL_Motto", self.Root,
		"ORDOVIC RIVER", UDim2.fromScale(0.1,0.61), UDim2.new(0.8,0,0,40), 30))
	self.Motto.Font = Style.Theme.Typography.TitleFont
	self.Motto.TextXAlignment, self.Motto.ZIndex = Enum.TextXAlignment.Center, 3
	self.Context = Style.OutlinedText(Style.Text("TL_LocationContext", self.Root, "Arnn Ridge",
		UDim2.fromScale(0.1,0.69), UDim2.new(0.8,0,0,24), 15))
	self.Context.TextXAlignment, self.Context.ZIndex = Enum.TextXAlignment.Center, 3
	self.Enter = Style.New("TextButton", "TB_EnterTethys", self.Root, {
		AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.8),
		Size = UDim2.new(0.8,0,0,52), Text = "ENTER TETHYS", Font = Style.Theme.Typography.TitleFont,
		TextSize = 28, TextColor3 = Style.Theme.Colors.Bone, BackgroundTransparency = 1,
		BorderSizePixel = 0, ZIndex = 4,
	})
	Style.Fit(self.Enter, 300, 52)
	Style.OutlinedText(self.Enter)
	Style.Button(self.Enter, function() self:Continue() end)
	self.Enter.NextSelectionUp, self.Enter.NextSelectionDown = self.Enter, self.Enter
	self.Enter.NextSelectionLeft, self.Enter.NextSelectionRight = self.Enter, self.Enter
	self.Hint = Style.Text("TL_Input", self.Root, "", UDim2.fromScale(0.1,0.88), UDim2.new(0.8,0,0,30), 14)
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
		local short = self.Screen.AbsoluteSize.Y < 500
		self.Logo.Size = UDim2.new(0.82,0,0,short and 130 or 216)
		self.Motto.TextSize = self.Screen.AbsoluteSize.X < 500 and 24 or 30
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
