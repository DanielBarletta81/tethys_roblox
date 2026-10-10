-- Client fixtures. No visits, knowledge, routes, inventory or XP are awarded.
local player = game.Players.LocalPlayer
local library = game.ReplicatedStorage.WildboundUI
local Style = require(library.UIStyle)
local Policy = require(library.PresentationPolicy)
local Notice = require(library.Controllers.NoticeController)
local artwork = require(library.LocationArtwork)
local result = {passed = {}, failed = {}}
local function test(name, callback)
	local ok, message = pcall(callback)
	table.insert(ok and result.passed or result.failed, ok and name or {name = name, error = tostring(message)})
end
local function loaded(image)
	local deadline = os.clock() + 6
	while not image.IsLoaded and os.clock() < deadline do task.wait(0.05) end
	assert(image.IsLoaded, "Artwork did not load: " .. image.Image)
end
local function fixture(callback)
	local ui = game.StarterGui.TethysUI:Clone()
	ui.Name, ui.Enabled, ui.Parent = "WB_LocationArtworkFixture", true, player.PlayerGui
	ui:SetAttribute("WB_PresentationProfile", "Exploration"); ui:SetAttribute("WB_ReducedMotion", true)
	Style.Apply(ui)
	local n = Notice.new(ui)
	for _, connection in ipairs(n.connections) do connection:Disconnect() end
	local ok, message = pcall(callback, ui, n)
	n:Destroy(); ui:Destroy(); assert(ok, message)
end
local function reveal(n, id, context)
	local cue = assert(Policy.ResolveTitle({Type = "TITLE", TitleId = id, ContextId = context}))
	assert(n:Location(cue.Title, cue.Context, cue)); n:_step(0)
	loaded(n.banner.IL_LocationArtwork)
	Style.Layout(n.ui, n.ui.AbsoluteSize)
	return cue
