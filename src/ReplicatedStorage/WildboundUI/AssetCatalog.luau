-- Approved icons, scene crops and brand art. Art never creates gameplay state.
local Catalog = {}
Catalog.LocationArtwork = require(script.Parent.LocationArtwork)
Catalog.PlayerArtwork = require(script.Parent.PlayerArtwork)
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
-- User-supplied regional art sheet; native rectangles preserve the original art.
Catalog.RegionalSheet = {Image = "rbxassetid://126132122426509", Width = 1024, Height = 768, SourceWidth = 1448, SourceHeight = 1086}
local function regionalRect(x, y, width, height)
	local sheet = Catalog.RegionalSheet
	local sx, sy = sheet.Width / sheet.SourceWidth, sheet.Height / sheet.SourceHeight
	return {Image = sheet.Image, Offset = Vector2.new(math.floor(x * sx), math.floor(y * sy)),
		Size = Vector2.new(math.floor((x + width) * sx) - math.floor(x * sx), math.floor((y + height) * sy) - math.floor(y * sy))}
end
local brand = regionalRect(20, 30, 326, 138)
local regionalScenes = {
	SkyCity = regionalRect(8, 272, 228, 204), MarshApproach = regionalRect(250, 272, 233, 204),
	TheWeep = regionalRect(491, 272, 230, 204), WatcherVolcano = regionalRect(730, 272, 229, 204),
	Archyda = regionalRect(970, 272, 228, 204), DanianDelta = regionalRect(1208, 272, 229, 204),
}
-- Retain the earlier composition's identity for existing presentation references.
Catalog.OpeningReference = {Image = "rbxassetid://126814394907037", Width = 1024, Height = 576, SourceWidth = 1672, SourceHeight = 941}
for key, descriptor in pairs(regionalScenes) do scenes.Wildbound[key] = descriptor end
-- Earlier atlas dimensions were measured in Studio; new sheet crops are checked visually.
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

local function isImageId(image)
	return type(image) == "string" and image:match("^rbxassetid://%d+$") ~= nil
end

function Catalog.ResolveIntroTitleCardImage()
	local override = script.Parent:GetAttribute("WB_IntroTitleCardImage")
	if isImageId(override) then
		return override
	end

	local menu = Catalog.LocationArtwork.MENU_WILDBOUND
	if menu and isImageId(menu.Image) then
		return menu.Image
	end

	if Catalog.OpeningReference and isImageId(Catalog.OpeningReference.Image) then
		return Catalog.OpeningReference.Image
	end

	local ordovic = Catalog.LocationArtwork.ORDOVIC_RIVER
	return ordovic and ordovic.Image or nil
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

function Catalog.ApplyItem(image, item)
	local source = type(item) == "table" and item.Image
	local id = type(source) == "string" and source:match("^rbxassetid://(%d+)$")
	local valid = type(id) == "string" and id:find("[1-9]") ~= nil
	image.Visible, image.Image = valid, valid and source or ""
	image.ImageRectOffset, image.ImageRectSize = Vector2.zero, Vector2.zero
	image:SetAttribute("UI_IconKey", nil)
	image:SetAttribute("WB_ItemImageId", valid and item.Id or nil)
	image.ImageColor3, image.ImageTransparency, image.ScaleType = Color3.new(1,1,1), 0, Enum.ScaleType.Fit
	return valid
end

function Catalog.ApplyBrand(image)
	if Catalog.Variant() ~= "Wildbound" then image.Visible = false; return false end
	local masthead = Catalog.PlayerArtwork.Masthead
	if masthead.Image:match("^rbxassetid://%d+$") then
		image.Image, image.ImageRectOffset, image.ImageRectSize = masthead.Image, Vector2.zero, Vector2.zero
		image.ImageColor3, image.ImageTransparency, image.ScaleType = Color3.new(1,1,1), 0, Enum.ScaleType.Fit
		image.Visible = true
		return true
	end
	image.Image, image.ImageRectOffset, image.ImageRectSize = brand.Image, brand.Offset, brand.Size
	image.ImageColor3, image.ImageTransparency, image.ScaleType = Color3.new(1,1,1), 0, Enum.ScaleType.Fit
	image.Visible = true
	return true
end

function Catalog.ApplyIntroScene(image)
	if Catalog.Variant() ~= "Wildbound" then return Catalog.ApplyScene(image, "SkyCity") end
	local introImage = Catalog.ResolveIntroTitleCardImage()
	if not isImageId(introImage) then
		return Catalog.ApplyScene(image, "SkyCity")
	end
	image.Image, image.ImageRectOffset, image.ImageRectSize = introImage, Vector2.zero, Vector2.zero
	image.ImageColor3, image.ImageTransparency, image.ScaleType = Color3.new(1,1,1), 0.05, Enum.ScaleType.Crop
	image:SetAttribute("UI_IntroCardImage", introImage)
	image.Visible = true
	return true
end

function Catalog.ApplyLocation(image, id)
	local entry = Catalog.Variant() == "Wildbound" and type(id) == "string" and Catalog.LocationArtwork[id]
	image.Visible = entry ~= nil and entry ~= false
	image:SetAttribute("UI_LocationId", entry and id or nil)
	if not entry then image.Image = ""; return false end
	image.Image, image.ImageRectOffset, image.ImageRectSize = entry.Image, Vector2.zero, Vector2.zero
	image.ImageColor3, image.ImageTransparency, image.ScaleType = Color3.new(1,1,1), 0.28, Enum.ScaleType.Fit
	return true
end

function Catalog.Region(title, variant)
	if type(title) ~= "string" then return nil end
	return regions[resolveVariant(variant)][string.upper(title):gsub("[^%w]", "")]
end

return Catalog
