--!strict
-- Place inside ServerScriptService -> TethysStreamingService
-- Ingests API layout vectors and programmatically fills block dimensions live

local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local STREAM_URL = "http://localhost:3030/api/v1/liveops/variant-stream"
local activeTerrain = Workspace.Terrain

type Vector3Data = { x: number, y: number, z: number }
type TerrainSegment = {
	id: string,
	name: string,
	targetMaterial: string,
	centerStuds: Vector3Data,
	sizeStuds: Vector3Data,
	loadPriority: number
}

local function renderVectorTopology(segments: {TerrainSegment})
	print("🏗️ [Terrain Engine] Re-stitching global landscape vectors...")
	
	-- Sort segments by loadPriority so base structural components draw first
	table.sort(segments, function(a, b)
		return a.loadPriority < b.loadPriority
	end)

	for _, segment in ipairs(segments) do
		-- Safe conversion from coordinate data to native engine vectors
		local centerCFrame = CFrame.new(segment.centerStuds.x, segment.centerStuds.y, segment.centerStuds.z)
		local sizeVector = Vector3.new(segment.sizeStuds.x, segment.sizeStuds.y, segment.sizeStuds.z)
		
		-- Resolve material enum safely
		local successMaterial, materialEnum = pcall(function()
			return Enum.Material[segment.targetMaterial]
		end)
		
		if successMaterial and materialEnum then
			-- The core engine paint brush: programmatically instantiates the biome geometry
			activeTerrain:FillBlock(centerCFrame, sizeVector, materialEnum)
			print(string.format("✅ [Voxel Stream] Rendered: %s (%s)", segment.name, segment.targetMaterial))
		else
			warn(string.format("❌ [Voxel Error] Unknown material parameter: %s", segment.targetMaterial))
		end
	end
end

function TethysStreamingService.PollActiveLayout()
	local success, jsonRaw = pcall(function()
		return HttpService:GetAsync(STREAM_URL)
	end)
	
	if success and jsonRaw then
		local parseSuccess, response = pcall(function()
			return HttpService:JSONDecode(jsonRaw)
		end)
		
		if parseSuccess and response.success and response.segments then
			renderVectorTopology(response.segments)
		end
	end
end

-- Fire background synchronization loop daemon
task.spawn(function()
	while true do
		TethysStreamingService.PollActiveLayout()
		task.wait(15) -- Refresh terrain topology bounds every 15 seconds
	end
end)

return TethysStreamingService