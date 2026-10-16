-- Edit only. Stage modules in ServerStorage.OrdovicBuild; never rebuild the world.
local storage = game:GetService("ServerStorage")
local root = workspace.WildboundOpening_Ordovic
assert(root:GetAttribute("BuildReady") and not root:GetAttribute("CaveOpenerReady"), "Wrong or already updated opening")
local archiveName = "OrdovicCaveHistory_20261015"
assert(not storage:FindFirstChild(archiveName), "Cave history already exists")
local modules = storage.OrdovicBuild:Clone()
modules.Name = "CaveBuildSession"; modules.Parent = storage
local caveBuilder, terrain = require(modules.CaveOpenerBuilder), require(modules.CaveTerrain)
local water = require(modules.OpenerWater)
local cave = root["01_High_Cave"]
local frame = caveBuilder.Frame(root)
local preflight, problem = pcall(function()
	assert(terrain.IsEmpty(terrain.Region(frame)), "Existing cave Terrain must be preserved")
	for _, part in ipairs(cave["01_RockShell"]:GetDescendants()) do
		if part:IsA("BasePart") then assert(part:GetAttribute("Generator") == "OrdovicOpening", "Unowned cave geometry") end
	end
end)
if not preflight then modules:Destroy(); error(problem) end
local history = game:GetService("ChangeHistoryService")
local outer = history:IsRecordingInProgress()
local recording = not outer and history:TryBeginRecording("CaveFlume", "Enlarge cave and connect the flume opener")
if not outer and not recording then modules:Destroy(); error("Studio undo recording is required") end
local backup = Instance.new("Folder"); backup.Name = archiveName; backup.Parent = storage
local volumes = root["90_DEBUG"].TerrainWaterVolumes
local savedVolumes = volumes:Clone(); savedVolumes.Parent = backup
local savedFolders = {}
for _, name in ipairs({"03_FlowZones", "04_StrykerSequence", "05_RapidsObstacles", "06_IntakeWorks"}) do
	savedFolders[name] = root[name]:Clone(); savedFolders[name].Parent = backup
end
local spawn = cave["04_Collision"].Spawn_OrdovicCave
local spawnBefore = spawn.CFrame
backup:SetAttribute("SpawnCFrameBefore", spawnBefore)
local snapshots = {}
local function snapshot(region)
	local low = region.CFrame.Position - region.Size / 2
	local high = low + region.Size
	local minimum = Vector3int16.new(low.X/4, low.Y/4, low.Z/4)
	local maximum = Vector3int16.new(high.X/4-1, high.Y/4-1, high.Z/4-1)
	local copy = workspace.Terrain:CopyRegion(Region3int16.new(minimum, maximum))
	copy.Name = "Before_" .. (#snapshots+1); copy:SetAttribute("VoxelMin", low/4); copy.Parent = backup
	table.insert(snapshots, {Copy = copy, Minimum = minimum})
end
local ok, result = pcall(function()
	local oldShell = cave["01_RockShell"]; oldShell.Parent = backup
	local addition = caveBuilder.Build(root)
	require(modules.FlumeBuilder).Build(root, addition, frame)
	-- Full target preflight before the first voxel write; existing water is also a conflict.
	for _, part in ipairs(volumes:GetChildren()) do
		local region = water.Bounds(part)
		assert(terrain.IsEmpty(region), "Occupied river Terrain at " .. part.Name .. "; no Terrain was written")
		snapshot(region)
	end
	snapshot(terrain.Region(frame))
	terrain.Fill(frame)
	water.Fill(volumes)
	require(modules.OpenerSequenceBuilder).Build(root)
	assert(spawn.CFrame == spawnBefore, "Existing spawn moved unexpectedly")
	addition:SetAttribute("NativeTerrainShell", true)
	root:SetAttribute("CaveOpenerReady", true)
	root:SetAttribute("CaveOpenerVersion", caveBuilder.PassId)
	return {Success=true, PassId=caveBuilder.PassId, SpawnUnchanged=true,
		WaterVolumes=#volumes:GetChildren(), CaveSize={52,30,72}, TerrainBackups=#snapshots}
end)
if not ok then
	for i = #snapshots,1,-1 do workspace.Terrain:PasteRegion(snapshots[i].Copy, snapshots[i].Minimum, true) end
	if cave:FindFirstChild("CaveExpansion") then cave.CaveExpansion:Destroy() end
	if backup:FindFirstChild("01_RockShell") then backup["01_RockShell"].Parent = cave end
	volumes:Destroy(); savedVolumes.Parent = root["90_DEBUG"]
	for name, saved in pairs(savedFolders) do root[name]:Destroy(); saved.Parent = root end
	root:SetAttribute("CaveOpenerReady", nil); root:SetAttribute("CaveOpenerVersion", nil)
	backup:Destroy(); modules:Destroy()
	if recording then history:FinishRecording(recording, Enum.FinishRecordingOperation.Cancel) end
	error("Cave pass failed; recording cancelled: " .. tostring(result))
end
modules:Destroy()
if recording then history:FinishRecording(recording, Enum.FinishRecordingOperation.Commit) end
return result
