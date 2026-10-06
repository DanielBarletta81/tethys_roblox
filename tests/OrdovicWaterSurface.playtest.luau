-- Run as a temporary Script inside the approved OrdovicOpening sandbox in Play.
local Http = game:GetService("HttpService")
local Surface = require(script.Parent.WaterSurfaceService)
local root = workspace.WildboundOpening_Ordovic
local results = {}
local function check(name, action)
	local ok, err = pcall(action)
	table.insert(results, {name = name, passed = ok, error = not ok and tostring(err) or nil})
end
task.wait(1)
local service = Surface.Active
check("distance sampling follows bends and wraps", function()
	local points = {Vector3.zero, Vector3.new(10,0,0), Vector3.new(10,0,20)}
	local p, direction, length = Surface.Sample(points, 15)
	assert(p == Vector3.new(10,0,5) and direction == Vector3.zAxis and length == 30)
	assert(Surface.Sample(points, 35) == Vector3.new(5,0,0))
	assert(Surface.Sample({Vector3.zero,Vector3.zero}, 0) == nil)
end)
check("real Terrain water backs every installed cue", function()
	assert(service and #service.Paths == root["09_WaterSurface"]:GetAttribute("SurfaceCueCount"))
	assert(service.Hidden == 0, "A path crosses missing Terrain water")
	for _, path in ipairs(service.Paths) do assert(#path.Points >= 2 and path.Length > 1) end
end)
check("ridge approach calms before intake", function()
	local flow = root["03_FlowZones"]
	assert(flow.FZMain_9:GetAttribute("FlowSpeed") > flow.FZMain_10:GetAttribute("FlowSpeed"))
	assert(flow.FZMain_10:GetAttribute("FlowSpeed") > flow.FZMain_11:GetAttribute("FlowSpeed"))
end)
check("cues animate on the water without collision or input", function()
	assert(service and #service.Paths > 0)
	local path = service.Paths[1]
	local before = path.Part.Position
	task.wait(0.6)
	assert((path.Part.Position - before).Magnitude > 0.05)
	assert(not path.Part.CanCollide and not path.Part.CanTouch and not path.Part.CanQuery)
	assert(path.Part.Transparency < 1)
end)
check("recovery eddies and Wake remain slower than main water", function()
	local seenWake, seenRecovery = false, false
	for _, path in ipairs(service.Paths) do
		if path.Part:GetAttribute("ZoneName") == "WAKE" then seenWake = true; assert(path.Speed == 1.4) end
		if path.Loop then seenRecovery = true; assert(path.Speed == 0.45) end
	end
	assert(seenWake and seenRecovery)
end)
check("missing water suppresses a cue rather than drawing a false route", function()
	local fixture = Instance.new("Folder"); fixture.Name = "SurfaceMissingWaterFixture"
	fixture:SetAttribute("BuildId", root:GetAttribute("BuildId")); fixture:SetAttribute("OpeningEnabled", true)
	local zones = Instance.new("Folder"); zones.Name = "03_FlowZones"; zones.Parent = fixture
	local zone = Instance.new("Part"); zone.Name = "FZMain_Gap"; zone.Size = Vector3.new(20,24,32)
	zone.CFrame = CFrame.new(0,10000,0); zone:SetAttribute("FlowSpeed", 8); zone.Parent = zones
	local folder = Instance.new("Folder"); folder.Name = "09_WaterSurface"; folder.Parent = fixture
	local cue = Instance.new("Part"); cue.Name = "GapCue"; cue.Transparency = 0
	cue:SetAttribute("Generator", "OrdovicOpening"); cue:SetAttribute("BuildId", root:GetAttribute("BuildId"))
	cue:SetAttribute("ZoneName", zone.Name); cue.Parent = folder
	fixture.Parent = game.ServerStorage
	local ok, err = pcall(function()
		local gap = Surface.Start(fixture)
		assert(gap.Hidden == 1 and #gap.Paths == 0 and cue.Transparency == 1)
		gap:Stop()
	end)
	fixture:Destroy()
	service = Surface.Start(root)
	assert(ok, err)
end)
check("surface lifecycle is idempotent and stops cleanly", function()
	assert(Surface.Start(root) == service)
	service:Stop()
	assert(service.Connection == nil and Surface.Active == nil)
	for _, path in ipairs(service.Paths) do assert(path.Part.Transparency == 1) end
	service = Surface.Start(root)
	assert(service and service.Connection)
end)
check("upstream closure survives and contains no active connection", function()
	local upstream = root["01_High_Cave"]["01_RockShell"].BlockedUpstream
	assert(upstream.CanCollide and upstream:GetAttribute("OpeningBoundary") == "ClosedUpstream")
	assert(upstream:GetAttribute("FutureConnection") == "UserAuthoredUpstream")
	assert(#upstream:GetChildren() == 0)
end)
script:SetAttribute("Results", Http:JSONEncode(results))
