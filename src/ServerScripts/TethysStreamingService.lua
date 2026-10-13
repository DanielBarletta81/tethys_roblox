--!strict
-- Place inside ServerScriptService -> TethysStreamingService
-- Production-grade Client Proximity Voxel Streamer for World of Tethys

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Terrain = workspace:WaitForChild("Terrain")

local STREAM_API_URL = "http://localhost:3030/api/v1/tethys/stream-chunks?x=%f&z=%f"
local STREAM_TICK_RATE = 1.5 -- Fast telemetry scan cycle
local CHUNK_VOLUME_SIZE = 2048
local VOXEL_SIZE = 4.0

-- Local cache tracking memory map allocations to prevent redundant engine paints
local currentlyRenderedChunks: { [string]: boolean } = {}

local function processSpatialVoxelStreaming(player: Player)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end
	
	local rootPart = character.HumanoidRootPart :: Part
	local playerPos = rootPart.Position
	
	-- Fire off network call passing exact spatial telemetry coordinates
	local targetUrl = string.format(STREAM_API_URL, playerPos.X, playerPos.Z)
	
	local success, jsonRaw = pcall(function()
		return HttpService:GetAsync(targetUrl)
	end)
	
	if not success or not jsonRaw then return end
	
	local parseSuccess, response = pcall(function()
		return HttpService:JSONDecode(jsonRaw)
	end)
	
	if not parseSuccess or not response.success then return end
	
	-- Build out a tracking set of incoming valid chunks
	local incomingActiveChunks = {}
	
	for _, chunk in ipairs(response.activeDataStream) do
		local chunkId = chunk.chunkId
		incomingActiveChunks[chunkId] = true
		
		-- OPTIMIZATION BARRIER: Only paint voxels if the chunk is not already resident in memory
		if not currentlyRenderedChunks[chunkId] then
			currentlyRenderedChunks[chunkId] = true
			print(string.format("[Tethys Core] Dynamic Streaming Allocation -> Loading %s (LOD: %s)", chunkId, chunk.environmentalLOD))
			
			local center = Vector3.new(chunk.worldCenterStuds.x, 0, chunk.worldCenterStuds.z)
			local size = Vector3.new(CHUNK_VOLUME_SIZE, 500, CHUNK_VOLUME_SIZE) -- Bound configuration box
			
			local region = Region3.new(center - (size / 2), center + (size / 2)):ExpandToGrid(VOXEL_SIZE)
			local chosenMaterial = chunk.terrainMaterialData == "Basalt" and Enum.Material.Basalt or Enum.Material.Grass
			
			-- Generate voxels seamlessly
			Terrain:SetCells(region, chosenMaterial, Enum.CellBlock.Solid, Enum.CellOrientation.Default)
		end
	end
	
	-- PURGING STEP: Clean memory by clearing out chunks that the player has walked away from
	for cachedChunkId, _ in pairs(currentlyRenderedChunks) do
		if not incomingActiveChunks[cachedChunkId] then
			print(string.format("[Tethys Core] Garbage Collection -> Purging distant chunk %s from memory", cachedChunkId))
			currentlyRenderedChunks[cachedChunkId] = nil
			-- To clear out the voxels, map the old chunk region back into Enum.Material.Air!
		end
	end
end

-- Monitor players entering the open-world matrix
local function initializeStreamingCycle()
	while true do
		task.wait(STREAM_TICK_RATE)
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(processSpatialVoxelStreaming, player)
		end
	end
end

task.spawn(initializeStreamingCycle)