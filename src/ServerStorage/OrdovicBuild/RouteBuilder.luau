local U=require(script.Parent.BuildUtil)
local Route={}
function Route.Build(root,plan)
	local route=U.Folder(root,"02_RiverRoute")
	local flow=U.Folder(root,"03_FlowZones")
	local hazards=U.Folder(root,"05_RapidsObstacles")
	local cascade=U.Folder(root,"07_RejectCascade")
	local debug=U.Folder(root,"90_DEBUG")
	local terrainVolumes=U.Folder(debug,"TerrainWaterVolumes")
	local function channel(parent,prefix,nodes,width,bypass)
		for i=1,#nodes-1 do
			local a,b=nodes[i],nodes[i+1]
			-- Flat runs end in real ledges. The lower run cannot be climbed back.
			local endPoint=bypass and Vector3.new(b.X,a.Y,b.Z) or b
			local pieces=math.ceil((b-a).Magnitude/56)
			for j=1,pieces do
				local x,y=a:Lerp(endPoint,(j-1)/pieces),a:Lerp(endPoint,j/pieces)
				local delta=y-x local cf=CFrame.lookAt((x+y)/2,y)
				local key=prefix..string.format("_%02d_%02d",i,j)
				U.Part(parent,"Bed"..key,Vector3.new(width+8,5,delta.Magnitude+7),cf*CFrame.new(0,-8.5,0))
				for _,sign in ipairs({-1,1}) do
					local recoveryGap=not bypass and sign==1 and ((i==6 or i==10) and j==1 or (i==5 or i==9) and j==pieces)
					local trim=recoveryGap and 24 or 0
					local offset=recoveryGap and ((i==6 or i==10) and -12 or 12) or 0
					U.Part(parent,"Bank"..key.."_"..sign,Vector3.new(12,bypass and 38 or 24,delta.Magnitude+12-trim),cf*CFrame.new(sign*(width/2+7),bypass and 2 or 3,offset),Enum.Material.Rock)
				end
				local water=U.Part(terrainVolumes,"Water"..key,Vector3.new(width,12,delta.Magnitude+8),cf,nil,nil,false)
				water.Transparency,water.CanQuery=1,false
			end
			if bypass then
				local drop=a.Y-b.Y
				local cf=CFrame.lookAt(endPoint,endPoint+Vector3.new(b.X-a.X,0,b.Z-a.Z))
				U.Part(parent,"DropFace_"..i,Vector3.new(width+8,drop+5,5),cf*CFrame.new(0,-drop/2-6,2.5),Enum.Material.Rock)
				local water=U.Part(terrainVolumes,"WaterFall_"..i,Vector3.new(width,drop+12,10),cf*CFrame.new(0,-drop/2,-4),nil,nil,false)
				water.Transparency,water.CanQuery=1,false
				U.Zone(flow,"FZ_Drop_"..i,endPoint+Vector3.new(0,4,0),b+cf.LookVector*8,width+8,20,"REJECT_CASCADE",3)
			end
			local phase=bypass and "REJECT_CASCADE" or i==1 and "RIVER_COMMIT" or i<4 and "EASY_RIVER" or i==4 and "SHALLOWS" or i==5 and "STRYKER_SHADOW" or i<10 and "RAPIDS" or "ENGINEERING_FIRST_READ"
			local speed=bypass and 17 or i<4 and 8 or i==4 and 6 or i<10 and 17 or i==10 and 8 or 6
			U.Zone(flow,"FZ"..prefix.."_"..i,a,endPoint,width+8,speed,phase,bypass and 2 or 1)
		end
	end
	channel(route,"Main",plan.Main,28,false)
	local wakeWater=U.Part(terrainVolumes,"WaterWake",Vector3.new(6,3,40),CFrame.new(plan.Source+Vector3.new(0,4.5,-20)),nil,nil,false)
	wakeWater.Transparency,wakeWater.CanQuery=1,false
	channel(cascade,"Bypass",plan.Bypass,14,true)
	for i=1,4 do
		local a,b=plan.Main[i+5],plan.Main[i+6]
		local p=a:Lerp(b,0.45)+CFrame.lookAt(a,b).RightVector*(i%2==0 and 7 or -7)
		local rock=U.Part(hazards,"RapidsRock_"..i,Vector3.new(9,8,10),CFrame.new(p),Enum.Material.Rock)
		rock.Shape=Enum.PartType.Ball;rock.CanTouch=true;rock:SetAttribute("Damage",8)
		rock:SetAttribute("MinSpeed",9)
	end
	for i=1,2 do
		local p=plan.Main[6+i]:Lerp(plan.Main[7+i],0.7)
		local log=U.Part(hazards,"OrdinaryBranch_"..i,Vector3.new(15,3,3),CFrame.new(p+Vector3.new(8,-1,0))*CFrame.Angles(0,math.rad(45),0),Enum.Material.Wood,Color3.fromRGB(89,72,52))
		log.Shape=Enum.PartType.Cylinder;log.CanTouch=true;log:SetAttribute("Damage",6);log:SetAttribute("MinSpeed",9)
	end
	-- Wider resting pockets before and after the hardest rapids.
	for _,i in ipairs({6,10}) do
		local center=plan.Main[i]
		local cf=CFrame.lookAt(center,plan.Main[i+1])
		local pocketCF=cf*CFrame.new(23,0,0)
		U.Part(route,"RecoveryShelf_"..i,Vector3.new(26,4,30),pocketCF*CFrame.new(0,3,0),Enum.Material.Slate)
		U.Part(route,"RecoveryOuterBank_"..i,Vector3.new(8,24,36),pocketCF*CFrame.new(16,3,0),Enum.Material.Rock)
		local water=U.Part(terrainVolumes,"WaterRecovery_"..i,Vector3.new(26,12,30),pocketCF,nil,nil,false)
		water.Transparency,water.CanQuery=1,false
		local calm=U.Zone(flow,"FZ_Recovery_"..i,pocketCF.Position-cf.LookVector*12,pocketCF.Position+cf.LookVector*12,26,0,"RECOVERY",4)
	end
	-- Stable dry footing sits above the lower pool's Terrain-water surface.
	local approach=plan.Bypass[#plan.Bypass]-plan.Bypass[#plan.Bypass-1]
	local downstream=Vector3.new(approach.X,0,approach.Z).Unit
	local dryLanding=plan.Landing+downstream*28
	local landing=U.Part(cascade,"WatcherLanding",Vector3.new(60,8,60),CFrame.new(dryLanding+Vector3.new(0,3,0)),Enum.Material.Slate)
	U.Guide(U.Folder(root,"00_Guides"),"GUIDE_WatcherLanding",dryLanding+Vector3.new(0,10,0))
	return terrainVolumes,landing
end
return Route
