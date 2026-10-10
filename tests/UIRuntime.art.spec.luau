-- Run in Studio Edit after the icon modules are installed. Detached fixtures only.
local function readModule(module)
	assert(module:IsDescendantOf(game.ReplicatedStorage.WildboundUI))
	local chunk = assert(loadstring(module.Source))
	setfenv(chunk, setmetatable({ script = module, require = readModule }, { __index = getfenv() }))
	return chunk()
end
local root = game.ReplicatedStorage.WildboundUI
local Assets, Style = readModule(root.AssetCatalog), readModule(root.UIStyle)
local adventure = readModule(root.Themes.AdventuresTheme)
local result = { passed = {}, failed = {} }
local function test(name, callback)
	local ok, message = pcall(callback)
	table.insert(ok and result.passed or result.failed, ok and name or { name = name, error = tostring(message) })
end
local gui = game.StarterGui.TethysUI:Clone()
test("Each variant has valid, bounded sprites across its own atlases", function()
	assert(#Assets.Order == 16)
	assert(#Assets.Variants.Adventures.Order == 36)
	for variant, definition in pairs(Assets.Variants) do
		local seen = {}
		for _, atlas in ipairs(definition.Atlases) do
		local area = 0
		assert(#atlas.Order == atlas.Columns * atlas.Rows)
		for _, key in ipairs(atlas.Order) do
			assert(not seen[key]); seen[key] = true
			local icon = Assets.Get(key, variant)
			assert(icon.Image == atlas.Image and icon.Size.X > 0 and icon.Size.Y > 0)
			assert(icon.Offset.X >= 0 and icon.Offset.Y >= 0)
			assert(icon.Offset.X + icon.Size.X <= atlas.Width and icon.Offset.Y + icon.Size.Y <= atlas.Height)
			area += icon.Size.X * icon.Size.Y
		end
		assert(area > 0 and area <= atlas.Width * atlas.Height)
		end
	end
end)
test("Unknown variants fall back and unknown symbols stay hidden", function()
	assert(Assets.Get("Health", "Unknown").Image == Assets.Variants.Wildbound.Image)
	assert(Assets.Get("Unknown") == nil)
	local image = Instance.new("ImageLabel")
	assert(not Assets.Apply(image, "Unknown") and not image.Visible)
	image:Destroy()
end)
test("Each game resolves its own locations without substituting regions", function()
	for variant, definition in pairs(Assets.Variants) do
		assert(#definition.Regions == 8)
		for _, key in ipairs(definition.Regions) do assert(Assets.Region(key, variant) == key and Assets.Get(key, variant)) end
	end
	assert(Assets.Region("SKY_CITY") == "SkyCity" and Assets.Region("The Weep") == "TheWeep")
	assert(Assets.Region("MUSHROOM_WOODS", "Adventures") == "MushroomWoods")
	assert(Assets.Region("Cambria Road", "Adventures") == nil and Assets.Region("Mushroom Woods", "Wildbound") == nil)
	assert(Assets.Region("Unknown location") == nil)
end)
test("Adventures symbols stay separate from survival gameplay meanings", function()
	for _, key in ipairs({ "Hearts", "Energy", "Discovery", "BuddyBond", "SplashWet", "Mud", "Bravery", "Snack", "StormAlert", "PredatorAlert" }) do
		assert(Assets.Get(key, "Adventures") and Assets.Get(key, "Wildbound") == nil, key)
	end
	for _, key in ipairs({ "Health", "Stamina", "Thirst", "WaterExposure", "Journal" }) do assert(Assets.Get(key, "Adventures") == nil, key) end
end)
test("Existing Wildbound sprites retain exact image IDs and rectangles", function()
	for index, key in ipairs(Assets.Order) do
		local icon = Assets.Get(key, "Wildbound")
		assert(icon.Image == "rbxassetid://132772321322120" and icon.Size == Vector2.new(256, 256))
		assert(icon.Offset == Vector2.new((index - 1) % 4 * 256, math.floor((index - 1) / 4) * 256))
	end
end)
test("Status art keeps native labels and values separate", function()
	Style.Apply(gui)
	for _, name in ipairs({ "Health", "Stamina", "Thirst", "Exposure" }) do
		local row = gui.HUD.FR_StatusPanel["FR_" .. name]
		assert(row.IL_StatusGlyph:IsA("ImageLabel") and row.IL_StatusGlyph.Visible)
		assert(row.IL_StatusGlyph.Image == Assets.Variants.Wildbound.Image)
		assert(row.TL_Label:IsA("TextLabel") and row.TL_Value:IsA("TextLabel"))
	end
end)
test("Adventures palette retains shared theme fields and readable contrast", function()
	for key in pairs(Style.Theme.Colors) do assert(typeof(adventure.Colors[key]) == "Color3", key) end
	local function luminance(color)
		local function linear(x) return x <= 0.04045 and x / 12.92 or ((x + 0.055) / 1.055) ^ 2.4 end
		return 0.2126 * linear(color.R) + 0.7152 * linear(color.G) + 0.0722 * linear(color.B)
	end
	assert((luminance(adventure.Colors.Obsidian) + 0.05) / (luminance(adventure.Colors.Bone) + 0.05) >= 4.5)
end)
test("Location originals retain whole-image placement and clear stale crops", function()
	local image = Instance.new("ImageLabel")
	local ok, message = pcall(function()
		for id, entry in pairs(Assets.LocationArtwork) do
			image.ImageRectOffset, image.ImageRectSize = Vector2.new(12,34), Vector2.new(56,78)
			assert(Assets.ApplyLocation(image, id) and image.Image == entry.Image and image.Visible)
			assert(image.ImageRectOffset == Vector2.zero and image.ImageRectSize == Vector2.zero)
			assert(image.ScaleType == Enum.ScaleType.Fit and image:GetAttribute("UI_LocationId") == id)
		end
		assert(not Assets.ApplyLocation(image, "Unknown") and image.Image == "" and not image.Visible)
		assert(image:GetAttribute("UI_LocationId") == nil)
	end)
	image:Destroy(); assert(ok, message)
end)
test("Seven authored locations resolve captions without opening reserved upstream", function()
	local policy = readModule(root.PresentationPolicy)
	local count, images = 0, {}
	for id, entry in pairs(Assets.LocationArtwork) do
		count += 1; assert(not images[entry.Image]); images[entry.Image] = true
		local cue = assert(policy.ResolveTitle({Type = "TITLE", TitleId = id, ContextId = "Authored context"}))
		assert(cue.Authored and cue.Context == "Authored context" and cue.Id == id)
	end
	assert(count == 7 and not policy.ResolveTitle({Type = "TITLE", TitleId = "SILURIAN_UPSTREAM"}))
	assert(Assets.LocationArtwork.SILURIA.Context == "East of Sky City")
end)
test("Only server-owned intake approach and landing phases request its reveal", function()
	local policy = readModule(root.PresentationPolicy)
	assert(policy.OpeningLocation("ENGINEERING_FIRST_READ").Id == "SKY_CITY_INTAKE")
	assert(policy.OpeningLocation("INTAKE_WORKS").Id == "SKY_CITY_INTAKE")
	for _, phase in ipairs({"CAVE_WAKE", "INTAKE_CHOICE", "REJECT_CASCADE", "EASY_RIVER", "UNKNOWN"}) do
		assert(policy.OpeningLocation(phase) == nil)
	end
	assert(policy.OpeningLocation(nil) == nil)
end)
gui:Destroy()
return result
