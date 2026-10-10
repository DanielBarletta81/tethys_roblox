-- Edit only, after prepare_raised_routes preflight. One connector undo operation.
local storage=game:GetService("ServerStorage")
local stage=storage.OrdovicRaisedStage
local old=workspace.WildboundOpening_Ordovic
assert(stage:GetAttribute("PreparedForCommit") and stage:GetAttribute("LayoutVersion")=="RaisedRoutes_20261010")
assert(old:GetAttribute("BuildId")==stage:GetAttribute("BuildId"),"Opening ownership differs")
assert(not storage:FindFirstChild("OrdovicLayoutHistory_20261010"),"This layout has already been committed")
local history=game:GetService("ChangeHistoryService")
local outer=history:IsRecordingInProgress()
local recording=not outer and history:TryBeginRecording("OrdovicRaisedRoutes","Build raised Ordovic, city and Watcher connections")
assert(outer or recording,"Studio undo recording unavailable")
local started=os.clock()
local modules=Instance.new("Folder");modules.Name="RaisedCommitSession";modules.Parent=storage.OrdovicBuild
for _,o in ipairs(storage.OrdovicBuild:GetChildren())do if o:IsA("ModuleScript")then o:Clone().Parent=modules end end
local nextBackup=Instance.new("Folder");nextBackup.Name="RaisedTerrainBackups";nextBackup.Parent=storage
nextBackup:SetAttribute("BuildId",stage:GetAttribute("BuildId"))
local ok,result=pcall(function()
	local water=require(modules.TerrainWater)
	-- Water.Fill checks every target before writing any new Terrain.
	local count=water.Fill(stage["90_DEBUG"].TerrainWaterVolumes,nextBackup)
	local archive=Instance.new("Folder");archive.Name="OrdovicLayoutHistory_20261010";archive.Parent=storage
	archive:SetAttribute("Generator","OrdovicOpening");archive:SetAttribute("LayoutVersion","NaturalWake_CordgeSurface1")
	local backup=storage.OrdovicTerrainBackups
	-- The creator cleared the old native Terrain during layout work. Preserve
	-- its historical backups; do not paste old data back into the clean floor.
	old:SetAttribute("OpeningEnabled",false)
	for _,o in ipairs(old:GetDescendants())do if o:IsA("SpawnLocation")then o.Enabled=false end end
	old.Parent=archive;backup.Parent=archive
	nextBackup.Name="OrdovicTerrainBackups"
	stage.Name="WildboundOpening_Ordovic";stage.Parent=workspace
	stage:SetAttribute("TerrainVolumeCount",count);stage:SetAttribute("BuildReady",true);stage:SetAttribute("OpeningEnabled",true)
	-- Reconnect the moved maintenance walk without changing its authored rotation.
	local sort=workspace.World["05_Mountain_Works"].Givers_Intake["01_GiversFallsIntake"].FirstSort
	local walks=sort.MaintenanceWalks
	local target=sort.Basin.FirstSort_BasinFloor.Position.Y+3
	local shift=target-walks.MaintenanceWalk_Cross.Position.Y
	for _,o in ipairs(walks:GetDescendants())do if o:IsA("BasePart")then o.CFrame+=Vector3.new(0,shift,0)end end
	walks:SetAttribute("RaisedLayoutCorrection",shift)
	return {Success=true,Descendants=#stage:GetDescendants(),WaterVolumes=count,
		OldTerrainWrites=0,OriginalOpeningArchived=true,
		MaintenanceWalkRaised=shift,BuildSeconds=os.clock()-started}
end)
modules:Destroy()
if recording then history:FinishRecording(recording,Enum.FinishRecordingOperation.Commit)end
if not ok then return game:GetService("HttpService"):JSONEncode({Success=false,Error=tostring(result),UndoRequired=true})end
return game:GetService("HttpService"):JSONEncode(result)
