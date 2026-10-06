-- Static source assets remain untouched. ScaleTo also handles SpecialMesh geometry.
local AssetPlacement = {}

function AssetPlacement.CloneStatic(source)
	if source:IsA("LuaSourceContainer") then return nil end
	local ok, clone = pcall(function() return source:Clone() end)
	if ok then return clone end
	-- Older Models may carry ScriptGlobals capabilities that Studio MCP cannot clone.
	-- Fresh static containers retain their geometry, attributes and authored pivot.
	assert(source:IsA("Model") or source:IsA("Folder"), tostring(clone))
	local rebuilt = Instance.new(source.ClassName)
	local copied, err = pcall(function()
		rebuilt.Name = source.Name
		for key, value in pairs(source:GetAttributes()) do rebuilt:SetAttribute(key, value) end
		for _, child in ipairs(source:GetChildren()) do
			local childClone = AssetPlacement.CloneStatic(child)
			if childClone then childClone.Parent = rebuilt end
		end
		if rebuilt:IsA("Model") then rebuilt.WorldPivot = source:GetPivot() end
		rebuilt:SetAttribute("ScatterRebuiltContainer", true)
	end)
	if not copied then rebuilt:Destroy(); error(err, 0) end
	return rebuilt
end

function AssetPlacement.Collect(sourceFolder, category)
	assert(typeof(sourceFolder) == "Instance" and sourceFolder:IsA("Folder"), "SourceFolder must be a Folder")
	local folder = sourceFolder:FindFirstChild(category)
	assert(folder and folder:IsA("Folder"), "Missing source category: " .. category)
	local assets, keys = {}, {}
	for _, source in ipairs(folder:GetChildren()) do
		if source.Archivable and (source:IsA("BasePart") or (source:IsA("Model") and source:FindFirstChildWhichIsA("BasePart", true))) then
			local key = source:GetAttribute("ScatterId") or source.Name
			assert(type(key) == "string" and key ~= "", "ScatterId must be a nonempty string")
			assert(not keys[key], "Duplicate source key: " .. key .. "; assign unique ScatterId attributes")
			keys[key] = true
			local cf, size
			if source:IsA("Model") then cf, size = source:GetBoundingBox() else cf, size = source.CFrame, source.Size end
			local radius = 0
			for _, x in ipairs({ -1, 1 }) do
				for _, y in ipairs({ -1, 1 }) do
					for _, z in ipairs({ -1, 1 }) do
						local corner = cf:VectorToWorldSpace(size * Vector3.new(x, y, z) * 0.5)
						radius = math.max(radius, Vector2.new(corner.X, corner.Z).Magnitude)
					end
				end
			end
			table.insert(assets, { Key = key, Source = source, Radius = radius })
		end
	end
	assert(#assets > 0, "No archivable Models or BaseParts in source category: " .. category)
	-- Persisted IDs make results independent of GetChildren ordering and duplicate names.
	table.sort(assets, function(a, b) return a.Key < b.Key end)
	return assets
end

local function bottomCenter(model)
	local cf, size = model:GetBoundingBox()
	local lowest = math.huge
	for _, x in ipairs({ -1, 1 }) do
		for _, y in ipairs({ -1, 1 }) do
			for _, z in ipairs({ -1, 1 }) do
				local corner = cf:PointToWorldSpace(size * Vector3.new(x, y, z) * 0.5)
				lowest = math.min(lowest, corner.Y)
			end
		end
	end
	return Vector3.new(cf.Position.X, lowest, cf.Position.Z)
end

function AssetPlacement.Place(asset, position, yaw, scale, groundOffset, parent)
	local clone = AssetPlacement.CloneStatic(asset.Source)
	assert(clone, "Could not clone source: " .. asset.Key)
	local model = clone
	if not clone:IsA("Model") then
		model = Instance.new("Model")
		clone.Parent = model
	end
	local ok, err = pcall(function()
		model.Name = asset.Source.Name
		for _, item in ipairs(model:GetDescendants()) do
			if item:IsA("LuaSourceContainer") then
				item:Destroy()
			elseif item:IsA("BasePart") then
				item.Anchored = true
			end
		end
		model:ScaleTo(model:GetScale() * scale)
		-- Keep authored orientation; random rotation is around world Y only.
		model:PivotTo(model:GetPivot().Rotation)
		local base = bottomCenter(model)
		local target = position + Vector3.new(0, groundOffset * scale, 0)
		model:PivotTo(CFrame.new(target) * CFrame.Angles(0, yaw, 0) * CFrame.new(-base) * model:GetPivot())
		model:SetAttribute("ScatterSourceId", asset.Key)
		model:SetAttribute("ScatterScale", scale)
		model:SetAttribute("ScatterYaw", yaw)
		model.Parent = parent
	end)
	if not ok then
		model:Destroy()
		error(err, 0)
	end
	return model
end

return AssetPlacement
