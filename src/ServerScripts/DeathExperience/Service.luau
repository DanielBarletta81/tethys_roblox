local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(script.Parent.Config)
local Ledger = require(script.Parent.Ledger)
local Context = require(script.Parent.WorldContext)
local Rest = require(script.Parent.RestService)
local Policy = require(script.Parent.Policy)
local Service = {States = {}}
local function sync(player, ledger)
	player:SetAttribute("WB_PlayerXP", ledger.XP)
	player:SetAttribute("WB_ExplorationDeathXP", ledger.DeathXP)
	player:SetAttribute("WB_PlayerLevel", Policy.Level(ledger.XP))
	player:SetAttribute("WB_ExperiencePersistence", "RuntimeOnly_SaveIntegrationRequired")
end
local function alive(player, state)
	return state and state.Character == player.Character and state.Humanoid and state.Humanoid.Health > 0
end
function Service.Record(player, kind, id)
	local state = Service.States[player]
	if not alive(player, state) or type(id) ~= "string" then return false end
	local recorded = state.Ledger:Record(state.Character, kind, id)
	if recorded then state.LastActive = os.clock() end
	return recorded
end
function Service.Hazard(player, id)
	local state = Service.States[player]
	if not alive(player, state) or type(id) ~= "string" or #id > 80 then return end
	state.LastHazard, state.HazardAt = id, os.clock()
	Service.Record(player, "Hazards", id)
end
local function bindCharacter(player, character)
	local state = Service.States[player]
	if state.Character == character then return end
	if state.Died then state.Died:Disconnect() end
	if state.Character then state.Ledger:Discard(state.Character) end
	state.Character, state.Humanoid, state.Root = character, nil, nil
	local h, root = character:WaitForChild("Humanoid", 10), character:WaitForChild("HumanoidRootPart", 10)
	if player.Character ~= character or not h or not root then return end
	state.Humanoid, state.Root = h, root
	state.LastPosition, state.LastSample, state.LastActive = root.Position, os.clock(), -math.huge
	state.LastHazard, state.HazardAt = nil, -math.huge
	state.Ledger:Begin(os.clock(), character)
	state.Died = h.Died:Once(function()
		if player.Character ~= character then return end
		Rest.MarkDeath(player)
		local signature = if os.clock() - state.HazardAt <= 20 then state.LastHazard else "Unspecified"
		local position = state.LastPosition
		local result = state.Ledger:Finish(character, os.clock(), signature, {X = position.X, Z = position.Z})
		if not result then return end
		sync(player, state.Ledger)
		player:SetAttribute("WB_DeathExperience", result.Amount)
		player:SetAttribute("WB_DeathExperienceReason", result.Reason)
		player:SetAttribute("WB_DeathExperienceLifeId", result.LifeId)
		-- Revision last: client reads one complete, server-authored batch.
		player:SetAttribute("WB_DeathExperienceRevision", result.LifeId)
	end)
end
local function bindPlayer(player)
	if Service.States[player] then return end
	local state = {Ledger = Ledger.new(), Connections = {}}
	Service.States[player] = state
	local function earnedXP()
		local value = player:GetAttribute("SC_XP")
		if type(value) == "number" then state.Ledger:SetEarnedXP(value) end
		sync(player, state.Ledger)
	end
	-- Existing living route/mission rewards count toward player experience. The
	-- death component never writes SC_XP or its legacy access gates.
	table.insert(state.Connections, player:GetAttributeChangedSignal("SC_XP"):Connect(earnedXP))
	earnedXP()
	sync(player, state.Ledger)
	table.insert(state.Connections, player.CharacterAdded:Connect(function(character) bindCharacter(player, character) end))
	table.insert(state.Connections, player.CharacterRemoving:Connect(function(character) state.Ledger:Discard(character) end))
	-- Only consume facts from the existing server knowledge owner. XP never writes these facts.
	local function watchObservations(folder)
		for _, node in ipairs(folder:GetChildren()) do
			if state.Ledger.EvidenceCount >= Config.MaxEvidence then break end
			state.Ledger.Evidence["Observations:Knowledge:" .. node.Name] = true
			state.Ledger.EvidenceCount += 1
		end
		table.insert(state.Connections, folder.ChildAdded:Connect(function(node)
			if node:IsA("StringValue") then Service.Record(player, "Observations", "Knowledge:" .. node.Name) end
		end))
	end
	local function watchSphere(sphere)
		local observations = sphere:FindFirstChild("Observations")
		if observations then watchObservations(observations) end
		table.insert(state.Connections, sphere.ChildAdded:Connect(function(folder) if folder.Name == "Observations" then watchObservations(folder) end end))
	end
	local sphere = player:FindFirstChild("PlayerSphere")
	if sphere then watchSphere(sphere) end
	table.insert(state.Connections, player.ChildAdded:Connect(function(folder) if folder.Name == "PlayerSphere" then watchSphere(folder) end end))
	for _, key in ipairs({"Return", "Break", "Hold", "Scour"}) do
		local attr = "WB_Knowledge_" .. key
		if player:GetAttribute(attr) == true then
			state.Ledger.Evidence["Observations:" .. attr] = true; state.Ledger.EvidenceCount += 1
		end
		table.insert(state.Connections, player:GetAttributeChangedSignal(attr):Connect(function()
			if player:GetAttribute(attr) == true then Service.Record(player, "Observations", attr) end
		end))
	end
	if player.Character then task.spawn(bindCharacter, player, player.Character) end
