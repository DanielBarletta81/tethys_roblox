local CollectionService = game:GetService("CollectionService")
local Rest = require(script.Parent.RestService)
local Context = {}
Context.__index = Context
local function contains(cf, size, position)
	local p = cf:PointToObjectSpace(position)
	return math.abs(p.X) <= size.X / 2 and math.abs(p.Y) <= size.Y / 2 and math.abs(p.Z) <= size.Z / 2
end
local function bounds(folder)
	local low, high = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, p in ipairs(folder:GetDescendants()) do
		if p:IsA("BasePart") then
			for _, x in ipairs({-1, 1}) do for _, y in ipairs({-1, 1}) do for _, z in ipairs({-1, 1}) do
				local v = p.CFrame:PointToWorldSpace(p.Size * Vector3.new(x, y, z) / 2)
				low, high = low:Min(v), high:Max(v)
			end end end
		end
	end
	if low.X == math.huge then return nil end
	return {CF = CFrame.new((low + high) / 2), Size = high - low + Vector3.new(4, 6, 4)}
end
function Context.new()
	local self = setmetatable({Safe = {}, Areas = {}}, Context)
	local root = workspace:FindFirstChild("WildboundOpening_Ordovic")
	if root then
		local cave = root:FindFirstChild("01_High_Cave")
		if cave then table.insert(self.Safe, bounds(cave)) end
		local zones = root:FindFirstChild("03_FlowZones")
		if zones then for _, p in ipairs(zones:GetChildren()) do
			if p:IsA("BasePart") then table.insert(self.Areas, {Part = p, Id = "Ordovic:" .. tostring(p:GetAttribute("PhaseName"))}) end
		end end
		local chamber = root:FindFirstChild("08_HiddenCaveVein")
		local guide = chamber and chamber:FindFirstChild("00_Guides")
		local box = guide and guide:FindFirstChild("GUIDE_CaveBounds")
		if box then table.insert(self.Areas, {Part = box, Id = "HiddenCaveChamber"}) end
	end
	local world = workspace:FindFirstChild("World")
	local sky = world and (world:FindFirstChild("Sky_City") or world)
	local network = sky and sky:FindFirstChild("09_CaveNetwork")
	local residences = network and network:FindFirstChild("06_PlayerResidences")
	local limbo = residences and residences:FindFirstChild("Limbo")
	local home = limbo and limbo:FindFirstChild("03_CommonArea")
	if home then table.insert(self.Safe, bounds(home)) end
	return self
end
function Context:Read(player, position)
	for _, zone in ipairs(self.Safe) do if contains(zone.CF, zone.Size, position) then return true end end
	for _, p in ipairs(CollectionService:GetTagged("WB_SafeZone")) do
		if p:IsA("BasePart") and p:IsDescendantOf(workspace) and contains(p.CFrame, p.Size, position) then return true end
	end
	if Rest.IsNearRest(player, position) then return true end
	for _, area in ipairs(self.Areas) do
		local p = area.Part
		if p:IsDescendantOf(workspace) and contains(p.CFrame, p.Size, position) then return false, area.Id end
	end
	for _, p in ipairs(CollectionService:GetTagged("WB_ExplorationArea")) do
		local id = p:GetAttribute("AreaId")
		if p:IsA("BasePart") and type(id) == "string" and #id <= 80 and p:IsDescendantOf(workspace)
			and contains(p.CFrame, p.Size, position) then return false, id end
	end
	return false
end
return Context
