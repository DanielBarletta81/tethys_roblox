local Config = require(if script then script.Parent.Config else "./Config")
local Noise = require(if script then script.Parent.Noise else "./Noise")
local Erosion = require(if script then script.Parent.Erosion else "./Erosion")
local Heightfield = {}
local function smooth(t) t = math.clamp(t, 0, 1); return t * t * (3 - 2 * t) end

local function riverDistance(c, x, z)
	local u, v = (x - 0.5) * 4 / c.Width, (z - 0.5) * 4 / c.Length
	local meander = 0.5 + 0.12 * math.sin(v * math.pi * 2 + c.Seed % 31)
		+ 0.08 * (Noise.sample(v * 3, 0, c.Seed + 17) - 0.5)
	return math.abs(u - meander) * c.Width
end

function Heightfield.generate(input)
	local c = Config.normalize(input)
	local nx, nz = c.Width / 4, c.Length / 4
	local heights, slopes, wet = {}, {}, {}
	local waterLevel = 12 -- Relative to FloorY; same datum along this authored patch.
	for x = 1, nx do
		heights[x] = {}
		for z = 1, nz do
			local sx, sz = (x - 0.5) * 4 / c.Scale, (z - 0.5) * 4 / c.Scale
			local wx = (Noise.sample(sx * 0.45, sz * 0.45, c.Seed + 3) - 0.5) * 0.7
			local wz = (Noise.sample(sx * 0.45, sz * 0.45, c.Seed + 5) - 0.5) * 0.7
			local n = Noise.fractal(sx + wx, sz + wz, c.Seed, true)
			local h = 8 + c.Relief * (0.18 + 0.82 * n)
			if c.Preset == "RiverValley" then
				local distance = riverDistance(c, x, z)
				local bank = smooth((distance - c.RiverWidth * 0.5) / (c.Width * 0.32))
				h = 10 + c.Relief * bank * (0.35 + 0.65 * n)
			elseif c.Preset == "Island" then
				local u, v = ((x - 0.5) / nx - 0.5) * 2, ((z - 0.5) / nz - 0.5) * 2
				h = 4 + c.Relief * smooth(1 - math.sqrt(u * u + v * v)) * (0.45 + 0.55 * n)
			end
			heights[x][z] = h
		end
	end
	Erosion.apply(heights, c.Erosion, 4 * math.tan(math.rad(34)))
	-- Recut the continuous authored river after talus relaxation so it stays open.
	if c.Preset == "RiverValley" then
		for x = 1, nx do for z = 1, nz do
			local t = smooth((riverDistance(c, x, z) - c.RiverWidth * 0.35) / (c.RiverWidth * 0.35))
			heights[x][z] = 5 + (heights[x][z] - 5) * t
		end end
	end
	local minimum, maximum, waterColumns = math.huge, -math.huge, 0
	for x = 1, nx do
		slopes[x], wet[x] = {}, {}
		for z = 1, nz do
			local h = math.clamp(heights[x][z], 4, c.Height - 8)
			heights[x][z] = h
			minimum, maximum = math.min(minimum, h), math.max(maximum, h)
			wet[x][z] = c.Water and c.Preset ~= "Mountains" and h < waterLevel
			if wet[x][z] then waterColumns += 1 end
		end
	end
	for x = 1, nx do for z = 1, nz do
		local xa, xb, za, zb = math.max(1, x - 1), math.min(nx, x + 1), math.max(1, z - 1), math.min(nz, z + 1)
		local dx = (heights[xb][z] - heights[xa][z]) / ((xb - xa) * 4)
		local dz = (heights[x][zb] - heights[x][za]) / ((zb - za) * 4)
		slopes[x][z] = math.deg(math.atan(math.sqrt(dx * dx + dz * dz)))
	end end
	for _, grid in ipairs({ heights, slopes, wet }) do
		for _, row in ipairs(grid) do table.freeze(row) end
		table.freeze(grid)
	end
	return table.freeze({ Config = c, Heights = heights, Slopes = slopes, Wet = wet, WaterLevel = waterLevel,
		Minimum = minimum, Maximum = maximum, WaterColumns = waterColumns, NX = nx, NZ = nz })
end

return Heightfield
