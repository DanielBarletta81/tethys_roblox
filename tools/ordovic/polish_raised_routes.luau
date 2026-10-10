-- Edit, only the owned dry connections. Native Terrain remains untouched.
local root=workspace.WildboundOpening_Ordovic
assert(root:GetAttribute("LayoutVersion")=="RaisedRoutes_20261010" and root:GetAttribute("BuildReady"))
local storage=game.ServerStorage
assert(not storage:FindFirstChild("OrdovicJunctionHistory_20261010"),"Route polish already applied")
assert(game:GetService("ChangeHistoryService"):IsRecordingInProgress(),"Studio recording required")
local session=Instance.new("Folder");session.Name="JunctionPolishSession";session.Parent=storage.OrdovicBuild
for _,module in ipairs(storage.OrdovicBuild:GetChildren())do
	if module:IsA("ModuleScript")then module:Clone().Parent=session end
end
local archive=Instance.new("Folder");archive.Name="OrdovicJunctionHistory_20261010";archive.Parent=storage
archive:SetAttribute("Generator","OrdovicOpening");archive:SetAttribute("BuildId",root:GetAttribute("BuildId"))
root["10_RouteConnections"].Parent=archive
for _,name in ipairs({"GUIDE_CityThreshold","GUIDE_WatcherApproach"})do root["00_Guides"][name].Parent=archive end
local ok,result=pcall(function()
	require(session.ConnectionBuilder).Build(root,require(session.RoutePlan).Resolve())
	local lengths={}
	for _,route in ipairs(root["10_RouteConnections"]:GetChildren())do
		if route:GetAttribute("LengthStuds")then lengths[route.Name]=route:GetAttribute("LengthStuds")end
	end
	return {Success=true,Descendants=#root:GetDescendants(),Lengths=lengths,TerrainWrites=0}
end)
session:Destroy()
if not ok then return game.HttpService:JSONEncode({Success=false,Error=tostring(result),UndoRequired=true})end
return game.HttpService:JSONEncode(result)
