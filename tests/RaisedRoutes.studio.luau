-- Edit, read-only against the separately prepared stage or committed opening.
local storage=game:GetService("ServerStorage")
local root=storage:FindFirstChild("OrdovicRaisedStage") or workspace.WildboundOpening_Ordovic
assert(root:GetAttribute("LayoutVersion")=="RaisedRoutes_20261010")
local results={}
local function check(name,fn)
	local ok,err=pcall(fn);table.insert(results,{name=name,passed=ok,error=not ok and tostring(err) or nil})
end
check("Raised authoring source, not the old basin",function()
	assert(root:GetAttribute("SourceAnchor"):find("Ordovic_River3.Ord_River_3",1,true))
	assert(root["00_Guides"].GUIDE_OrdovicOpeningOrigin.Position.Y==2473)
end)
check("River zones descend throughout the main route",function()
	for _,zone in ipairs(root["03_FlowZones"]:GetChildren())do
		if zone.Name:match("^FZMain_")then assert(zone.CFrame.LookVector.Y<=0)end
	end
end)
check("Walking widths and grades remain controller friendly",function()
	local count=0
	for _,p in ipairs(root["10_RouteConnections"]:GetDescendants())do
		if p:IsA("BasePart") and p:GetAttribute("WalkingSurface")then
			assert(p.Size.X>=18 and p.CanCollide and p.Anchored)
			assert(p.CFrame.UpVector.Y>0.94);count+=1
		end
	end
	assert(count>70)
end)
check("Tunnel return has a roof and roomy clearance",function()
	local tunnel=root["10_RouteConnections"].G2_OldWorksReturn
	local floors,roofs=0,0
	for _,p in ipairs(tunnel:GetChildren())do
		if p.Name:match("^Floor")then floors+=1 end
		if p.Name:match("^Roof")then roofs+=1;assert(p.Size.X==26)end
	end
	assert(floors>0 and floors==roofs)
end)
check("Cordge clues and bounds moved with the chamber",function()
	local cave=root["08_HiddenCaveVein"]
	local origin=cave:GetAttribute("Origin")
	assert(origin.Y>1500 and cave.Cordge:GetAttribute("NPCId")=="Cordge")
	local count=0
	for _,p in ipairs(cave["00_Guides"]:GetChildren())do
		if p:GetAttribute("ClueId")then count+=1;assert((p.Position-origin).Magnitude<45)end
	end
	assert(count==5)
end)
check("Closed upstream and blocked deeper route survive",function()
	assert(root["01_High_Cave"]["01_RockShell"].BlockedUpstream:GetAttribute("OpeningBoundary")=="ClosedUpstream")
	for i=1,3 do assert(root["08_HiddenCaveVein"]["01_Collision"]["LowerRouteRubble_"..i].CanCollide)end
end)
check("Arrival markers identify actual dry endpoints",function()
	assert(root["00_Guides"].GUIDE_CityThreshold:GetAttribute("RegionId")=="SKY_CITY")
	assert(root["00_Guides"].GUIDE_WatcherApproach:GetAttribute("RegionId")=="WATCHER")
	local routes=root["10_RouteConnections"]
	assert((routes.G2_IntakeToCity.Arrival.Position-routes.G2_OldWorksReturn.Arrival.Position).Magnitude<0.01)
end)
check("First Sort CLEAR is a local physical interaction",function()
	local station=root["10_RouteConnections"].FirstSortMaintenance
	assert(station.ScreenDebris:GetAttribute("RepairId")=="FirstSort_Clear")
	assert(math.abs(station.ClearScreen.Clear.HoldDuration-1.2)<0.001 and station.ClearScreen.Clear.GamepadKeyCode==Enum.KeyCode.ButtonX)
	assert(station:GetAttribute("Cleared")==false)
end)
check("Generated ownership remains beneath the opening",function()
	for _,p in ipairs(root:GetDescendants())do
		if p:IsA("BasePart") or p:IsA("ProximityPrompt")then
			assert(p:GetAttribute("Generator")=="OrdovicOpening" and p:GetAttribute("BuildId")==root:GetAttribute("BuildId"))
		end
	end
end)
check("Reviewed capability sets have not grown",function()
	local expected={
		[storage.OrdovicBuild]="RunServerScript | AccessOutsideWrite | CreateInstances | Basic | Physics | UI | Input | Environment | Players",
		[game.ServerScriptService.OrdovicOpening]="RunServerScript | AccessOutsideWrite | CreateInstances | Basic | Physics | UI | Input | Players | AvatarBehavior",
	}
	for folder,caps in pairs(expected)do assert(folder.Sandboxed and tostring(folder.Capabilities)==caps)end
end)
check("Dry centerlines and turns have no blocking geometry",function()
	local ray=RaycastParams.new();ray.RespectCanCollide=true
	for _,route in ipairs(root["10_RouteConnections"]:GetChildren())do
		local floors={}
		for _,part in ipairs(route:GetChildren())do if part.Name:match("^Floor")then table.insert(floors,part)end end
		table.sort(floors,function(a,b)return a.Name<b.Name end)
		local last
		for _,floor in ipairs(floors)do
			local a=floor.CFrame:PointToWorldSpace(Vector3.new(0,1.5,floor.Size.Z/2-2))+Vector3.new(0,4,0)
			local b=floor.CFrame:PointToWorldSpace(Vector3.new(0,1.5,-floor.Size.Z/2+2))+Vector3.new(0,4,0)
			for _,segment in ipairs({{a,b},{last or a,a}})do
				local hit=workspace:Raycast(segment[1],segment[2]-segment[1],ray)
				assert(not hit,hit and route.Name.." / "..floor.Name.." blocked by "..hit.Instance:GetFullName())
			end
			last=b
		end
	end
end)
check("Refusal handoff has an open swimming lane",function()
	local zone=root["03_FlowZones"].FZBypass_1
	local mouth=root["00_Guides"].GUIDE_BypassMouth.Position
	local ray=RaycastParams.new();ray.RespectCanCollide=true;ray.IgnoreWater=true
	local hit=workspace:Raycast(mouth,zone.CFrame.LookVector*35,ray)
	assert(not hit,hit and "Bypass mouth blocked by "..hit.Instance:GetFullName())
end)
return results
