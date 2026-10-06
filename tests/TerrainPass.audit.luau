-- Read-only audit of a generated pass against actual Terrain and category rules.
local Config = require(game.ReplicatedStorage.Tethys.WorldModules.Scatter.ScatterConfig)
return function(folder)
	assert(folder.Parent == workspace.Generated and folder:GetAttribute("Generator") == "NatureScatter")
	local category = folder:GetAttribute("Category")
	local rules = Config.Categories[category]
	local zoneName = folder:GetAttribute("ZonePath"):match("([^%.]+)$")
	local zone = workspace.WorldSystems.ScatterZones:FindFirstChild(zoneName)
	assert(zone and zone:IsA("BasePart"), "Audit requires the original zone")
	local params = RaycastParams.new()
	params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { workspace.Terrain }
	params.IgnoreWater = false
	local items = folder:GetChildren()
	local result = { Category = category, Count = #items, Seed = folder:GetAttribute("Seed"), MinScale = math.huge, MaxScale = -math.huge, MaxSlope = 0, MaxBaseError = 0, OverlappingPairs = 0, MinSpacingMargin = math.huge }
	for _, model in ipairs(items) do
		assert(model:IsA("Model") and model.Parent == folder)
		local sample, scale = model:GetAttribute("ScatterPosition"), model:GetAttribute("ScatterScale")
		-- Repeat the zone's bounded ray, including when there is Terrain above it.
		local padding = Config.Defaults.RaycastPadding
		local origin = Vector3.new(sample.X, zone.Position.Y + zone.Size.Y / 2 + padding, sample.Z)
		local hit = workspace:Raycast(origin, Vector3.new(0, -zone.Size.Y - 2 * padding, 0), params)
		assert(hit and hit.Instance == workspace.Terrain and hit.Material ~= Enum.Material.Water)
		assert((hit.Position - sample).Magnitude < 0.02, "Terrain support point drifted")
		local slope = math.deg(math.acos(math.clamp(hit.Normal.Y, -1, 1)))
		assert(slope <= rules.MaxSlopeDegrees + 0.001)
		assert(scale >= rules.MinScale and scale <= rules.MaxScale)
		result.MinScale, result.MaxScale = math.min(result.MinScale, scale), math.max(result.MaxScale, scale)
		result.MaxSlope = math.max(result.MaxSlope, slope)
		local cf, size = model:GetBoundingBox()
		local lowest = math.huge
		for _, x in ipairs({ -1, 1 }) do
			for _, y in ipairs({ -1, 1 }) do
				for _, z in ipairs({ -1, 1 }) do lowest = math.min(lowest, cf:PointToWorldSpace(size * Vector3.new(x, y, z) * 0.5).Y) end
			end
		end
		result.MaxBaseError = math.max(result.MaxBaseError, math.abs(lowest - sample.Y))
	end
	for i = 1, #items do
		for j = i + 1, #items do
			local a, b = items[i], items[j]
			local delta = a:GetAttribute("ScatterPosition") - b:GetAttribute("ScatterPosition")
			local required = math.max(rules.MinSpacing, a:GetAttribute("ScatterFootprintRadius") + b:GetAttribute("ScatterFootprintRadius"))
			local margin = Vector2.new(delta.X, delta.Z).Magnitude - required
			result.MinSpacingMargin = math.min(result.MinSpacingMargin, margin)
			if margin < -0.001 then result.OverlappingPairs += 1 end
		end
	end
	assert(result.MaxBaseError < 0.02 and result.OverlappingPairs == 0)
	return result
end
