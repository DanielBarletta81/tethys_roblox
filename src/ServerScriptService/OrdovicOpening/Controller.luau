local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Flow = require(script.Parent.FlowService)
local Intake = require(script.Parent.IntakeService)
local Hazard = require(script.Parent.HazardService)
local Stryker = require(script.Parent.StrykerService)
local Checkpoint = require(script.Parent.CheckpointService)
local Rest = require(script.Parent.ExperienceBridge)
local Controller = {}
function Controller.CanLand(state, landing)
	local h = state.Humanoid
	local movement = h:GetState()
	return state.Choice == "DOWNSTREAM" and not state.Landed and h.Health > 0
		and (state.Root.Position - landing).Magnitude < 30 and math.abs(state.Root.Position.Y - landing.Y) < 5
		and h.FloorMaterial ~= Enum.Material.Air
		and movement ~= Enum.HumanoidStateType.Swimming and movement ~= Enum.HumanoidStateType.Freefall
end
function Controller.Start(root)
	assert(root:GetAttribute("BuildReady") and root:GetAttribute("OpeningEnabled"), "Opening not ready")
	local flow, intake, stryker = Flow.new(root), Intake.new(root), Stryker.new(root)
	local states, byCharacter = {}, {}
	local spawn = root["01_High_Cave"]["04_Collision"].Spawn_OrdovicCave
	local landing = root["00_Guides"].GUIDE_WatcherLanding.Position
	local function cleanup(player)
		local state = states[player]
		if not state then return end
		flow:Clear(state); intake:Release(state)
		if state.HealthConnection then state.HealthConnection:Disconnect() end
		byCharacter[state.Character], states[player] = nil, nil
		player:SetAttribute("WB_IntakeCaptured", false)
		player:SetAttribute("WB_CascadeSurvivalFloor", false)
	end
	local function characterAdded(player, character)
		cleanup(player)
		local humanoid = character:WaitForChild("Humanoid", 10)
		local part = character:WaitForChild("HumanoidRootPart", 10)
		if not humanoid or not part or player.Character ~= character then return end
		local choice = player:GetAttribute("WildboundOpeningChoice")
		local state = {Player = player, Character = character, Humanoid = humanoid, Root = part, Choice = choice}
		states[player], byCharacter[character] = state, state
		player:SetAttribute("WB_OpeningInjured", false)
		if Rest.TryRespawn(player, character) then
			state.Landed = true; player:SetAttribute("WB_OrdovicActive", false)
			player:SetAttribute("OpeningPhase", "FIELDHOLD_RETURN")
		elseif choice == "CITY" then
			state.Landed = true; player:SetAttribute("WB_OrdovicActive", false)
			player:SetAttribute("OpeningPhase", "INTAKE_WORKS")
			character:PivotTo(CFrame.new(intake.Landing))
		elseif choice == "DOWNSTREAM" then
			player:SetAttribute("WB_OrdovicActive", true)
			local position, completed = Checkpoint.RefusalSpawn(root, player)
			character:PivotTo(CFrame.new(position))
			if completed then Hazard.Land(state) else
				player:SetAttribute("OpeningPhase", "REJECT_CASCADE")
				player:SetAttribute("WB_CascadeSurvivalFloor", true)
			end
		else
			player:SetAttribute("WB_OrdovicActive", true)
			player:SetAttribute("OpeningPhase", "CAVE_WAKE")
			player:SetAttribute("WB_StrykerFirstPass", false)
			local wake = spawn.Position + Vector3.new(0, 4, 0)
			character:PivotTo(CFrame.lookAt(wake, wake + Vector3.new(0, 0, 1)))
		end
		state.HealthConnection = humanoid.HealthChanged:Connect(function(health)
			if state.Choice == "DOWNSTREAM" and not state.Landed and health > 0 and health < humanoid.MaxHealth * 0.25 then
				humanoid.Health = humanoid.MaxHealth * 0.25
			end
		end)
		humanoid.Died:Once(function() cleanup(player) end)
	end
	local function playerAdded(player)
		player.RespawnLocation = spawn
		player:SetAttribute("WB_OrdovicActive", true)
		player:SetAttribute("OL_IntroSpawnDone", false)
		player:SetAttribute("OpeningBuildId", root:GetAttribute("BuildId"))
		player.CharacterAdded:Connect(function(character) characterAdded(player, character) end)
		if player.Character then task.spawn(characterAdded, player, player.Character) end
	end
	local works = root["06_IntakeWorks"]
	for name, choice in pairs({Prompt_TakeLine = "CITY", Prompt_BreakFree = "DOWNSTREAM"}) do
		local prompt = works[name].ProximityPrompt
		prompt.Triggered:Connect(function(player)
			local state = states[player]
			if intake:Choose(state, choice, prompt) then
				flow:Clear(state)
			end
		end)
	end
	Hazard.new(root, function(character) return byCharacter[character] end)
	RunService.Heartbeat:Connect(function()
		for player, state in pairs(states) do
			if state.Root.Parent and state.Humanoid.Health > 0 and not state.Landed then
				local phase = flow:Step(state)
				if phase and not state.Captured then
					player:SetAttribute("OpeningPhase", phase)
					if phase == "STRYKER_SHADOW" then stryker:Trigger(state) end
				end
				if not state.Choice and intake:Capture(state) then flow:Clear(state) end
				if Controller.CanLand(state, landing) then
					if Hazard.Land(state) then flow:Clear(state) end
				end
				Checkpoint.Update(root, state)
			end
		end
	end)
	Players.PlayerAdded:Connect(playerAdded)
	Players.PlayerRemoving:Connect(cleanup)
	for _, player in ipairs(Players:GetPlayers()) do playerAdded(player) end
	return {States = states, Flow = flow, Intake = intake}
end
return Controller
