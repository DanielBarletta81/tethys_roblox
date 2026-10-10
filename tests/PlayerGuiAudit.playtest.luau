-- Run in Client after dismissing the intro. Detached GUI fixtures are destroyed.
local player = game.Players.LocalPlayer
local live = player.PlayerGui.TethysUI
local library = game.ReplicatedStorage.WildboundUI
local Style = require(library.UIStyle)
local Notice = require(library.Controllers.NoticeController)
local Effects = require(library.UIEffects)
local result = {passed = {}, failed = {}}
local function test(name, callback)
	local ok, message = pcall(callback)
	table.insert(ok and result.passed or result.failed, ok and name or {name = name, error = tostring(message)})
end
local function fixture(callback)
	local ui = game.StarterGui.TethysUI:Clone()
	ui.Name, ui.Enabled, ui.Parent = "WB_GuiAuditFixture", false, player.PlayerGui
	Style.Apply(ui); ui:SetAttribute("WB_PresentationProfile", "Exploration")
	ui:SetAttribute("WB_ReducedMotion", true)
	local n = Notice.new(ui)
	for _, connection in ipairs(n.connections) do connection:Disconnect() end
	local ok, message = pcall(callback, ui, n)
	n:Destroy(); ui:Destroy(); assert(ok, message)
end
test("Intro leaves no loading cover or input capture after entry", function()
	local actions = game:GetService("ContextActionService"):GetAllBoundActionInfo()
	assert(live:GetAttribute("WB_IntroSeen") and not live:GetAttribute("WB_IntroActive"))
	assert(not player.PlayerGui.WOTIntro.Enabled and not player.PlayerGui:FindFirstChild("WOTLoading"))
	assert(not actions.WB_LoadingMovement and not actions.WB_IntroMovement and not actions.WB_IntroContinue)
	assert(game:GetService("ProximityPromptService").Enabled)
end)
test("PlayerGui has one shared HUD and suppresses legacy visual producers", function()
	local hud, intro = 0, 0
	for _, gui in ipairs(player.PlayerGui:GetChildren()) do
		if gui.Name == "TethysUI" then hud += 1 end
		if gui.Name == "WOTIntro" then intro += 1 end
	end
	assert(hud == 1 and intro == 1 and live.Enabled)
	assert(not player.PlayerGui.PC01_RiverCinematicHUD.Enabled and not player.PlayerGui.WildboundRuntimeDebug.Enabled)
	for _, name in ipairs({"WildboundHUD", "PC01_AdventureHintHUD", "FirstDayQuietCue", "IgziersLeapHUD", "HatcheryWatchHUD"}) do
		assert(not player.PlayerGui:FindFirstChild(name), name)
	end
end)
test("Discovery containers and ordinary HUD elements are borderless", function()
	fixture(function(ui, n)
		for _, frame in ipairs({ui.HUD.FR_StatusPanel, ui.QuestUI.FR_QuestTracker, n.banner, n.subtitle}) do
			assert(frame.BackgroundTransparency == 1 and frame.BorderSizePixel == 0)
			for _, object in ipairs(frame:GetDescendants()) do
				if object:IsA("UIStroke") and object.Parent:IsA("GuiObject") then assert(object.Transparency == 1) end
			end
		end
		assert(n:Toast("Discovery", "Field understanding", "An observed pattern.")); n:_step(0)
		local toast = n.toasts[1]
		assert(toast.BackgroundTransparency == 1 and toast.TL_Title.TextStrokeTransparency < 1)
	end)
end)
test("Text outlines fade with their text and reduced motion restores their alpha", function()
	fixture(function(ui, n)
		local label = n.subtitleLabel
		local baseline = label.TextStrokeTransparency
		local effects = Effects.new(n.subtitle, ui)
		ui:SetAttribute("WB_ReducedMotion", true)
		effects:Fade(1, 0.5); assert(label.TextTransparency == 1 and label.TextStrokeTransparency == 1)
		effects:Fade(0, 0.5); assert(label.TextTransparency == 0 and label.TextStrokeTransparency == baseline)
	end)
end)
test("Intro suppresses subtitles and reveals without dropping the reveal order", function()
	fixture(function(ui, n)
		ui:SetAttribute("WB_IntroActive", true)
		n:Subtitle("Authored speech.", "City")
		n:Location("SKY CITY", "Inside the Machine", {Id = "SKY_CITY", Authored = true})
		n:_step(0); assert(not n.banner.Visible and not n.subtitle.Visible and n.pendingLocation)
		ui:SetAttribute("WB_IntroActive", false)
		n:ClearSubtitle(); n:_step(0)
		assert(n.banner.Visible and n.banner.TL_Subtitle.Text == "Inside the Machine")
	end)
end)
test("Supplied intro and region artwork loads without using baked HUD rectangles", function()
	local intro = player.PlayerGui.WOTIntro.FR_Intro
	assert(intro.IL_IntroScene.IsLoaded and intro.IL_TethysMasthead.IsLoaded)
	assert(intro.IL_IntroScene.Image == Style.Assets.OpeningReference.Image)
	local offset, size, ref = intro.IL_IntroScene.ImageRectOffset, intro.IL_IntroScene.ImageRectSize, Style.Assets.OpeningReference
	assert(offset.X > 0 and offset.Y > 0 and offset.X + size.X <= ref.Width and offset.Y + size.Y <= ref.Height)
	assert(Style.Assets.ReferenceSheet.Image == "rbxassetid://120531122548244")
end)
test("Branded menu retains accessible actions in a bounded scroll area", function()
	local menu, viewport = live.Menus.FR_PauseMenu, live.AbsoluteSize
	local pos, size = menu.AbsolutePosition - live.AbsolutePosition, menu.AbsoluteSize
	assert(pos.X >= 0 and pos.Y >= 0 and pos.X + size.X <= viewport.X + 1 and pos.Y + size.Y <= viewport.Y + 1)
	assert(menu.FR_Brand.TL_Tethys.Text == "T E T H Y S")
	assert(menu.SF_MenuActions.AutomaticCanvasSize == Enum.AutomaticSize.Y)
	for _, name in ipairs({"Resume", "Inventory", "Codex", "Settings"}) do
		local frame = menu.SF_MenuActions["TB_MenuItem_" .. name]
		assert(frame.TB_Activate.Selectable and frame.Size.Y.Offset >= 44)
	end
end)
test("Empty radial slots do not retain stale names or counts", function()
	for _, slot in ipairs(live.InventoryUI.FR_Quickbar:GetChildren()) do
		if slot:IsA("Frame") and slot.Name:match("^FR_Slot_") and not slot:GetAttribute("WB_ItemId") then
			assert(not slot.Visible and slot.TL_Count.Text == "")
			local name = slot:FindFirstChild("TL_Name")
			if name then assert(name.Text == "") end
		end
	end
end)
return result
