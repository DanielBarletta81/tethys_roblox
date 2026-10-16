local U = require(script.Parent.BuildUtil)
local Builder = {}
Builder.PassId = "CaveFlume_20261015"

function Builder.Frame(root)
	-- The installed guide moved with the build; never re-resolve the old river anchor.
	local guide = root["00_Guides"].GUIDE_OrdovicOpeningOrigin
	return guide.CFrame
end

function Builder.Build(root)
	local cave, frame = root["01_High_Cave"], Builder.Frame(root)
	assert(not cave:FindFirstChild("CaveExpansion"), "Cave expansion already exists")
	local addition = U.Folder(cave, "CaveExpansion")
	addition:SetAttribute("PassId", Builder.PassId)
	addition:SetAttribute("AuthoringFrame", frame)
	local function part(name, size, position, material, collide)
		local p = U.Part(addition, name, size, frame * CFrame.new(position), material, nil, collide)
		if material == Enum.Material.Limestone then p.Color = Color3.fromRGB(168, 165, 145) end
		p:SetAttribute("PassId", Builder.PassId)
		return p
	end
	-- Flat dry footing stays at the old bank height. The existing spawn does not move.
	for _, sign in ipairs({-1, 1}) do
		part("DryShelf_" .. sign, Vector3.new(23, 4, 58), Vector3.new(sign * 14.5, 4, -39), Enum.Material.Limestone)
	end
	part("StreamBed", Vector3.new(6, 4, 66), Vector3.new(0, 0, -35), Enum.Material.Slate)
	local back = part("ReservedUpstream", Vector3.new(60, 36, 8), Vector3.new(0, 14, -74), Enum.Material.Rock)
	back:SetAttribute("OpeningBoundary", "ClosedUpstream")
	back:SetAttribute("FutureConnection", "UserAuthoredUpstream")
	-- Offset opening: daylight is a narrow invitation from the wake shelf.
	part("MouthLeft", Vector3.new(12, 25, 10), Vector3.new(-24, 15, -3), Enum.Material.Limestone)
	part("MouthRight", Vector3.new(34, 25, 10), Vector3.new(11, 15, -3), Enum.Material.Limestone)
	local brow = part("ExitBrow", Vector3.new(60, 12, 12), Vector3.new(0, 24, -3), Enum.Material.Limestone)
	local lightHost = part("DaylightSliver", Vector3.one, Vector3.new(-12, 15, 1), nil, false)
	lightHost.Transparency = 1; lightHost.CanQuery = false
	local light = Instance.new("SpotLight")
	light.Name = "SliverDaylight"; light.Color = Color3.fromRGB(242, 232, 200)
	light.Brightness = 2; light.Range = 56; light.Angle = 65
	light.Face = Enum.NormalId.Front; light.Parent = lightHost
	local beamEnd = Instance.new("Attachment"); beamEnd.Position = Vector3.new(4,-8,-30); beamEnd.Parent = lightHost
	local beamStart = Instance.new("Attachment"); beamStart.Parent = lightHost
	local beam = Instance.new("Beam"); beam.Name = "DaylightRibbon"
	beam.Attachment0 = beamStart; beam.Attachment1 = beamEnd; beam.FaceCamera = true
	beam.Width0 = 0.4; beam.Width1 = 3; beam.Transparency = NumberSequence.new(0.88)
	beam.Color = ColorSequence.new(light.Color); beam.LightEmission = 1; beam.Parent = lightHost
	local bounce = Instance.new("PointLight")
	bounce.Name = "QuietBounce"; bounce.Brightness = 0.35; bounce.Range = 38
	bounce.Color = Color3.fromRGB(118, 167, 164); bounce.Parent = addition.DryShelf_1
	local bounds = part("CaveBounds", Vector3.new(54, 32, 72), Vector3.new(0, 17, -36), nil, false)
	bounds.Transparency = 1; bounds.CanQuery = false
	local function observation(id, name, point, text, color)
		local node = part(id, Vector3.new(3, 2, 1), point, Enum.Material.Slate, false)
		node.Color = color; node:SetAttribute("ObservationId", id)
		node:SetAttribute("ObservationText", text)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "Inspect"; prompt.ActionText = "Inspect"; prompt.ObjectText = name
		prompt.HoldDuration = 0.4; prompt.MaxActivationDistance = 8; prompt.RequiresLineOfSight = true
		prompt.KeyboardKeyCode = Enum.KeyCode.E; prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.Parent = node
	end
	observation("MineralBand", "Mineral band", Vector3.new(-20, 9, -44),
		"A pale mineral seam crosses the darker rock.", Color3.fromRGB(184, 178, 147))
	observation("WaterGroove", "Water-worn stone", Vector3.new(5, 7.2, -17),
		"The stone is smooth where water passes over it.", Color3.fromRGB(89, 123, 127))
	observation("CrystalSeam", "Crystal seam", Vector3.new(21, 9, -53),
		"Small crystals catch the light along a fracture.", Color3.fromRGB(155, 191, 178))
	-- Mineral decoration has no collision and cannot snag a character or camera.
	for i = 1, 9 do
		local p = part("Calcite_" .. i, Vector3.new(2, 2 + i % 3, 2),
			Vector3.new(21 + i % 2, 7 + i % 3, -59 + i * 3), Enum.Material.Limestone, false)
		p.Shape = Enum.PartType.Ball
	end
	return addition
end
return Builder
