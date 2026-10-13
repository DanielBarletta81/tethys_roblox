-- Small adapter for the existing shared camp owner; not a free-build or terrain tool.
local Rest = require(script.Parent.RestService)
local Kit = {}
Kit.Specs = {
	Shelter = {cost = {Fiber = 1, Stone = 1}, action = "Build covered shelter", label = "Covered shelter"},
	RestSpot = {cost = {Fiber = 1}, action = "Raise the sleeping place", label = "Raised sleep"},
	Storage = {cost = {Fiber = 1, Resin = 1}, action = "Make shared storage", label = "Shared storage"},
	Boundary = {cost = {Stone = 1}, action = "Mark camp boundary", label = "Camp boundary"},
	WaterBasin = {cost = {Stone = 2}, action = "Build water basin", label = "Water basin"},
	HeatPit = {cost = {Stone = 2, Fiber = 1}, action = "Prepare heat pit", label = "Heat pit"},
}
function Kit.Description(kind)
	local spec, costs = Kit.Specs[kind], {}
	for _, material in ipairs({"Fiber", "Stone", "Resin"}) do
		if spec.cost[material] then table.insert(costs, spec.cost[material] .. " " .. material:lower()) end
	end
	return spec.label .. " · " .. table.concat(costs, " + ")
end
function Kit.RefreshRest(site, id)
	local ready, reason = Rest.CanUse(site)
	local assembled = true
	for kind in pairs(Kit.Specs) do
		if not site:FindFirstChild("Built_" .. kind) then assembled = false end
	end
	site:SetAttribute("WB_RestReady", ready)
	site:SetAttribute("WB_RestStatus", ready and "Covered sleep, stored water and heat are ready." or reason)
	local anchor = site:FindFirstChild("BuildAnchor_RestSpot")
	local restPrompt = anchor and anchor:FindFirstChild("RestAtCampPrompt")
	if restPrompt then
		restPrompt.ActionText = ready and "Rest until morning" or "Check Rest"
		restPrompt.ObjectText = ready and id:gsub("^Camp_[A-Z]_", ""):gsub("(%l)(%u)", "%1 %2") or reason
		-- An assembled but cold/dry camp can explain itself; Claim still revalidates.
		restPrompt.Enabled = assembled
	end
	return ready
end
local offsets = {Shelter = Vector3.zero, RestSpot = Vector3.zero, Storage = Vector3.new(7, 0, 4),
	Boundary = Vector3.new(0, 0, -8), WaterBasin = Vector3.new(6, 0, -3), HeatPit = Vector3.new(-6, 0, -3)}
function Kit.Anchor(plot, kind)
	local point = plot.CFrame:PointToWorldSpace(offsets[kind])
	local params = RaycastParams.new()
	params.RespectCanCollide = true
	params.FilterType = Enum.RaycastFilterType.Exclude
	local built = plot.Parent:FindFirstChild("AlphaCampBuild")
	params.FilterDescendantsInstances = built and {built} or {}
	local hit = workspace:Raycast(point + Vector3.new(0, 96, 0), Vector3.new(0, -192, 0), params)
	if not hit or hit.Material == Enum.Material.Water or hit.Normal.Y < 0.8 then return nil end
	return hit.Position + Vector3.new(0, 0.15, 0)
