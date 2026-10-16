local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Flow = require(script.Parent.FlowService)
local Math = require(script.Parent.FlowMath)
local Intake = require(script.Parent.IntakeService)
local Hazard = require(script.Parent.HazardService)
local Checkpoint = require(script.Parent.CheckpointService)
local Stryker = require(script.Parent.StrykerService)
local Observations = require(script.Parent.CaveObservations)
local Backend = require(script.Parent.BackendBridge)
local Experience = require(script.Parent.ExperienceBridge)
local Controller = {}

function Controller.Start(root)
	if Controller.Active then return Controller.Active end
	assert(root:GetAttribute("CaveOpenerReady") and root:GetAttribute("OpeningEnabled"), "Cave opener not ready")
	local flow, intake, stryker = Flow.new(root), Intake.new(root), Stryker.new(root)
	local addition = root["01_High_Cave"].CaveExpansion
	local observations, backend = Observations.new(addition), Backend.new(root)
	local states, byCharacter, connections = {}, {}, {}
	local spawn = root["01_High_Cave"]["04_Collision"].Spawn_OrdovicCave
	local function cleanup(player)
		local state = states[player]
		if not state then return end
		flow:Clear(state); intake:Release(state)
		if state.Death then state.Death:Disconnect() end
		if state.HealthConnection then state.HealthConnection:Disconnect() end
		byCharacter[state.Character], states[player] = nil, nil
		player:SetAttribute("WB_IntakeCaptured", false)
		player:SetAttribute("WB_CaveInside", false)
		player:SetAttribute("WB_FlumeActive", false)
		player:SetAttribute("WB_CascadeSurvivalFloor", false)
	end
	local function characterAdded(player, character)
		cleanup(player)
		local h = character:WaitForChild("Humanoid", 10)
		local part = character:WaitForChild("HumanoidRootPart", 10)
		if not h or not part or player.Character ~= character then return end
		local state = {Player = player, Character = character, Humanoid = h, Root = part,
			Choice = player:GetAttribute("WildboundOpeningChoice")}
		states[player], byCharacter[character] = state, state
		player:SetAttribute("WB_OrdovicActive", true)
		player:SetAttribute("WB_StrykerFirstPass", false)
		player:SetAttribute("WB_StrykerBeatStart", nil)
		player:SetAttribute("WB_StrykerCrashSeen", false)
		if Experience.TryRespawn(player, character) then
			state.Landed = true; player:SetAttribute("WB_OrdovicActive", false)
		elseif state.Choice == "CITY" then
			state.Landed = true; character:PivotTo(CFrame.new(intake.Landing))
			player:SetAttribute("WB_OrdovicActive", false); player:SetAttribute("OpeningPhase", "INTAKE_WORKS")
		elseif state.Choice == "DOWNSTREAM" then
			local position, completed = Checkpoint.RefusalSpawn(root, player)
			character:PivotTo(CFrame.new(position))
			if completed then Hazard.Land(state) end
			player:SetAttribute("WB_CascadeSurvivalFloor", not completed)
			player:SetAttribute("OpeningPhase", completed and "WATCHER_SURVIVAL" or "REJECT_CASCADE")
		else
			local wake = spawn.Position + Vector3.new(0, 4, 0)
			character:PivotTo(CFrame.lookAt(wake, addition.ExitBrow.Position))
			player:SetAttribute("OpeningPhase", "CAVE_WAKE")
		end
		part.AssemblyLinearVelocity = Vector3.zero
		state.HealthConnection = h.HealthChanged:Connect(function(health)
			if state.Choice == "DOWNSTREAM" and not state.Landed and health > 0 and health < h.MaxHealth * 0.25 then
				h.Health = h.MaxHealth * 0.25
			end
		end)
		state.Death = h.Died:Connect(function() cleanup(player) end)
	end
	local function playerAdded(player)
		player.RespawnLocation = spawn -- existing spawn, unchanged transform
		table.insert(connections, player.CharacterAdded:Connect(function(character) characterAdded(player, character) end))
		table.insert(connections, player.CharacterRemoving:Connect(function() cleanup(player) end))
		if player.Character then task.spawn(characterAdded, player, player.Character) end
	end
	for name, choice in pairs({Prompt_TakeLine = "CITY", Prompt_BreakFree = "DOWNSTREAM"}) do
		local prompt = root["06_IntakeWorks"][name].ProximityPrompt
		table.insert(connections, prompt.Triggered:Connect(function(player)
			local state = states[player]
			if state and state.Character == player.Character and intake:Choose(state, choice, prompt) then flow:Clear(state) end
		end))
	end
	local hazards = Hazard.new(root, function(character) return byCharacter[character] end)
	table.insert(connections, Run.Heartbeat:Connect(function()
		if not root.Parent or not root:GetAttribute("OpeningEnabled") then
			for player in pairs(states) do cleanup(player) end
			return
		end
		for player, state in pairs(states) do
			if state.Character ~= player.Character or not state.Root.Parent or state.Humanoid.Health <= 0 then cleanup(player); continue end
			local inside = Math.Contains(addition.CaveBounds, state.Root.Position)
			if player:GetAttribute("WB_CaveInside") ~= inside then player:SetAttribute("WB_CaveInside", inside) end
			if state.Landed then continue end
			local phase = flow:Step(state)
			local sliding = phase == "FLUME_DROP"
			if player:GetAttribute("WB_FlumeActive") ~= sliding then player:SetAttribute("WB_FlumeActive", sliding) end
			if phase and not state.Captured then
				player:SetAttribute("OpeningPhase", phase)
				if phase == "STRYKER_SHADOW" then stryker:Trigger(state) end
				if phase ~= "FLUME_DROP" and not state.RiverReported then
					state.RiverReported = true; backend:Zone(player, "Ordovic_Rapids")
				end
			end
			if not state.Choice and intake:Capture(state) then flow:Clear(state) end
			local landing = root["00_Guides"].GUIDE_WatcherLanding.Position
			if state.Choice == "DOWNSTREAM" and (state.Root.Position - landing).Magnitude < 30
				and math.abs(state.Root.Position.Y-landing.Y) < 5 and state.Humanoid.FloorMaterial ~= Enum.Material.Air
				and state.Humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then
				if Hazard.Land(state) then flow:Clear(state) end
			end
			Checkpoint.Update(root, state)
		end
	end))
	table.insert(connections, Players.PlayerAdded:Connect(playerAdded))
	table.insert(connections, Players.PlayerRemoving:Connect(function(player)
		cleanup(player); observations:Forget(player); backend:Forget(player)
	end))
	for _, player in ipairs(Players:GetPlayers()) do playerAdded(player) end
	Controller.Active = {States = states, Flow = flow, Intake = intake, Observations = observations, Stop = function()
		for _, c in ipairs(connections) do c:Disconnect() end
		for _, c in ipairs(hazards.Connections) do c:Disconnect() end
		for player in pairs(states) do cleanup(player) end
		observations:Stop(); Controller.Active = nil
	end}
	return Controller.Active
end
return Controller
