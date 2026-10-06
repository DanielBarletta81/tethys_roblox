local Config = require(script.Parent.Config)
local Heightfield = require(script.Parent.Heightfield)
local Voxelizer = require(script.Parent.Voxelizer)
local Selection = game:GetService("Selection")
local Panel = {}
local colors = { Background = Color3.fromRGB(24, 30, 32), Panel = Color3.fromRGB(37, 46, 48),
	Text = Color3.fromRGB(227, 216, 192), Muted = Color3.fromRGB(172, 180, 176), Brass = Color3.fromRGB(191, 146, 83),
	Grass = Color3.fromRGB(83, 110, 70), Rock = Color3.fromRGB(111, 116, 113), Mud = Color3.fromRGB(119, 94, 67),
	Sand = Color3.fromRGB(191, 174, 118), Snow = Color3.fromRGB(215, 224, 222), Water = Color3.fromRGB(47, 119, 141) }

local function make(class, props, parent)
	local instance = Instance.new(class)
	for key, value in pairs(props) do instance[key] = value end
	instance.Parent = parent
	return instance
end

function Panel.mount(widget, session, backend)
	local connections, boxes, map = {}, {}, nil
	local busy, dead = false, false
	local function connect(signal, callback) table.insert(connections, signal:Connect(callback)) end
	local scroll = make("ScrollingFrame", { Name = "TerrainPanel", Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = colors.Background, BorderSizePixel = 0, ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, widget)
	make("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 14) }, scroll)
	make("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
	local order = 0
	local function row(height)
		order += 1
		return make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height), LayoutOrder = order }, scroll)
	end
	local function text(parent, value, size, color)
		return make("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = value,
			TextColor3 = color or colors.Text, Font = Enum.Font.Gotham, TextSize = size or 13,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true }, parent)
	end
	text(row(28), "TETHYS  /  TERRAIN", 20, colors.Brass)
	text(row(38), "Shape a small landscape. Preview first, then apply to an empty patch.", 13, colors.Muted)
	local status = text(row(56), "Preview makes no world changes. Dimensions and origins use a 4-stud grid.", 12, colors.Muted)
	status.Name = "Status"
	local function message(value, failure)
		status.Text = value
		status.TextColor3 = if failure then Color3.fromRGB(241, 153, 124) else colors.Muted
	end
	local function invalidate()
		map = nil
		message("Settings changed. Generate a fresh preview before applying.")
	end
	local function button(parent, label, name)
		return make("TextButton", { Name = name or label, Text = label, Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = colors.Panel, BorderSizePixel = 0, TextColor3 = colors.Text,
			Font = Enum.Font.GothamMedium, TextSize = 13, AutoButtonColor = true }, parent)
	end
	local preset = "RiverValley"
	local presetButton = button(row(32), "Preset: River valley", "Preset")
	connect(presetButton.Activated, function()
		if busy then return end
		preset = Config.Presets[table.find(Config.Presets, preset) % #Config.Presets + 1]
		presetButton.Text = "Preset: " .. preset
		invalidate()
	end)
	local labels = { Seed = "Seed", Width = "Width (studs)", Length = "Length (studs)", Height = "Box height (studs)",
		OriginX = "West edge X", OriginZ = "North edge Z", FloorY = "Bottom Y", Relief = "Relief (studs)",
		Scale = "Feature scale", Erosion = "Thermal passes (0–32)", RiverWidth = "River width (studs)" }
	for _, key in ipairs({ "Seed", "Width", "Length", "Height", "OriginX", "OriginZ", "FloorY", "Relief", "Scale", "Erosion", "RiverWidth" }) do
		local parent = row(29)
		local label = text(parent, labels[key], 12)
		label.Size = UDim2.new(0.58, -6, 1, 0)
		local box = make("TextBox", { Name = key, Position = UDim2.fromScale(0.58, 0), Size = UDim2.fromScale(0.42, 1),
			Text = tostring(Config.Defaults[key]), ClearTextOnFocus = false, TextColor3 = colors.Text,
			BackgroundColor3 = colors.Panel, BorderSizePixel = 0, Font = Enum.Font.Gotham, TextSize = 13 }, parent)
		boxes[key] = box
		connect(box:GetPropertyChangedSignal("Text"), invalidate)
	end
	local water = true
	local waterButton = button(row(30), "Water: on", "Water")
	connect(waterButton.Activated, function()
		if busy then return end
		water = not water; waterButton.Text = "Water: " .. (if water then "on" else "off"); invalidate()
	end)
	local selected = button(row(32), "Use selected box bounds", "UseSelection")
	connect(selected.Activated, function()
		if busy then return end
		local ok, err = pcall(function()
			local selection = Selection:Get()
			assert(#selection == 1 and selection[1]:IsA("BasePart"), "Select one axis-aligned bounds guide Part")
			local part = selection[1]
			assert((part.CFrame.RightVector - Vector3.xAxis).Magnitude < 0.0001 and
				(part.CFrame.UpVector - Vector3.yAxis).Magnitude < 0.0001, "Bounds guide must have zero rotation")
			local low = part.Position - part.Size / 2
			local input = { Width = part.Size.X, Length = part.Size.Z, Height = part.Size.Y,
				OriginX = low.X, FloorY = low.Y, OriginZ = low.Z,
				Relief = math.min(tonumber(boxes.Relief.Text) or 56, part.Size.Y - 16),
				RiverWidth = math.min(tonumber(boxes.RiverWidth.Text) or 16, part.Size.X / 2) }
			Config.normalize(input)
			for key, value in pairs(input) do boxes[key].Text = tostring(value) end
			backend.IgnorePart = part
		end)
		if not ok then message(tostring(err), true) end
	end)
	local previewButton = button(row(34), "PREVIEW LANDSCAPE", "Preview")
	local previewRow = row(244)
	local preview = make("Frame", { Name = "HeightPreview", BackgroundColor3 = colors.Panel,
		Size = UDim2.fromOffset(240, 240), Position = UDim2.fromScale(0.5, 0), AnchorPoint = Vector2.new(0.5, 0), BorderSizePixel = 0 }, previewRow)
	text(row(34), "Plan view · north at top · blue is water. Rock follows slope; riverbeds use mud.", 11, colors.Muted)
	local applyButton = button(row(34), "APPLY PREVIEW TO EMPTY PATCH", "Apply")
	local clearButton = button(row(32), "Clear latest unchanged pass", "Clear")
	text(row(50), "Apply and Clear each create one Studio Undo step. Sculpted patches are protected. Earlier passes remain editable Terrain.", 11, colors.Muted)
	local function action(callback)
		if busy or dead then return end
		busy = true
		local ok, result = pcall(callback)
		busy = false
		if not ok then message(tostring(result), true) end
	end
	connect(previewButton.Activated, function() action(function()
		local settings = { Preset = preset, Water = water }
		for key, box in pairs(boxes) do
			settings[key] = tonumber(box.Text)
			assert(settings[key], labels[key] .. " must be a number")
		end
		local start = os.clock()
		local fresh = Heightfield.generate(settings)
		for _, child in ipairs(preview:GetChildren()) do child:Destroy() end
		local resolution = math.min(32, fresh.NX, fresh.NZ)
		for px = 1, resolution do for pz = 1, resolution do
			local x = math.floor((px - 0.5) / resolution * fresh.NX) + 1
			local z = math.floor((pz - 0.5) / resolution * fresh.NZ) + 1
			local material = Voxelizer.material(fresh, x, z, fresh.Heights[x][z] - 1)
			local color = if fresh.Wet[x][z] then colors.Water else colors[material]
			local shade = 0.75 + 0.25 * (fresh.Heights[x][z] / fresh.Config.Height)
			make("Frame", { Name = "Cell", BorderSizePixel = 0,
				Position = UDim2.fromScale((px - 1) / resolution, (pz - 1) / resolution),
				Size = UDim2.fromScale(1 / resolution, 1 / resolution), BackgroundColor3 = color:Lerp(Color3.new(), 1 - shade) }, preview)
		end end
		map = fresh
		message(string.format("Seed %d · %d voxels · %.1f–%.1f studs high · preview %.3fs\nBox starts at (%d, %d, %d).",
			fresh.Config.Seed, fresh.NX * fresh.NZ * fresh.Config.Height / 4, fresh.Minimum, fresh.Maximum,
			os.clock() - start, fresh.Config.OriginX, fresh.Config.FloorY, fresh.Config.OriginZ))
	end) end)
	connect(applyButton.Activated, function() action(function()
		assert(map, "Generate a preview for the current settings first")
		local start = os.clock()
		local pass = session:apply(map)
		message(string.format("Applied seed %d in %.3fs. Pass %s\nUse Studio Undo to restore; Clear protects later edits.", pass.Seed, os.clock() - start, pass.Id:sub(1, 8)))
	end) end)
	connect(clearButton.Activated, function() action(function()
		session:clear(); message("Latest pass restored to its original empty state. Clear itself supports Undo.")
	end) end)
	return function()
		dead = true
		for _, connection in ipairs(connections) do connection:Disconnect() end
		scroll:Destroy()
	end
end

return Panel
