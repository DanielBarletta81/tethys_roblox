local Config = require(if script then script.Parent.Config else "./Config")
local Voxelizer = require(if script then script.Parent.Voxelizer else "./Voxelizer")
local EditSession = {}
EditSession.__index = EditSession

function EditSession.empty(channels)
	for x, column in ipairs(channels.SolidOccupancy) do for y, row in ipairs(column) do for z, value in ipairs(row) do
		if value > 0 or channels.LiquidOccupancy[x][y][z] > 0 then return false end
	end end end
	return true
end

function EditSession.equal(a, b)
	for _, key in ipairs({ "SolidMaterial", "SolidOccupancy", "LiquidOccupancy" }) do
		if #a[key] ~= #b[key] then return false end
		for x, column in ipairs(a[key]) do
			if #column ~= #b[key][x] then return false end
			for y, row in ipairs(column) do
				if #row ~= #b[key][x][y] then return false end
				for z, value in ipairs(row) do if value ~= b[key][x][y][z] then return false end end
			end
		end
	end
	return true
end

function EditSession.new(backend)
	return setmetatable({ Backend = backend, Busy = false, Latest = nil }, EditSession)
end

function EditSession:_transaction(label, callback)
	assert(not self.Busy, "A terrain edit is already running")
	assert(self.Backend.IsEditMode(), "Terrain authoring is available only in Edit mode")
	self.Busy = true
	local token
	local ok, result = pcall(function()
		token = self.Backend.Begin(label)
		assert(token, "Studio could not start an Undo recording; no terrain was written")
		return callback()
	end)
	if token then
		local finished, finishError = pcall(self.Backend.Finish, token, ok)
		if not finished then ok, result = false, "Undo recording failed: " .. tostring(finishError) end
	end
	self.Busy = false
	assert(ok, tostring(result))
	return result
end

function EditSession:apply(map)
	assert(not self.Busy, "A terrain edit is already running")
	assert(self.Backend.IsEditMode(), "Stop playtesting before authoring terrain")
	local bounds = Config.bounds(map.Config)
	self.Backend.CheckBounds(bounds)
	local before = self.Backend.Read(bounds)
	assert(EditSession.empty(before), "Existing solid terrain or water intersects this box. Choose an empty patch; nothing was changed")
	local channels = Voxelizer.build(map)
	local pass = self:_transaction("Generate Tethys Terrain", function()
		-- Check again inside the recording; edits never yield across the terrain write.
		assert(EditSession.equal(before, self.Backend.Read(bounds)), "Terrain changed during preflight")
		self.Backend.Write(bounds, channels)
		local after = self.Backend.Read(bounds) -- Engine quantization, not unrounded source values.
		local id = self.Backend.CreateMetadata(map, bounds)
		return { Id = id, Bounds = bounds, Before = before, After = after, Seed = map.Config.Seed }
	end)
	self.Latest = pass
	return pass
end

function EditSession:clear()
	local pass = self.Latest
	assert(pass, "No pass is owned by this session. Use Studio Undo for earlier passes")
	assert(self.Backend.HasMetadata(pass.Id), "Pass metadata is missing, possibly after Undo. No terrain was changed")
	assert(EditSession.equal(pass.After, self.Backend.Read(pass.Bounds)), "This patch was edited after generation. Use Studio Undo; Clear will preserve your edits")
	self:_transaction("Clear Tethys Terrain pass", function()
		assert(EditSession.equal(pass.After, self.Backend.Read(pass.Bounds)), "Terrain changed during Clear preflight")
		self.Backend.Write(pass.Bounds, pass.Before)
		self.Backend.RemoveMetadata(pass.Id)
	end)
	self.Latest = nil
	return pass.Id
end

return EditSession
