-- Local empty-patch authoring only. The river and water remain separate channels.
local Terrain = {}
function Terrain.Region(frame)
	assert(frame.UpVector:Dot(Vector3.yAxis) > 0.999, "Cave authoring requires an upright frame")
	local lo, hi = Vector3.one * math.huge, Vector3.one * -math.huge
	for _, x in ipairs({-36, 36}) do for _, y in ipairs({-8, 44}) do for _, z in ipairs({-84, 8}) do
		local p = frame:PointToWorldSpace(Vector3.new(x, y, z)); lo = lo:Min(p); hi = hi:Max(p)
	end end end
	return Region3.new(lo, hi):ExpandToGrid(4)
end
function Terrain.IsEmpty(region)
	local channels = workspace.Terrain:ReadVoxelChannels(region, 4, {"SolidOccupancy", "LiquidOccupancy"})
	for x, ys in ipairs(channels.SolidOccupancy) do for y, zs in ipairs(ys) do for z, value in ipairs(zs) do
		if value > 0 or channels.LiquidOccupancy[x][y][z] > 0 then return false end
	end end end
	return true
end
function Terrain.Fill(frame)
	local region = Terrain.Region(frame)
	assert(Terrain.IsEmpty(region), "Cave patch contains Terrain; preserve the sculpt and choose an empty patch")
	local channels = workspace.Terrain:ReadVoxelChannels(region, 4, {"SolidMaterial", "SolidOccupancy"})
	local minimum = region.CFrame.Position - region.Size / 2
	for x, ys in ipairs(channels.SolidOccupancy) do for y, zs in ipairs(ys) do for z in ipairs(zs) do
		local world = minimum + Vector3.new(x - 0.5, y - 0.5, z - 0.5) * 4
		local p = frame:PointToObjectSpace(world)
		local variation = math.noise(p.X / 16, p.Y / 14, p.Z / 20) * 2
		local insideFootprint = math.abs(p.X) < 34 and p.Z > -82 and p.Z < 5
		local shell = p.Y < 1 or math.abs(p.X) > 26 + variation
			or p.Y > 31 + variation or p.Z < -75
		if insideFootprint and shell then
			channels.SolidMaterial[x][y][z] = p.Y > 23 and Enum.Material.Rock or Enum.Material.Limestone
			channels.SolidOccupancy[x][y][z] = 1
		end
	end end end
	workspace.Terrain:WriteVoxelChannels(region, 4, {
		SolidMaterial = channels.SolidMaterial, SolidOccupancy = channels.SolidOccupancy,
	})
	return region
end
return Terrain
