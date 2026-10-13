local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Math=require(script.Parent.FlowMath)
local Progress={}
local ids={CITY="GUIDE_CityThreshold",WATCHER="GUIDE_WatcherApproach"}

function Progress.Respawn(root,player,character)
	local id=player:GetAttribute("WB_RouteCheckpoint")
	local name=ids[id]
	local marker=name and root["00_Guides"]:FindFirstChild(name)
	local human=character:FindFirstChildOfClass("Humanoid")
	if not marker or not human or human.Health<=0 or not player:GetAttribute("WildboundOpeningChoice") then return false end
	local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances={character};ray.RespectCanCollide=true
	local hit=workspace:Raycast(marker.Position+Vector3.new(0,4,0),Vector3.new(0,-16,0),ray)
	if not hit or hit.Material==Enum.Material.Water or hit.Normal.Y<0.85 then return false end
	character:PivotTo(CFrame.new(hit.Position+Vector3.new(0,3.5,0)))
	local part=character:FindFirstChild("HumanoidRootPart")
	if part then part.AssemblyLinearVelocity=Vector3.zero;part.AssemblyAngularVelocity=Vector3.zero end
	return true
end

function Progress.Start(root)
	if Progress.Active then return Progress.Active end
	local endpoint=script.Parent:WaitForChild("BF_RouteProgress",10)
	assert(endpoint and endpoint:IsA("BindableFunction"),"Existing Wildbound owner did not expose route progress")
	local elapsed=0
	local connection=RunService.Heartbeat:Connect(function(dt)
		elapsed+=dt;if elapsed<0.2 then return end;elapsed=0
		for _,player in ipairs(Players:GetPlayers())do
			local character=player.Character
			local human=character and character:FindFirstChildOfClass("Humanoid")
			local part=character and character:FindFirstChild("HumanoidRootPart")
			if not part or not human or human.Health<=0 or human.FloorMaterial==Enum.Material.Air
				or human:GetState()==Enum.HumanoidStateType.Swimming or not player:GetAttribute("WildboundOpeningChoice") then continue end
			for id,name in pairs(ids)do
				local marker=root["00_Guides"]:FindFirstChild(name)
				if marker and Math.Contains(marker,part.Position) and player:GetAttribute("WB_RouteCheckpoint")~=id then
					if endpoint:Invoke(id,player) then player:SetAttribute("WB_RouteCheckpoint",id) end
				end
			end
		end
	end)
	Progress.Active={Connection=connection}
	return Progress.Active
end
return Progress
