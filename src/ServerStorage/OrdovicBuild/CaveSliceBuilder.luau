local U = require(script.Parent.BuildUtil)
local Slice = {}

function Slice.Build(root, plan)
	local cave = U.Folder(root, "08_HiddenCaveVein")
	local origin = plan.Intake + Vector3.new(92, 10, 81)
	cave:SetAttribute("RouteId", "HiddenVein_A")
	cave:SetAttribute("Origin", origin)
	local shell, features = U.Folder(cave, "01_Collision"), U.Folder(cave, "02_Features")
	local guides, triggers = U.Folder(cave, "00_Guides"), U.Folder(cave, "06_Triggers")
	local function rock(name, size, offset, material)
		return U.Part(shell, name, size, CFrame.new(origin + offset), material or Enum.Material.Rock)
	end
	rock("MainFloor", Vector3.new(52, 4, 50), Vector3.new(0, -2, -8))
	rock("LowWetFloor", Vector3.new(52, 4, 16), Vector3.new(0, -6, 25))
	for i = 1, 3 do rock("WetAreaStep_" .. i, Vector3.new(14, 2, 3), Vector3.new(0, -i, 16 + i * 2)) end
	rock("NorthWall", Vector3.new(64, 34, 6), Vector3.new(0, 15, -36))
	rock("EastWall", Vector3.new(6, 34, 78), Vector3.new(29, 15, 0))
	for i, spec in ipairs({{-30.5, 11}, {-7.5, 15}, {24, 24}}) do
		rock("WestRock_" .. i, Vector3.new(6, 34, spec[2]), Vector3.new(-29, 15, spec[1]))
	end
	rock("OverlookLowerLip", Vector3.new(6, 5, 12), Vector3.new(-29, 2.5, 6))
	rock("OverlookBrow", Vector3.new(6, 16, 12), Vector3.new(-29, 27, 6))
	rock("RoofMain", Vector3.new(64, 6, 78), Vector3.new(0, 36, 0))
	rock("RoofLowerBrow", Vector3.new(18, 7, 32), Vector3.new(16, 30, -14))
	rock("EntryFloor", Vector3.new(26, 4, 9), Vector3.new(-42, -2, -20))
	rock("EntryWallNorth", Vector3.new(26, 12, 4), Vector3.new(-42, 4, -26.5))
	rock("EntryWallSouth", Vector3.new(26, 12, 4), Vector3.new(-42, 4, -13.5))
	rock("EntryRoof", Vector3.new(26, 4, 13), Vector3.new(-42, 11, -20))
	rock("OldCutPlatform", Vector3.new(22, 2, 10), Vector3.new(-16, 4, 6))
	for i = 1, 5 do rock("OverlookStep_" .. i, Vector3.new(9, i, 3), Vector3.new(-16, i / 2, -13 + i * 3)) end
	for _, sign in ipairs({-1, 1}) do
		rock("SouthWall_" .. sign, Vector3.new(24, 34, 6), Vector3.new(sign * 17, 15, 36))
		rock("LowerPassageWall_" .. sign, Vector3.new(5, 16, 24), Vector3.new(sign * 6.5, 2, 48))
	end
	rock("LowerPassageRoof", Vector3.new(18, 6, 24), Vector3.new(0, 9, 48))
	rock("LowerPassageFloor", Vector3.new(8, 4, 24), Vector3.new(0, -6, 48))
	rock("LowerPassageFarRock", Vector3.new(18, 16, 5), Vector3.new(0, 2, 62))
	for i = 1, 3 do
		local rubble = rock("LowerRouteRubble_" .. i, Vector3.new(5, 6, 5), Vector3.new((i - 2) * 3, -1, 37))
		rubble.CFrame *= CFrame.Angles(0, i * 0.3, i * 0.13)
	end
	local pool = U.Part(features, "BrackishPocket", Vector3.new(14, 0.15, 12), CFrame.new(origin + Vector3.new(14, -3.8, 25)), Enum.Material.Glass, Color3.fromRGB(67, 81, 73), false)
	pool.Transparency = 0.45; pool:SetAttribute("VisualWaterOnly", true)
	for i = 1, 7 do
		U.Part(features, "HighSaltLine_" .. i, Vector3.new(0.25, 0.7, 2.2), CFrame.new(origin + Vector3.new(25.8, 1.4, 15 + i * 2.3)), Enum.Material.Salt, Color3.fromRGB(181, 179, 149), false)
	end
	for side = -1, 1, 2 do for i = 1, 3 do
		U.Part(features, "MasonryJamb_" .. side .. "_" .. i, Vector3.new(3, 3, 2), CFrame.new(origin + Vector3.new(25.8, i * 3 - 1.5, -6 + side * 4.5)), Enum.Material.Cobblestone, Color3.fromRGB(110, 108, 92), false)
	end end
	U.Part(features, "BuriedDoorLintel", Vector3.new(13, 3, 2), CFrame.new(origin + Vector3.new(25.8, 10.5, -6)) * CFrame.Angles(0, math.pi / 2, 0), Enum.Material.Cobblestone, Color3.fromRGB(110, 108, 92), false)
	for i = 1, 3 do
		U.Part(features, "SightCut_" .. i, Vector3.new(0.12, 0.12, 1.4), CFrame.new(origin + Vector3.new(-24.5, 5.12, 3 + i)), Enum.Material.Slate, Color3.fromRGB(30, 34, 32), false)
	end
	local drainA, drainB = origin + Vector3.new(11, 0.08, -20), origin + Vector3.new(14, -3.7, 20)
	U.Part(features, "HandCutDrain", Vector3.new(1.8, 0.16, (drainB - drainA).Magnitude), CFrame.lookAt((drainA + drainB) / 2, drainB), Enum.Material.Slate, Color3.fromRGB(33, 42, 39), false)
	local landing = plan.Intake + Vector3.new(17, 7, 16)
	local entry = origin + Vector3.new(-55, 0, -20)
	U.Part(shell, "IntakeToCaveWalk", Vector3.new(12, 4, (entry - landing).Magnitude + 4), CFrame.lookAt((entry + landing) / 2 - Vector3.new(0, 2, 0), entry - Vector3.new(0, 2, 0)), Enum.Material.Cobblestone)
	local bounds = U.Guide(guides, "GUIDE_CaveBounds", origin + Vector3.new(-10, 13, 5))
	bounds.Size = Vector3.new(94, 54, 122)
	-- Temporary natural bounce lighting keeps the graybox clues readable.
	-- Final lighting/art can replace these marked proxies without global changes.
	for i, offset in ipairs({Vector3.new(-37, 7, -20), Vector3.new(-7, 14, -6), Vector3.new(13, 8, 25)}) do
		local anchor = U.Guide(guides, "NaturalBounce_" .. i, origin + offset)
		local light = Instance.new("PointLight")
		light.Name, light.Brightness, light.Range = "GrayboxBounce", 1.2, 40
		light.Color, light.Shadows = Color3.fromRGB(182, 193, 184), false
		light:SetAttribute("ProxyLighting", true); U.Mark(light); light.Parent = anchor
	end
	local actor = Instance.new("Model"); actor.Name = "Cordge"; U.Mark(actor); actor.Parent = cave
	actor:SetAttribute("NPCId", "Cordge"); actor:SetAttribute("WB_CordgeEnabled", true)
	actor:SetAttribute("ProxyArt", true); actor:SetAttribute("VoicePending", true)
	actor:SetAttribute("FollowBehavior", "StagedGuide")
	local actorOrigin = origin + Vector3.new(-14, 0, -18)
	local function body(name, size, offset, color)
		return U.Part(actor, name, size, CFrame.new(actorOrigin + offset), Enum.Material.SmoothPlastic, color, false)
	end
	actor.PrimaryPart = body("Torso", Vector3.new(3.4, 3.3, 1.6), Vector3.new(0, 4.55, 0), Color3.fromRGB(72, 79, 68))
	body("Head", Vector3.new(1.5, 1.5, 1.5), Vector3.new(0, 6.85, 0), Color3.fromRGB(111, 117, 96))
	for _, sign in ipairs({-1, 1}) do
		body("Leg_" .. sign, Vector3.new(1.25, 2.9, 1.3), Vector3.new(sign * 0.85, 1.45, 0), Color3.fromRGB(58, 65, 56))
		body("Arm_" .. sign, Vector3.new(0.9, 3.4, 1.15), Vector3.new(sign * 2.2, 4.5, 0), Color3.fromRGB(96, 103, 86))
	end
	local function observation(name, point, text, dialogueId, priority)
		local marker = U.Guide(guides, "CLUE_Cave_" .. name, origin + point)
		marker:SetAttribute("ClueId", "Cave_" .. name); marker:SetAttribute("ObservationText", text)
		local prompt = Instance.new("ProximityPrompt"); prompt.Name = "Inspect"
		prompt.ActionText, prompt.ObjectText, prompt.HoldDuration = "Inspect", name:gsub("(%u)", " %1"):sub(2), 0
		prompt.KeyboardKeyCode, prompt.GamepadKeyCode = Enum.KeyCode.E, Enum.KeyCode.ButtonX
		prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 10, true
		U.Mark(prompt); prompt.Parent = marker
		if dialogueId then
			local zone = U.Guide(triggers, "DBG_Cordge_" .. name, marker.Position)
			zone.Size = Vector3.new(12, 12, 12)
			zone:SetAttribute("DialogueId", dialogueId); zone:SetAttribute("Priority", priority or 2)
			zone:SetAttribute("OneShot", true); zone:SetAttribute("RequiresClue", "Cave_" .. name)
		end
	end
	observation("ObservationSlit", Vector3.new(-16, 8, 6), "The opening overlooks an exposed route from inside protected rock.", "CAVE_OVERLOOK_01", 2)
	observation("SaltLine", Vector3.new(15, -1, 18), "Mineral staining remains above the present waterline.", "CAVE_SALT_01", 3)
	observation("Masonry", Vector3.new(18, 4, -6), "Worked stone intersects the natural passage.", "CAVE_MASONRY_01", 2)
	-- Inspect from the dry approach; the close camera can sit behind rubble
	-- when the prompt is placed down inside the blocked passage.
	observation("LowerRoute", Vector3.new(0, 3, 14), "The lower passage continues beyond a collapse.", "CAVE_BLOCKED_01", 2)
	observation("DrainCut", Vector3.new(11, 3, -14), "A narrow cut leads water toward the low pocket.")
	local entryZone = U.Guide(triggers, "DBG_Cordge_CaveEntry", origin + Vector3.new(-31, 4, -20))
	entryZone.Size = Vector3.new(14, 12, 12); entryZone:SetAttribute("DialogueId", "CAVE_ENTRY_01")
	entryZone:SetAttribute("Priority", 1); entryZone:SetAttribute("OneShot", true)
	cave:SetAttribute("BuildReady", true)
	return cave
end
return Slice
