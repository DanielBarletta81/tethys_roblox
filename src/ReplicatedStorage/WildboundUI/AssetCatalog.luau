-- Text-free sprites from approved references. Art never creates gameplay state.
local Catalog = {}
local wildboundOrder = {
	"Health", "Stamina", "Thirst", "WaterExposure",
	"Inventory", "Settings", "Journal", "Tracks",
	"SkyCity", "TheWeep", "TheStakes", "DanianDelta",
	"Archyda", "PermianDesert", "WatcherVolcano", "CambriaRoad",
}
local statusOrder = {
	"Hearts", "Energy", "Discovery", "BuddyBond",
	"SplashWet", "Mud", "Bravery", "Snack",
	"StormAlert", "PredatorAlert", "Backpack", "Settings",
	"Quests", "FriendsBuddy", "PlayAdventure", "Help",
}
local explorationOrder = {
	"SkyCity", "TheWeep", "TheStakes", "DanianDelta",
	"Archyda", "PermianDesert", "WatcherVolcano", "MushroomWoods",
	"PterosaurFriend", "MammothTrail", "Footprints", "Mushrooms",
	"Fish", "Climb", "Swim", "RopeBridge",
	"Camp", "Map", "Shop", "PlayerMarker",
}
Catalog.Order = wildboundOrder
Catalog.Variants = {
	Wildbound = {
		Image = "rbxassetid://132772321322120", Width = 1024, Height = 1024,
		Regions = { "SkyCity", "TheWeep", "TheStakes", "DanianDelta", "Archyda", "PermianDesert", "WatcherVolcano", "CambriaRoad" },
		Atlases = { { Image = "rbxassetid://132772321322120", Width = 1024, Height = 1024, Columns = 4, Rows = 4, Order = wildboundOrder } },
	},
	Adventures = {
		Regions = { "SkyCity", "TheWeep", "TheStakes", "DanianDelta", "Archyda", "PermianDesert", "WatcherVolcano", "MushroomWoods" },
		-- Presentation aliases only; no survival or Journal-to-Quests aliases.
		Aliases = { Inventory = "Backpack", Tracks = "Footprints" },
		Atlases = {
			{ Image = "rbxassetid://71185697304081", Width = 1024, Height = 1024, Columns = 4, Rows = 4, Order = statusOrder },
			{ Image = "rbxassetid://139296753046914", Width = 819, Height = 1023, Columns = 4, Rows = 5, Order = explorationOrder },
		},
	},
}
-- Original supplied sheet is preserved; runtime rectangles use served dimensions.
Catalog.ReferenceSheet = {Image = "rbxassetid://120531122548244", Width = 1024, Height = 768, SourceWidth = 1448, SourceHeight = 1086}
local function sheetRect(x, y, width, height)
	local sheet = Catalog.ReferenceSheet
	local sx, sy = sheet.Width / sheet.SourceWidth, sheet.Height / sheet.SourceHeight
	return {Image = sheet.Image, Offset = Vector2.new(math.floor(x * sx), math.floor(y * sy)),
		Size = Vector2.new(math.floor((x + width) * sx) - math.floor(x * sx), math.floor((y + height) * sy) - math.floor(y * sy))}
end
local extraSprites = {Wildbound = {Injury = sheetRect(302, 479, 76, 81)}}
local scenes = {Wildbound = {SkyCity = sheetRect(1134, 16, 304, 158)}}
-- Served dimensions were measured in Studio after upload.
local symbols, regions = {}, {}
for name, variant in pairs(Catalog.Variants) do
	symbols[name], regions[name], variant.Order = {}, {}, {}
	for _, atlas in ipairs(variant.Atlases) do
		for index, key in ipairs(atlas.Order) do
			assert(not symbols[name][key], "Duplicate UI icon: " .. key)
			local column, row = (index - 1) % atlas.Columns, math.floor((index - 1) / atlas.Columns)
			local left, top = math.floor(column * atlas.Width / atlas.Columns), math.floor(row * atlas.Height / atlas.Rows)
			local right, bottom = math.floor((column + 1) * atlas.Width / atlas.Columns), math.floor((row + 1) * atlas.Height / atlas.Rows)
			symbols[name][key] = { Image = atlas.Image, Offset = Vector2.new(left, top), Size = Vector2.new(right - left, bottom - top) }
			table.insert(variant.Order, key)
		end
	end
	for _, key in ipairs(variant.Regions) do regions[name][string.upper(key)] = key end
end

function Catalog.Variant()
	local requested = script.Parent:GetAttribute("ThemeVariant")
	return Catalog.Variants[requested] and requested or "Wildbound"
end

local function resolveVariant(requested)
	local name = requested or Catalog.Variant()
	return Catalog.Variants[name] and name or "Wildbound"
end

function Catalog.Get(key, variant)
	if type(key) ~= "string" then return nil end
	local name = resolveVariant(variant)
	local aliases = Catalog.Variants[name].Aliases
	local resolved = aliases and aliases[key] or key
	local descriptor = symbols[name][resolved] or (extraSprites[name] and extraSprites[name][resolved])
	if not descriptor then return nil end
	return { Image = descriptor.Image, Offset = descriptor.Offset, Size = descriptor.Size }
end

function Catalog.Apply(image, key, variant)
	local descriptor = Catalog.Get(key, variant)
	image.Visible = descriptor ~= nil
	if not descriptor then return false end
	image.Image, image.ImageRectOffset, image.ImageRectSize = descriptor.Image, descriptor.Offset, descriptor.Size
	image.ImageColor3, image.ImageTransparency = Color3.new(1, 1, 1), 0
	image.ScaleType = Enum.ScaleType.Fit
	image:SetAttribute("UI_IconKey", key)
	return true
end

function Catalog.ApplyScene(image, key, variant)
	local descriptor = scenes[resolveVariant(variant)] and scenes[resolveVariant(variant)][key]
	image.Visible = descriptor ~= nil
	image:SetAttribute("UI_SceneKey", descriptor and key or nil)
	if not descriptor then return false end
	image.Image, image.ImageRectOffset, image.ImageRectSize = descriptor.Image, descriptor.Offset, descriptor.Size
	image.ImageColor3, image.ImageTransparency, image.ScaleType = Color3.new(1,1,1), 0.55, Enum.ScaleType.Crop
	return true
end

function Catalog.Region(title, variant)
	if type(title) ~= "string" then return nil end
	return regions[resolveVariant(variant)][string.upper(title):gsub("[^%w]", "")]
end

return Catalog
