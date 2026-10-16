local U = require(script.Parent.BuildUtil)
local Flume = {}
function Flume.Build(root, addition, frame)
	local nodes = {Vector3.new(-12, 5.8, -10), Vector3.new(-12, 4, 10),
		Vector3.new(-9, -1, 32), Vector3.new(-8, -7, 62)}
	local waters = root["90_DEBUG"].TerrainWaterVolumes
	for i = 1, #nodes - 1 do
		local a, b = frame:PointToWorldSpace(nodes[i]), frame:PointToWorldSpace(nodes[i + 1])
		local cf = CFrame.lookAt((a + b) / 2, b)
		local floor = U.Part(addition, "FlumeFloor_" .. i, Vector3.new(12, 2, (b-a).Magnitude + 3),
			cf * CFrame.new(0, -1, 0), Enum.Material.Slate)
		floor.CustomPhysicalProperties = PhysicalProperties.new(2.5, 0.06, 0, 100, 100)
		for _, sign in ipairs({-1, 1}) do
			local rail = U.Part(addition, "FlumeSide_" .. i .. "_" .. sign, Vector3.new(3, 7, (b-a).Magnitude + 4),
				cf * CFrame.new(sign * 7.5, 1.5, 0), Enum.Material.Rock)
			rail.CustomPhysicalProperties = floor.CustomPhysicalProperties
		end
		local zone = U.Zone(root["03_FlowZones"], "FZ_Flume_" .. i, a + Vector3.new(0, 3, 0),
			b + Vector3.new(0, 3, 0), 12, 28 + i * 3, "FLUME_DROP", 10)
		zone.Size = Vector3.new(12, 10, zone.Size.Z - 8)
		if i == 1 then zone.Size = Vector3.new(12, 10, (b-a).Magnitude - 4) end
		zone:SetAttribute("ResponseTime", 0.35)
		zone:SetAttribute("PassId", "CaveFlume_20261015")
		-- Thin visible water supports the slide; deep native water begins at the river.
		local water = U.Part(waters, "WaterFlume_" .. i, Vector3.new(10, 2, (b-a).Magnitude + 3),
			cf * CFrame.new(0, 0.5, 0), nil, nil, false)
		water.Transparency = 1; water.CanQuery = false
	end
	local wake = waters.WaterWake
	wake.CFrame = frame * CFrame.new(0, 4.5, -35); wake.Size = Vector3.new(6, 3, 66)
	-- Rapids precede the smooth-rock pause, then the flyover/crash reach.
	for i = 1, 3 do
		local zone = root["03_FlowZones"]["FZMain_" .. i]
		zone:SetAttribute("PhaseName", "RAPIDS"); zone:SetAttribute("FlowSpeed", 24)
	end
	root["03_FlowZones"].FZMain_4:SetAttribute("PhaseName", "SMOOTH_ROCKS")
	root["03_FlowZones"].FZMain_4:SetAttribute("FlowSpeed", 10)
	for i = 1, 4 do
		local zone = root["03_FlowZones"]["FZMain_" .. (i < 4 and i or 4)]
		local p = zone.CFrame:PointToWorldSpace(Vector3.new(i % 2 == 0 and 7 or -7, 0, 0))
		local rock = U.Part(root["05_RapidsObstacles"], "OpeningSmoothRock_" .. i,
			Vector3.new(8, 6, 10), CFrame.new(p), Enum.Material.Slate)
		rock.Shape = Enum.PartType.Ball; rock.CanTouch = true
		rock.CustomPhysicalProperties = PhysicalProperties.new(2.5, 0.08, 0, 100, 100)
		rock:SetAttribute("Damage", i == 4 and 0 or 5); rock:SetAttribute("MinSpeed", 12)
	end
end
return Flume
