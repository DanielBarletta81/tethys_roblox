local TweenService = game:GetService("TweenService")
local Style = require(script.Parent.Parent.UIStyle)
local Data = require(script.Parent.Parent.RuntimeData)
local Effects = require(script.Parent.Parent.UIEffects)
local HUD = {}

function HUD.new(player, ui)
	local status = ui.HUD.FR_StatusPanel
	local tweens, healthConnections = {}, {}
	local function setRow(row, ratio, text, dangerous)
		row.Visible = ratio ~= nil
		if not ratio then return end
		local fill = row.FR_BarBack.FR_BarFill
		if tweens[row] then tweens[row]:Cancel() end
		tweens[row] = TweenService:Create(fill, TweenInfo.new(Effects.Reduced(ui) and 0 or 0.15), { Size = UDim2.fromScale(ratio, 1) })
		tweens[row]:Play()
		row.TL_Value.Text = text or string.format("%d%%", math.floor(ratio * 100 + 0.5))
		row.TL_Value.TextColor3 = dangerous and Style.Theme.Colors.Amber or Style.Theme.Colors.Bone
		row.TL_Value.Visible = ui:GetAttribute("WB_NumericVitals") == true
	end
	local condition = Style.New("Frame", "FR_ConditionCue", status, {
		Size = UDim2.new(1,0,0,26), BackgroundTransparency = 1, Visible = false, LayoutOrder = 5,
	})
	Style.Icon("Injury", "IL_ConditionGlyph", condition, UDim2.fromOffset(0,1), UDim2.fromOffset(24,24))
	local conditionText = Style.Text("TL_Condition", condition, "INJURED", UDim2.fromOffset(34,3), UDim2.new(1,-34,0,20), 11)
	conditionText.TextColor3 = Style.Theme.Colors.Amber
	local function updateCondition() condition.Visible = player:GetAttribute("WB_OpeningInjured") == true end
	player:GetAttributeChangedSignal("WB_OpeningInjured"):Connect(updateCondition)
	updateCondition()
	local function updateVitals()
		status.Visible = ui:GetAttribute("WB_IntroActive") ~= true
		local state = Data.Vitals(player)
		setRow(status.FR_Stamina, state.Stamina, nil, state.Stamina and state.Stamina < 0.25)
		setRow(status.FR_Thirst, state.Hydration, nil, state.Hydration and state.Hydration < 0.35)
		setRow(status.FR_Exposure, state.Exposure and state.Exposure > 0.01 and state.Exposure or nil, nil, state.Exposure and state.Exposure > 0.25)
		if ui:GetAttribute("WB_PresentationProfile") == "Game1" then
			status.FR_Stamina.Visible, status.FR_Exposure.Visible = false, false
		end
	end
	local function bindCharacter(character)
		for _, connection in ipairs(healthConnections) do connection:Disconnect() end
		table.clear(healthConnections)
		setRow(status.FR_Health, nil)
		local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
		if not humanoid or player.Character ~= character then return end
		local function update()
			local ratio = humanoid.MaxHealth > 0 and math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1) or 0
			setRow(status.FR_Health, ratio, string.format("%d / %d", math.floor(humanoid.Health + 0.5), math.floor(humanoid.MaxHealth + 0.5)), ratio < 0.3)
		end
		table.insert(healthConnections, humanoid.HealthChanged:Connect(update))
		table.insert(healthConnections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update))
		update()
	end
	local route = ui.QuestUI.FR_QuestTracker
	local function updateRoute()
		local title, text, count = Data.Route(player)
		local subtitle = ui.InteractionUI.FR_Subtitle
		local prompt = ui.InteractionUI.FR_PromptBar
		local hasNotice = false
		for _, toast in ipairs(ui.Notifications.SF_ToastStack:GetChildren()) do
			if toast:IsA("GuiObject") and toast.Visible and toast.Name:match("^FR_ToastRuntime_") then hasNotice = true; break end
		end
		local spaceAvailable = ui:GetAttribute("WB_TransientBusy") ~= true and not subtitle.Visible and not hasNotice and not ui.LocationUI.FR_LocationBanner.Visible
			and ui:GetAttribute("WB_MenuOpen") ~= true and (ui.AbsoluteSize.X >= 900 or not prompt.Visible)
		route.Visible = title ~= nil and spaceAvailable and ui:GetAttribute("WB_IntroActive") ~= true and ui:GetAttribute("WB_RouteHintsEnabled") ~= false
			and ui:GetAttribute("WB_PresentationProfile") ~= "Game1"
		if not title then return end
		route.TL_Title.Text = title
		route:SetAttribute("WB_ContextHasCount", count ~= nil and count ~= "")
		route.Size = UDim2.new(route.Size.X.Scale, route.Size.X.Offset, 0, route:GetAttribute("WB_ContextHasCount") and 138 or 114)
		local objective = route.FR_Objectives.FR_ObjectiveTemplate
		objective.TL_Text.Text, objective.TL_Count.Text = tostring(text or ""), count or ""
	end
	for _, attribute in ipairs({ "OL_Stamina", "OL_Hydration", "OL_PrettyWaterExposure" }) do player:GetAttributeChangedSignal(attribute):Connect(updateVitals) end
	for _, attribute in ipairs({ "IL_Active", "IL_Title", "IL_Message", "IL_Step", "IL_RouteCount", "HW_Status", "HW_Message", "HW_Step", "HW_TotalSteps",
		"OL_ObjectiveTrack", "OL_ObjectiveStep", "OL_ObjectiveDone", "WOT_NextPull", "WT_WaterStage", "WT_WaterStageLabel", "WT_WaterObjective", "WT_WaterStageIndex", "WT_WaterChainComplete", "SC_OnboardingStage", "HW_Complete", "WB_Chapter" }) do
		player:GetAttributeChangedSignal(attribute):Connect(updateRoute)
	end
	ui:GetAttributeChangedSignal("WB_RouteHintsEnabled"):Connect(updateRoute)
	ui:GetAttributeChangedSignal("WB_MenuOpen"):Connect(updateRoute)
	ui:GetAttributeChangedSignal("WB_TransientBusy"):Connect(updateRoute)
	ui:GetAttributeChangedSignal("WB_PresentationProfile"):Connect(function() updateVitals(); updateRoute() end)
	ui:GetAttributeChangedSignal("WB_IntroActive"):Connect(function() updateVitals(); updateRoute() end)
	ui:GetAttributeChangedSignal("WB_NumericVitals"):Connect(function()
		for _, name in ipairs({ "Health", "Stamina", "Thirst", "Exposure" }) do status["FR_" .. name].TL_Value.Visible = ui:GetAttribute("WB_NumericVitals") == true end
	end)
	ui.Notifications.SF_ToastStack.ChildAdded:Connect(updateRoute)
	ui.Notifications.SF_ToastStack.ChildRemoved:Connect(updateRoute)
	ui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateRoute)
	ui.InteractionUI.FR_Subtitle:GetPropertyChangedSignal("Visible"):Connect(updateRoute)
	ui.InteractionUI.FR_PromptBar:GetPropertyChangedSignal("Visible"):Connect(updateRoute)
	ui.LocationUI.FR_LocationBanner:GetPropertyChangedSignal("Visible"):Connect(updateRoute)
	player.CharacterAdded:Connect(bindCharacter)
	if player.Character then task.spawn(bindCharacter, player.Character) end
	updateVitals()
	updateRoute()
	return { Refresh = function() updateVitals(); updateRoute() end }
end

return HUD
