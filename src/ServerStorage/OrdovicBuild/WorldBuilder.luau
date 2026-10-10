local Plan=require(script.Parent.RoutePlan)
local Cave=require(script.Parent.CaveBuilder)
local Route=require(script.Parent.RouteBuilder)
local Scene=require(script.Parent.SceneBuilder)
local CaveSlice=require(script.Parent.CaveSliceBuilder)
local U=require(script.Parent.BuildUtil)
local Surface=require(script.Parent.SurfaceBuilder)
local Connections=require(script.Parent.ConnectionBuilder)
local Builder={}
function Builder.Build(root)
	root=root or workspace:FindFirstChild("WildboundOpening_Ordovic")
	assert(root and root:IsA("Folder"),"Use the existing opening scaffold")
	assert(root:GetAttribute("BuildId")==nil,"An opening build already exists; do not overwrite it")
	local plan=Plan.Resolve()
	root:SetAttribute("BuildId",Plan.BuildId);root:SetAttribute("BuildReady",false)
	root:SetAttribute("OpeningEnabled",false)
	root:SetAttribute("SourceAnchor",plan.BasinPath);root:SetAttribute("IntakeAnchor",plan.IntakePath)
	local spawn=Cave.Build(root,plan)
	local volumes=Route.Build(root,plan)
	Scene.Build(root,plan)
	CaveSlice.Build(root,plan)
	Surface.Build(root,plan)
	Connections.Build(root,plan)
	root:SetAttribute("OpeningDesignLock",Plan.OpeningLock)
	root:SetAttribute("LayoutVersion",Plan.LayoutVersion)
	local length=0
	for i=1,#plan.Main-1 do length+=(plan.Main[i+1]-plan.Main[i]).Magnitude end
	root:SetAttribute("MainRouteLength",length)
	return {Root=root,WaterVolumes=volumes,Spawn=spawn,Plan=plan}
end
return Builder
