local U = require(script.Parent.BuildUtil)
local Connections = {}

local function corridor(parent, id, nodes, tunnel)
	local folder = U.Folder(parent, id)
	folder:SetAttribute("RouteId", id)
	folder:SetAttribute("AuthoringStatus", "Graybox")
	local total = 0
	for i=1,#nodes-1 do
		local a,b = nodes[i],nodes[i+1]
		local delta = b-a
		local horizontal = Vector3.new(delta.X,0,delta.Z).Magnitude
		assert(horizontal > 1 and math.abs(delta.Y)/horizontal < 0.36, "Walking grade exceeds route limit: "..id)
		local pieces = math.ceil(delta.Magnitude/64)
		for j=1,pieces do
			local x,y = a:Lerp(b,(j-1)/pieces),a:Lerp(b,j/pieces)
			local cf = CFrame.lookAt((x+y)/2,y)
			local key = string.format("_%02d_%02d",i,j)
			local length = (y-x).Magnitude+4
			local floor = U.Part(folder,"Floor"..key,Vector3.new(18,3,length),cf*CFrame.new(0,-1.5,0),Enum.Material.Slate)
			floor:SetAttribute("RouteId",id);floor:SetAttribute("WalkingSurface",true)
			for _,sign in ipairs({-1,1}) do
				U.Part(folder,(tunnel and "Wall" or "Kerb")..key.."_"..sign,
					Vector3.new(tunnel and 4 or 1,tunnel and 18 or 2,length),
					cf*CFrame.new(sign*(tunnel and 11 or 9.5),tunnel and 7.5 or 1,0),Enum.Material.Rock)
			end
			if tunnel then U.Part(folder,"Roof"..key,Vector3.new(26,4,length),cf*CFrame.new(0,18.5,0),Enum.Material.Rock) end
		end
		U.Part(folder,"Junction_"..i,Vector3.new(24,3,24),CFrame.new(a-Vector3.new(0,1.5,0)),Enum.Material.Slate)
		total += delta.Magnitude
	end
	U.Part(folder,"Arrival",Vector3.new(28,3,28),CFrame.new(nodes[#nodes]-Vector3.new(0,1.5,0)),Enum.Material.Slate)
	folder:SetAttribute("LengthStuds",total)
	return folder
end

function Connections.Build(root, plan)
	local folder = U.Folder(root,"10_RouteConnections")
	local landing = plan.Intake+Vector3.new(17,7,16)
	local city = plan.City
	local cityRoute = corridor(folder,"G2_IntakeToCity",{landing,
		Vector3.new(-100,1535,-1390),Vector3.new(200,1500,-1450),Vector3.new(330,1460,-1250),
		Vector3.new(120,1430,-1080),city},false)
	cityRoute:SetAttribute("Chapter",2)
	local watcher = root["00_Guides"].GUIDE_WatcherLanding.Position-Vector3.new(0,3,0)
	local trek = corridor(folder,"WatcherSideDescent",{watcher,Vector3.new(-1250,1320,-1100),
		Vector3.new(-1500,1240,-1600),Vector3.new(-1950,1130,-1980),Vector3.new(-2400,1020,-1620),
		Vector3.new(-2840,900,-1270),Vector3.new(-3210,800,-950)},false)
	trek:SetAttribute("RouteCategory","RegionalTraversal");trek:SetAttribute("Destination", "WatcherApproach")
	local returnRoute = corridor(folder,"G2_OldWorksReturn",{watcher,
		Vector3.new(-780,1440,-1140),Vector3.new(-580,1440,-1240),
		Vector3.new(-360,1425,-1290),Vector3.new(-180,1415,-1310),city},true)
	returnRoute:SetAttribute("Chapter",2)
	local guides = root["00_Guides"]
	local threshold = U.Guide(guides,"GUIDE_CityThreshold",city+Vector3.new(0,3,0))
	threshold.Size=Vector3.new(28,14,28)
	threshold:SetAttribute("RegionId","SKY_CITY");threshold:SetAttribute("ArrivalId","SkyCity_FromIntake")
	local vista = U.Guide(guides,"GUIDE_WatcherApproach",Vector3.new(-3210,803,-950))
	vista.Size=Vector3.new(28,14,28)
	vista:SetAttribute("RegionId","WATCHER");vista:SetAttribute("ArrivalId","Watcher_RidgeApproach")
	local station=U.Folder(folder,"FirstSortMaintenance")
	local point=landing+Vector3.new(8,0,-6)
	U.Part(station,"StandingShelf",Vector3.new(24,3,24),CFrame.new(point-Vector3.new(0,1.5,0)),Enum.Material.Cobblestone)
	local debris=U.Part(station,"ScreenDebris",Vector3.new(10,3,2),CFrame.new(point+Vector3.new(0,1,-7)),Enum.Material.Wood,Color3.fromRGB(81,70,47),false)
	debris:SetAttribute("RepairId","FirstSort_Clear")
	local marker=U.Guide(station,"ClearScreen",point+Vector3.new(0,3,-5))
	marker:SetAttribute("InteractionId","FirstSort_Clear")
	local prompt=Instance.new("ProximityPrompt")
	prompt.Name="Clear";prompt.ActionText="Clear";prompt.ObjectText="Debris screen"
	prompt.HoldDuration=1.2;prompt.MaxActivationDistance=9;prompt.RequiresLineOfSight=true
	prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.GamepadKeyCode=Enum.KeyCode.ButtonX
	U.Mark(prompt);prompt.Parent=marker;station:SetAttribute("Cleared",false)
	return folder
end
return Connections
