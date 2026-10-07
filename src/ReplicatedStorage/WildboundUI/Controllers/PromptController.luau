local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local Style = require(script.Parent.Parent.UIStyle)
local PromptUI = {}

local function glyph(prompt, mode)
	if mode == "Touch" then return prompt.HoldDuration > 0 and "HOLD" or "TAP" end
	local name = mode == "Controller" and prompt.GamepadKeyCode.Name or prompt.KeyboardKeyCode.Name
	return name:gsub("^Button", "")
end

function PromptUI.new(ui, inputMode)
	local bar = ui.InteractionUI.FR_PromptBar
	bar.Position, bar.Size = UDim2.fromScale(0.5, 0.88), UDim2.new(0.8, 0, 0, 62)
	Style.Fit(bar, 680, 62)
	bar.UL_Prompts.HorizontalAlignment = Enum.HorizontalAlignment.Center
	bar.UL_Prompts.Padding = UDim.new(0, 8)
	local template = bar.FR_Prompt_Gather
	for _, child in ipairs(bar:GetChildren()) do if child:IsA("GuiObject") then child.Visible = false end end
	-- Keep registered prompts alive in Lua; weak instance keys can disappear while
	-- their world instance remains, leaving a Custom prompt with no rendered view.
	local active, owned, serial = {}, {}, 0
	local function blocked()
		return ui:GetAttribute("WB_MenuOpen") == true or ui:GetAttribute("WB_ReturnNoticeActive") == true
	end
	local function register(prompt)
		if prompt:IsA("ProximityPrompt") and prompt.Style == Enum.ProximityPromptStyle.Default
			and prompt:GetAttribute("WB_KeepDefaultUI") ~= true then
			owned[prompt] = true
			prompt.Style = Enum.ProximityPromptStyle.Custom -- Client presentation only.
		end
	end
	for _, object in ipairs(workspace:GetDescendants()) do register(object) end
	workspace.DescendantAdded:Connect(register)

	local function refresh()
		local count = 0
		for _ in pairs(active) do count += 1 end
		Style.Fit(bar, math.min(680, math.max(1, count) * 320), 62)
		bar.Visible = count > 0 and not blocked()
		for prompt, view in pairs(active) do
			view.frame.Size = UDim2.new(1 / math.max(1, count), -8, 1, 0)
			view.frame.FR_Keycap.TL_Key.Text = glyph(prompt, inputMode:GetMode())
			view.frame.TL_Action.Text = prompt.ActionText
			view.object.Text = prompt.ObjectText
		end
	end
	local function hide(prompt)
		local view = active[prompt]
		if not view then return end
		if view.tween then view.tween:Cancel() end
		if view.holding then prompt:InputHoldEnd() end
		for _, connection in ipairs(view.connections) do connection:Disconnect() end
		view.frame:Destroy()
		active[prompt] = nil
		refresh()
	end
	ProximityPromptService.PromptShown:Connect(function(prompt)
		if not owned[prompt] or active[prompt] then return end
		local frame = template:Clone()
		serial += 1
		frame.Name, frame.Visible, frame.ZIndex = "FR_ActivePrompt_" .. serial, true, 45
		frame:SetAttribute("WB_PromptPath", prompt:GetFullName())
		frame.Parent = bar
		Style.Panel(frame)
		frame.FR_Keycap.Position, frame.FR_Keycap.Size = UDim2.fromOffset(10, 12), UDim2.fromOffset(36, 36)
		frame.FR_Keycap.BackgroundColor3 = Style.Theme.Colors.WetStone
		frame.FR_Keycap.TL_Key.TextSize = 12
		frame.TL_Action.Position, frame.TL_Action.Size = UDim2.fromOffset(58, 9), UDim2.new(1, -68, 0, 20)
		frame.TL_Action.Font, frame.TL_Action.TextSize = Style.Theme.Typography.StrongFont, 14
		local object = Style.Text("TL_Object", frame, "", UDim2.fromOffset(58, 28), UDim2.new(1, -68, 0, 30), 11)
		object.TextColor3 = Style.Theme.Colors.Ash
		local fill = Style.New("Frame", "FR_HoldProgress", frame, {
			Position = UDim2.new(0, 0, 1, -3), Size = UDim2.new(0, 0, 0, 3),
			BackgroundColor3 = Style.Theme.Colors.BronzeBright, BorderSizePixel = 0, ZIndex = 46,
		})
		local button = Style.Button(frame)
		local view = { frame = frame, object = object, fill = fill, connections = {} }
		active[prompt] = view
		local function begin(input)
			if blocked() or not prompt.ClickablePrompt then return end
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				view.holding = true
				prompt:InputHoldBegin()
			end
		end
		local function finish(input)
			if view.holding and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
				view.holding = false
				prompt:InputHoldEnd()
			end
		end
		table.insert(view.connections, button.InputBegan:Connect(begin))
		table.insert(view.connections, button.InputEnded:Connect(finish))
		table.insert(view.connections, prompt:GetPropertyChangedSignal("ActionText"):Connect(refresh))
		table.insert(view.connections, prompt:GetPropertyChangedSignal("ObjectText"):Connect(refresh))
		table.insert(view.connections, prompt:GetPropertyChangedSignal("HoldDuration"):Connect(refresh))
		table.insert(view.connections, prompt.Destroying:Connect(function() hide(prompt) end))
		refresh()
	end)
	ProximityPromptService.PromptHidden:Connect(hide)
	workspace.DescendantRemoving:Connect(function(object)
		if owned[object] then hide(object); owned[object] = nil end
	end)
	ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
		local view = active[prompt]
		if not view then return end
		if view.tween then view.tween:Cancel() end
		view.fill.Size = UDim2.new(0, 0, 0, 3)
		view.tween = TweenService:Create(view.fill, TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear), { Size = UDim2.new(1, 0, 0, 3) })
		view.tween:Play()
	end)
	ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt)
		local view = active[prompt]
		if view then
			if view.tween then view.tween:Cancel() end
			view.fill.Size = UDim2.new(0, 0, 0, 3)
		end
	end)
	local previousEnabled
	local function refreshBlocked()
		if blocked() then
			if previousEnabled == nil then previousEnabled = ProximityPromptService.Enabled end
			ProximityPromptService.Enabled = false
			for prompt, view in pairs(active) do if view.holding then view.holding = false; prompt:InputHoldEnd() end end
		elseif previousEnabled ~= nil then
			ProximityPromptService.Enabled = previousEnabled
			previousEnabled = nil
		end
		refresh()
	end
	ui:GetAttributeChangedSignal("WB_MenuOpen"):Connect(refreshBlocked)
	ui:GetAttributeChangedSignal("WB_ReturnNoticeActive"):Connect(refreshBlocked)
	inputMode:ModeChangedSignal():Connect(refresh)
	bar.Visible = false
	refreshBlocked()
	return { Refresh = refresh }
end

return PromptUI
