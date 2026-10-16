local Math = require(script.Parent.FlowMath)
local Observations = {}
Observations.__index = Observations
function Observations.new(addition)
	local self = setmetatable({Root = addition, Seen = {}, Connections = {}}, Observations)
	for _, node in ipairs(addition:GetChildren()) do
		local prompt = node:FindFirstChild("Inspect")
		if prompt and prompt:IsA("ProximityPrompt") then
			table.insert(self.Connections, prompt.Triggered:Connect(function(player) self:Inspect(player, node, prompt) end))
		end
	end
	return self
end
function Observations:Inspect(player, node, prompt)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local human = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not human or human.Health <= 0 or node.Parent ~= self.Root
		or prompt.Parent ~= node or not prompt.Enabled or not Math.Contains(self.Root.CaveBounds, root.Position)
		or (root.Position - node.Position).Magnitude > prompt.MaxActivationDistance + 1 then return false end
	local ray = RaycastParams.new(); ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = {char, node}; ray.RespectCanCollide = true
	if workspace:Raycast(root.Position, node.Position-root.Position, ray) then return false end
	local id = node:GetAttribute("ObservationId")
	if type(id) ~= "string" then return false end
	local seen = self.Seen[player] or {}; self.Seen[player] = seen
	if seen[id] then return false end
	seen[id] = true
	-- The existing headless owner may cache sanitized CMS text on an explicitly
	-- mapped LoreId. This sandbox does not acquire Network capability.
	local cached = node:GetAttribute("LoreBodyText")
	local text = type(cached) == "string" and cached ~= "" and cached:sub(1,700) or node:GetAttribute("ObservationText")
	player:SetAttribute("WB_CaveObserved_" .. id, true)
	player:SetAttribute("WB_CaveObservationText", text)
	player:SetAttribute("OL_CineDuration", 4)
	player:SetAttribute("OL_CineSpeaker", "Observation")
	player:SetAttribute("OL_CineLine", text)
	player:SetAttribute("OL_CineTick", (player:GetAttribute("OL_CineTick") or 0) + 1)
	return true
end
function Observations:Forget(player) self.Seen[player] = nil end
function Observations:Stop()
	for _, connection in ipairs(self.Connections) do connection:Disconnect() end
	self.Connections = {}; self.Seen = {}
end
return Observations
