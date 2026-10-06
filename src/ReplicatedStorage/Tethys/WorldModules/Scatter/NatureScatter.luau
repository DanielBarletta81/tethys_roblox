-- Edit-time generation only. Each named pass owns one folder in Workspace.Generated.
local RunService = game:GetService("RunService")
local Config = require(script.Parent.ScatterConfig)
local Placement = require(script.Parent.AssetPlacement)
local NatureScatter = {}
local OWNER_ATTRIBUTE = "TethysNatureScatterVersion"
local busy = {}

local function editOnly()
	assert(RunService:IsStudio() and not RunService:IsRunning(), "Nature Scatter must run in Studio edit mode")
end

local function numberInRange(value, name, low, high)
	assert(type(value) == "number" and value == value and value >= low and value <= high, name .. " is out of range")
	return value
end

local function passName(name)
	assert(type(name) == "string" and #name <= 100 and name:match("^GEN_[%w_%-]+$"), "PassName must start with GEN_ and use letters, digits, underscores or hyphens")
	return name
end

local function generatedRoot(create)
	local root = workspace:FindFirstChild("Generated")
	assert(not root or root:IsA("Folder"), "Workspace.Generated must be a Folder")
	if not root and create then
		root = Instance.new("Folder")
		root.Name = "Generated"
		root.Parent = workspace
	end
	return root
end

local function previousPass(name)
	local root = generatedRoot(false)
	local previous = root and root:FindFirstChild(name)
	assert(not previous or (previous:IsA("Folder") and previous:GetAttribute(OWNER_ATTRIBUTE) == 1 and previous:GetAttribute("Generator") == "NatureScatter" and previous:GetAttribute("PassId") == name), "Refusing to replace content not owned by Nature Scatter: " .. name)
	return previous
end

local function settings(options)
	assert(type(options) == "table", "Provide a scatter options table")
	local category = Config.Categories[options.Category]
	assert(category, "Category must be Trees, Rocks, Understory or GroundCover")
	local zone = options.Zone
	assert(typeof(zone) == "Instance" and zone:IsA("BasePart") and zone:IsDescendantOf(workspace), "Zone must be a BasePart in Workspace")
	assert(zone.CFrame.UpVector:Dot(Vector3.yAxis) > 0.99999, "Zone must be upright; Y rotation is supported")
	local result = { Zone = zone, Category = options.Category, SourceFolder = options.SourceFolder }
	for key, value in pairs(Config.Defaults) do result[key] = value end
	for key, value in pairs(category) do result[key] = value end
	for key, value in pairs(options) do result[key] = value end
	result.PassName = passName(result.PassName)
	result.Biome = result.Biome or "Unassigned"
	assert(type(result.Biome) == "string" and #result.Biome > 0 and #result.Biome <= 100, "Biome must be a nonempty label")
	numberInRange(result.Seed, "Seed", -2147483648, 2147483647)
	assert(result.Seed % 1 == 0, "Seed must be an integer")
	numberInRange(result.Count, "Count", 1, 10000)
	assert(result.Count % 1 == 0, "Count must be an integer")
	numberInRange(result.MinScale, "MinScale", 0.01, 100)
	numberInRange(result.MaxScale, "MaxScale", result.MinScale, 100)
	result.MinSlopeDegrees = result.MinSlopeDegrees or 0
	numberInRange(result.MinSlopeDegrees, "MinSlopeDegrees", 0, 90)
	numberInRange(result.MaxSlopeDegrees, "MaxSlopeDegrees", result.MinSlopeDegrees, 90)
	numberInRange(result.MinSpacing, "MinSpacing", 0, 10000)
	assert(type(result.UseAssetFootprints) == "boolean", "UseAssetFootprints must be a boolean")
	numberInRange(result.GroundOffset, "GroundOffset", -1000, 1000)
	numberInRange(result.RaycastPadding, "RaycastPadding", 0.01, 1000)
	numberInRange(result.AttemptsPerPlacement, "AttemptsPerPlacement", 1, 100)
	result.MaxAttempts = result.MaxAttempts or math.ceil(result.Count * result.AttemptsPerPlacement)
	numberInRange(result.MaxAttempts, "MaxAttempts", 1, 120000)
	assert(result.MaxAttempts % 1 == 0, "MaxAttempts must be an integer")
	result.SurfaceRoots = result.SurfaceRoots or { workspace.Terrain }
	assert(type(result.SurfaceRoots) == "table" and #result.SurfaceRoots > 0, "SurfaceRoots must be a nonempty array")
	for _, surface in ipairs(result.SurfaceRoots) do
		assert(typeof(surface) == "Instance" and surface:IsDescendantOf(workspace), "SurfaceRoots must contain Workspace instances")
		assert(surface == workspace.Terrain or surface:IsA("BasePart") or surface:IsA("Model") or surface:IsA("Folder"), "Unsupported surface root")
		local root = generatedRoot(false)
		assert(not root or (surface ~= root and not root:IsDescendantOf(surface)), "SurfaceRoots cannot include all Generated content")
	end
	return result
end

local function spaced(position, spacing, radius, cellSize, grid)
	if cellSize == 0 then return true end
	local x, z = math.floor(position.X / cellSize), math.floor(position.Z / cellSize)
	for dx = -1, 1 do
		for dz = -1, 1 do
			for _, other in ipairs(grid[(x + dx) .. ":" .. (z + dz)] or {}) do
				local delta = position - other.Position
				local required = math.max(spacing, radius + other.Radius)
				if delta.X * delta.X + delta.Z * delta.Z < required * required then return false end
			end
		end
	end
	return true
end

local function remember(position, radius, cellSize, grid)
	if cellSize == 0 then return end
	local key = math.floor(position.X / cellSize) .. ":" .. math.floor(position.Z / cellSize)
	grid[key] = grid[key] or {}
	table.insert(grid[key], { Position = position, Radius = radius })
end

function NatureScatter.Generate(options)
	editOnly()
	local cfg = settings(options)
	assert(not busy[cfg.PassName], "Pass is already generating: " .. cfg.PassName)
	previousPass(cfg.PassName)
	local assets = Placement.Collect(cfg.SourceFolder, cfg.Category)
	local cellSize = cfg.MinSpacing
	if cfg.UseAssetFootprints then
		for _, asset in ipairs(assets) do cellSize = math.max(cellSize, 2 * asset.Radius * cfg.MaxScale) end
	end
	local zoneCF, zoneSize = cfg.Zone.CFrame, cfg.Zone.Size
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = cfg.SurfaceRoots
	-- Water must be hit and rejected, rather than silently planting on the bed below it.
	params.IgnoreWater = false
	params.RespectCanCollide = false
	local random, grid = Random.new(cfg.Seed), {}
	local stage = Instance.new("Folder")
	stage.Name = cfg.PassName
	stage:SetAttribute(OWNER_ATTRIBUTE, 1)
	stage:SetAttribute("Generator", "NatureScatter")
	stage:SetAttribute("PassId", cfg.PassName)
	stage:SetAttribute("Biome", cfg.Biome)
	stage:SetAttribute("Seed", cfg.Seed)
	stage:SetAttribute("Category", cfg.Category)
	stage:SetAttribute("ZonePath", cfg.Zone:GetFullName())
	stage:SetAttribute("RequestedCount", cfg.Count)
	local stats = { Requested = cfg.Count, Placed = 0, Attempts = 0, NoSurface = 0, Water = 0, OutsideZone = 0, Slope = 0, Spacing = 0 }
	busy[cfg.PassName] = true
	local ok, err = pcall(function()
		for attempt = 1, cfg.MaxAttempts do
			if stats.Placed >= cfg.Count then break end
			stats.Attempts = attempt
			local x = random:NextNumber(-zoneSize.X / 2, zoneSize.X / 2)
			local z = random:NextNumber(-zoneSize.Z / 2, zoneSize.Z / 2)
			local asset = assets[random:NextInteger(1, #assets)]
			local scale = random:NextNumber(cfg.MinScale, cfg.MaxScale)
			local radius = cfg.UseAssetFootprints and asset.Radius * scale or 0
			local yaw = random:NextNumber(0, 2 * math.pi)
			local origin = zoneCF:PointToWorldSpace(Vector3.new(x, zoneSize.Y / 2 + cfg.RaycastPadding, z))
			local hit = workspace:Raycast(origin, Vector3.new(0, -zoneSize.Y - 2 * cfg.RaycastPadding, 0), params)
			local reason
			if not hit then
				reason = "NoSurface"
			elseif hit.Material == Enum.Material.Water then
				reason = "Water"
			elseif math.abs(zoneCF:PointToObjectSpace(hit.Position).Y) > zoneSize.Y / 2 + 0.01 then
				reason = "OutsideZone"
			else
				local slope = math.deg(math.acos(math.clamp(hit.Normal:Dot(Vector3.yAxis), -1, 1)))
				if slope < cfg.MinSlopeDegrees or slope > cfg.MaxSlopeDegrees then
					reason = "Slope"
				elseif not spaced(hit.Position, cfg.MinSpacing, radius, cellSize, grid) then
					reason = "Spacing"
				end
			end
			if reason then
				stats[reason] += 1
			else
				local item = Placement.Place(asset, hit.Position, yaw, scale, cfg.GroundOffset, stage)
				stats.Placed += 1
				item:SetAttribute("ScatterIndex", stats.Placed)
				item:SetAttribute("ScatterPosition", hit.Position)
				item:SetAttribute("ScatterFootprintRadius", radius)
				remember(hit.Position, radius, cellSize, grid)
			end
			if attempt % 250 == 0 then task.wait() end
		end
		assert(stats.Placed > 0, "No valid placements; previous pass preserved. Check zone height, surfaces and slope settings")
		-- Only replace the old pass after a complete successful build.
		local previous = previousPass(cfg.PassName)
		stage:SetAttribute("PlacedCount", stats.Placed)
		stage:SetAttribute("Attempts", stats.Attempts)
		stage.Parent = generatedRoot(true)
		-- Destroy locks descendants' Parent properties and breaks Studio undo.
		-- Detach instead; Studio history retains the prior instances for restoration.
		if previous then previous.Parent = nil end
	end)
	busy[cfg.PassName] = nil
	if not ok then
		stage:Destroy()
		error(err, 0)
	end
	stats.Shortfall = cfg.Count - stats.Placed
	return stage, stats
end

function NatureScatter.Clear(name)
	editOnly()
	passName(name)
	assert(not busy[name], "Pass is already generating: " .. name)
	local previous = previousPass(name)
	if previous then previous.Parent = nil end
	return previous ~= nil
end

return NatureScatter
