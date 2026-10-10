-- Edit only. Prepare separate modules/geometry before any live replacement or Terrain write.
local storage=game:GetService("ServerStorage")
local approved=storage.OrdovicBuild
assert(not storage:FindFirstChild("OrdovicRaisedStage"),"A prepared stage already exists")
assert(not approved:FindFirstChild("RaisedBuildSession"),"A builder session already exists")
local modules=Instance.new("Folder");modules.Name="RaisedBuildSession";modules.Parent=approved
for _,o in ipairs(approved:GetChildren())do if o:IsA("ModuleScript")then o:Clone().Parent=modules end end
local stage=Instance.new("Folder");stage.Name="OrdovicRaisedStage";stage.Parent=storage
local cave=Instance.new("Model");cave.Name="01_High_Cave";cave.Parent=stage
for _,name in ipairs({"00_Guides","01_RockShell","02_RiverBed","03_Water","04_Collision","05_Dressing","06_Triggers"})do
	local folder=Instance.new("Folder");folder.Name=name;folder.Parent=cave
end
local ok,result=pcall(function()
	local built=require(modules.WorldBuilder).Build(stage)
	local overlaps=OverlapParams.new();overlaps.FilterType=Enum.RaycastFilterType.Include
	overlaps.FilterDescendantsInstances={workspace.World};overlaps.RespectCanCollide=true
	local defects={}
	for _,p in ipairs(stage["10_RouteConnections"]:GetDescendants())do
		if p:IsA("BasePart") and p:GetAttribute("WalkingSurface")then
			for _,hit in ipairs(workspace:GetPartBoundsInBox(p.CFrame*CFrame.new(0,5,0),Vector3.new(10,6,math.max(1,p.Size.Z-8)),overlaps))do
				table.insert(defects,{Route=p.Parent.Name,Slab=p.Name,Obstacle=hit:GetFullName()})
			end
		end
	end
	stage:SetAttribute("PreflightDefects",#defects)
	stage:SetAttribute("PreparedForCommit",#defects==0)
	local source=built.Plan.Source
	return {Descendants=#stage:GetDescendants(),MainLength=stage:GetAttribute("MainRouteLength"),
		Source={source.X,source.Y,source.Z},WaterVolumes=#built.WaterVolumes:GetChildren(),Defects=defects}
end)
modules:Destroy()
if not ok then stage:Destroy();error(result) end
return game:GetService("HttpService"):JSONEncode(result)
