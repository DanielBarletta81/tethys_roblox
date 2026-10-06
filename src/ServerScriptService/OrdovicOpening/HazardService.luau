local Hazard = {}
Hazard.__index = Hazard
function Hazard.new(root, getState)
	local self = setmetatable({Connections = {}}, Hazard)
	for _, obstacle in ipairs(root["05_RapidsObstacles"]:GetChildren()) do
		table.insert(self.Connections, obstacle.Touched:Connect(function(hit)
			local character = hit:FindFirstAncestorOfClass("Model")
			local state = getState(character)
			if not state or state.Captured or state.Landed or state.Humanoid.Health <= 0 then return end
			local speed = state.Root.AssemblyLinearVelocity.Magnitude
			if speed < obstacle:GetAttribute("MinSpeed") or os.clock() - (state.LastImpact or -10) < 1.6 then return end
			state.LastImpact = os.clock()
			state.Humanoid:TakeDamage(obstacle:GetAttribute("Damage"))
			local away = state.Root.Position - obstacle.Position
			if away.Magnitude > 0.1 then state.Root:ApplyImpulse(away.Unit * state.Root.AssemblyMass * 6) end
		end))
	end
	return self
end
function Hazard.ClampAlive(humanoid, desired)
	-- Never resurrect a dead character, and never heal to the landing target.
	if humanoid.Health <= 0 then return false end
	humanoid.Health = math.min(humanoid.Health, humanoid.MaxHealth * desired)
	return true
end
function Hazard.Land(state)
	if state.Landed or not Hazard.ClampAlive(state.Humanoid, 0.4) then return false end
	state.Landed = true
	state.Player:SetAttribute("WB_CascadeSurvivalFloor", false)
	state.Player:SetAttribute("OpeningPhase", "WATCHER_SURVIVAL")
	state.Player:SetAttribute("WB_OpeningInjured", true)
	state.Player:SetAttribute("WB_OrdovicCascadeComplete", true)
	local previous = state.Humanoid.WalkSpeed
	state.Humanoid.WalkSpeed = 9
	task.delay(25, function()
		if state.Humanoid.Parent and state.Humanoid.Health > 0 and state.Humanoid.WalkSpeed == 9 then
			state.Humanoid.WalkSpeed = previous
		end
		if state.Player.Parent and state.Player.Character == state.Character then state.Player:SetAttribute("WB_OpeningInjured", false) end
	end)
	return true
end
return Hazard
