-- Edit or Server Play. Detached service fixtures; not an unassisted route test.
local root = workspace.WildboundOpening_Ordovic
local modules = game.ServerScriptService.OrdovicOpening
local Flow = require(modules.FlowService)
local Intake = require(modules.IntakeService)
local Lore = require(modules.LoreMetadata)
local addition = root["01_High_Cave"].CaveExpansion
local frame = root["00_Guides"].GUIDE_OrdovicOpeningOrigin.CFrame
local results = {}
local function check(name, action)
	local ok, err = pcall(action)
	table.insert(results, {name=name, passed=ok, error=not ok and tostring(err) or nil})
end
local fixture = Instance.new("Folder"); fixture.Name = "CaveOpenerFixture"; fixture.Parent = game.ServerStorage
check("native cave shell surrounds an open room", function()
	local ray = RaycastParams.new(); ray.FilterType = Enum.RaycastFilterType.Include
	ray.FilterDescendantsInstances = {workspace.Terrain}; ray.IgnoreWater = true
	local from = frame:PointToWorldSpace(Vector3.new(0,15,-36))
	for _, delta in ipairs({Vector3.new(60,0,0),Vector3.new(-60,0,0),Vector3.new(0,50,0),Vector3.new(0,0,-80)}) do
		local hit = workspace:Raycast(from,delta,ray)
		assert(hit and hit.Distance > 12, "Missing shell or obstructed room")
	end
end)
check("spawn remains on the original dry shelf", function()
	local cave = root["01_High_Cave"]
	local spawn = cave["04_Collision"].Spawn_OrdovicCave
	assert((cave["00_Guides"].GUIDE_CaveWake.Position-spawn.Position-Vector3.new(0,4,0)).Magnitude < 0.01)
	local p = frame:PointToObjectSpace(spawn.Position)
	assert(math.abs(p.X+8)<0.01 and math.abs(p.Z+27)<0.01 and math.abs(p.Y-6.55)<0.01)
end)
check("upstream stays closed and observations have native prompts", function()
	assert(addition.ReservedUpstream.CanCollide and addition.ReservedUpstream:GetAttribute("OpeningBoundary")=="ClosedUpstream")
	local count = 0
	for _,node in ipairs(addition:GetChildren()) do
		if node:GetAttribute("ObservationId") then assert(node.Inspect:IsA("ProximityPrompt")); count += 1 end
	end
	assert(count==3)
end)
check("flume mouth and route order", function()
	assert(addition.MouthRight.Position.X-addition.MouthRight.Size.X/2
		-(addition.MouthLeft.Position.X+addition.MouthLeft.Size.X/2)>=11.9)
	for i=1,3 do assert(root["03_FlowZones"]["FZMain_"..i]:GetAttribute("PhaseName")=="RAPIDS") end
	assert(root["03_FlowZones"].FZMain_4:GetAttribute("PhaseName")=="SMOOTH_ROCKS")
	assert(root["03_FlowZones"].FZMain_5:GetAttribute("PhaseName")=="STRYKER_SHADOW")
end)
check("native water lies below the flume exit", function()
	local p = frame:PointToWorldSpace(Vector3.new(-8,20,66))
	local ray = RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Include
	ray.FilterDescendantsInstances={workspace.Terrain}; ray.IgnoreWater=false
	local hit=workspace:Raycast(p,Vector3.new(0,-45,0),ray)
	assert(hit and hit.Material==Enum.Material.Water)
end)
local part=Instance.new("Part"); part.Anchored=false; part.Parent=fixture
local h={Health=100,Parent=true,PlatformStand=false,AutoRotate=true,
	GetState=function()return Enum.HumanoidStateType.Swimming end,ChangeState=function()end}
local state={Root=part,Humanoid=h}
local flow=Flow.new(root)
check("current constrains only downstream and clears on leaving", function()
	part.CFrame=root["03_FlowZones"].FZMain_2.CFrame
	assert(flow:Step(state)=="RAPIDS")
	assert(state.Force:IsA("LinearVelocity") and state.Force.VelocityConstraintMode==Enum.VelocityConstraintMode.Line)
	part.CFrame=CFrame.new(0,10000,0); flow:Step(state)
	assert(not state.Force and not state.FlowAttachment)
end)
check("slide restores posture on death and outside its volume", function()
	part.CFrame=root["03_FlowZones"].FZ_Flume_2.CFrame
	flow:Step(state); assert(h.PlatformStand and not h.AutoRotate)
	h.Health=0; flow:Step(state)
	assert(not h.PlatformStand and h.AutoRotate and not state.Force)
	h.Health=100
end)
check("rescue rejects foreign prompts and distant or dead players", function()
	local intake=Intake.new(root)
	local player={SetAttribute=function()end}
	local human={Health=100,WalkSpeed=16,JumpPower=50,JumpHeight=7.2,AutoRotate=true,Parent=true}
	local s={Root=part,Humanoid=human,Player=player}
	part.CFrame=CFrame.new(intake.Catch)
	assert(intake:Capture(s))
	local host=Instance.new("Part");host.Parent=fixture
	local foreign=Instance.new("ProximityPrompt");foreign.Parent=host
	assert(not intake:Choose(s,"CITY",foreign))
	part.CFrame=CFrame.new(intake.Catch+Vector3.new(80,0,0))
	assert(not intake:Choose(s,"CITY",intake.AcceptPrompt))
	human.Health=0;part.CFrame=CFrame.new(intake.Catch)
	assert(not intake:Choose(s,"CITY",intake.AcceptPrompt))
	intake:Release(s);assert(human.WalkSpeed==16 and human.JumpPower==50)
end)
check("CMS mapping requires explicit ids and uses the existing schema", function()
	local c=Instance.new("Folder");c.Parent=fixture
	local node=Instance.new("Part");node:SetAttribute("ObservationId","Fixture");node.Parent=c
	local payload={success=true,narrativeStream={{nodeId=42,bodyText="A mapped CMS observation."}}}
	assert(Lore.Apply(c,payload)==0)
	node:SetAttribute("LoreId",42);assert(Lore.Apply(c,payload)==1)
	assert(node:GetAttribute("LoreBodyText")=="A mapped CMS observation.")
end)
flow:Clear(state);fixture:Destroy()
return results
