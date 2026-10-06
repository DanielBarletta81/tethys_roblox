local Voxelizer = {}

function Voxelizer.material(map, x, z, bottom)
	local h, slope = map.Heights[x][z], map.Slopes[x][z]
	if bottom < h - 8 then return "Rock" end
	if map.Wet[x][z] or h <= map.WaterLevel + 2 and map.Config.Preset ~= "Mountains" then
		return if map.Config.Preset == "Island" then "Sand" else "Mud"
	end
	if slope >= 38 then return "Rock" end
	if map.Config.Preset == "Mountains" and h >= map.Config.Height * 0.7 then return "Snow" end
	return "Grass"
end

-- Material names are converted to Enum.Material only at the engine boundary.
function Voxelizer.build(map)
	local materials, solids, liquids = {}, {}, {}
	local ny = map.Config.Height / 4
	for x = 1, map.NX do
		materials[x], solids[x], liquids[x] = {}, {}, {}
		for y = 1, ny do
			materials[x][y], solids[x][y], liquids[x][y] = {}, {}, {}
			local bottom = (y - 1) * 4
			for z = 1, map.NZ do
				local solid = math.clamp((map.Heights[x][z] - bottom) / 4, 0, 1)
				materials[x][y][z] = if solid > 0 then Voxelizer.material(map, x, z, bottom) else "Air"
				solids[x][y][z] = solid
				liquids[x][y][z] = if map.Wet[x][z] and solid < 1 then math.clamp((map.WaterLevel - bottom) / 4, 0, 1) else 0
			end
		end
	end
	return { SolidMaterial = materials, SolidOccupancy = solids, LiquidOccupancy = liquids }
end

return Voxelizer
