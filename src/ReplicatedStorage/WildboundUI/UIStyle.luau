local Theme = require(script.Parent.Theme)
local Assets = require(script.Parent.AssetCatalog)
local ArtworkLayers = require(script.Parent.ArtworkLayers)
if Assets.Variant() == "Adventures" then Theme = require(script.Parent.Themes.AdventuresTheme) end
if Assets.Variant() == "Wildbound" then
	Theme = table.clone(Theme)
	Theme.Colors = table.clone(Theme.Colors)
	Theme.Colors.HealthMuted, Theme.Colors.Danger = Color3.fromRGB(163, 84, 78), Color3.fromRGB(163, 84, 78)
	Theme.Colors.StaminaMuted = Color3.fromRGB(110, 124, 80)
end
local Style = { Theme = Theme, Assets = Assets, Artwork = ArtworkLayers }

function Style.New(className, name, parent, properties)
	local object = Instance.new(className)
	object.Name = name
	for key, value in pairs(properties or {}) do object[key] = value end
	object.Parent = parent
	return object
end

function Style.Icon(key, name, parent, position, size)
	local image = parent:FindFirstChild(name) or Style.New("ImageLabel", name, parent)
	image.BackgroundTransparency, image.BorderSizePixel = 1, 0
	image.Position, image.Size = position, size
	image.ZIndex = parent.ZIndex + 1
	Assets.Apply(image, key)
	return image
end

function Style.Text(name, parent, text, position, size, textSize)
	return Style.New("TextLabel", name, parent, {
		BackgroundTransparency = 1, BorderSizePixel = 0, Text = text or "",
		Position = position or UDim2.new(), Size = size or UDim2.fromScale(1, 1),
		Font = Theme.Typography.BodyFont, TextSize = textSize or 14,
		TextColor3 = Theme.Colors.Bone, TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true, RichText = false, ZIndex = parent:IsA("GuiObject") and parent.ZIndex + 1 or 32,
	})
end

function Style.Panel(frame)
	frame.BackgroundColor3 = Theme.Colors.Obsidian
	frame.BackgroundTransparency = 0.34
	frame.BorderSizePixel = 0
	local border = frame:FindFirstChild("US_Border") or Style.New("UIStroke", "US_Border", frame)
	border.Color, border.Thickness, border.Transparency = Theme.Colors.Bronze, 1, 0.28
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local corner = frame:FindFirstChildOfClass("UICorner") or Style.New("UICorner", "UC_Panel", frame)
	corner.CornerRadius = Theme.Radii.Panel
	return frame
end

function Style.OutlinedText(label)
	label.TextStrokeColor3, label.TextStrokeTransparency = Theme.Colors.Obsidian, 0.45
	return label
end

function Style.Open(frame)
	frame.BackgroundTransparency, frame.BorderSizePixel = 1, 0
	for _, object in ipairs(frame:GetDescendants()) do
		if object:IsA("UIStroke") and object.Parent:IsA("GuiObject") then
			object.Transparency = 1
		elseif object:IsA("TextLabel") then Style.OutlinedText(object) end
	end
	return frame
end

function Style.Scene(parent, name, key, transparency)
	local scene = Style.New("ImageLabel", name, parent, {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		ZIndex = parent.ZIndex, Active = false,
	})
	if Assets.ApplyScene(scene, key) then scene.ImageTransparency = transparency or 0.8 end
	Style.New("UIGradient", "UG_Atmosphere", scene, {
		Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.18),
			NumberSequenceKeypoint.new(0.45,0.65),NumberSequenceKeypoint.new(1,1)}),
	})
	return scene
end

