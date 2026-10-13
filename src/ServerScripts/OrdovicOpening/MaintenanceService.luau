local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Maintenance={}
function Maintenance.Start(root)
	local station=root["10_RouteConnections"].FirstSortMaintenance
	local marker=station.ClearScreen
	local prompt=marker.Clear
	local starts={}
	local function valid(player)
		local character=player.Character
		local human=character and character:FindFirstChildOfClass("Humanoid")
		local part=character and character:FindFirstChild("HumanoidRootPart")
		if not prompt.Enabled or station:GetAttribute("Cleared") or not human or human.Health<=0
			or not part or (part.Position-marker.Position).Magnitude>prompt.MaxActivationDistance+1 then return false end
		local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Exclude
		ray.FilterDescendantsInstances={character,marker};ray.RespectCanCollide=true
		return workspace:Raycast(part.Position,marker.Position-part.Position,ray)==nil
	end
	prompt.PromptButtonHoldBegan:Connect(function(player)
		if valid(player) then starts[player]={At=os.clock(),Character=player.Character} end
	end)
	prompt.Triggered:Connect(function(player)
		local held=starts[player];starts[player]=nil
		if not held or held.Character~=player.Character or os.clock()-held.At<prompt.HoldDuration-0.05
			or held.Ended and os.clock()-held.Ended>0.3 or not valid(player) then return end
		station:SetAttribute("Cleared",true);station:SetAttribute("ClearedBy",player.UserId)
		station.ScreenDebris.Transparency=1;prompt.Enabled=false
		-- Graybox current response. This is not a hydraulic simulation.
		for _,zone in ipairs(root["03_FlowZones"]:GetChildren())do
			if zone.Name:match("^FZBypass_") then zone:SetAttribute("FlowSpeed",12) end
		end
		player:SetAttribute("WB_FirstSortCleared",true)
		player:SetAttribute("WB_LastMaintenanceAction","FirstSort_Clear")
	end)
	prompt.PromptButtonHoldEnded:Connect(function(player)
		local held=starts[player]
		if held and os.clock()-held.At<prompt.HoldDuration-0.05 then starts[player]=nil end
		if held then held.Ended=os.clock() end
	end)
	local elapsed=0
	RunService.Heartbeat:Connect(function(dt)
		elapsed+=dt;if elapsed<0.1 then return end;elapsed=0
		for player,held in pairs(starts)do
			if not valid(player) or held.Ended and os.clock()-held.Ended>0.3
				or os.clock()-held.At>prompt.HoldDuration+2 then starts[player]=nil end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)starts[player]=nil end)
	return {Valid=valid,Starts=starts,Station=station}
end
return Maintenance
