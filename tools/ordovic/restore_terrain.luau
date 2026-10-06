-- Review before running. Restores ONLY this build's backed-up terrain voxel boxes.
-- Geometry and script rollback are separate Studio undo operations.
local backup = game.ServerStorage:FindFirstChild("OrdovicTerrainBackups")
assert(backup and backup:GetAttribute("BuildId") == "OrdovicV1_20261006", "Missing build backup")
local history = game:GetService("ChangeHistoryService")
local outerRecording = history:IsRecordingInProgress()
local id = not outerRecording and history:TryBeginRecording("OrdovicTerrainRestore", "Restore pre-Ordovic terrain")
assert(outerRecording or id, "Undo recording unavailable")
local ok, err = pcall(function()
	workspace.WildboundOpening_Ordovic:SetAttribute("OpeningEnabled", false)
	require(game.ServerStorage.OrdovicBuild.TerrainWater).Restore(backup)
end)
if id then history:FinishRecording(id, Enum.FinishRecordingOperation.Commit) end
if not ok then return {Success = false, Error = tostring(err)} end
return "Original terrain regions restored; opening disabled"
