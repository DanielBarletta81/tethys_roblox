-- Run in Studio Client. Isolated GUI/character clones; never awards location knowledge.
local player = game.Players.LocalPlayer
local library = game.ReplicatedStorage.WildboundUI
local live = player.PlayerGui.TethysUI
local Style = require(library.UIStyle)
local Policy = require(library.PresentationPolicy)
local Effects = require(library.UIEffects)
local Notice = require(library.Controllers.NoticeController)
local Preview = require(library.Controllers.CharacterPreviewController)
local result = {passed = {}, failed = {}}
local function test(name, callback)
	local ok, message = pcall(callback)
	table.insert(ok and result.passed or result.failed, ok and name or {name = name, error = tostring(message)})
end
local function fixture(callback)
	local ui = game.StarterGui.TethysUI:Clone()
	ui.Name, ui.Enabled, ui.Parent = "WB_PresentationAudit", false, player.PlayerGui
	ui:SetAttribute("WB_PresentationProfile", "Exploration")
	ui:SetAttribute("WB_ReducedMotion", true)
	Style.Apply(ui); Style.Layout(ui, ui.AbsoluteSize)
	ui.InteractionUI.FR_PromptBar.Visible = false
	local notices = Notice.new(ui)
	-- Manual time steps make interruption/expiry checks independent of frame timing.
	for _, connection in ipairs(notices.connections) do connection:Disconnect() end
	local ok, message = pcall(callback, ui, notices)
	notices:Destroy(); ui:Destroy()
	assert(ok, message)
end