function Style.Brand(parent)
	local brand = Style.New("Frame", "FR_Brand", parent, {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 100), ZIndex = parent.ZIndex + 1,
	})
	Style.OutlinedText(Style.Text("TL_WorldOf", brand, "W O R L D  O F", UDim2.fromOffset(0,4), UDim2.new(1,0,0,18), 11)).TextXAlignment = Enum.TextXAlignment.Center
	local title = Style.Text("TL_Tethys", brand, "T E T H Y S", UDim2.fromOffset(0,18), UDim2.new(1,0,0,48), 40)
	title.Font, title.TextXAlignment = Theme.Typography.TitleFont, Enum.TextXAlignment.Center
	Style.OutlinedText(title)
	local sub = Style.Text("TL_Wildbound", brand, Assets.Variant() == "Adventures" and "A D V E N T U R E S" or "W I L D B O U N D", UDim2.fromOffset(0,70), UDim2.new(1,0,0,18), 12)
	sub.TextColor3, sub.TextXAlignment = Theme.Colors.BronzeBright, Enum.TextXAlignment.Center
	if Assets.Variant() == "Wildbound" then
		local logo = ArtworkLayers.Whole(brand, "Masthead", "IL_PlayerMasthead")
		if logo then
			local function fallback()
				for _, name in ipairs({"TL_WorldOf", "TL_Tethys", "TL_Wildbound"}) do brand[name].Visible = not logo.IsLoaded end
			end
			logo:GetPropertyChangedSignal("IsLoaded"):Connect(fallback); fallback()
		end
	end
	return brand
end

function Style.Codex(gui, ui)
	local function decorate(object)
		if object:IsA("TextLabel") or object:IsA("TextButton") then
			object.TextColor3, object.Font = Theme.Colors.Bone, Theme.Typography.BodyFont
			Style.OutlinedText(object)
		elseif object:IsA("UIStroke") then object.Color = Theme.Colors.Bronze end
	end
	for _, object in ipairs(gui:GetDescendants()) do decorate(object) end
	gui.DescendantAdded:Connect(decorate)
	local panel = gui:WaitForChild("Panel")
	panel:WaitForChild("Header").Font = Theme.Typography.TitleFont
	panel.Header.TextSize = 23
	panel.BackgroundTransparency = 0.12
	Style.Scene(panel, "IL_CodexScene", "Archyda", 0.9)
	local toggle = gui:WaitForChild("Toggle")
	Style.Open(toggle)
	local function layout()
		panel.Size = UDim2.new(0.9, 0, 0, math.min(510, math.max(240, ui.AbsoluteSize.Y - 130)))
	end
	ui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	layout()
end

-- Preserve authored Frames and children; add one real button for all input types.
function Style.Button(frame, callback)
	local button = frame:IsA("GuiButton") and frame or frame:FindFirstChild("TB_Activate")
	if not button then
		button = Style.New("TextButton", "TB_Activate", frame, {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = frame.ZIndex + 10,
		})
	end
	if button ~= frame then frame.Selectable = false end
	button.Selectable, button.Active, button.AutoButtonColor = true, true, false
	button.SelectionImageObject = Style.New("ImageLabel", "IL_FocusSelection", button, {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ImageTransparency = 1,
	})
	local stroke = frame:FindFirstChild("US_Focus") or Style.New("UIStroke", "US_Focus", frame)
	stroke.Color, stroke.Thickness, stroke.Transparency = Theme.Colors.BronzeBright, 2, 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local hovered, selected = false, false
	local function refresh() stroke.Transparency = (hovered or selected) and 0 or 1 end
	button.MouseEnter:Connect(function() hovered = true; refresh() end)
	button.MouseLeave:Connect(function() hovered = false; refresh() end)
	button.SelectionGained:Connect(function() selected = true; refresh() end)
	button.SelectionLost:Connect(function() selected = false; refresh() end)
	if callback then button.Activated:Connect(callback) end
	return button
end

function Style.Fit(frame, maxWidth, maxHeight)
	local constraint = frame:FindFirstChild("SZ_Runtime") or Style.New("UISizeConstraint", "SZ_Runtime", frame)
	constraint.MaxSize = Vector2.new(maxWidth, maxHeight)
	return constraint
end

