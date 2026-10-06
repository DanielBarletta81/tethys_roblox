-- Run in Studio edit mode after installation. Fixtures are removed even on failure.
local Scatter = require(game.ReplicatedStorage.Tethys.WorldModules.Scatter.NatureScatter)
local Placement = require(game.ReplicatedStorage.Tethys.WorldModules.Scatter.AssetPlacement)
local Driver = require(game.ServerStorage.TethysTools.NatureScatterDriver)
local Http = game:GetService("HttpService")
local Config = require(game.ReplicatedStorage.Tethys.WorldModules.Scatter.ScatterConfig)
local pass = "GEN_NatureScatter_Test_01"
assert(not workspace.Generated:FindFirstChild(pass), "Reserved test pass already exists")
assert(not workspace.Generated:FindFirstChild("NatureScatterTestFixture"), "Test fixture already exists")
assert(not game.ServerStorage:FindFirstChild("NatureScatterTestSources"), "Test sources already exist")
assert(not workspace.WorldSystems.ScatterZones:FindFirstChild("ZONE_NatureScatterTest"), "Test zone already exists")
local fixture = Instance.new("Folder")
fixture.Name = "NatureScatterTestFixture"
fixture.Parent = workspace.Generated
local sources = Instance.new("Folder")
sources.Name = "NatureScatterTestSources"
sources.Capabilities = game.ReplicatedStorage.Tethys.WorldModules.Scatter.Capabilities
sources.Sandboxed = true
sources.Parent = game.ServerStorage
local checks = {}
local function check(name, action)
	local passed, failure = pcall(action)
	assert(passed, name .. ": " .. tostring(failure))
	table.insert(checks, name)
end
local function expectError(action, pattern)
	local ok, err = pcall(action)
	assert(not ok and tostring(err):find(pattern, 1, true), "Expected error: " .. pattern .. "; got: " .. tostring(err))
end
local function part(name, size, cf, parent)
	local item = Instance.new("Part")
	item.Name, item.Size, item.CFrame, item.Anchored = name, size, cf, true
	item.Parent = parent
	return item
end
local function snapshot(folder)
	local result = {}
	for _, model in ipairs(folder:GetChildren()) do
		table.insert(result, { model:GetAttribute("ScatterSourceId"), tostring(model:GetPivot()), model:GetAttribute("ScatterScale"), model:GetAttribute("ScatterYaw") })
	end
	return Http:JSONEncode(result)
end

