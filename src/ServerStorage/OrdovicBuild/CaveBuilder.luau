local U = require(script.Parent.BuildUtil)
local Cave = {}
function Cave.Build(root, plan)
	local cave = root:FindFirstChild("01_High_Cave")
	assert(cave and cave:IsA("Model") and #cave:GetDescendants() == 7, "Preserve the existing empty cave scaffold")
	local shell = U.Folder(cave, "01_RockShell")
	local collision = U.Folder(cave, "04_Collision")
	local guides = U.Folder(cave, "00_Guides")
	local origin = plan.Source
	local function rock(name, size, offset)
		return U.Part(shell, name, size, CFrame.new(origin + offset), Enum.Material.Rock)
	end
	-- A natural wake pocket. Human evidence belongs to the later Hidden Vein.
	for _, sign in ipairs({-1, 1}) do
		rock("DryBank_" .. sign, Vector3.new(10, 6, 40), Vector3.new(sign * 8, 3, -20))
		rock("ChamberWall_" .. sign, Vector3.new(6, 18, 46), Vector3.new(sign * 16, 13, -20))
	end
	rock("StreamBed", Vector3.new(6, 4, 40), Vector3.new(0, 1, -20))
	rock("NaturalRoof", Vector3.new(38, 7, 46), Vector3.new(0, 25.5, -20))
	local upstream = rock("BlockedUpstream", Vector3.new(38, 23, 7), Vector3.new(0, 10.5, -43))
	upstream:SetAttribute("OpeningBoundary", "ClosedUpstream")
	upstream:SetAttribute("FutureConnection", "UserAuthoredUpstream")
	rock("ExitBrow", Vector3.new(38, 5, 8), Vector3.new(0, 22, 2))
	local spawn = Instance.new("SpawnLocation")
	spawn.Name, spawn.Size = "Spawn_OrdovicCave", Vector3.new(8, 1, 12)
	spawn.CFrame = CFrame.new(origin + Vector3.new(-8, 6.55, -27))
	spawn.Anchored, spawn.CanCollide, spawn.Transparency = true, true, 1
	spawn.Neutral, spawn.Duration, spawn.Enabled = true, 0, true
	spawn:SetAttribute("DefaultJoinSpawn", true); U.Mark(spawn); spawn.Parent = collision
	U.Guide(guides, "GUIDE_CaveWake", spawn.Position + Vector3.new(0, 4, 0))
	local daylight = Instance.new("PointLight")
	daylight.Name, daylight.Brightness, daylight.Range = "GrayboxDaylight", 1, 36
	daylight.Color = Color3.fromRGB(183, 200, 204)
	daylight:SetAttribute("ProxyLighting", true); U.Mark(daylight); daylight.Parent = shell.ExitBrow
	return spawn
end
return Cave