function Style.VerticalNavigation(buttons)
	for index, button in ipairs(buttons) do
		button.NextSelectionUp = buttons[(index - 2) % #buttons + 1]
		button.NextSelectionDown = buttons[index % #buttons + 1]
		button.NextSelectionLeft, button.NextSelectionRight = button, button
	end
end

function Style.Layout(ui, viewport)
	local portrait = viewport.X < 650
	local compact = viewport.X < 900
	-- Scale anchors follow a 1920x1080 canvas; caps keep utility text readable.
	local status = ui.HUD.FR_StatusPanel
	status.Position, status.Size = UDim2.fromScale(0.04, portrait and 0.12 or 0.04), UDim2.new(portrait and 0.58 or compact and 0.28 or 0.2, 0, 0, 0)
	status.SZ_Runtime.MinSize = Vector2.new(0, 0)
	status.FR_Exposure.TL_Label.TextSize = portrait and 11 or 12
	local route = ui.QuestUI.FR_QuestTracker
	route.AnchorPoint = Vector2.new(1, 0)
	route.Size = UDim2.new(portrait and 0.92 or 0.26, 0, 0, route:GetAttribute("WB_ContextHasCount") and 138 or 114)
	route.Position = UDim2.fromScale(0.96, portrait and 0.31 or 0.15)
	local quickbar = ui.InventoryUI.FR_Quickbar
	quickbar.AnchorPoint = Vector2.new(portrait and 0.5 or 0, 1)
	quickbar.Position = UDim2.fromScale(portrait and 0.5 or 0.04, portrait and 0.9 or compact and 0.84 or 0.9)
	quickbar.Size = UDim2.fromScale(portrait and 0.46 or compact and 0.2 or 0.14, 0.25)
	local radialConstraint = Style.Fit(quickbar, 220, 220)
	radialConstraint.MinSize = Vector2.new(154, 154)
	local centers = { Vector2.new(0.5, 0.16), Vector2.new(0.16, 0.5), Vector2.new(0.84, 0.5), Vector2.new(0.5, 0.84) }
	if quickbar:GetAttribute("WB_QuickArtworkLoaded") == true then
		centers = {Vector2.new(0.5,0.18), Vector2.new(0.17,0.74), Vector2.new(0.84,0.74), Vector2.new(0.5,0.61)}
	end
	local slots = {}
	for _, slot in ipairs(quickbar:GetChildren()) do
		if slot:IsA("Frame") and slot.Name:match("^FR_Slot_") then table.insert(slots, slot) end
	end
	table.sort(slots, function(a, b) return a.Name < b.Name end)
	for index, slot in ipairs(slots) do
		if centers[index] then
			slot.AnchorPoint, slot.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.3, 0.3)
			slot.Position = UDim2.fromScale(centers[index].X, centers[index].Y)
		else slot.Visible = false end
	end
	local prompt = ui.InteractionUI.FR_PromptBar
	prompt.Position = UDim2.fromScale(0.5, portrait and 0.65 or 0.91)
	prompt.Size = UDim2.new(portrait and 0.92 or compact and 0.44 or 0.5, 0, 0, 62)
	local subtitle = ui.InteractionUI:FindFirstChild("FR_Subtitle")
	if subtitle then
		subtitle.Position = UDim2.fromScale(0.5, portrait and 0.54 or compact and 0.75 or 0.81)
			subtitle.Size = UDim2.new(portrait and 0.92 or compact and 0.5 or 0.55, 0, 0, 96)
	end
	local stack = ui.Notifications.SF_ToastStack
	stack.Position = UDim2.fromScale(0.96, portrait and 0.31 or 0.15)
	stack.Size = UDim2.new(portrait and 0.92 or 0.26, 0, 0, 242)
	local compass = ui.MapUI:FindFirstChild("FR_Compass")
	if compass then
		compass.Size = UDim2.new(portrait and 0.72 or compact and 0.28 or 0.3, 0, 0, 48)
		Style.Fit(compass, 380, 48)
		compass.AnchorPoint, compass.Position = Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.04)
	end
	local map = ui.MapUI.FR_Minimap
	map.AnchorPoint = Vector2.new(1, portrait and 0 or 1)
	map.Position = UDim2.fromScale(0.96, portrait and 0.12 or compact and 0.81 or 0.87)
	map.Size = UDim2.fromScale(portrait and 0.3 or compact and 0.18 or 0.14, 0.25)
	local mapConstraint = Style.Fit(map, 200, 200)
	mapConstraint.MinSize = Vector2.new(128, 128)
	local aspect = map:FindFirstChild("AR_LocalMap") or Style.New("UIAspectRatioConstraint", "AR_LocalMap", map)
	aspect.AspectRatio, aspect.DominantAxis = 1, Enum.DominantAxis.Width
	local time = ui.MapUI:FindFirstChild("TL_TimeIndicator")
	if time then
		time.AnchorPoint = Vector2.new(1, 0)
		time.Position = UDim2.new(0.96, 0, portrait and 0.12 or compact and 0.82 or 0.88, portrait and 132 or 0)
		time.Size = UDim2.new(0.2, 0, 0, 20)
	end
	local toggle = ui.Menus:FindFirstChild("TB_MenuToggle")
	if toggle then toggle.Position = UDim2.fromScale(0.04, 0.97) end
	local banner = ui.LocationUI.FR_LocationBanner
	local narrow = viewport.X < 900
	local artwork = banner:FindFirstChild("IL_LocationArtwork")
	if artwork and artwork:GetAttribute("UI_LocationId") and artwork.IsLoaded then
		local aspect = 1672 / 941
		local width = math.min(680, viewport.X * (portrait and 0.9 or 0.5), viewport.Y * (portrait and 0.22 or 0.32) * aspect)
		local height = math.floor(width / aspect)
		banner.AnchorPoint, banner.Position = Vector2.new(0.5, 0), UDim2.fromScale(0.5, portrait and 0.34 or 0.14)
		banner.Size = UDim2.fromOffset(math.floor(width), height)
		Style.Fit(banner, 680, 383)
		artwork.Position, artwork.Size = UDim2.fromScale(0,0), UDim2.fromScale(1,1)
		banner.IL_RegionBadge.Visible, banner.IL_SceneAccent.Visible, banner.TL_Kicker.Visible = false, false, false
		local titleY = math.floor(height * 0.5)
		banner.TL_LocationName.Position, banner.TL_LocationName.Size = UDim2.fromOffset(18, titleY), UDim2.new(1,-36,0,34)
		banner.TL_LocationName.TextSize = narrow and 22 or 30
		banner.TL_Subtitle.Position, banner.TL_Subtitle.Size = UDim2.fromOffset(18, titleY + 40), UDim2.new(1,-36,0,24)
		banner.TL_Subtitle.TextSize = narrow and 14 or 16
		return
	end
	banner.AnchorPoint = Vector2.new(0.5, 0)
	local height = narrow and 70 or 88
	banner.Position = UDim2.fromScale(0.5, portrait and 0.28 or narrow and 0.30 or 0.12)
	banner.Size = UDim2.new(portrait and 0.88 or narrow and 0.58 or 0.43, 0, 0, height)
	Style.Fit(banner, 560, height)
	local badge = banner:FindFirstChild("IL_RegionBadge")
	local badgeSize = narrow and 44 or 62
	if badge then badge.Position, badge.Size = UDim2.fromOffset(10, 12), UDim2.fromOffset(badgeSize, badgeSize) end
	local scene = banner:FindFirstChild("IL_SceneAccent")
	local hasScene = scene and scene:GetAttribute("UI_SceneKey") ~= nil and not narrow and ui:GetAttribute("WB_RevealSceneAccents") == true
	if scene then
		scene.Visible = hasScene == true
		scene.Position, scene.Size = UDim2.new(1, -150, 0, 1), UDim2.new(0, 149, 1, -2)
	end
	local inset, right = narrow and 66 or 86, hasScene and 152 or 12
	banner.TL_Kicker.Visible = false
	banner.TL_LocationName.Position = UDim2.fromOffset(inset, narrow and 10 or 13)
	banner.TL_LocationName.Size = UDim2.new(1, -inset - right, 0, 30)
	banner.TL_LocationName.TextSize = portrait and 22 or narrow and 24 or 30
	banner.TL_Subtitle.Position = UDim2.fromOffset(inset, narrow and 43 or 50)
	banner.TL_Subtitle.Size = UDim2.new(1, -inset - right, 0, 24)
	banner.TL_Subtitle.TextSize = narrow and 14 or 16
