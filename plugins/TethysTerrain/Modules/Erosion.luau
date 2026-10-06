local Erosion = {}
local neighbours = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }

-- Simultaneous conservative talus transfer; no sequential sweep bias or runoff claim.
function Erosion.apply(heights, iterations, talus)
	local width, length = #heights, #heights[1]
	for _ = 1, iterations do
		local delta = {}
		for x = 1, width do delta[x] = table.create(length, 0) end
		for x = 1, width do
			for z = 1, length do
				local excess, total, maximum = {}, 0, 0
				for i, offset in ipairs(neighbours) do
					local nx, nz = x + offset[1], z + offset[2]
					local drop = 0
					if nx >= 1 and nx <= width and nz >= 1 and nz <= length then
						drop = math.max(0, heights[x][z] - heights[nx][nz] - talus)
					end
					excess[i], total, maximum = drop, total + drop, math.max(maximum, drop)
				end
				if total > 0 then
					local transfer = maximum * 0.25
					delta[x][z] -= transfer
					for i, offset in ipairs(neighbours) do
						if excess[i] > 0 then delta[x + offset[1]][z + offset[2]] += transfer * excess[i] / total end
					end
				end
			end
		end
		for x = 1, width do for z = 1, length do heights[x][z] += delta[x][z] end end
	end
	return heights
end

return Erosion