end
function Kit.Build(site, kind, position)
	local old = site:FindFirstChild("Built_" .. kind)
	if old then return old end
	local model = Instance.new("Model")
	model.Name = "Built_" .. kind
	model:SetAttribute("BuiltByCommunity", true)
	model:SetAttribute("Generator", "FieldholdRestKit")
	local function piece(name, size, offset, material, color, collide)
		local p = Instance.new("Part")
		p.Name, p.Size, p.Position = name, size, position + offset
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, collide == true, false, true
		p.Material, p.Color = material, color
		p:SetAttribute("WB_Condition", 1)
		p.Parent = model
		return p
	end
	local wood, stone, woven = Color3.fromRGB(95, 71, 48), Color3.fromRGB(88, 94, 93), Color3.fromRGB(134, 111, 77)
	if kind == "Shelter" then
		for _, x in ipairs({-2.7, 2.7}) do piece("Post_" .. tostring(x), Vector3.new(0.6, 7.2, 0.6), Vector3.new(x, 3.6, -2.7), Enum.Material.Wood, wood, true) end
		piece("Ridge", Vector3.new(6, 0.4, 0.6), Vector3.new(0, 7.2, -2.7), Enum.Material.Wood, wood, false)
		piece("Cover", Vector3.new(7, 0.35, 8), Vector3.new(0, 7.5, 0), Enum.Material.Grass, Color3.fromRGB(79, 96, 64), true)
	elseif kind == "RestSpot" then
		piece("SleepPlatform", Vector3.new(4, 0.3, 6), Vector3.new(0, 1.1, 0), Enum.Material.Wood, wood, true)
		piece("WovenMat", Vector3.new(3.5, 0.1, 5.5), Vector3.new(0, 1.3, 0), Enum.Material.Fabric, woven, false)
		for _, x in ipairs({-1.6, 1.6}) do for _, z in ipairs({-2.5, 2.5}) do piece("Leg_" .. x .. "_" .. z, Vector3.new(0.5, 1, 0.5), Vector3.new(x, 0.5, z), Enum.Material.Wood, wood, true) end end
	elseif kind == "Storage" then
		piece("SuppliesBox", Vector3.new(2.5, 1.5, 2), Vector3.new(0, 0.75, 0), Enum.Material.Wood, wood, true)
	elseif kind == "Boundary" then
		piece("MarkerPost", Vector3.new(0.5, 2.2, 0.5), Vector3.new(0, 1.1, 0), Enum.Material.Wood, wood, true)
		piece("MarkerTop", Vector3.new(1.1, 0.2, 0.3), Vector3.new(0, 1.8, 0), Enum.Material.Fabric, woven, false)
	elseif kind == "WaterBasin" then
		local basin = piece("Basin", Vector3.new(2.5, 0.5, 2.5), Vector3.new(0, 0.25, 0), Enum.Material.Slate, stone, true)
		basin:SetAttribute("StoredWater", 0)
		for _, x in ipairs({-1.2, 1.2}) do piece("Rim_" .. x, Vector3.new(0.3, 0.6, 2.5), Vector3.new(x, 0.7, 0), Enum.Material.Slate, stone, true) end
		for _, z in ipairs({-1.2, 1.2}) do piece("RimZ_" .. z, Vector3.new(2.5, 0.6, 0.3), Vector3.new(0, 0.7, z), Enum.Material.Slate, stone, true) end
		local water = piece("StoredWaterSurface", Vector3.new(2.1, 0.05, 2.1), Vector3.new(0, 0.65, 0), Enum.Material.Glass, Color3.fromRGB(52, 111, 122), false)
		water.Transparency = 1
	elseif kind == "HeatPit" then
		piece("Pit", Vector3.new(2.5, 0.25, 2.5), Vector3.new(0, 0.125, 0), Enum.Material.Slate, stone, true)
		local heat = piece("Heat", Vector3.new(1.2, 0.3, 1.2), Vector3.new(0, 0.4, 0), Enum.Material.Neon, Color3.fromRGB(181, 91, 43), false)
		heat:SetAttribute("WarmUntil", os.clock() + 600)
		local light = Instance.new("PointLight")
		light.Color, light.Brightness, light.Range, light.Parent = heat.Color, 0.7, 10, heat
	end
	model.Parent = site
	return model
