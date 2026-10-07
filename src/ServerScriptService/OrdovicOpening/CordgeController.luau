local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Math = require(script.Parent.FlowMath)
local Dialogue = require(script.Parent.CordgeDialogue)
local Policy = require(script.Parent.CordgePolicy)
local Experience = require(script.Parent.ExperienceBridge)
local Cordge = {}
function Cordge.Start(cave)
	assert(cave:GetAttribute("BuildReady"), "Cave slice is not ready")
	if Cordge.Active then
		assert(Cordge.Active.Cave == cave, "Cordge is already bound to another cave")
		return Cordge.Active
	end
	local actor, bounds = cave.Cordge, cave["00_Guides"].GUIDE_CaveBounds
	local states, connections = {}, {}
	local function stateFor(player)
		if not states[player] then states[player] = {Seen = {}, LastPlayed = {}, Clues = {}, Revision = 0} end
		return states[player]
	end
	local function publish(player, state, id, text)
		state.Revision += 1
		player:SetAttribute("WB_CordgeLineId", id)
		player:SetAttribute("WB_CordgeSpeechText", text or "")
		player:SetAttribute("WB_CordgeSpeechRevision", state.Revision)
	end
	local function clear(player, state)
		if state.Current then state.Current = nil; publish(player, state, nil, "") end
	end
	local function inspect(player, marker, prompt)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local id = marker:GetAttribute("ClueId")
		if not marker:IsDescendantOf(cave) or not prompt.Enabled or type(id) ~= "string" then return false end
		if not root or not humanoid or humanoid.Health <= 0 or (root.Position - marker.Position).Magnitude > prompt.MaxActivationDistance + 1 then return false end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {character, actor, cave["00_Guides"], cave["06_Triggers"]}
		params.RespectCanCollide = true
		if workspace:Raycast(root.Position, marker.Position - root.Position, params) then return false end
		local state = stateFor(player)
		if state.Clues[id] then return false end
		state.Clues[id] = true
		player:SetAttribute("WB_Clue_" .. id, true)
		player:SetAttribute("WB_LastClueId", id)
		player:SetAttribute("WB_CaveObservationText", marker:GetAttribute("ObservationText"))
		Experience.Record(player, "Observations", "Cordge:" .. id)
		return true
	end
	for _, marker in ipairs(cave["00_Guides"]:GetChildren()) do
		local prompt = marker:FindFirstChild("Inspect")
		if prompt then table.insert(connections, prompt.Triggered:Connect(function(player)
			inspect(player, marker, prompt)
		end)) end
	end
	local accumulated = 0
	table.insert(connections, RunService.Heartbeat:Connect(function(dt)
		accumulated += dt; if accumulated < 0.15 then return end; accumulated = 0
		local now = os.clock()
		for _, player in ipairs(Players:GetPlayers()) do
			local state = stateFor(player)
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local alive = humanoid and humanoid.Health > 0
			local present = alive and root and actor.Parent and actor:GetAttribute("WB_CordgeEnabled") ~= false
				and Math.Contains(bounds, root.Position) and (root.Position - actor:GetPivot().Position).Magnitude < 90 or false
			if player:GetAttribute("WB_CordgePresent") ~= present then player:SetAttribute("WB_CordgePresent", present) end
			if not present then clear(player, state); continue end
			if state.Current and now >= state.Current.Expires then clear(player, state) end
			local candidates = {}
			for _, zone in ipairs(cave["06_Triggers"]:GetChildren()) do
				if zone:IsA("BasePart") and Math.Contains(zone, root.Position) then
					local id = zone:GetAttribute("DialogueId")
					local definition = Dialogue[id]
					local trigger = zone:GetAttributes()
					if Policy.CanSpeak(state, id, definition, trigger, state.Clues, now, present, alive) then
						table.insert(candidates, {Id = id, Definition = definition, Priority = trigger.Priority or definition.Priority})
					end
				end
			end
			table.sort(candidates, function(a, b) if a.Priority == b.Priority then return a.Id < b.Id end; return a.Priority > b.Priority end)
			local choice = candidates[1]
			if choice then
				Policy.Begin(state, choice.Id, choice.Definition, choice.Priority, now)
				player:SetAttribute("WB_CordgeSeen_" .. choice.Id, true)
				publish(player, state, choice.Id, choice.Definition.Text)
			end
		end
	end))
	table.insert(connections, Players.PlayerRemoving:Connect(function(player) states[player] = nil end))
	Cordge.Active = {Cave = cave, States = states, Inspect = inspect, Stop = function()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		for player, state in pairs(states) do if player.Parent then clear(player, state); player:SetAttribute("WB_CordgePresent", false) end end
		Cordge.Active = nil
	end}
	return Cordge.Active
end
return Cordge
