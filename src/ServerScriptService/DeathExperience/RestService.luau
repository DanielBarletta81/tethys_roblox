-- Server-only Rest registry. Registration never grants immunity or changes the world.
local Rest = {}
local sites, claims, pending = {}, {}, {}

function Rest.Register(site, id)
	assert(site:IsA("Folder") and type(id) == "string" and #id <= 96)
	sites[site] = id
end
function Rest.Unregister(site) sites[site] = nil end
function Rest.InRange(player, anchor, range)
	local character = player.Character
	local h = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not h or h.Health <= 0 or not root or not anchor:IsDescendantOf(workspace)
		or (root.Position - anchor.Position).Magnitude > range then return false end
	local params = RaycastParams.new()
	params.RespectCanCollide = true
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	local direction = anchor.Position - root.Position
	local hit = workspace:Raycast(root.Position, direction, params)
	return not hit or hit.Instance == anchor or hit.Instance:IsDescendantOf(anchor.Parent)
end
local function part(site, model, name)
	local parent = site:FindFirstChild("Built_" .. model)
	local value = parent and parent:FindFirstChild(name)
	return value and value:IsA("BasePart") and value.Anchored and value.CanQuery
		and (value:GetAttribute("WB_Condition") or 1) > 0 and value or nil
end
function Rest.CanUse(site, player)
	if not sites[site] or not site:IsDescendantOf(workspace) then return false, "Rest is no longer here." end
	local owner = site:GetAttribute("OwnerUserId")
	if player and owner and owner ~= player.UserId then return false, "This is another traveler's Rest." end
	local sleep, roof = part(site, "RestSpot", "SleepPlatform"), part(site, "Shelter", "Cover")
	local basin, heat = part(site, "WaterBasin", "Basin"), part(site, "HeatPit", "Heat")
	if not sleep or not sleep.CanCollide or not roof then return false, "Covered sleep is needed." end
	if not basin or (basin:GetAttribute("StoredWater") or 0) <= 0 then return false, "Store water before settling here." end
	if not heat or (heat:GetAttribute("WarmUntil") or 0) <= os.clock() then return false, "The heat needs fuel." end
	for _, name in ipairs({"Storage", "Boundary"}) do
		if not site:FindFirstChild("Built_" .. name) then return false, "Finish the camp's storage and boundary." end
	end
	local supportParams = RaycastParams.new()
	supportParams.FilterType, supportParams.RespectCanCollide = Enum.RaycastFilterType.Exclude, true
	local exclude = {site}
	for _, traveler in ipairs(game.Players:GetPlayers()) do if traveler.Character then table.insert(exclude, traveler.Character) end end
	supportParams.FilterDescendantsInstances = exclude
	for _, offset in ipairs({Vector3.zero, Vector3.new(1.4, 0, 2), Vector3.new(-1.4, 0, -2)}) do
		local hit = workspace:Raycast(sleep.Position + offset + Vector3.new(0, 0.5, 0), Vector3.new(0, -3, 0), supportParams)
		if not hit or hit.Material == Enum.Material.Water or hit.Normal.Y < 0.8 then return false, "The sleeping place needs stable ground support." end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {site.Built_Shelter}
	for _, offset in ipairs({Vector3.zero, Vector3.new(1.4, 0, 2), Vector3.new(-1.4, 0, -2)}) do
		local hit = workspace:Raycast(sleep.Position + offset + Vector3.new(0, 0.3, 0), Vector3.new(0, 12, 0), params)
		if not hit or hit.Instance ~= roof or hit.Distance < 5.5 then return false, "The sleeping place needs usable cover." end
	end
	return true, sleep
end
function Rest.Claim(player, site)
	local valid, sleep = Rest.CanUse(site, player)
	if not valid then return false, sleep end
	if not Rest.InRange(player, sleep, 10) then return false, "Move close enough to settle here." end
	claims[player] = site
	player:SetAttribute("WB_ActiveRestId", sites[site])
	player:SetAttribute("WB_RestPersistence", "RuntimeOnly_SaveIntegrationRequired")
	return true
end
function Rest.MarkDeath(player) pending[player] = true end
function Rest.TryRespawn(player, character)
	if player.Character ~= character then return false end
	if not pending[player] then return false end
	pending[player] = nil
	local site = claims[player]
	if not site then return false end
	local valid, sleep = Rest.CanUse(site, player)
	local h, root = character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("HumanoidRootPart")
	if not valid or not h or h.Health <= 0 or not root then
		player:SetAttribute("WB_RestReturn", "Fallback")
		return false
	end
	character:PivotTo(sleep.CFrame + Vector3.new(0, sleep.Size.Y / 2 + h.HipHeight + root.Size.Y / 2 + 0.2, 0))
	root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	player:SetAttribute("WB_RestReturn", sites[site])
	return true
end
function Rest.IsNearRest(player, position)
	local site = claims[player]
	if not site then return false end
	local valid, sleep = Rest.CanUse(site, player)
	return valid == true and (position - sleep.Position).Magnitude <= 12
end
function Rest.Remove(player) claims[player], pending[player] = nil, nil end
return Rest