end
test("Seven supplied locations have distinct assets and retain authored captions", function()
	local count, images = 0, {}
	for id, entry in pairs(artwork) do
		count += 1; assert(entry.Image:match("^rbxassetid://%d+$") and not images[entry.Image])
		images[entry.Image] = true
		local cue = assert(Policy.ResolveTitle({Type = "TITLE", TitleId = id, ContextId = "Authored context"}))
		assert(cue.Context == "Authored context" and cue.Id == id and cue.Authored)
	end
	assert(count == 7 and artwork.SILURIA.Image ~= artwork.SKY_CITY.Image)
	assert(Policy.ResolveTitle({Type = "TITLE", TitleId = "SILURIAN_UPSTREAM"}) == nil)
end)
test("Only existing intake phases request the intake artwork", function()
	assert(Policy.OpeningLocation("ENGINEERING_FIRST_READ").Id == "SKY_CITY_INTAKE")
	assert(Policy.OpeningLocation("INTAKE_WORKS").Id == "SKY_CITY_INTAKE")
	for _, phase in ipairs({"CAVE_WAKE", "INTAKE_CHOICE", "REJECT_CASCADE", "EASY_RIVER", "UNKNOWN"}) do
		assert(Policy.OpeningLocation(phase) == nil)
	end
	assert(Policy.OpeningLocation(nil) == nil)
end)
test("All seven originals load as whole images without atlas crops", function()
	fixture(function(ui, n)
		for id, entry in pairs(artwork) do
			Style.Assets.ApplyLocation(n.banner.IL_LocationArtwork, id)
			n.banner.Visible = true; loaded(n.banner.IL_LocationArtwork)
			local image = n.banner.IL_LocationArtwork
			assert(image.Image == entry.Image and image.ImageRectSize == Vector2.zero and image.ImageRectOffset == Vector2.zero)
			assert(image.ScaleType == Enum.ScaleType.Fit and image.BorderSizePixel == 0)
		end
	end)
end)
test("Image and native text share reduced-motion fade and a borderless container", function()
	fixture(function(ui, n)
		reveal(n, "WATCHER_VOLCANO", "The mountain ahead")
		local image = n.banner.IL_LocationArtwork
		assert(n.banner.BackgroundTransparency == 1 and n.banner.BorderSizePixel == 0)
		assert(n.banner.TL_Subtitle.Text == "The mountain ahead" and not n.banner.IL_RegionBadge.Visible)
		n.bannerEffects:Fade(1, 0.65)
		assert(image.ImageTransparency == 1 and n.banner.TL_LocationName.TextTransparency == 1)
		n.bannerEffects:Fade(0, 0.65)
		assert(math.abs(image.ImageTransparency - 0.28) < 0.001 and n.banner.TL_LocationName.TextStrokeTransparency < 1)
	end)
end)
test("Speech, prompts, intro, menus and death hide the entire image reveal", function()
	fixture(function(ui, n)
		reveal(n, "SKY_CITY")
		n:Subtitle("Look at the waterline.", "Cordge"); n:_refresh(); n:_step(0.8)
		assert(not n.banner.Visible and n.currentLocation.Elapsed == 0)
		n:ClearSubtitle("Cordge")
		ui.InteractionUI.FR_PromptBar.Visible = true; n:_refresh(); n:_step(0.8)
		assert(not n.banner.Visible and n.currentLocation.Elapsed == 0)
		ui.InteractionUI.FR_PromptBar.Visible = false
		for _, attribute in ipairs({"WB_IntroActive", "WB_MenuOpen", "WB_ReturnNoticeActive"}) do
			ui:SetAttribute(attribute, true); n:_refresh(); n:_step(0.8)
			assert(not n.banner.Visible and n.currentLocation.Elapsed == 0)
			ui:SetAttribute(attribute, false)
		end
		n:_refresh(); assert(n.banner.Visible)
	end)
end)
test("Whole-image layouts fit four viewports and keep captions readable", function()
	fixture(function(ui, n)
		reveal(n, "SKY_CITY_INTAKE")
		local host = Instance.new("Frame"); host.BackgroundTransparency = 1; host.Parent = ui
		local frame = Instance.new("Frame"); frame.BackgroundTransparency = 1; frame.Parent = host
		for _, name in ipairs({"HUD", "QuestUI", "InventoryUI", "InteractionUI", "Notifications", "MapUI", "Menus", "LocationUI"}) do ui[name].Parent = frame end
		for _, viewport in ipairs({Vector2.new(1920,1080), Vector2.new(1280,720), Vector2.new(854,480), Vector2.new(390,844)}) do
			frame.Size = UDim2.fromOffset(viewport.X, viewport.Y); Style.Layout(frame, viewport); task.wait(0.05)
			local pos, size = n.banner.AbsolutePosition - frame.AbsolutePosition, n.banner.AbsoluteSize
			assert(pos.X >= 0 and pos.Y >= 0 and pos.X + size.X <= viewport.X + 1 and pos.Y + size.Y <= viewport.Y + 1)
			assert(size.Y <= viewport.Y * 0.32 + 1 and n.banner.TL_LocationName.TextSize >= 22)
			for _, label in ipairs({n.banner.TL_LocationName, n.banner.TL_Subtitle}) do
				assert(label.TextBounds.X <= label.AbsoluteSize.X + 1 and label.TextBounds.Y <= label.AbsoluteSize.Y + 1)
			end
		end
		-- Restore children before fixture teardown's layout connection can fire.
		for _, child in ipairs(frame:GetChildren()) do child.Parent = ui end
		host:Destroy()
	end)
end)
test("Image reveals expire, deduplicate and leave unmapped regions text-only", function()
	fixture(function(ui, n)
		reveal(n, "SKY_CITY_INTAKE")
		n:_step(3.01); assert(not n.banner.Visible and not n.currentLocation)
		assert(not n:Location("SKY CITY INTAKE", "Again", {Id = "SKY_CITY_INTAKE", Authored = true}))
		assert(n:Location("THE WEEP", "Below the city", {Id = "THE_WEEP", Icon = "TheWeep", Authored = true}))
		n:_step(0)
		assert(not n.banner.IL_LocationArtwork.Visible and n.banner.IL_LocationArtwork.Image == "")
		assert(not n.banner.IL_LocationArtwork:GetAttribute("UI_LocationId") and n.banner.Visible)
	end)
end)
test("The live opener uses the Arnn Ridge artwork and native Ordovic title", function()
	local intro = player.PlayerGui.WOTIntro.FR_Intro
	assert(intro.IL_IntroScene.Image == artwork.ORDOVIC_RIVER.Image and intro.IL_IntroScene.IsLoaded)
	assert(intro.TL_Motto.Text == "ORDOVIC RIVER" and intro.TL_LocationContext.Text == "Arnn Ridge")
	assert(player.PlayerScripts.WildboundUIRuntimeBinder:GetAttribute("WB_RuntimeBinderVersion") == "HUD1.6")
end)
return result
