--!strict
-- Place this inside a Script within ServerScriptService
local HttpService = game:GetService("HttpService")
local Terrain = workspace:WaitForChild("Terrain")

local VOXEL_SIZE = 4.0

-- Declare precise type interfaces for runtime safety
type SegmentPayload = {
	id: string,
	name: string,
	targetMaterial: string,
	hexMaskColor: string,
	centerStuds: {x: number, y: number, z: number},
	sizeStuds: {x: number, y: number, z: number},
	loadPriority: number
}

-- Simulating the structural response delivered from our TypeScript backend configuration
local mockJsonResponse = [[
{
	"segments": [
		{"id": "volcano", "name": "Watcher Island", "targetMaterial": "Basalt", "centerStuds":{"x":-8000,"y":500,"z":-8000}, "sizeStuds":{"x":4000,"y":1762,"z":4000}, "loadPriority": 2},
		{"id": "ridge", "name": "Cimmerian Ridge", "targetMaterial": "Rock", "centerStuds":{"x":4000,"y":800,"z":4000}, "sizeStuds":{"x":12000,"y":2500,"z":8000}, "loadPriority": 1},
		{"id": "city", "name": "Sky City Basin", "targetMaterial": "Grass", "centerStuds":{"x":5000,"y":200,"z":5000}, "sizeStuds":{"x":3500,"y":100,"z":3500}, "loadPriority": 3}
	]
}
]]

local function processRemoteConfigPayload(jsonString: string)
	local success, decodedData = pcall(function()
		return HttpService:JSONDecode(jsonString)
	end)
	
	if not success or not decodedData or not decodedData.segments then
		warn("[ELO Engine Error] Critically malformed JSON payload streaming from configuration hub.")
		return
	end
	
	local segments: {SegmentPayload} = decodedData.segments
	
	-- SORTING STEP: Ensure base layers are drawn before city basins override them
	table.sort(segments, function(a, b)
		return a.loadPriority < b.loadPriority
	end)
	
	-- EXECUTION STEP: Safe voxel painting via defensive wrappers
	for _, segment in ipairs(segments) do
		print(string.format("[ELO Stream] Initializing voxels for: %s", segment.name))
		
		local materialSuccess, targetEnum = pcall(function()
			return Enum.Material[segment.targetMaterial]
		end)
		
		if not materialSuccess or not targetEnum then
			warn(string.format("[ELO Telemetry] Dropped invalid terrain assignment material: %s", segment.targetMaterial))
			continue
		end
		
		-- Frame the spatial structural volume data
		local position = Vector3.new(segment.centerStuds.x, segment.centerStuds.y, segment.centerStuds.z)
		local size = Vector3.new(segment.sizeStuds.x, segment.sizeStuds.y, segment.sizeStuds.z)
		
		local minBound = position - (size / 2)
		local maxBound = position + (size / 2)
		
		local region = Region3.new(minBound, maxBound):ExpandToGrid(VOXEL_SIZE)
		
		-- Commit voxels securely to memory
		local paintSuccess, runtimeErr = pcall(function()
			Terrain:SetCells(region, targetEnum, Enum.CellBlock.Solid, Enum.CellOrientation.Default)
		end)
		
		if not paintSuccess then
			warn(string.format("[ELO Crash Prevention] Failed to commit voxel region %s: %s", segment.id, tostring(runtimeErr)))
		end
	end
	
	print("[ELO Engine] System synchronization successful. Cretaceous earthscape successfully deployed to server voxels.")
end

processRemoteConfigPayload(mockJsonResponse)
