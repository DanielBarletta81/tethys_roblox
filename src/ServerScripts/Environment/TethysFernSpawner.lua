--!strict
-- Place inside ServerScriptService -> TethysFernSpawner
-- Generates dense prehistoric jungle visuals at low rendering costs

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Asset Vault Setup
local FernStorageFolder = ReplicatedStorage:FindFirstChild("PrehistoricAssets")
if not FernStorageFolder then
	FernStorageFolder = Instance.new("Folder")
	FernStorageFolder.Name = "PrehistoricAssets"
	FernStorageFolder.Parent = ReplicatedStorage
end

-- Fallback base asset generator if no custom model exists yet
local BaseFernModel = FernStorageFolder:FindFirstChild("CretaceousFern")
if not BaseFernModel then
	local model = Instance.new("Model")
	model.Name = "CretaceousFern"
	
	-- Smoke & Mirrors optimization trick: Single un-anchored, low-poly structural mesh part representing an entire leafy fern bundle
	local leafCluster = Instance.new("MeshPart")
	leafCluster.Name = "LeafCluster"
	leafCluster.Size = Vector3.new(8, 12, 8)
	leafCluster.Color = Color3.fromRGB(34, 76, 42)
	leafCluster.Material = Enum.Material.Grass
	leafCluster.Anchored = true
	leafCluster.CanCollide = false -- Extreme Performance Optimization: No structural calculation passes required
	leafCluster.Parent = model
	model.PrimaryPart = leafCluster
	model.Parent = FernStorageFolder
	BaseFernModel = model
end

local activeInstancedAssets: { [string]: {Model} } = {}

-- Spawns low-poly plant clusters around an incoming chunk vector coordinate boundary
local function spawnFernAssetsInChunk(chunkId: string, centerPos: Vector3, lod: string)
	if activeInstancedAssets[chunkId] then return end -- Already spawned
	
	local instancesCollection = {}
	-- "Smoke & Mirrors" Grid Density Scale: High LOD yields 12 plants; Medium drops to 4; Low drops to 0
	local spawnCount = lod == "High" and 12 or (lod == "Medium" and 4 or 0)
	
	if spawnCount == 0 then return end
	
	for i = 1, spawnCount do
		local fernClone = (BaseFernModel :: Model):Clone()
		
		-- Scatter position randomly within our 2048-stud chunk grid footprint
		local offsetX = math.random(-1024, 1024)
		local offsetZ = math.random(-1024, 1024)
		
		-- Use raycasting locally to find ground elevation automatically
		local spawnX = centerPos.X + offsetX
		local spawnZ = centerPos.Z + offsetZ
		local raycastOrigin = Vector3.new(spawnX, 300, spawnZ)
		local raycastDirection = Vector3.new(0, -600, 0)
		
		local result = workspace:Raycast(raycastOrigin, raycastDirection)
		local targetY = result and result.Position.Y or 20 -- Fallback baseline ground height
		
		local targetCFrame = CFrame.new(spawnX, targetY, spawnZ) 
			* CFrame.Angles(0, math.rad(math.random(0, 360)), 0) -- Randomized rotation to break visible patterns
			* CFrame.fromScaleOp(math.random(0.7, 1.5)) -- Randomized scale profile
			
		fernClone:PivotTo(targetCFrame)
		fernClone.Parent = workspace
		
		table.insert(instancesCollection, fernClone)
	end
	
	activeInstancedAssets[chunkId] = instancesCollection
end

-- Securely purges old tree/plant geometry from engine memory when players walk away
local function clearFernAssetsInChunk(chunkId: string)
	local collection = activeInstancedAssets[chunkId]
	if not collection then return end
	
	for _, instance in ipairs(collection) do
		instance:Destroy()
	end
	
	activeInstancedAssets[chunkId] = nil
	print(string.format("[Tethys Detailer] Cleared environmental models for chunk %s. Memory reclaimed.", chunkId))
end

-- Bind into your existing TethysStreamingService chunk loops by calling these entry points:
-- spawnFernAssetsInChunk(chunkId, centerVector, chunk.environmentalLOD)
-- clearFernAssetsInChunk(chunkId)

print("[Tethys Detailer] Optimized Fern Instancing Engine standing by for streaming events.")