-- Plain data so the same constraints run in Studio and portable Luau tests.
local Config = {}
Config.Version = "0.1.0"
Config.Resolution = 4
Config.MaxVoxels = 196608
Config.Presets = { "RiverValley", "Mountains", "Island" }
Config.Defaults = table.freeze({
	Seed = 20261005, Preset = "RiverValley", Width = 128, Length = 128,
	Height = 96, OriginX = 0, OriginZ = 0, FloorY = 0,
	Relief = 56, Scale = 80, Erosion = 8, RiverWidth = 16, Water = true,
})

local function number(value, name, low, high, multiple)
	assert(type(value) == "number" and value == value and math.abs(value) < math.huge, name .. " must be finite")
	assert(value >= low and value <= high, name .. " must be between " .. low .. " and " .. high)
	if multiple then assert(value % multiple == 0, name .. " must be a multiple of " .. multiple) end
	return value
end

function Config.normalize(input)
	assert(type(input) == "table", "Settings must be a table")
	local c = table.clone(Config.Defaults)
	for key, value in pairs(input) do
		assert(c[key] ~= nil, "Unknown setting: " .. tostring(key))
		c[key] = value
	end
	number(c.Seed, "Seed", 0, 2147483647, 1)
	assert(table.find(Config.Presets, c.Preset), "Unknown preset")
	number(c.Width, "Width", 32, 256, 4)
	number(c.Length, "Length", 32, 256, 4)
	number(c.Height, "Height", 32, 192, 4)
	for _, key in ipairs({ "OriginX", "OriginZ", "FloorY" }) do number(c[key], key, -100000, 100000, 4) end
	number(c.Relief, "Relief", 0, c.Height - 16)
	number(c.Scale, "Scale", 16, 512)
	number(c.Erosion, "Erosion", 0, 32, 1)
	number(c.RiverWidth, "RiverWidth", 8, c.Width / 2, 4)
	assert(type(c.Water) == "boolean", "Water must be true or false")
	assert(c.Width * c.Length * c.Height / 64 <= Config.MaxVoxels, "Patch exceeds the voxel budget")
	return table.freeze(c)
end

function Config.bounds(c)
	return { X = c.OriginX, Y = c.FloorY, Z = c.OriginZ, Width = c.Width, Height = c.Height, Length = c.Length }
end

return Config