end
local function prompt(anchor, name, action)
	local p = Instance.new("ProximityPrompt")
	p.Name, p.ActionText, p.ObjectText, p.HoldDuration = name, action, "Fieldhold", 0.5
	-- Decorative guides are queryable; the server ray validates solid occlusion instead.
	p.MaxActivationDistance, p.RequiresLineOfSight, p.Parent = 10, false, anchor
	p.KeyboardKeyCode, p.GamepadKeyCode = Enum.KeyCode.F, Enum.KeyCode.ButtonX
	return p
end
function Kit.Bind(site, id)
	Rest.Register(site, id)
	local waterAnchor, heatAnchor = site.BuildAnchor_WaterBasin, site.BuildAnchor_HeatPit
	local fill = prompt(waterAnchor, "StoreWaterPrompt", "Store water")
	local fuel = prompt(heatAnchor, "FuelHeatPrompt", "Feed heat")
	fill.ObjectText, fuel.ObjectText = "Water basin · filled waterskin", "Heat pit · 1 dry fiber"
	fill.Triggered:Connect(function(player)
		local model = site:FindFirstChild("Built_WaterBasin")
		local basin = model and model:FindFirstChild("Basin")
		if not basin or not Rest.InRange(player, waterAnchor, 10) or basin:GetAttribute("StoredWater") > 0 then return end
		local inventory = player:FindFirstChild("Inventory")
		local waterSkin = inventory and inventory:FindFirstChild("WaterSkin")
		if not waterSkin or not waterSkin:IsA("IntValue") or waterSkin.Value < 1 then
			player:SetAttribute("SC_Message", "A filled waterskin is needed for the basin."); return
		end
		-- Prototype supplies treat one WaterSkin inventory unit as one filled ration.
		waterSkin.Value -= 1; basin:SetAttribute("StoredWater", 1)
		local total = 0
		for _, value in ipairs(inventory:GetChildren()) do if value:IsA("IntValue") then total += value.Value end end
		player:SetAttribute("INV_TotalCount", total)
		model.StoredWaterSurface.Transparency = 0.35
		local ready = Kit.RefreshRest(site, id)
		player:SetAttribute("SC_Message", ready and "Water stored. This Rest is ready." or "Water stored. Check the heat and sleeping cover.")
		fill.Enabled = false
	end)
	fuel.Triggered:Connect(function(player)
		local model = site:FindFirstChild("Built_HeatPit")
		local heat = model and model:FindFirstChild("Heat")
		if not heat or not Rest.InRange(player, heatAnchor, 10) or heat:GetAttribute("WarmUntil") > os.clock() then return end
		local fiber = player:GetAttribute("TS_Fiber") or 0
		if fiber < 1 then player:SetAttribute("SC_Message", "Dry fiber is needed for the heat."); return end
		player:SetAttribute("TS_Fiber", fiber - 1); heat:SetAttribute("WarmUntil", os.clock() + 600)
		local ready = Kit.RefreshRest(site, id)
		player:SetAttribute("SC_Message", ready and "The heat holds. This Rest is ready." or "The heat holds. Check the water and sleeping cover.")
		fuel.Enabled = false
	end)
	-- A single bounded camp refresh; fuel expiration also invalidates Rest at respawn time.
	task.spawn(function()
		while site:IsDescendantOf(workspace) do
			local basin = site:FindFirstChild("Built_WaterBasin")
			local heat = site:FindFirstChild("Built_HeatPit")
			fill.Parent = basin and basin.Basin or waterAnchor
			fuel.Parent = heat and heat.Heat or heatAnchor
			fill.Enabled = basin ~= nil and basin.Basin:GetAttribute("StoredWater") <= 0
			fuel.Enabled = heat ~= nil and heat.Heat:GetAttribute("WarmUntil") <= os.clock()
			if heat then heat.Heat.Transparency = fuel.Enabled and 0.7 or 0; heat.Heat.PointLight.Enabled = not fuel.Enabled end
			Kit.RefreshRest(site, id)
			task.wait(2)
		end
	end)
end
return Kit
