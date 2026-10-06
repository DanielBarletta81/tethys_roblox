-- Bounded engine fixture. Call with the staged Modules folder; no plugin UI required.
-- This exercises native voxel channels and collision, not plugin-owned Undo recording.
return function(modules, marker)
	local Config, Heightfield = require(modules.Config), require(modules.Heightfield)
	local EditSession, Backend = require(modules.EditSession), require(modules.RobloxBackend)
	local backend = Backend.new(marker)
	local map = Heightfield.generate({ OriginX = 8000, OriginZ = 8000 })
	local bounds = Config.bounds(map.Config)
	backend.CheckBounds(bounds)
	local original = backend.Read(bounds)
	assert(EditSession.empty(original), "Fixture requires an empty test box; no writes")
	local priorGenerated = workspace:FindFirstChild("Generated")
	local priorFolder = priorGenerated and priorGenerated:FindFirstChild("TethysTerrain")
	local created, guide, snapshot = {}, nil, nil
	local nativeCreate = backend.CreateMetadata
	backend.CreateMetadata = function(field, box)
		local id = nativeCreate(field, box); table.insert(created, id); return id
	end
	-- The MCP command has its own context. Model transaction rollback explicitly
	-- here; production retains the real ChangeHistoryService backend unchanged.
	backend.Begin = function() snapshot = backend.Read(bounds); return "engine-fixture" end
	backend.Finish = function(_, commit) if not commit then backend.Write(bounds, snapshot) end end
	local session = EditSession.new(backend)
	local results = { Groups = {}, PluginUndoTested = false, Seed = map.Config.Seed, Voxels = map.NX * map.NZ * map.Config.Height / 4 }
	local function check(name, callback)
		callback(); table.insert(results.Groups, name)
	end
	local function rejected(callback, fragment)
		local ok, err = pcall(callback)
		assert(not ok and tostring(err):find(fragment, 1, true), tostring(err))
	end
	local ok, failure = pcall(function()
		local start = os.clock()
		local pass = session:apply(map)
		results.GenerationSeconds = os.clock() - start
		local first = backend.Read(bounds)
		-- Voxel reads are immediate; collision meshes update on a later frame.
		task.wait(0.25)
		check("native solid and liquid channels", function()
			local solidCount, waterCount = 0, 0
			for x, column in ipairs(first.SolidOccupancy) do for y, row in ipairs(column) do for z, solid in ipairs(row) do
				if solid > 0 then solidCount += 1 end
				if first.LiquidOccupancy[x][y][z] > 0 then waterCount += 1 end
			end end end
			assert(solidCount > 0 and waterCount > 0)
			results.SolidCells, results.WaterCells = solidCount, waterCount
		end)
		check("generated metadata ownership", function()
			local metadata = workspace.Generated.TethysTerrain:FindFirstChild("Pass_" .. pass.Id)
			assert(metadata and metadata:GetAttribute("Seed") == 20261005 and metadata:GetAttribute("Generator") == "TethysTerrain")
			assert(metadata:GetAttribute("BoundsMin") == Vector3.new(8000, 0, 8000))
		end)
		check("raycasts hit actual Terrain water and riverbed", function()
			local z, x = math.floor(map.NZ / 2), 1
			for candidate = 1, map.NX do if map.Heights[candidate][z] < map.Heights[x][z] then x = candidate end end
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = { workspace.Terrain }
			params.IgnoreWater = false
			local origin = Vector3.new(8000 + (x - 0.5) * 4, 120, 8000 + (z - 0.5) * 4)
			local hit = workspace:Raycast(origin, Vector3.new(0, -124, 0), params)
			assert(hit and hit.Instance == workspace.Terrain and hit.Material == Enum.Material.Water, "Water ray missed native Terrain")
			assert(math.abs(hit.Position.Y - map.WaterLevel) <= 4, "Unexpected water surface")
			results.WaterSurfaceY = hit.Position.Y
			params.IgnoreWater = true
			local bed = workspace:Raycast(origin, Vector3.new(0, -124, 0), params)
			assert(bed and bed.Instance == workspace.Terrain and bed.Material ~= Enum.Material.Water)
			results.RiverbedY = bed.Position.Y
		end)
		check("existing terrain rejection preserves the patch", function()
			rejected(function() session:apply(map) end, "Existing solid terrain or water")
			assert(EditSession.equal(first, backend.Read(bounds)))
		end)
		check("Clear restores the complete original box", function()
			session:clear()
			assert(EditSession.equal(original, backend.Read(bounds)))
		end)
		check("seed reproduces native quantized voxel channels", function()
			session:apply(Heightfield.generate(map.Config))
			assert(EditSession.equal(first, backend.Read(bounds)))
			session:clear()
		end)
		check("manual sculpting blocks Clear", function()
			local current = session:apply(map)
			local edited = backend.Read(bounds)
			edited.SolidOccupancy[1][1][1] = 0.25
			backend.Write(bounds, edited)
			local manual = backend.Read(bounds)
			rejected(function() session:clear() end, "edited after generation")
			assert(EditSession.equal(manual, backend.Read(bounds)))
			backend.Write(bounds, current.After)
			session:clear()
		end)
		check("water-only conflicts are protected", function()
			local water = backend.Read(bounds)
			water.LiquidOccupancy[1][1][1] = 1
			backend.Write(bounds, water)
			local before = backend.Read(bounds)
			rejected(function() session:apply(map) end, "Existing solid terrain or water")
			assert(EditSession.equal(before, backend.Read(bounds)))
			backend.Write(bounds, original)
		end)
		check("Part bounds guard and explicit selected guide", function()
			guide = Instance.new("Part")
			guide.Name, guide.Anchored, guide.CanCollide = "TethysTerrainTestGuide", true, false
			guide.Position, guide.Size = Vector3.new(8064, 48, 8064), Vector3.new(8, 8, 8)
			guide.Parent = workspace
			rejected(function() backend.CheckBounds(bounds) end, "Part overlaps")
			backend.IgnorePart = guide
			backend.CheckBounds(bounds)
		end)
	end)
	-- Restore even on a failing assertion; only touch fixture-owned entries.
	backend.Write(bounds, original)
	if guide then guide:Destroy() end
	for _, id in ipairs(created) do if backend.HasMetadata(id) then backend.RemoveMetadata(id) end end
	local generated = workspace:FindFirstChild("Generated")
	local folder = generated and generated:FindFirstChild("TethysTerrain")
	if not priorFolder and folder and folder:GetAttribute("Generator") == "TethysTerrain" and #folder:GetChildren() == 0 then folder:Destroy() end
	if not priorGenerated and generated and #generated:GetChildren() == 0 then generated:Destroy() end
	results.Restored = EditSession.equal(original, backend.Read(bounds))
	assert(results.Restored, "Fixture cleanup did not restore the original box")
	assert(ok, tostring(failure))
	results.Passed = #results.Groups
	return results
end