local ok, err = pcall(function()
	for _, category in ipairs({ "Trees", "Rocks", "Understory", "GroundCover" }) do
		local folder = Instance.new("Folder")
		folder.Name, folder.Parent = category, sources
		local source = part("DuplicateName", Vector3.new(2, 6, 2), CFrame.new(10, 300, 40), folder)
		source:SetAttribute("ScatterId", "B")
		local model = Instance.new("Model")
		model.Name, model.Parent = "DuplicateName", folder
		part("Trunk", Vector3.new(3, 8, 3), CFrame.new(25, 304, 20), model)
		part("Canopy", Vector3.new(7, 2, 7), CFrame.new(25, 309, 20), model)
		model.WorldPivot = CFrame.new(900, 900, 900)
		model:ScaleTo(1.5)
		model:SetAttribute("ScatterId", "A")
		local unwanted = Instance.new("Script")
		unwanted.Disabled, unwanted.Name, unwanted.Parent = true, "SourceBehavior", model
	end
	local ground = part("Ground", Vector3.new(300, 2, 300), CFrame.new(0, 20000, 0), fixture)
	local zone = part("Zone", Vector3.new(120, 30, 120), CFrame.new(0, 20001, 0) * CFrame.Angles(0, math.rad(33), 0), fixture)
	zone.CanCollide, zone.CanQuery = false, false
	local options = { Zone = zone, SourceFolder = sources, Category = "Trees", PassName = pass, Seed = 20261005, Biome = "Test", Count = 30, MinSpacing = 4, SurfaceRoots = { ground } }
	local originalPivot = sources.Trees:FindFirstChildWhichIsA("Model"):GetPivot()
	local folder, stats
	local firstSnapshot
	check("yawed zone, counts, scale, rotation, bottom placement and static clones", function()
		folder, stats = Scatter.Generate(options)
		assert(stats.Placed == 30 and stats.Shortfall == 0)
		assert(folder.Parent == workspace.Generated)
		assert(folder:GetAttribute("Generator") == "NatureScatter" and folder:GetAttribute("PassId") == pass)
		assert(folder:GetAttribute("Seed") == 20261005 and folder:GetAttribute("Biome") == "Test" and folder:GetAttribute("Category") == "Trees")
		firstSnapshot = snapshot(folder)
		for _, model in ipairs(folder:GetChildren()) do
			local sample = model:GetAttribute("ScatterPosition")
			local localSample = zone.CFrame:PointToObjectSpace(sample)
			assert(math.abs(localSample.X) <= 60.001 and math.abs(localSample.Z) <= 60.001)
			assert(math.abs(sample.Y - 20001) < 0.01)
			assert(model:GetAttribute("ScatterScale") >= 0.85 and model:GetAttribute("ScatterScale") <= 1.15)
			assert(model:GetAttribute("ScatterYaw") >= 0 and model:GetAttribute("ScatterYaw") < 2 * math.pi)
			assert(not model:FindFirstChildWhichIsA("LuaSourceContainer", true))
			for _, item in ipairs(model:GetDescendants()) do if item:IsA("BasePart") then assert(item.Anchored) end end
			local cf, size = model:GetBoundingBox()
			assert(math.abs(cf.Position.Y - size.Y / 2 - sample.Y) < 0.02, "Asset bottom floats or sinks")
		end
		assert(sources.Trees:FindFirstChildWhichIsA("Model"):GetPivot() == originalPivot)
		assert(sources.Trees:FindFirstChildWhichIsA("Model").SourceBehavior.Parent ~= nil)
		local items = folder:GetChildren()
		for i = 1, #items do
			for j = i + 1, #items do
				local delta = items[i]:GetAttribute("ScatterPosition") - items[j]:GetAttribute("ScatterPosition")
				local required = math.max(options.MinSpacing, items[i]:GetAttribute("ScatterFootprintRadius") + items[j]:GetAttribute("ScatterFootprintRadius"))
				assert(Vector2.new(delta.X, delta.Z).Magnitude + 0.001 >= required, "Footprint spacing overlaps")
			end
		end
	end)
	check("seeded regeneration replaces only its own pass", function()
		local old = folder
		folder = Scatter.Generate(options)
		assert(snapshot(folder) == firstSnapshot and old.Parent == nil)
		local changed = table.clone(options)
		changed.Seed = 5678
		folder = Scatter.Generate(changed)
		assert(snapshot(folder) ~= firstSnapshot)
	end)
	check("source ordering is deterministic and duplicate IDs fail", function()
		local assets = Placement.Collect(sources, "Trees")
		assert(assets[1].Key == "A" and assets[2].Key == "B")
		assets[2].Source:SetAttribute("ScatterId", "A")
		expectError(function() Scatter.Generate(options) end, "Duplicate source key")
		assert(folder.Parent == workspace.Generated)
		assets[2].Source:SetAttribute("ScatterId", "B")
	end)
	check("invalid input and unowned output preserve existing content", function()
		local invalid = table.clone(options)
		invalid.MinScale = 0
		expectError(function() Scatter.Generate(invalid) end, "MinScale")
		invalid = table.clone(options)
		invalid.Seed = 0 / 0
		expectError(function() Scatter.Generate(invalid) end, "Seed")
		local unowned = Instance.new("Folder")
		unowned.Name, unowned.Parent = "GEN_NatureScatter_Unowned", workspace.Generated
		expectError(function() Scatter.Clear(unowned.Name) end, "not owned")
		invalid = table.clone(options)
		invalid.PassName = unowned.Name
		expectError(function() Scatter.Generate(invalid) end, "not owned")
		assert(unowned.Parent == workspace.Generated)
		unowned:Destroy()
	end)
	check("slope filtering, insufficient spacing and failed pass preservation", function()
		ground.CFrame = CFrame.new(0, 20000, 0) * CFrame.Angles(0, 0, math.rad(45))
		local steep = table.clone(options)
		steep.MaxSlopeDegrees, steep.MaxAttempts = 20, 20
		expectError(function() Scatter.Generate(steep) end, "No valid placements")
		assert(folder.Parent == workspace.Generated)
		steep.Category, steep.MaxSlopeDegrees = "Rocks", 65
		folder, stats = Scatter.Generate(steep)
		assert(stats.Placed > 0 and stats.Shortfall > 0)
		ground.CFrame = CFrame.new(0, 20000, 0)
		local sparse = table.clone(options)
		sparse.MinSpacing, sparse.MaxAttempts = 1000, 15
		folder, stats = Scatter.Generate(sparse)
		assert(stats.Placed == 1 and stats.Spacing == 14 and stats.Shortfall == 29)
	end)
	check("empty zones preserve previous pass", function()
		zone.CFrame = CFrame.new(0, 21000, 0)
		expectError(function() Scatter.Generate(options) end, "No valid placements")
		assert(folder.Parent == workspace.Generated)
		zone.CFrame = CFrame.new(0, 20001, 0)
	end)
	check("all four source categories generate", function()
		for _, category in ipairs({ "Trees", "Rocks", "Understory", "GroundCover" }) do
			local cfg = table.clone(options)
			cfg.Category = category
			folder, stats = Scatter.Generate(cfg)
			assert(stats.Placed == 30)
			for _, item in ipairs(folder:GetChildren()) do
				local scale = item:GetAttribute("ScatterScale")
				assert(scale >= Config.Categories[category].MinScale and scale <= Config.Categories[category].MaxScale)
				local source = item:GetAttribute("ScatterSourceId") == "A" and sources[category]:FindFirstChildWhichIsA("Model") or sources[category]:FindFirstChildWhichIsA("BasePart")
				local sourceHeight = source:IsA("Model") and select(2, source:GetBoundingBox()).Y or source.Size.Y
				assert(math.abs(select(2, item:GetBoundingBox()).Y / sourceHeight - scale) < 0.002)
			end
		end
	end)
	for _, category in ipairs({ "Trees", "Rocks", "Understory", "GroundCover" }) do
		check(category .. " slope limit accepts below and rejects above", function()
			local limit = Config.Categories[category].MaxSlopeDegrees
			zone.CFrame, zone.Size = CFrame.new(0, 20001, 0), Vector3.new(80, 400, 80)
			ground.CFrame = CFrame.new(0, 20000, 0) * CFrame.Angles(0, 0, math.rad(limit - 2))
			local cfg = { Zone = zone, SourceFolder = sources, Category = category, PassName = pass, Seed = 20261005, Count = 6, SurfaceRoots = { ground }, MaxAttempts = 100 }
			folder, stats = Scatter.Generate(cfg)
			assert(stats.Placed == 6)
			ground.CFrame = CFrame.new(0, 20000, 0) * CFrame.Angles(0, 0, math.rad(limit + 2))
			expectError(function() Scatter.Generate(cfg) end, "No valid placements")
			assert(folder.Parent == workspace.Generated)
			ground.CFrame = CFrame.new(0, 20000, 0)
		end)
	end
	check("clear is scoped and idempotent", function()
		assert(Scatter.Clear(pass))
		assert(not Scatter.Clear(pass))
		assert(ground.Parent == fixture and #sources.Trees:GetChildren() == 2)
	end)
	check("Studio driver creates zones and generates with undo recording", function()
		local zoneName = "ZONE_NatureScatterTest"
		assert(not workspace.WorldSystems.ScatterZones:FindFirstChild(zoneName))
		local driverZone = Driver.CreateZone(zoneName, CFrame.new(0, 20001, 0), Vector3.new(100, 30, 100))
		local cfg = { SourceFolder = sources, SurfaceRoots = { ground }, Count = 5, PassName = pass }
		folder, stats = Driver.Generate(zoneName, cfg)
		assert(stats.Placed == 5)
		assert(Driver.Clear(pass))
		driverZone:Destroy()
	end)
	check("real Terrain integration with imported assets", function()
		local position = Vector3.new(-332, 135.06005859375, -390)
		zone.CFrame, zone.Size = CFrame.new(position), Vector3.new(20, 60, 20)
		local cfg = { Zone = zone, SourceFolder = game.ServerStorage.TethysAssets.Nature, Category = "GroundCover", PassName = pass, Seed = 2468, Count = 3, MinSpacing = 2 }
		folder, stats = Scatter.Generate(cfg)
		assert(stats.Placed == 3)
		local terrainParams = RaycastParams.new()
		terrainParams.FilterType, terrainParams.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { workspace.Terrain }
		for _, model in ipairs(folder:GetChildren()) do
			local point = model:GetAttribute("ScatterPosition")
			local hit = workspace:Raycast(point + Vector3.new(0, 10, 0), Vector3.new(0, -20, 0), terrainParams)
			assert(hit and hit.Instance == workspace.Terrain and (hit.Position - point).Magnitude < 0.02)
		end
		assert(Scatter.Clear(pass))
	end)
end)
local leftover = workspace.Generated:FindFirstChild(pass)
if leftover and leftover:GetAttribute("TethysNatureScatterVersion") == 1 then leftover:Destroy() end
local unowned = workspace.Generated:FindFirstChild("GEN_NatureScatter_Unowned")
if unowned then unowned:Destroy() end
local driverZone = workspace.WorldSystems.ScatterZones:FindFirstChild("ZONE_NatureScatterTest")
if driverZone then driverZone:Destroy() end
fixture:Destroy()
sources:Destroy()
if not ok then error(err, 0) end
return Http:JSONEncode({ Passed = #checks, Checks = checks })
