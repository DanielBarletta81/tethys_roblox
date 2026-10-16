local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild("PlayerGui")
local template = StarterGui:FindFirstChild("TethysUI")
if not template then warn("[WildboundUIRuntimeBinder] TethysUI missing"); return end

-- Let Roblox copy StarterGui first; immediate cloning used to create two HUDs.
player:SetAttribute("WOT_WildboundUIActive", true)
local ui = playerGui:WaitForChild("TethysUI", 5)
if not ui then ui = template:Clone(); ui.Parent = playerGui end
if ui:GetAttribute("WB_RuntimeBound") then return end
ui.Enabled = false

local library = ReplicatedStorage:WaitForChild("WildboundUI")
local controllers = library:WaitForChild("Controllers")
require(library.TemplateState).Prepare(ui)
ui:SetAttribute("WB_RuntimeBound", true)
local Style = require(library.UIStyle)
local Data = require(library.RuntimeData)
local function updateProfile() ui:SetAttribute("WB_PresentationProfile", Data.Profile(player, ui)) end
ui:GetAttributeChangedSignal("WB_HUDProfile"):Connect(updateProfile)
library:GetAttributeChangedSignal("HUDProfile"):Connect(updateProfile)
player:GetAttributeChangedSignal("SC_OnboardingStage"):Connect(updateProfile)
player:GetAttributeChangedSignal("HW_Complete"):Connect(updateProfile)
player:GetAttributeChangedSignal("WB_Chapter"):Connect(updateProfile)
updateProfile()
local inputMode = require(library.InputMode).new()
Style.Apply(ui)
local inventory = require(controllers.InventoryController).new(player, ui)
inventory:SetInputMode(inputMode:GetMode())
inputMode:ModeChangedSignal():Connect(function(mode) inventory:SetInputMode(mode) end)
local menu = require(controllers.MenuController).new(ui, inventory, inputMode)
local notices = require(controllers.NoticeController).new(ui)
local noticeChannel = Instance.new("BindableEvent")
noticeChannel.Name, noticeChannel.Parent = "BE_Notice", ui.Notifications
noticeChannel.Event:Connect(function(kind, title, text) notices:Toast(kind, title, text) end)
require(controllers.ReturnController).new(player, ui, function() menu:CloseAll() end)
require(controllers.HUDController).new(player, ui)
require(controllers.NavigationController).new(player, ui)
require(controllers.PromptController).new(ui, inputMode)
require(controllers.CharacterPreviewController).new(ui, library)
local function updateLayout() Style.Layout(ui, ui.AbsoluteSize) end
ui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayout)
updateLayout()
ui.LocationUI.FR_LocationBanner.Visible = false
require(controllers.IntroController).new(player, ui, inputMode)
ui.Enabled = true -- Reveal only after templates, profile and controllers are ready.
script:SetAttribute("WB_RuntimeBinderActive", true)
script:SetAttribute("WB_RuntimeBinderVersion", "HUD1.6")
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

