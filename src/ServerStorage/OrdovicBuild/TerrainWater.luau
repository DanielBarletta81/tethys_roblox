local Water={}
local function bounds(part)
	local lo,hi=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
	for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
		local p=part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2)
		lo=lo:Min(p);hi=hi:Max(p)
	end end end
	return Region3.new(lo,hi):ExpandToGrid(4)
end
function Water.Preflight(volumes)
	local regions={}
	-- Preflight every cell before changing any terrain, including overlapping boxes.
	for _,p in ipairs(volumes:GetChildren()) do
		local region=bounds(p)
		local channels=workspace.Terrain:ReadVoxelChannels(region,4,{"SolidOccupancy","LiquidOccupancy"})
		local solid,liquid=channels.SolidOccupancy,channels.LiquidOccupancy
		for x=1,#solid do for y=1,#solid[x] do for z=1,#solid[x][y] do
			assert(solid[x][y][z]==0 and liquid[x][y][z]==0,"Existing terrain intersects "..p.Name.."; no terrain was written")
		end end end
		table.insert(regions,{Part=p,Region=region})
	end
	return regions
end
function Water.Fill(volumes,backupFolder)
	local regions=Water.Preflight(volumes)
	for _,item in ipairs(regions) do
		local min=item.Region.CFrame.Position-item.Region.Size/2
		local max=item.Region.CFrame.Position+item.Region.Size/2
		local low=Vector3int16.new(math.floor(min.X/4),math.floor(min.Y/4),math.floor(min.Z/4))
		local high=Vector3int16.new(math.floor(max.X/4)-1,math.floor(max.Y/4)-1,math.floor(max.Z/4)-1)
		local copy=workspace.Terrain:CopyRegion(Region3int16.new(low,high))
		copy.Name=item.Part.Name
		copy:SetAttribute("VoxelMin",Vector3.new(low.X,low.Y,low.Z))
		copy:SetAttribute("BuildId","OrdovicV1_20261006")
		copy.Parent=backupFolder
	end
	for _,item in ipairs(regions) do workspace.Terrain:FillBlock(item.Part.CFrame,item.Part.Size,Enum.Material.Water) end
	return #regions
end
function Water.Restore(backupFolder)
	for _,region in ipairs(backupFolder:GetChildren()) do
		local p=region:GetAttribute("VoxelMin")
		workspace.Terrain:PasteRegion(region,Vector3int16.new(p.X,p.Y,p.Z),true)
	end
end
return Water
