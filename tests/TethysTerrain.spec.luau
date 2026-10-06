-- The production math and edit policy run unchanged in the official Luau CLI.
local root = if script then script.Parent:WaitForChild("TethysTerrainModules") else "../plugins/TethysTerrain/Modules/"
local function module(name) return require(if script then root[name] else root .. name) end
local Config, Heightfield, Erosion = module("Config"), module("Heightfield"), module("Erosion")
local Voxelizer, EditSession = module("Voxelizer"), module("EditSession")
local passed = 0
local function test(name, callback)
	callback(); passed += 1; print("PASS " .. name)
end
local function rejects(callback, fragment)
	local ok, err = pcall(callback)
	assert(not ok, "Expected rejection")
	if fragment then assert(tostring(err):find(fragment, 1, true), tostring(err)) end
end
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}; for key, item in pairs(value) do result[key] = copy(item) end; return result
end
local settings = { Width = 32, Length = 32, Height = 32, Relief = 16, RiverWidth = 8, Erosion = 4 }
local function generate(extra)
	local input = table.clone(settings)
	for key, value in pairs(extra or {}) do input[key] = value end
	return Heightfield.generate(input)
end
local function fakeBackend()
	local backend = { Current = { SolidMaterial = {}, SolidOccupancy = {}, LiquidOccupancy = {} },
		Metadata = {}, Writes = 0, Commits = 0, Cancels = 0, Starts = 0, Edit = true }
	for _, key in ipairs({ "SolidMaterial", "SolidOccupancy", "LiquidOccupancy" }) do
		for x = 1, 8 do
			backend.Current[key][x] = {}
			for y = 1, 8 do backend.Current[key][x][y] = table.create(8, if key == "SolidMaterial" then "Air" else 0) end
		end
	end
	function backend.IsEditMode() return backend.Edit end
	function backend.CheckBounds() assert(not backend.PartBlocked, "Part overlap") end
	function backend.Read() return copy(backend.Current) end
	function backend.Write(_, channels)
		backend.Writes += 1
		backend.Current = copy(channels)
		for _, key in ipairs({ "SolidOccupancy", "LiquidOccupancy" }) do
			for _, column in ipairs(backend.Current[key]) do for _, row in ipairs(column) do
				for z, value in ipairs(row) do row[z] = math.floor(value * 256 + 0.5) / 256 end
			end end
		end
		assert(not backend.FailWrite, "Injected post-write failure")
	end
	function backend.Begin()
		backend.Starts += 1
		if backend.RefuseRecording then return nil end
		backend.Snapshot, backend.MetadataSnapshot = copy(backend.Current), copy(backend.Metadata)
		return "recording"
	end
	function backend.Finish(_, commit)
		if commit then backend.Commits += 1 else
			backend.Current, backend.Metadata = backend.Snapshot, backend.MetadataSnapshot
			backend.Cancels += 1
		end
	end
	function backend.CreateMetadata()
		assert(not backend.FailMetadata, "Injected metadata failure")
		local id = tostring(backend.Commits + 1); backend.Metadata[id] = true; return id
	end
	function backend.HasMetadata(id) return backend.Metadata[id] == true end
	function backend.RemoveMetadata(id) backend.Metadata[id] = nil end
	return backend
end

