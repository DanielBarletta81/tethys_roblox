-- Writes water without erasing native rock. All target boxes are preflighted first.
local Water = {}
function Water.Bounds(part)
	local low, high = Vector3.one * math.huge, Vector3.one * -math.huge
	for _, x in ipairs({-1,1}) do for _, y in ipairs({-1,1}) do for _, z in ipairs({-1,1}) do
		local p = part.CFrame:PointToWorldSpace(part.Size * Vector3.new(x,y,z) / 2)
		low = low:Min(p); high = high:Max(p)
	end end end
	return Region3.new(low,high):ExpandToGrid(4)
end
function Water.Fill(volumes)
	for i, part in ipairs(volumes:GetChildren()) do
		local region = Water.Bounds(part)
		local channels = workspace.Terrain:ReadVoxelChannels(region, 4, {"SolidOccupancy", "LiquidOccupancy"})
		local minimum = region.CFrame.Position - region.Size / 2
		for x, ys in ipairs(channels.LiquidOccupancy) do for y, zs in ipairs(ys) do for z, value in ipairs(zs) do
			local p = part.CFrame:PointToObjectSpace(minimum + Vector3.new(x-0.5,y-0.5,z-0.5) * 4)
			local half = part.Size / 2
			-- Account for partial vertical cells in the thin flume and wake stream.
			if math.abs(p.X) <= half.X and math.abs(p.Z) <= half.Z then
				local occupancy = math.clamp((half.Y - p.Y + 2) / 4, 0, 1)
				if p.Y >= -half.Y-2 and channels.SolidOccupancy[x][y][z] < 1 then
					channels.LiquidOccupancy[x][y][z] = math.max(value, occupancy)
				end
			end
		end end end
		workspace.Terrain:WriteVoxelChannels(region, 4, {LiquidOccupancy = channels.LiquidOccupancy})
		if i % 8 == 0 then task.wait() end
	end
end
return Water