end
function Service.Start()
	if Service.Started then return Service end
	Service.Started = true
	local opening = game.ServerScriptService:FindFirstChild("OrdovicOpening")
	if opening then
		local endpoint = opening:FindFirstChild("BF_DeathExperience") or Instance.new("BindableFunction")
		endpoint.Name, endpoint.Parent = "BF_DeathExperience", opening
		endpoint.OnInvoke = function(action, player, first, second)
			if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then return false end
			if action == "RestReturn" then
				return first == player.Character and Rest.TryRespawn(player, first)
			elseif action == "Observation" then
				if first ~= "Observations" or type(second) ~= "string" or second:sub(1, 7) ~= "Cordge:" then return false end
				if player:GetAttribute("WB_Clue_" .. second:sub(8)) ~= true then return false end
				return Service.Record(player, first, second)
			elseif action == "Hazard" and first == "RapidsImpact" then
				Service.Hazard(player, first); return true
			end
			return false
		end
	end
	local context = Context.new()
	Players.PlayerAdded:Connect(bindPlayer)
	Players.PlayerRemoving:Connect(function(player)
		local state = Service.States[player]
		if state then
			for _, connection in ipairs(state.Connections) do connection:Disconnect() end
			if state.Died then state.Died:Disconnect() end
		end
		Service.States[player] = nil; Rest.Remove(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do bindPlayer(player) end
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < Config.SampleInterval then return end
		elapsed = 0
		for player, state in pairs(Service.States) do
			if not alive(player, state) or not state.Root or not state.Root.Parent then continue end
			local now, position = os.clock(), state.Root.Position
			local interval = now - state.LastSample
			local delta = position - state.LastPosition
			state.LastPosition, state.LastSample = position, now
			-- Rebase after pauses and teleports; neither counts as traveled ground.
			if interval > Config.MaxSampleSeconds or delta.Magnitude > Config.MaxSpeed * interval + 4 then continue end
			-- MoveDirection is local to the controlling simulation. The server measures
			-- plausible travel while running, climbing or swimming; freefall is not activity.
			local movement = state.Humanoid:GetState()
			local moving = movement == Enum.HumanoidStateType.Running or movement == Enum.HumanoidStateType.Climbing
				or movement == Enum.HumanoidStateType.Swimming
			if moving and Vector3.new(delta.X, 0, delta.Z).Magnitude >= 0.25 then state.LastActive = now end
			local safe, area = context:Read(player, position)
			if not safe and state.Humanoid:GetState() == Enum.HumanoidStateType.Swimming then Service.Hazard(player, "RiverCurrent") end
			local cell = math.floor(position.X / Config.CellSize) .. ":" .. math.floor(position.Z / Config.CellSize)
			if state.Ledger:Sample(state.Character, interval, Vector3.new(delta.X, 0, delta.Z).Magnitude,
				cell, safe, now - state.LastActive <= Config.ActivityGrace) and delta.Magnitude >= 0.25 and area then
				Service.Record(player, "Areas", area)
			end
		end
	end)
	return Service
end
return Service
