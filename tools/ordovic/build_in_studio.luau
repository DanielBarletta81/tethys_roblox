-- Execute only after approval of docs/Ordovic-opening-capabilities.md.
-- The installed modules remain separate; this driver records one reversible build.
local approved = game.ServerStorage.OrdovicBuild
-- Edit-mode require caches functions and their original sandbox grants.
-- Fresh module copies inherit exactly the same approved sandbox, then are
-- removed after this build. The eight source modules remain separate.
local modules = Instance.new("Folder")
modules.Name = "TemporaryBuildSession"
assert(not approved:FindFirstChild(modules.Name), "A builder session already exists")
modules.Parent = approved
for _, source in ipairs(approved:GetChildren()) do
	if source:IsA("ModuleScript") then source:Clone().Parent = modules end
end
local loaded, Builder, Water = pcall(function()
	return require(modules.WorldBuilder), require(modules.TerrainWater)
end)
if not loaded then modules:Destroy(); error(Builder) end
local history = game:GetService("ChangeHistoryService")
assert(not game.ServerStorage:FindFirstChild("OrdovicTerrainBackups"))
-- Studio MCP owns an outer recording, as in the validated Scatter driver.
local outerRecording = history:IsRecordingInProgress()
local id = not outerRecording and history:TryBeginRecording("OrdovicOpeningV1", "Build Ordovic opening v1")
assert(outerRecording or id, "Studio undo recording unavailable; no build started")
local backup = Instance.new("Folder")
backup.Name = "OrdovicTerrainBackups"
backup:SetAttribute("BuildId", "OrdovicV1_20261006")
backup.Parent = game.ServerStorage
local built
local started = os.clock()
local ok, result = pcall(function()
	built = Builder.Build()
	local count = Water.Fill(built.WaterVolumes, backup)
	built.Root:SetAttribute("TerrainVolumeCount", count)
	built.Root:SetAttribute("BuildReady", true)
	built.Root:SetAttribute("OpeningEnabled", true)
	return {BuildId = built.Root:GetAttribute("BuildId"), TerrainVolumes = count,
		RouteLength = built.Root:GetAttribute("MainRouteLength"), Descendants = #built.Root:GetDescendants(),
		BuildSeconds = os.clock() - started, OuterUndoRecording = outerRecording}
end)
if not ok then
	-- Keep an undo entry for a partial build; never claim Cancel restores the world.
	local root = workspace:FindFirstChild("WildboundOpening_Ordovic")
	if root then root:SetAttribute("OpeningEnabled", false); root:SetAttribute("BuildReady", false) end
	if id then history:FinishRecording(id, Enum.FinishRecordingOperation.Commit) end
	modules:Destroy()
	return {Success = false, Error = tostring(result), PartialBuild = built ~= nil, OuterUndoRecording = outerRecording}
end
if id then history:FinishRecording(id, Enum.FinishRecordingOperation.Commit) end
modules:Destroy()
result.Success = true
return result
