-- Require from Studio's Command Bar. Nothing runs when the game starts.
local RunService = game:GetService("RunService")
local History = game:GetService("ChangeHistoryService")
local Scatter = require(game:GetService("ReplicatedStorage").Tethys.WorldModules.Scatter.NatureScatter)
local Driver = {}

local function editOnly()
	assert(RunService:IsStudio() and not RunService:IsRunning(), "Use the Studio Command Bar in edit mode")
end

local function record(label, action)
	editOnly()
	-- Studio MCP already records its command. Reuse that outer recording.
	if History:IsRecordingInProgress() then return action() end
	local recording = History:TryBeginRecording("TethysNatureScatter", label)
	assert(recording, "Could not start Studio undo recording; finish the current recording and retry")
	local results = table.pack(pcall(action))
	History:FinishRecording(recording, results[1] and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
	if not results[1] then error(results[2], 0) end
	return table.unpack(results, 2, results.n)
end

local function zones()
	local systems = workspace:FindFirstChild("WorldSystems")
	local folder = systems and systems:FindFirstChild("ScatterZones")
	assert(folder and folder:IsA("Folder"), "Missing Workspace.WorldSystems.ScatterZones")
	return folder
end

function Driver.CreateZone(name, cf, size)
	assert(type(name) == "string" and name:match("^ZONE_[%w_%-]+$"), "Use a unique ZONE_ name")
	assert(typeof(cf) == "CFrame" and typeof(size) == "Vector3" and size.X > 0 and size.Y > 0 and size.Z > 0, "Provide a CFrame and positive Vector3 size")
	assert(cf.UpVector:Dot(Vector3.yAxis) > 0.99999, "Zone must be upright")
	assert(not zones():FindFirstChild(name), "Zone already exists: " .. name)
	return record("Create scatter zone", function()
		local zone = Instance.new("Part")
		zone.Name, zone.CFrame, zone.Size = name, cf, size
		zone.Anchored, zone.CanCollide, zone.CanTouch, zone.CanQuery = true, false, false, false
		zone.CastShadow, zone.Transparency = false, 1
		zone.Color = Color3.fromRGB(74, 91, 58)
		zone:SetAttribute("TethysScatterZone", true)
		zone.Parent = zones()
		return zone
	end)
end

function Driver.Generate(zoneName, overrides)
	editOnly()
	local zone = zones():FindFirstChild(zoneName)
	assert(zone and zone:IsA("BasePart"), "Missing scatter zone: " .. tostring(zoneName))
	local assets = game:GetService("ServerStorage"):FindFirstChild("TethysAssets")
	local source = assets and assets:FindFirstChild("Nature")
	local options = table.clone(overrides or {})
	options.Category = options.Category or "Trees"
	options.Zone = zone
	options.SourceFolder = options.SourceFolder or source
	options.PassName = options.PassName or ("GEN_" .. zoneName:gsub("^ZONE_", "") .. "_" .. options.Category .. "_01")
	return record("Generate " .. options.PassName, function()
		local folder, stats = Scatter.Generate(options)
		print(string.format("Nature Scatter: %s | %d/%d placed | %d attempts", folder.Name, stats.Placed, stats.Requested, stats.Attempts))
		if stats.Shortfall > 0 then warn("Placement shortfall: inspect returned rejection counts or reduce Count/MinSpacing") end
		return folder, stats
	end)
end

function Driver.Clear(name)
	return record("Clear " .. name, function() return Scatter.Clear(name) end)
end

return Driver
