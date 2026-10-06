-- Add this pass to the existing validated opening without rewriting Terrain.
local root = workspace.WildboundOpening_Ordovic
local approved = game.ServerStorage.OrdovicBuild
assert(root:GetAttribute("BuildReady") and root:GetAttribute("BuildId") == "OrdovicV1_20261006")
assert(not root:FindFirstChild("09_WaterSurface"), "Surface pass already installed")
assert(not approved:FindFirstChild("TemporaryBuildSession"), "Builder session already active")
local upstream = root["01_High_Cave"]["01_RockShell"].BlockedUpstream
assert(upstream.CanCollide, "Keep the inaccessible upstream intact")
local history = game:GetService("ChangeHistoryService")
local outer = history:IsRecordingInProgress()
local recording = not outer and history:TryBeginRecording("OrdovicWaterSurface", "Read Ordovic water surfaces")
assert(outer or recording, "Studio undo recording unavailable")
local modules = Instance.new("Folder"); modules.Name = "TemporaryBuildSession"; modules.Parent = approved
for _, name in ipairs({"RoutePlan", "BuildUtil", "SurfaceBuilder"}) do approved[name]:Clone().Parent = modules end
local ok, result = pcall(function()
	local Plan = require(modules.RoutePlan)
	local folder = require(modules.SurfaceBuilder).Build(root, Plan.Resolve())
	root["03_FlowZones"].FZMain_10:SetAttribute("FlowSpeed", 8)
	root["03_FlowZones"].FZMain_11:SetAttribute("FlowSpeed", 6)
	upstream:SetAttribute("OpeningBoundary", "ClosedUpstream")
	upstream:SetAttribute("FutureConnection", "UserAuthoredUpstream")
	root:SetAttribute("OpeningDesignLock", Plan.OpeningLock)
	root:SetAttribute("LayoutVersion", "NaturalWake_CordgeSurface1")
	return {Success = true, CueCount = #folder:GetChildren(), Descendants = #root:GetDescendants(),
		TerrainVolumes = root:GetAttribute("TerrainVolumeCount"), UpstreamClosed = upstream.CanCollide}
end)
modules:Destroy()
if recording then history:FinishRecording(recording, Enum.FinishRecordingOperation.Commit) end
if not ok then return {Success = false, Error = tostring(result), UndoRequired = true} end
return result
