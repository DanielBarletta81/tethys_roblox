local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local RobloxBackend = {}

local function region(bounds)
	local low = Vector3.new(bounds.X, bounds.Y, bounds.Z)
	return Region3.new(low, low + Vector3.new(bounds.Width, bounds.Height, bounds.Length))
end

function RobloxBackend.new(pluginInstance)
	local terrain = workspace.Terrain
	local backend = { IgnorePart = nil }
	local function ownedFolder()
		local generated = workspace:FindFirstChild("Generated")
		if not generated or not generated:IsA("Folder") then return nil end
		local folder = generated:FindFirstChild("TethysTerrain")
		if folder and folder:IsA("Folder") and folder:GetAttribute("Generator") == "TethysTerrain" then return folder end
		return nil
	end
	function backend.IsEditMode() return RunService:IsEdit() end
	function backend.CheckBounds(bounds)
		local box = region(bounds)
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = if backend.IgnorePart then { backend.IgnorePart } else {}
		params.MaxParts = 1
		local parts = workspace:GetPartBoundsInBox(box.CFrame, box.Size, params)
		assert(#parts == 0, "A queryable Part overlaps this box. Choose an empty patch or use a selected bounds guide")
	end
	function backend.Read(bounds)
		return terrain:ReadVoxelChannels(region(bounds), 4, { "SolidMaterial", "SolidOccupancy", "LiquidOccupancy" })
	end
	function backend.Write(bounds, channels)
		local converted = {}
		for x, column in ipairs(channels.SolidMaterial) do
			converted[x] = {}
			for y, row in ipairs(column) do
				converted[x][y] = {}
				for z, material in ipairs(row) do
					converted[x][y][z] = if type(material) == "string" then Enum.Material[material] else material
				end
			end
		end
		terrain:WriteVoxelChannels(region(bounds), 4, {
			SolidMaterial = converted, SolidOccupancy = channels.SolidOccupancy, LiquidOccupancy = channels.LiquidOccupancy,
		})
	end
	function backend.Begin(label)
		local id = ChangeHistoryService:TryBeginRecording("TethysTerrainEdit", label)
		if id then pluginInstance:SetAttribute("TethysTerrainRecording", id) end
		return id
	end
	function backend.Finish(id, commit)
		local operation = if commit then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel
		local ok, err = pcall(function() ChangeHistoryService:FinishRecording(id, operation) end)
		if not ok then
			-- Keep ownership of this plugin's recording; never reset global history.
			pcall(function() ChangeHistoryService:FinishRecording(id, Enum.FinishRecordingOperation.Cancel) end)
		end
		pluginInstance:SetAttribute("TethysTerrainRecording", nil)
		assert(ok, tostring(err))
	end
	function backend.CancelPending()
		local id = pluginInstance:GetAttribute("TethysTerrainRecording")
		if id then backend.Finish(id, false) end
	end
	function backend.CreateMetadata(map, bounds)
		local generated = workspace:FindFirstChild("Generated")
		assert(not generated or generated:IsA("Folder"), "Workspace.Generated is not a Folder")
		if not generated then generated = Instance.new("Folder"); generated.Name = "Generated"; generated.Parent = workspace end
		local folder = generated:FindFirstChild("TethysTerrain")
		assert(not folder or ownedFolder() == folder, "TethysTerrain metadata name is occupied by unrelated content")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "TethysTerrain"
			folder:SetAttribute("Generator", "TethysTerrain")
			folder.Parent = generated
		end
		local id = HttpService:GenerateGUID(false)
		local pass = Instance.new("Folder")
		pass.Name = "Pass_" .. id
		for key, value in pairs({ Generator = "TethysTerrain", Version = "0.1.0", PassId = id,
			Seed = map.Config.Seed, Preset = map.Config.Preset, Category = "Terrain", Settings = HttpService:JSONEncode(map.Config) }) do
			pass:SetAttribute(key, value)
		end
		pass:SetAttribute("BoundsMin", Vector3.new(bounds.X, bounds.Y, bounds.Z))
		pass:SetAttribute("BoundsSize", Vector3.new(bounds.Width, bounds.Height, bounds.Length))
		pass.Parent = folder
		return id
	end
	function backend.HasMetadata(id)
		local folder = ownedFolder()
		local pass = folder and folder:FindFirstChild("Pass_" .. id)
		return pass ~= nil and pass:GetAttribute("Generator") == "TethysTerrain" and pass:GetAttribute("PassId") == id
	end
	function backend.RemoveMetadata(id)
		assert(backend.HasMetadata(id), "Pass ownership mismatch")
		ownedFolder():FindFirstChild("Pass_" .. id):Destroy()
	end
	return backend
end

return RobloxBackend
