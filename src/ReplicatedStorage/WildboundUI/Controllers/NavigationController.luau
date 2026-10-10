local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Style = require(script.Parent.Parent.UIStyle)
local Data = require(script.Parent.Parent.NavigationData)
local Navigation = {}

function Navigation.new(player, ui)
	local compass = Style.New("Frame", "FR_Compass", ui.MapUI, { BackgroundTransparency = 1, ZIndex = 32 })
	Style.New("Frame", "FR_Line", compass, {
		Position = UDim2.fromScale(0, 0.48), Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Style.Theme.Colors.Bronze, BackgroundTransparency = 0.28, BorderSizePixel = 0, ZIndex = 32,
	})
	local heading = Style.Text("TL_Heading", compass, "N", UDim2.fromScale(0.4, 0), UDim2.fromScale(0.2, 0.45), 14)
	heading.TextXAlignment = Enum.TextXAlignment.Center
	local labels = {}
	for index, name in ipairs({ "N", "E", "S", "W" }) do
		local label = Style.Text("TL_" .. name, compass, name, UDim2.new(), UDim2.fromOffset(22, 18), 12)
		label.AnchorPoint = Vector2.new(0.5, 0)
		label.Font, label.TextColor3 = Style.Theme.Typography.TitleFont, Style.Theme.Colors.Bone
		label.TextXAlignment = Enum.TextXAlignment.Center
		labels[index] = label
	end
	local marker = Style.Text("TL_LandmarkMarker", compass, "△", UDim2.new(), UDim2.fromOffset(20, 18), 16)
	marker.AnchorPoint, marker.TextXAlignment = Vector2.new(0.5, 0), Enum.TextXAlignment.Center
	marker.TextColor3, marker.Visible = Style.Theme.Colors.BronzeBright, false
	local landmark = Style.Text("TL_Landmark", compass, "", UDim2.fromScale(0, 0.6), UDim2.fromScale(1, 0.4), 12)
	landmark.TextXAlignment, landmark.TextTruncate = Enum.TextXAlignment.Center, Enum.TextTruncate.AtEnd
	landmark.Font = Style.Theme.Typography.TitleFont

	local map = ui.MapUI.FR_Minimap
	for _, child in ipairs(map:GetChildren()) do if child:IsA("GuiObject") then child.Visible = false end end
	map.BackgroundColor3, map.BackgroundTransparency, map.BorderSizePixel = Style.Theme.Colors.Basalt, 0.38, 0
	local circle = map:FindFirstChildOfClass("UICorner") or Style.New("UICorner", "UC_LocalMap", map)
	circle.CornerRadius = UDim.new(0.5, 0)
	local border = map:FindFirstChildOfClass("UIStroke") or Style.New("UIStroke", "US_LocalMap", map)
	border.Color, border.Thickness, border.Transparency = Style.Theme.Colors.Bronze, 1, 0.28
	map:SetAttribute("WB_MapKind", "LearnedWaterSketch")
	Style.Text("TL_SketchTitle", map, "WATER SKETCH", UDim2.fromScale(0.1, 0.04), UDim2.fromScale(0.8, 0.1), 10).TextXAlignment = Enum.TextXAlignment.Center
	local nodes, lines = {}, {}
	for index, stage in ipairs(Data.Stages) do
		local node = Style.New("Frame", "FR_Known_" .. stage.Id, map, {
			Position = UDim2.fromScale(stage.Sketch.X, stage.Sketch.Y), AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(5, 5), BackgroundColor3 = Style.Theme.Colors.Bone, BorderSizePixel = 0, ZIndex = 34,
		})
		Style.New("UICorner", "UC_Mark", node, { CornerRadius = UDim.new(0.5, 0) })
		local label = Style.Text("TL_Label", node, stage.Short, UDim2.fromOffset(7, -5), UDim2.fromOffset(51, 14), 10)
		if stage.Sketch.X > 0.5 then label.Position = UDim2.fromOffset(-58, -5); label.TextXAlignment = Enum.TextXAlignment.Right end
		label.TextWrapped = false
		nodes[index] = node
		if index > 1 then
			lines[index] = Style.New("Frame", "FR_KnownFlow_" .. index, map, {
				AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Style.Theme.Colors.WaterPale,
				BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 33,
			})
		end
	end
	local time
	local function draw()
		local count = Data.KnownCount(player)
		local clear = ui:GetAttribute("WB_IntroActive") ~= true and ui:GetAttribute("WB_MenuOpen") ~= true and not ui.LocationUI.FR_LocationBanner.Visible
			and ui:GetAttribute("WB_PresentationProfile") ~= "Game1"
		compass.Visible = clear
		map.Visible = count > 0 and clear
		if time then time.Visible = clear end
		for index, node in ipairs(nodes) do
			node.Visible = index <= count
			local line = lines[index]
			if line then
				line.Visible = index <= count
				local a, b = Data.Stages[index - 1].Sketch, Data.Stages[index].Sketch
				local delta = Vector2.new((b.X - a.X) * map.AbsoluteSize.X, (b.Y - a.Y) * map.AbsoluteSize.Y)
				line.Position = UDim2.fromScale((a.X + b.X) / 2, (a.Y + b.Y) / 2)
				line.Size, line.Rotation = UDim2.fromOffset(delta.Magnitude, 1), math.deg(math.atan2(delta.Y, delta.X))
			end
		end
	end
	player:GetAttributeChangedSignal("WT_WaterStageIndex"):Connect(draw)
	map:GetPropertyChangedSignal("AbsoluteSize"):Connect(draw)
	ui:GetAttributeChangedSignal("WB_MenuOpen"):Connect(draw)
	ui:GetAttributeChangedSignal("WB_IntroActive"):Connect(draw)
	ui:GetAttributeChangedSignal("WB_PresentationProfile"):Connect(draw)
	ui.LocationUI.FR_LocationBanner:GetPropertyChangedSignal("Visible"):Connect(draw)
	draw()
	time = Style.Text("TL_TimeIndicator", ui.MapUI, "", UDim2.new(), UDim2.fromOffset(140, 20), 10)
	time.TextXAlignment, time.TextColor3 = Enum.TextXAlignment.Right, Style.Theme.Colors.Bone
	local function updateTime()
		local hour = Lighting.ClockTime
		time.Text = hour >= 5 and hour < 8 and "DAWN" or hour >= 8 and hour < 17 and "DAY" or hour >= 17 and hour < 20 and "DUSK" or "NIGHT"
	end
	Lighting:GetPropertyChangedSignal("ClockTime"):Connect(updateTime)
	updateTime()
	draw()
	local elapsed = 0
	RunService.RenderStepped:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.15 then return end
		elapsed = 0
		local camera = workspace.CurrentCamera
		if not camera then marker.Visible = false; return end
		local look = camera.CFrame.LookVector
		local degrees = (math.deg(math.atan2(look.X, -look.Z)) + 360) % 360
		local names = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }
		heading.Text = names[math.floor((degrees + 22.5) / 45) % 8 + 1]
		for index, label in ipairs(labels) do
			local delta = Data.Delta((index - 1) * 90, degrees)
			label.Visible = math.abs(delta) <= 80 and math.abs(delta) > 12
			label.Position = UDim2.fromScale(0.5 + delta / 180, 0)
		end
		local stage = Data.Stages[Data.KnownCount(player)]
		landmark.Text = stage and stage.Label or ""
		local position = stage and Data.Anchor(stage)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		marker.Visible = false
		if root and position then
			local offset = position - root.Position
			if Vector2.new(offset.X, offset.Z).Magnitude > 1 then
				local bearing = (math.deg(math.atan2(offset.X, -offset.Z)) + 360) % 360
				local delta = Data.Delta(bearing, degrees)
				marker.Visible = math.abs(delta) <= 80
				marker.Position = UDim2.fromScale(0.5 + delta / 180, 0.21)
			end
		end
	end)
	return { Refresh = draw }
end

return Navigation
