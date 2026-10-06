-- Seeded value noise. Integer products stay below the exact-double limit.
local Noise = {}
local function lattice(x, z, seed)
	local h = (x * 374761393 + z * 668265263 + seed * 69069) % 2147483647
	h = (h * 48271) % 2147483647
	h = (h * 48271) % 2147483647
	return h / 2147483647
end
local function fade(t) return t * t * t * (t * (t * 6 - 15) + 10) end
local function lerp(a, b, t) return a + (b - a) * t end

function Noise.sample(x, z, seed)
	local ix, iz = math.floor(x), math.floor(z)
	local fx, fz = fade(x - ix), fade(z - iz)
	return lerp(lerp(lattice(ix, iz, seed), lattice(ix + 1, iz, seed), fx),
		lerp(lattice(ix, iz + 1, seed), lattice(ix + 1, iz + 1, seed), fx), fz)
end

function Noise.fractal(x, z, seed, ridged)
	local value, weight, amplitude = 0, 0, 1
	for octave = 1, 5 do
		local n = Noise.sample(x, z, seed + octave * 7339)
		if ridged then n = (1 - math.abs(2 * n - 1)) ^ 2 end
		value += n * amplitude
		weight += amplitude
		amplitude *= 0.5
		x, z = x * 2.03, z * 2.03
	end
	return value / weight
end

return Noise
