-- Read existing game state. This module never awards items or advances gameplay.
local Data = {}

local TRACK_LABELS = {
	LeaveCity = "Lower-Tier Survival", RiseHatchery = "Hatchery Shift",
	Greenhouse = "Greenhouse Shift", Workshop = "Workshop Shift",
}
local TRACK_STEPS = { LeaveCity = 5, RiseHatchery = 4, Greenhouse = 4, Workshop = 4 }
local ITEM_LABELS = {
	FieldBandage = "Field Bandage", WaterSkin = "Water Skin", TrailRation = "Trail Ration",
	FiberLine = "Fiber Line", SignalFlare = "Signal Flare",
}

function Data.Number(value)
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return nil end
	return value
end

function Data.Percent(value, maximum)
	local number = Data.Number(value)
	if not number then return nil end
	return math.clamp(number / (maximum or 100), 0, 1)
end

function Data.Label(name)
	return ITEM_LABELS[name] or tostring(name):gsub("(%l)(%u)", "%1 %2"):gsub("_", " ")
end

function Data.Vitals(player)
	return {
		Stamina = Data.Percent(player:GetAttribute("OL_Stamina")),
		Hydration = Data.Percent(player:GetAttribute("OL_Hydration")),
		Exposure = Data.Percent(player:GetAttribute("OL_PrettyWaterExposure"), 1),
	}
end

function Data.Profile(player, ui)
	-- An explicit client preview wins; the place setting follows real onboarding.
	local override = ui:GetAttribute("WB_HUDProfile")
	if override == "Game1" or override == "Exploration" then return override end
	if (Data.Number(player:GetAttribute("WB_Chapter")) or 1)>=2 then return "Exploration" end
	local configured = script.Parent:GetAttribute("HUDProfile")
	if configured == "Game1" and player:GetAttribute("SC_OnboardingStage") ~= "CityOpen"
		and player:GetAttribute("HW_Complete") ~= true then return "Game1" end
	return "Exploration"
end

function Data.Route(player)
	if player:GetAttribute("IL_Active") == true then
		local total = math.max(1, Data.Number(player:GetAttribute("IL_RouteCount")) or 7)
		local step = math.clamp(Data.Number(player:GetAttribute("IL_Step")) or 1, 1, total)
		return player:GetAttribute("IL_Title") or "Igzier's Leap", player:GetAttribute("IL_Message") or "", string.format("%d / %d", step, total)
	end
	if player:GetAttribute("HW_Status") == "InProgress" then
		local total = math.max(1, Data.Number(player:GetAttribute("HW_TotalSteps")) or 6)
		local step = math.clamp(Data.Number(player:GetAttribute("HW_Step")) or 1, 1, total)
		return "Hatchery Watch", player:GetAttribute("HW_Message") or "", string.format("%d / %d", step, total)
	end

	-- Ordered zone visits are owned by the existing water controller.
	local waterIndex = Data.Number(player:GetAttribute("WT_WaterStageIndex"))
	local freePlay = (Data.Number(player:GetAttribute("WB_Chapter")) or 1)>=2
		or player:GetAttribute("SC_OnboardingStage") == "CityOpen" or player:GetAttribute("HW_Complete") == true
	if not freePlay and waterIndex and waterIndex >= 0 and waterIndex < 5 and player:GetAttribute("WT_WaterChainComplete") ~= true then
		local objective = player:GetAttribute("WT_WaterObjective")
		if type(objective) == "string" and objective ~= "" then return "Follow the Water", objective, "" end
	end
	local track = player:GetAttribute("OL_ObjectiveTrack")
	if type(track) == "string" and track ~= "" and player:GetAttribute("OL_ObjectiveDone") ~= true then
		local total = TRACK_STEPS[track]
		local step = Data.Number(player:GetAttribute("OL_ObjectiveStep")) or 1
		local count = total and string.format("%d / %d", math.clamp(step, 1, total), total) or ""
		return TRACK_LABELS[track] or Data.Label(track), player:GetAttribute("WOT_NextPull") or "", count
	end

	return nil
end

-- Four presentation slots; the full inventory remains authoritative.
function Data.QuickItems(items)
	local result, used, byId = {}, {}, {}
	for _, item in ipairs(items) do byId[item.Id] = item end
	for index, id in pairs({ [1] = "TrailRation", [3] = "FiberLine", [4] = "WaterSkin" }) do
		if byId[id] then result[index], used[id] = byId[id], true end
	end
	for _, item in ipairs(items) do
		if item.Tool and not used[item.Id] then result[2], used[item.Id] = item, true; break end
	end
	for index = 1, 4 do
		if not result[index] then
			for _, item in ipairs(items) do
				if not used[item.Id] then result[index], used[item.Id] = item, true; break end
			end
		end
	end
	return result
end

function Data.Inventory(player)
	local items, byName = {}, {}
	local inventory = player:FindFirstChild("Inventory")
	if inventory then
		for _, value in ipairs(inventory:GetChildren()) do
			if value:IsA("IntValue") and value.Value > 0 then
				local item = { Id = value.Name, Label = Data.Label(value.Name), Count = value.Value }
				byName[value.Name] = item
				table.insert(items, item)
			end
		end
	end
	for _, container in pairs({ player:FindFirstChild("Backpack"), player.Character }) do
		if container then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") then
					local item = byName[tool.Name]
					if not item then
						item = { Id = tool.Name, Label = Data.Label(tool.Name), Count = 1 }
						byName[tool.Name] = item
						table.insert(items, item)
					end
					item.Tool = tool
				end
			end
		end
	end
	table.sort(items, function(a, b) return a.Id < b.Id end)
	return items
end

return Data