end

function Style.Apply(ui)
	ui.ResetOnSpawn = false
	ui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	ui.DisplayOrder = 30
	ui:SetAttribute("WB_LayoutReference", "1920x1080")
	for _, object in ipairs(ui:GetDescendants()) do
		if object:IsA("TextLabel") or object:IsA("TextButton") then
			object.TextColor3 = Theme.Colors.Bone
			object.TextStrokeTransparency = 1
			object.Font = Theme.Typography.BodyFont
			object.TextSize = 14
			object.RichText = false
		elseif object:IsA("ImageLabel") then
			-- Existing decoration uses placeholder Roblox widgets, not authored artwork.
			if object.Image == "" or object.Image:find("rbxasset://textures/ui/", 1, true) then object.Visible = false end
		elseif object:IsA("UIStroke") then
			object.Color = Theme.Colors.Bronze
			object.Transparency = object.Name == "US_XboxFocus" and 1 or 0.28
		end
	end

	local status = ui.HUD.FR_StatusPanel
	status.Position, status.Size = UDim2.fromScale(0.02, 0.03), UDim2.new(0.23, 0, 0, 172)
	Style.Fit(status, 272, 172)
	Style.Open(status)
	Style.New("UIPadding", "UP_Runtime", status, {
		PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
	})
	status.AutomaticSize = Enum.AutomaticSize.Y
	status.Size = UDim2.new(0.23, 0, 0, 0)
	status.UL_Rows.SortOrder = Enum.SortOrder.LayoutOrder
	status.UL_Rows.Padding = UDim.new(0, 8)
	for index, name in ipairs({ "Health", "Stamina", "Thirst", "Exposure" }) do
		local row = status["FR_" .. name]
		row.Size, row.LayoutOrder, row.Selectable = UDim2.new(1, 0, 0, 30), index, false
		local key = name == "Exposure" and "WaterExposure" or name
		Style.Icon(key, "IL_StatusGlyph", row, UDim2.fromOffset(0, 1), UDim2.fromOffset(28, 28))
		row.TL_Label.Position, row.TL_Label.Size = UDim2.fromOffset(34, 0), UDim2.new(0.65, -34, 0, 18)
		row.TL_Label.TextSize, row.TL_Label.TextTransparency = 12, 0
		row.TL_Value.Position, row.TL_Value.Size = UDim2.fromScale(0.65, 0), UDim2.new(0.35, 0, 0, 18)
		row.TL_Value.TextSize, row.TL_Value.TextTransparency = 14, 0
		row.TL_Value.TextXAlignment = Enum.TextXAlignment.Right
		row.TL_Value.Visible = false
		row.FR_BarBack.Position, row.FR_BarBack.Size = UDim2.fromOffset(34, 21), UDim2.new(1, -34, 0, 7)
		row.FR_BarBack.BackgroundColor3, row.FR_BarBack.BackgroundTransparency = Theme.Colors.WetStone, 0.25
	end
	status.FR_Thirst.TL_Label.Text = "HYDRATION"
	status.FR_Exposure.TL_Label.Text = "WATER EXPOSURE"
	status.FR_Health.FR_BarBack.FR_BarFill.BackgroundColor3 = Theme.Colors.HealthMuted
	status.FR_Stamina.FR_BarBack.FR_BarFill.BackgroundColor3 = Theme.Colors.StaminaMuted
	status.FR_Thirst.FR_BarBack.FR_BarFill.BackgroundColor3 = Theme.Colors.MistTeal
	status.FR_Exposure.FR_BarBack.FR_BarFill.BackgroundColor3 = Theme.Colors.Amber
	if Assets.Variant() == "Wildbound" then
		for _, name in ipairs({"Health", "Thirst", "Exposure"}) do ArtworkLayers.Meter(status["FR_" .. name], name) end
	end

	local route = ui.QuestUI.FR_QuestTracker
	route.AnchorPoint, route.Position, route.Size = Vector2.new(0, 1), UDim2.fromScale(0.02, 0.88), UDim2.new(0.29, 0, 0, 138)
	Style.Fit(route, 340, 138)
	Style.Open(route)
	route.FR_Optional.Visible = false
	route.TL_QuestType.Text, route.TL_QuestType.TextSize = "CONTEXT", 10
	route.TL_QuestType.Position, route.TL_QuestType.Size = UDim2.fromOffset(14, 10), UDim2.new(1, -28, 0, 16)
	route.TL_QuestType.TextColor3 = Theme.Colors.BronzeBright
	route.TL_Title.Position, route.TL_Title.Size = UDim2.fromOffset(14, 29), UDim2.new(1, -28, 0, 24)
	route.TL_Title.Font, route.TL_Title.TextSize = Theme.Typography.TitleFont, 23
	Style.New("Frame", "FR_ContextDivider", route, { Position = UDim2.new(0, 14, 0, 57), Size = UDim2.new(1, -28, 0, 1), BackgroundColor3 = Theme.Colors.Bronze, BackgroundTransparency = 0.28, BorderSizePixel = 0 })
	route.FR_Objectives.Position, route.FR_Objectives.Size = UDim2.fromOffset(14, 61), UDim2.new(1, -28, 0, 66)
	local objective = route.FR_Objectives.FR_ObjectiveTemplate
	objective.Size = UDim2.fromScale(1, 1)
	objective.TL_Text.Position, objective.TL_Text.Size = UDim2.new(), UDim2.new(1, 0, 0, 44)
	objective.TL_Text.TextSize, objective.TL_Text.TextYAlignment = 13, Enum.TextYAlignment.Top
	objective.TL_Text.TextWrapped = true
	objective.TL_Count.Position, objective.TL_Count.Size = UDim2.new(0, 0, 1, -16), UDim2.new(1, 0, 0, 16)
	objective.TL_Count.TextColor3 = Theme.Colors.Ash

	local stack = ui.Notifications.SF_ToastStack
	stack.Position, stack.Size = UDim2.fromScale(0.98, 0.03), UDim2.new(0.3, 0, 0, 242)
	stack.AnchorPoint, stack.AutomaticCanvasSize = Vector2.new(1, 0), Enum.AutomaticSize.Y
	stack.CanvasSize, stack.ScrollBarThickness, stack.BackgroundTransparency = UDim2.new(), 0, 1
	Style.Fit(stack, 350, 242)
	for _, toast in ipairs(stack:GetChildren()) do
		if toast:IsA("Frame") then
			Style.Open(toast)
			toast.Visible, toast.Size = false, UDim2.new(1, -4, 0, 72)
			toast.TL_Title.Position, toast.TL_Title.Size = UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 20)
			toast.TL_Title.Font, toast.TL_Title.TextSize = Theme.Typography.TitleFont, 18
			toast.TL_Message.Position, toast.TL_Message.Size = UDim2.fromOffset(12, 31), UDim2.new(1, -24, 0, 33)
			toast.TL_Message.TextSize, toast.TL_Message.TextYAlignment = 12, Enum.TextYAlignment.Top
		end
	end

	local banner = ui.LocationUI.FR_LocationBanner
	Style.Open(banner)
	Style.Icon("SkyCity", "IL_RegionBadge", banner, UDim2.fromOffset(12, 10), UDim2.fromOffset(72, 72))
	banner.Position, banner.Size = UDim2.fromScale(0.5, 0.12), UDim2.new(0.6, 0, 0, 94)
	Style.Fit(banner, 560, 88)
	local scene = Style.New("ImageLabel", "IL_SceneAccent", banner, {
		BackgroundTransparency = 1, ImageTransparency = 0.55, Visible = false, ZIndex = banner.ZIndex + 1,
	})
	Style.New("UIGradient", "UG_SceneEdge", scene, {
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(0.32,0.7), NumberSequenceKeypoint.new(1,0.22)}),
	})
	local artwork = Style.New("ImageLabel", "IL_LocationArtwork", banner, {
		BackgroundTransparency = 1, BorderSizePixel = 0, ImageTransparency = 0.28,
		Size = UDim2.fromScale(1,1), Visible = false, ZIndex = banner.ZIndex,
	})
	Style.New("UIGradient", "UG_SoftEdges", artwork, {
		Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),
			NumberSequenceKeypoint.new(0.12,0.08), NumberSequenceKeypoint.new(0.78,0.08), NumberSequenceKeypoint.new(1,1)}),
	})
	artwork:GetPropertyChangedSignal("IsLoaded"):Connect(function() Style.Layout(ui, ui.AbsoluteSize) end)
	banner.TL_LocationName.ZIndex, banner.TL_Subtitle.ZIndex = banner.ZIndex + 2, banner.ZIndex + 2
	banner.TL_LocationName.Font, banner.TL_LocationName.TextSize = Theme.Typography.TitleFont, 32
	banner.TL_Kicker.TextSize, banner.TL_Subtitle.TextSize = 10, 12
	ui.LoadingUI.FR_LoadingScreen.Visible = false
	ui.MapUI.FR_Minimap.Visible = false -- No authored map is connected yet.
	local templates = ui.Shared:FindFirstChild("Templates")
	if templates then
		for _, template in ipairs(templates:GetChildren()) do if template:IsA("GuiObject") then template.Visible = false end end
	end
end

return Style