test("Title handoff retains ContextId and rejects unsupported or premature cue types", function()
	local reveal = Policy.ResolveTitle({Type = "TITLE", TitleId = "SKY_CITY", ContextId = "Inside the Machine"})
	assert(reveal.Authored and reveal.Context == "Inside the Machine" and reveal.Icon == "SkyCity")
	assert(Policy.ResolveTitle({Type = "REGION", TitleId = "SKY_CITY"}) == nil)
	assert(Policy.ResolveTitle({Type = "TITLE", TitleId = "ORDOVIC_RECOVERY"}) == nil)
	assert(Policy.ResolveTitle({Type = "TITLE", TitleId = "UNKNOWN"}) == nil)
end)
test("Quiet opening suppresses generic discoveries but allows an authored civic title", function()
	fixture(function(ui, n)
		ui:SetAttribute("WB_PresentationProfile", "Game1")
		assert(not n:Toast("Discovery", "Observation", "Unrequested world hint"))
		assert(not n:Location("SKY CITY", "Generic visit"))
		local cue = Policy.ResolveTitle({Type = "TITLE", TitleId = "SKY_CITY", ContextId = "Inside the Machine"})
		assert(n:Location(cue.Title, cue.Context, cue)); n:_step(0)
		assert(n.banner.Visible and n.banner.TL_Subtitle.Text == cue.Context)
		assert(not n.banner.TL_Kicker.Visible and n.banner.TL_Kicker.Text == "")
		assert(ui:GetAttribute("WB_PresentationProfile") == "Game1")
	end)
end)
test("A title uses three seconds, then clears; repeated entry does not replay it", function()
	fixture(function(ui, n)
		assert(n:Location("SKY CITY", "Inside the Machine", {Id = "SKY_CITY", Icon = "SkyCity", Authored = true}))
		n:_step(0); n:_step(0.65); assert(n.currentLocation.Phase == "Hold")
		n:_step(1.5); assert(n.currentLocation.Phase == "Out")
		n:_step(0.86); assert(not n.banner.Visible and not n.currentLocation and not ui:GetAttribute("WB_TransientBusy"))
		assert(not n:Location("SKY CITY", "Again", {Id = "SKY_CITY", Authored = true}))
	end)
end)
test("Dialogue and native prompts suppress cards; interrupted reveal time is preserved", function()
	fixture(function(ui, n)
		n:Location("THE WEEP", "Lower water", {Id = "THE_WEEP", Icon = "TheWeep", Authored = true}); n:_step(0)
		n:Subtitle("Let the water settle before you move.", "Cordge"); n:_refresh(); n:_step(1)
		assert(n.currentLocation.Elapsed == 0 and not n.banner.Visible and n.subtitle.Visible)
		n:ClearSubtitle("Cordge"); n:_refresh(); n:_step(0.7)
		assert(n.banner.Visible and n.currentLocation.Phase == "Hold")
		ui.InteractionUI.FR_PromptBar.Visible = true; n:_refresh(); n:_step(1)
		assert(not n.banner.Visible and n.currentLocation.Elapsed == 0.7)
		ui.InteractionUI.FR_PromptBar.Visible = false; n:_refresh(); assert(n.banner.Visible)
	end)
end)
test("Stale queued cards expire; menus do not release a backlog of old titles", function()
	fixture(function(ui, n)
		ui:SetAttribute("WB_MenuOpen", true)
		n:Location("THE WEEP", "Old cue", {Id = "THE_WEEP", Authored = true})
		n:Toast("Item", "Supplies", "Old receipt")
		n.pendingLocation.Deadline, n.pendingToasts[1].Deadline = os.clock() - 1, os.clock() - 1
		n:_step(0); ui:SetAttribute("WB_MenuOpen", false); n:_step(0)
		assert(not n.currentLocation and not n.pendingLocation and #n.toasts == 0 and #n.pendingToasts == 0)
	end)
end)
test("Toast bursts are bounded and deduplicated without blocking the world", function()
	fixture(function(ui, n)
		ui:SetAttribute("WB_MenuOpen", true)
		for i = 1, 8 do assert(n:Toast("Item", "Supplies", "Receipt " .. i)) end
		assert(#n.pendingToasts == 4 and not n:Toast("Item", "Supplies", "Receipt 8"))
		ui:SetAttribute("WB_MenuOpen", false); n:_step(0)
		assert(#n.toasts == 2 and #n.pendingToasts == 2)
		ui.InteractionUI.FR_PromptBar.Visible = true; n:_refresh()
		local remaining = n.toastRecords[n.toasts[1]].Remaining; n:_step(1)
		assert(not n.stack.Visible and n.toastRecords[n.toasts[1]].Remaining == remaining)
		ui.InteractionUI.FR_PromptBar.Visible = false; n:_refresh(); n:_step(3.3)
		assert(#n.toasts == 2 and #n.pendingToasts == 0)
	end)
end)
test("Game1 shows one actual item receipt and no observation stack", function()
	fixture(function(ui, n)
		ui:SetAttribute("WB_PresentationProfile", "Game1")
		n:Toast("Item", "Supplies", "Water Skin"); n:Toast("Item", "Supplies", "Fiber Line"); n:_step(0)
		assert(#n.toasts == 1 and #n.pendingToasts == 1)
	end)
end)
test("Cordge speech has priority and clearing remains source-owned", function()
	fixture(function(ui, n)
		n:Subtitle("The flow is changing.", "Cordge")
		n:Subtitle("The flow is changing.", "City")
		assert(n.lastSubtitleSource == "Cordge")
		n:ClearSubtitle("City"); assert(n.subtitle.Visible)
		n:ClearSubtitle("Cordge"); assert(not n.subtitle.Visible)
		n:Subtitle("The flow is changing.", "City")
		n:ClearSubtitle("City"); assert(not n.subtitle.Visible)
	end)
end)
test("Reduced motion snaps fades to the original alpha and cancels older tweens", function()
	fixture(function(ui, n)
		local frame = Instance.new("Frame"); frame.BackgroundTransparency = 0.34; frame.Parent = ui
		local label = Instance.new("TextLabel"); label.TextTransparency = 0.15; label.Parent = frame
		local effects = Effects.new(frame, ui)
		ui:SetAttribute("WB_ReducedMotion", false); effects:Fade(1, 0.5)
		ui:SetAttribute("WB_ReducedMotion", true); effects:Fade(0, 0.65)
		assert(Effects.Reduced(ui) and math.abs(frame.BackgroundTransparency - 0.34) < 0.00001 and math.abs(label.TextTransparency - 0.15) < 0.00001)
		task.wait(0.1); assert(math.abs(frame.BackgroundTransparency - 0.34) < 0.00001)
		effects:Cancel(); frame:Destroy()
	end)
end)
test("Supplied imagery loads using served-size rectangles without disturbing earlier atlases", function()
	fixture(function(ui, n)
		local assets = Style.Assets
		local injury, old = assets.Get("Injury"), assets.Get("Health")
		assert(old.Image == "rbxassetid://132772321322120" and old.Size == Vector2.new(256, 256))
		assert(injury.Offset.X + injury.Size.X <= 1024 and injury.Offset.Y + injury.Size.Y <= 768)
		assert(assets.Get("Injury", "Adventures") == nil and #assets.Variants.Adventures.Order == 36)
		local image = n.banner.IL_SceneAccent
		assert(assets.ApplyScene(image, "SkyCity")); local descriptor = injury
		local icon = Instance.new("ImageLabel"); assets.Apply(icon, "Injury"); icon.Parent = ui
		for _, child in ipairs(ui:GetChildren()) do if child:IsA("GuiObject") then child.Visible = false end end
		local scene = image:Clone(); scene.Position = UDim2.fromOffset(450,80); scene.Size = UDim2.fromOffset(149,88); scene.Visible = true; scene.Parent = ui
		icon.Position = UDim2.fromOffset(400,80); icon.Size = UDim2.fromOffset(48,48); icon.Visible = true
		ui.Enabled = true
		local statuses = {}
		game:GetService("ContentProvider"):PreloadAsync({scene, icon}, function(id, status) statuses[id] = tostring(status) end)
		task.wait(0.3)
		assert(scene.IsLoaded and icon.IsLoaded, game:GetService("HttpService"):JSONEncode(statuses))
		assert(assets.ApplyScene(image, "TheWeep") and image.Visible and image:GetAttribute("UI_SceneKey") == "TheWeep")
		assert(not assets.ApplyScene(image, "Unknown") and not image.Visible)
	end)
end)
test("Static character previews copy and sanitize only explicitly approved models", function()
	local original = Instance.new("Model"); original.Name = "AuditOnly"
	local part = Instance.new("Part"); part.Anchored = false; part.CanCollide = true; part.Parent = original
	local scriptFixture = Instance.new("LocalScript"); scriptFixture.Parent = original
	local prompt = Instance.new("ProximityPrompt"); prompt.Parent = part
	game:GetService("CollectionService"):AddTag(part, "WB_Trigger")
	assert(Preview.Prepare(original) == nil)
	original:SetAttribute("UI_PreviewApproved", true)
	local clone = Preview.Prepare(original)
	assert(clone and #clone:GetDescendants() == 1 and clone.Part.Anchored and not clone.Part.CanCollide and not clone.Part.CanTouch)
	assert(#game:GetService("CollectionService"):GetTags(clone.Part) == 0)
	assert(not part.Anchored and part.CanCollide and prompt.Parent == part and scriptFixture.Parent == original)
	clone:Destroy(); original:Destroy()
end)
test("Approved portrait renders only beside an open wide-screen menu", function()
	local ui = game.StarterGui.TethysUI:Clone()
	ui.Name, ui.Enabled, ui.Parent = "WB_PortraitAudit", false, player.PlayerGui
	Style.Apply(ui)
	local fakeLibrary = Instance.new("Folder")
	local models = Instance.new("Folder"); models.Name, models.Parent = "CharacterModels", fakeLibrary
	local original = Instance.new("Model"); original.Name, original.Parent = "AuditOnly", models
	original:SetAttribute("UI_PreviewApproved", true)
	local part = Instance.new("Part"); part.Size = Vector3.new(2, 6, 2); part.Parent = original
	fakeLibrary:SetAttribute("CharacterPreviewKey", "AuditOnly")
	local controller = Preview.new(ui, fakeLibrary)
	local ok, message = pcall(function()
		ui:SetAttribute("WB_MenuOpen", true); ui.Menus.FR_PauseMenu.Visible = true
		controller:Refresh(); task.wait(0.05)
		assert(controller.Panel.Visible and #controller.World:GetChildren() == 1)
		assert(controller.View.CurrentCamera == controller.Camera and controller.Camera.FieldOfView == 35)
		local size = controller.Panel.AbsoluteSize
		local edge = controller.Panel.AbsolutePosition.X - ui.AbsolutePosition.X + size.X
		assert(edge <= ui.AbsoluteSize.X + 1 and controller.Caption.Text == "AuditOnly")
		ui:SetAttribute("WB_MenuOpen", false); controller:Refresh()
		assert(not controller.Panel.Visible and #controller.World:GetChildren() == 0 and #original:GetDescendants() == 1)
	end)
	controller:Destroy(); ui:Destroy(); fakeLibrary:Destroy()
	assert(ok, message)
end)
test("Unavailable finished character models produce no placeholder portrait", function()
	assert(#library.CharacterModels:GetChildren() == 0 and not live.Menus.FR_CharacterPreview.Visible)
end)
test("Injury cue follows the existing injury producer and never infers injury from low health", function()
	local old = player:GetAttribute("WB_OpeningInjured")
	local ok, message = pcall(function()
		player:SetAttribute("WB_OpeningInjured", true); task.wait(0.05)
		assert(live.HUD.FR_StatusPanel.FR_ConditionCue.Visible)
		player:SetAttribute("WB_OpeningInjured", false); task.wait(0.05)
		assert(not live.HUD.FR_StatusPanel.FR_ConditionCue.Visible)
	end)
	player:SetAttribute("WB_OpeningInjured", old)
	assert(ok, message)
end)
test("Quiet live HUD remains a singleton with no premature title or portrait", function()
	local count = 0; for _, ui in ipairs(player.PlayerGui:GetChildren()) do if ui.Name == "TethysUI" then count += 1 end end
	assert(count == 1 and live:GetAttribute("WB_PresentationProfile") == "Game1")
	assert(not live.LocationUI.FR_LocationBanner.Visible and not live.MapUI.FR_Compass.Visible)
	assert(not live.HUD.FR_StatusPanel.FR_Stamina.Visible and not live.Menus.FR_CharacterPreview.Visible)
	assert(player.PlayerScripts.WildboundUIRuntimeBinder:GetAttribute("WB_RuntimeBinderVersion") == "HUD1.5")
end)
test("Live HUD enables only after binding and contains no saved demo text", function()
	assert(live.Enabled and live:GetAttribute("WB_RuntimeBound") and live:GetAttribute("WB_TemplateVersion") == "HUD1.4")
	local demo = { ["MAIN QUEST"] = true, ["Watcher Stirs"] = true, ["Item Found"] = true,
		["Mushroom collected."] = true, ["Predator nearby."] = true,
		["New location mapped."] = true, ["Optional: Gather ashbloom mushrooms"] = true }
	for _, object in ipairs(live:GetDescendants()) do
		if object:IsA("TextLabel") or object:IsA("TextButton") then
			assert(not demo[object.Text], object:GetFullName() .. " still carries demo text")
		end
	end
	for _, slot in ipairs(live.InventoryUI.FR_Quickbar:GetChildren()) do
		if slot:IsA("Frame") and slot.Name:match("^FR_Slot_") and not slot:GetAttribute("WB_ItemId") then
			assert(not slot.Visible and slot.TL_Count.Text == "")
		end
	end
end)
return result
