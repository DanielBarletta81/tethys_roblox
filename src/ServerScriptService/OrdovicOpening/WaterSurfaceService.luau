local RunService = game:GetService("RunService")
local Surface = {}
Surface.__index = Surface

function Surface.Sample(points, distance)
	if #points < 2 then return nil end
	local lengths, total = {}, 0
	for i = 1, #points - 1 do
		lengths[i] = (points[i + 1] - points[i]).Magnitude
		total += lengths[i]
	end
	if total < 0.01 then return nil end
	local d = distance % total
	for i, length in ipairs(lengths) do
		if length > 0 and d <= length then
			return points[i]:Lerp(points[i + 1], d / length), (points[i + 1] - points[i]).Unit, total
		end
		d -= length
	end
	return points[1], (points[2] - points[1]).Unit, total
end

local function pathFor(root, foam, ray)
	local zoneName = foam:GetAttribute("ZoneName")
	local lane = foam:GetAttribute("Lane") or 0
	local positions, speed, loop = {}, 0, false
	if zoneName == "WAKE" then
		local water = root["90_DEBUG"].TerrainWaterVolumes.WaterWake
		for i = 0, 20 do
			table.insert(positions, water.Position + Vector3.new(lane * 6, 0, -18 + i * 1.8))
		end
		speed = 1.4
	else
		local zone = root["03_FlowZones"]:FindFirstChild(zoneName)
		if not zone then return nil end
		speed = zone:GetAttribute("FlowSpeed") or 0
		loop = speed == 0
		if loop then
			-- A slow eddy communicates shelter without carrying the player onward.
			for i = 0, 24 do
				local theta = i / 24 * math.pi * 2
				table.insert(positions, zone.CFrame:PointToWorldSpace(Vector3.new(math.cos(theta) * 5, 0, math.sin(theta) * 5)))
			end
			speed = 0.45
		else
			local length = zone.Size.Z - 12
			local samples = math.max(12, math.ceil(length / 16))
			for i = 0, samples do
				local z = length / 2 - i / samples * length
				table.insert(positions, zone.CFrame:PointToWorldSpace(Vector3.new(lane * (zone.Size.X - 8), 0, z)))
			end
		end
	end
	local points = {}
	for _, p in ipairs(positions) do
		local hit = workspace:Raycast(p + Vector3.new(0, 80, 0), Vector3.new(0, -160, 0), ray)
		-- Never draw a navigational cue across a missing or non-water surface.
		if not hit or hit.Material ~= Enum.Material.Water then return nil end
		table.insert(points, hit.Position + Vector3.new(0, 0.09, 0))
	end
	local _, _, length = Surface.Sample(points, 0)
	if not length then return nil end
	return {Part = foam, Points = points, Length = length, Speed = speed, Loop = loop,
		Offset = (foam:GetAttribute("CycleOffset") or 0) * length}
end

function Surface.Start(root)
	if Surface.Active and Surface.Active.Root == root then return Surface.Active end
	if Surface.Active then Surface.Active:Stop() end
	local folder = root:FindFirstChild("09_WaterSurface")
	if not folder then return nil end
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Include
	ray.FilterDescendantsInstances = {workspace.Terrain}
	ray.IgnoreWater = false
	local self = setmetatable({Root = root, Paths = {}, Elapsed = 0, Accumulator = 0, Hidden = 0, Ray = ray}, Surface)
	for _, foam in ipairs(folder:GetChildren()) do
		if foam:IsA("BasePart") and foam:GetAttribute("Generator") == "OrdovicOpening"
			and foam:GetAttribute("BuildId") == root:GetAttribute("BuildId") then
			local path = pathFor(root, foam, ray)
			if path then table.insert(self.Paths, path) else foam.Transparency = 1; self.Hidden += 1 end
		end
	end
	folder:SetAttribute("ActiveSurfaceCues", #self.Paths)
	folder:SetAttribute("HiddenSurfaceCues", self.Hidden)
	self.Connection = RunService.Heartbeat:Connect(function(dt)
		if not root.Parent or not root:GetAttribute("OpeningEnabled") then self:Stop(); return end
		self.Elapsed += dt
		self.Accumulator += dt
		if self.Accumulator < 0.1 then return end
		self.Accumulator = 0
		for _, path in ipairs(self.Paths) do
			local d = (self.Elapsed * path.Speed + path.Offset) % path.Length
			local p, direction = Surface.Sample(path.Points, d)
			if path.Part.Parent and p then
				-- Terrain is voxel stepped; keep the moving effect on its actual surface.
				local hit = workspace:Raycast(p + Vector3.new(0, 8, 0), Vector3.new(0, -16, 0), self.Ray)
				if hit and hit.Material == Enum.Material.Water then
					p = hit.Position + Vector3.new(0, 0.09, 0)
					local flat = Vector3.new(direction.X, 0, direction.Z)
					path.Part.CFrame = CFrame.lookAt(p, p + (flat.Magnitude > 0.01 and flat or Vector3.zAxis))
					local fade = path.Loop and 1 or math.min(1, d / 6, (path.Length - d) / 6)
					path.Part.Transparency = 1 - (1 - path.Part:GetAttribute("BaseTransparency")) * fade
				else path.Part.Transparency = 1 end
			end
		end
	end)
	Surface.Active = self
	return self
end

function Surface:Stop()
	if self.Connection then self.Connection:Disconnect(); self.Connection = nil end
	for _, path in ipairs(self.Paths) do if path.Part.Parent then path.Part.Transparency = 1 end end
	if Surface.Active == self then Surface.Active = nil end
end
return Surface