test("settings reject nonfinite, off-grid, oversized and unknown input", function()
	for _, invalid in ipairs({ { Seed = 0 / 0 }, { Width = 33 }, { Length = 512 }, { OriginX = 1 },
		{ Relief = 100 }, { Erosion = 2.5 }, { Water = "true" }, { Preset = "Gaea" }, { ReplaceEverything = true } }) do
		rejects(function() Config.normalize(invalid) end)
	end
	assert(Config.normalize({ Seed = 0 }).Seed == 0)
	assert(Config.normalize({ Width = 256, Length = 256, Height = 192 }).Height == 192)
end)
test("same seed and settings reproduce every height and voxel", function()
	local a, b = generate(), generate()
	assert(EditSession.equal(Voxelizer.build(a), Voxelizer.build(b)))
	for x = 1, a.NX do for z = 1, a.NZ do assert(a.Heights[x][z] == b.Heights[x][z]) end end
end)
test("different seed changes terrain", function()
	assert(not EditSession.equal(Voxelizer.build(generate()), Voxelizer.build(generate({ Seed = 20261006 }))))
end)
test("all presets stay within the declared box", function()
	for _, preset in ipairs(Config.Presets) do
		local map = generate({ Preset = preset })
		for x = 1, map.NX do for z = 1, map.NZ do
			assert(map.Heights[x][z] >= 4 and map.Heights[x][z] <= map.Config.Height - 8)
			assert(map.Slopes[x][z] >= 0 and map.Slopes[x][z] < 90)
		end end
	end
end)
test("river has a wet channel through every cross section", function()
	for _, seed in ipairs({ 0, 1, 17, 20261005, 2147483647 }) do
		local map = generate({ Seed = seed })
		for z = 1, map.NZ do
			local found = false
			for x = 1, map.NX do if map.Wet[x][z] then found = true end end
			assert(found, "Disconnected river cross section")
		end
	end
end)
test("water-off and mountain preset emit no liquid", function()
	for _, map in ipairs({ generate({ Water = false }), generate({ Preset = "Mountains" }) }) do
		assert(map.WaterColumns == 0)
		for _, column in ipairs(Voxelizer.build(map).LiquidOccupancy) do for _, row in ipairs(column) do
			for _, value in ipairs(row) do assert(value == 0) end
		end end
	end
end)
test("thermal erosion conserves mass and lowers an isolated peak", function()
	local grid, before = {}, 0
	for x = 1, 9 do grid[x] = table.create(9, 4) end
	grid[5][5] = 80
	for _, row in ipairs(grid) do for _, h in ipairs(row) do before += h end end
	Erosion.apply(grid, 16, 2)
	local after = 0
	for _, row in ipairs(grid) do for _, h in ipairs(row) do after += h; assert(h >= 4) end end
	assert(math.abs(before - after) < 0.000001 and grid[5][5] < 80)
	local unchanged = copy(grid); Erosion.apply(grid, 0, 2)
	for x = 1, 9 do for z = 1, 9 do assert(grid[x][z] == unchanged[x][z]) end end
end)
test("voxel channels have bounded occupancy and correct solid-air separation", function()
	local map = generate()
	local channels = Voxelizer.build(map)
	for x = 1, map.NX do for y = 1, map.Config.Height / 4 do for z = 1, map.NZ do
		local solid, liquid = channels.SolidOccupancy[x][y][z], channels.LiquidOccupancy[x][y][z]
		assert(solid >= 0 and solid <= 1 and liquid >= 0 and liquid <= 1)
		assert((channels.SolidMaterial[x][y][z] == "Air") == (solid == 0))
		if solid == 1 then assert(liquid == 0) end
		if not map.Wet[x][z] then assert(liquid == 0) end
	end end end
end)
test("preview maps are immutable and use local coordinates", function()
	local a, b = generate(), generate({ OriginX = 8000, OriginZ = -8000, FloorY = -40 })
	rejects(function() a.Heights[1][1] = 90 end)
	rejects(function() a.Config.Seed = 2 end)
	assert(EditSession.equal(Voxelizer.build(a), Voxelizer.build(b)))
end)
test("apply and clear restore the original channels with two recordings", function()
	local backend = fakeBackend()
	local original = copy(backend.Current)
	local session = EditSession.new(backend)
	local pass = session:apply(generate())
	assert(backend.Commits == 1 and backend.HasMetadata(pass.Id) and not EditSession.empty(backend.Current))
	session:clear()
	assert(backend.Commits == 2 and EditSession.equal(original, backend.Current) and not backend.HasMetadata(pass.Id))
end)
test("solid and water conflicts reject before any write or recording", function()
	for _, key in ipairs({ "SolidOccupancy", "LiquidOccupancy" }) do
		local backend = fakeBackend(); backend.Current[key][1][1][1] = 0.5
		rejects(function() EditSession.new(backend):apply(generate()) end, "Existing solid terrain or water")
		assert(backend.Writes == 0 and backend.Starts == 0)
	end
end)
test("play mode, overlapping Parts and concurrent edits reject", function()
	local backend = fakeBackend(); local session = EditSession.new(backend)
	backend.Edit = false; rejects(function() session:apply(generate()) end, "Stop playtesting")
	backend.Edit = true; backend.PartBlocked = true; rejects(function() session:apply(generate()) end, "Part overlap")
	backend.PartBlocked = false; session.Busy = true; rejects(function() session:apply(generate()) end, "already running")
	assert(backend.Writes == 0)
end)
test("refused Undo recording leaves terrain untouched", function()
	local backend = fakeBackend(); backend.RefuseRecording = true
	local session = EditSession.new(backend)
	rejects(function() session:apply(generate()) end, "could not start an Undo recording")
	assert(backend.Writes == 0 and session.Latest == nil and not session.Busy)
end)
test("failures after writing or creating metadata cancel and restore", function()
	for _, key in ipairs({ "FailWrite", "FailMetadata" }) do
		local backend = fakeBackend(); backend[key] = true
		local before = copy(backend.Current); local session = EditSession.new(backend)
		rejects(function() session:apply(generate()) end, "Injected")
		assert(backend.Cancels == 1 and backend.Commits == 0 and EditSession.equal(before, backend.Current))
		assert(session.Latest == nil and not session.Busy and next(backend.Metadata) == nil)
	end
end)
test("Clear preserves manual sculpting and missing or undone ownership", function()
	local backend = fakeBackend(); local session = EditSession.new(backend)
	local pass = session:apply(generate())
	backend.Current.SolidOccupancy[1][1][1] = 0.25
	local edited = copy(backend.Current)
	rejects(function() session:clear() end, "edited after generation")
	assert(EditSession.equal(edited, backend.Current) and backend.Commits == 1)
	backend.Metadata[pass.Id] = nil
	rejects(function() session:clear() end, "metadata is missing")
	assert(EditSession.equal(edited, backend.Current))
end)
print("Tethys Terrain: " .. passed .. " groups passed")
return passed
