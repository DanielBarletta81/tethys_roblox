-- Rebuild only the opening's marked instances and backed-up Terrain.
-- Existing world, source modules and the original empty cave scaffold survive.
local approved = game.ServerStorage.OrdovicBuild
local root = workspace.WildboundOpening_Ordovic
local buildId = "OrdovicV1_20261006"
local backup = game.ServerStorage:FindFirstChild("OrdovicTerrainBackups")
assert(root:GetAttribute("BuildId") == buildId and backup and backup:GetAttribute("BuildId") == buildId, "Build/backup ownership mismatch")
for _, region in ipairs(backup:GetChildren()) do
	assert(region:IsA("TerrainRegion") and region:GetAttribute("BuildId") == buildId and region:GetAttribute("VoxelMin"), "Unowned terrain backup")
end
local history = game:GetService("ChangeHistoryService")
local outer = history:IsRecordingInProgress()
local recording = not outer and history:TryBeginRecording("OrdovicOpeningCaveSlice", "Build natural Wake and Cordge cave slice")
assert(outer or recording, "Studio undo recording unavailable")
assert(not approved:FindFirstChild("TemporaryBuildSession"), "Builder session already active")
local modules = Instance.new("Folder"); modules.Name = "TemporaryBuildSession"; modules.Parent = approved
for _, source in ipairs(approved:GetChildren()) do if source:IsA("ModuleScript") then source:Clone().Parent = modules end end
local started = os.clock()
local ok, result = pcall(function()
	local Builder, Water = require(modules.WorldBuilder), require(modules.TerrainWater)
	root:SetAttribute("OpeningEnabled", false); root:SetAttribute("BuildReady", false)
	Water.Restore(backup)
	for _, object in ipairs(root:GetDescendants()) do
		if object.Parent and object:GetAttribute("Generator") == "OrdovicOpening" and object:GetAttribute("BuildId") == buildId then object:Destroy() end
	end
	backup:Destroy()
	for _, key in ipairs({"BuildId", "SourceAnchor", "IntakeAnchor", "MainRouteLength", "TerrainVolumeCount"}) do root:SetAttribute(key, nil) end
	local built = Builder.Build()
	local nextBackup = Instance.new("Folder"); nextBackup.Name = "OrdovicTerrainBackups"
	nextBackup:SetAttribute("BuildId", buildId); nextBackup.Parent = game.ServerStorage
	local count = Water.Fill(built.WaterVolumes, nextBackup)
	root:SetAttribute("TerrainVolumeCount", count)
	root:SetAttribute("BuildReady", true); root:SetAttribute("OpeningEnabled", true)
	root:SetAttribute("LayoutVersion", "NaturalWake_CordgeSurface1")
	return {Success = true, BuildId = buildId, TerrainVolumes = count, Descendants = #root:GetDescendants(),
		RouteLength = root:GetAttribute("MainRouteLength"), BuildSeconds = os.clock() - started}
end)
modules:Destroy()
if not ok then root:SetAttribute("OpeningEnabled", false); root:SetAttribute("BuildReady", false) end
if recording then history:FinishRecording(recording, Enum.FinishRecordingOperation.Commit) end
if not ok then return {Success = false, Error = tostring(result), UndoRequired = true} end
return result