local numericSlots = {
	[Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4,
}
local directionalSlots = { [Enum.KeyCode.DPadUp] = 1, [Enum.KeyCode.DPadLeft] = 2, [Enum.KeyCode.DPadRight] = 3, [Enum.KeyCode.DPadDown] = 4 }
ContextActionService:BindActionAtPriority("WB_RadialItems", function(_, state, input)
	if ui:GetAttribute("WB_IntroActive") or ui:GetAttribute("WB_ReturnNoticeActive") or ui:GetAttribute("WB_MenuOpen") or UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
	if state == Enum.UserInputState.Begin then inventory:SelectQuick(directionalSlots[input.KeyCode]) end
	return Enum.ContextActionResult.Sink
end, false, 3200, Enum.KeyCode.DPadUp, Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight, Enum.KeyCode.DPadDown)
UserInputService.InputBegan:Connect(function(input, processed)
	local key = input.KeyCode
	if ui:GetAttribute("WB_ReturnNoticeActive") or ui:GetAttribute("WB_IntroActive") then return end
	if key == Enum.KeyCode.ButtonB and ui:GetAttribute("WB_MenuOpen") then menu:CloseAll(); return end
	if processed or UserInputService:GetFocusedTextBox() then return end
	if key == Enum.KeyCode.M or key == Enum.KeyCode.ButtonStart then menu:SetOpen(not menu.open); return end
	if key == Enum.KeyCode.I or key == Enum.KeyCode.ButtonY then
		menu:SetOpen(false)
		inventory:SetOpen(not inventory.panel.Visible)
		return
	end
	if key == Enum.KeyCode.ButtonB then menu:CloseAll(); return end
	if ui:GetAttribute("WB_MenuOpen") then return end
	if numericSlots[key] then inventory:SelectQuick(numericSlots[key]) end
end)
UserInputService.WindowFocusReleased:Connect(function() menu:CloseAll() end)

local hintQueued = false
local lastHintSignature
local function queueHint()
	if hintQueued then return end
	hintQueued = true
	-- Several producers stamp tick before text. Read the completed attribute batch.
	task.delay(0.05, function()
		hintQueued = false
		local text = player:GetAttribute("OL_LastHintText")
		if type(text) ~= "string" or text == "" then return end
		local key = tostring(player:GetAttribute("OL_LastHintKey") or "")
		local signature = tostring(player:GetAttribute("OL_LastHintTick")) .. "|" .. text
		if signature == lastHintSignature then return end
		lastHintSignature = signature
		if text == player:GetAttribute("WOT_NextPull") then return end
		if key:lower():find("dialog", 1, true) or key:lower():find("taunt", 1, true) then notices:Subtitle(text, "Field")
		elseif ui:GetAttribute("WB_PresentationProfile") ~= "Game1" then
			notices:Toast(key:find("Hazard") and "Danger" or "Discovery", "Field observation", text, math.clamp(3 + #text / 45, 4, 9))
		end
	end)
end
for _, attribute in ipairs({ "OL_LastHintTick", "OL_LastHintText" }) do player:GetAttributeChangedSignal(attribute):Connect(queueHint) end
player:GetAttributeChangedSignal("SC_Message"):Connect(function() notices:Subtitle(player:GetAttribute("SC_Message"), "City") end)
local function openingLocation()
	local reveal = require(library.PresentationPolicy).OpeningLocation(player:GetAttribute("OpeningPhase"))
	if reveal then notices:Location(reveal.Title, reveal.Context, reveal) end
end
player:GetAttributeChangedSignal("OpeningPhase"):Connect(openingLocation)
openingLocation()
local cineQueued, lastCineTick = false, nil
local function queueCinematic()
	if cineQueued then return end
	cineQueued = true
	task.delay(0.05, function()
		cineQueued = false
		local tick = player:GetAttribute("OL_CineTick")
		if type(tick) ~= "number" or tick == lastCineTick then return end
		lastCineTick = tick
		local speaker, text = player:GetAttribute("OL_CineSpeaker"), player:GetAttribute("OL_CineLine")
		local upper = (tostring(speaker) .. " " .. tostring(text)):upper()
		if upper:find("STRYKER",1,true) or upper:find("CURRENT-RAT",1,true) then return end
		notices:Subtitle(text, "Cinematic", player:GetAttribute("OL_CineDuration"))
	end)
end
player:GetAttributeChangedSignal("OL_CineTick"):Connect(queueCinematic)
local function updateCordge()
	local text = player:GetAttribute("WB_CordgeSpeechText")
	if player:GetAttribute("WB_CordgeLineId") and type(text) == "string" and text ~= "" then
		notices:Subtitle(text, "Cordge")
	else
		notices:ClearSubtitle("Cordge")
	end
end
-- Revision is published after the line and text, making this a complete batch.
player:GetAttributeChangedSignal("WB_CordgeSpeechRevision"):Connect(updateCordge)
player.CharacterRemoving:Connect(function() notices:ClearSubtitle("Cordge") end)
player:GetAttributeChangedSignal("INV_LastGrant"):Connect(function()
	local grant = player:GetAttribute("INV_LastGrant")
	if type(grant) == "string" and grant ~= "" then notices:Toast("Item", "Supplies acquired", Data.Label(grant)) end
end)

local function bindRemote(remote, callback)
	if remote and remote:IsA("RemoteEvent") then remote.OnClientEvent:Connect(callback) end
end
local wildbound = ReplicatedStorage:FindFirstChild("Wildbound")
local remotes = wildbound and wildbound:FindFirstChild("Remotes")
bindRemote(remotes and remotes:FindFirstChild("WB_RuntimeCue"), function(cue)
	if type(cue) ~= "table" then return end
	local reveal = require(library.PresentationPolicy).ResolveTitle(cue)
	if reveal then notices:Location(reveal.Title, reveal.Context, reveal) end
end)
local tethys = ReplicatedStorage:FindFirstChild("Tethys")
local knowledgeRemotes = tethys and tethys:FindFirstChild("Remotes")
bindRemote(knowledgeRemotes and knowledgeRemotes:FindFirstChild("KnowledgeUpdate"), function(cue)
	if type(cue) == "table" and cue.kind == "Cue" then notices:Subtitle(cue.text, "Knowledge") end
end)
queueHint()
queueCinematic()
notices:Subtitle(player:GetAttribute("SC_Message"), "City")
updateCordge()

print("[WildboundUIRuntimeBinder] HUD1.6 ready")

local function connectCodex(gui)
	if gui.Name ~= "WOTSymbolCodexGui" then return end
	-- The producer parents this GUI before its controls exist.
	task.spawn(function() Style.Codex(gui, ui) end)
	local function updateToggle()
		local toggle = gui:FindFirstChild("Toggle")
		if toggle then toggle.Visible = ui:GetAttribute("WB_IntroActive") ~= true and ui:GetAttribute("WB_PresentationProfile") ~= "Game1" end
	end
	ui:GetAttributeChangedSignal("WB_PresentationProfile"):Connect(updateToggle)
	ui:GetAttributeChangedSignal("WB_IntroActive"):Connect(updateToggle)
	gui.ChildAdded:Connect(function(child) if child.Name == "Toggle" then updateToggle() end end)
	updateToggle()
	menu.onOpenCodex = function() local event = gui:FindFirstChild("BE_SetOpen"); if event then event:Fire(true) end end
	menu.onBeforeOpen = function()
		local event = gui:FindFirstChild("BE_SetOpen")
		if event then event:Fire(false) end
	end
	gui:GetAttributeChangedSignal("WB_CodexOpen"):Connect(function()
		local open = gui:GetAttribute("WB_CodexOpen") == true
		if open then menu:SetOpen(false); inventory:SetOpen(false) end
		menu.externalOpen = open
		menu:_syncOverlay()
	end)
end
for _, gui in ipairs(playerGui:GetChildren()) do connectCodex(gui) end
playerGui.ChildAdded:Connect(connectCodex)
