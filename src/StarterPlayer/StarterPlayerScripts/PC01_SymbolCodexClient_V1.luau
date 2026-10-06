local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SYMBOL_ROOT_PATH = "Workspace.World.22_ImmediateCityFortressLoop_V1.09_ContextSymbology_V1"

local function findPath(path)
    local cur = game
    for token in string.gmatch(path, "[^%.]+") do
        cur = cur:FindFirstChild(token)
        if not cur then
            return nil
        end
    end
    return cur
end

local function attrString(v)
    if type(v) == "string" then
        return v
    end
    return ""
end

local function parseKnownKeys(raw)
    local known = {}
    if type(raw) ~= "string" or raw == "" then
        return known
    end
    for token in string.gmatch(raw, "[^|]+") do
        known[token] = true
    end
    return known
end

local function cloneKnownMap(known)
    local copy = {}
    for key, isKnown in pairs(known) do
        if isKnown then
            copy[key] = true
        end
    end
    return copy
end

local function collectCatalog()
    local uiLibrary = game:GetService("ReplicatedStorage"):FindFirstChild("WildboundUI")
    local symRoot = uiLibrary and uiLibrary:FindFirstChild("SymbolCatalog") or findPath(SYMBOL_ROOT_PATH)
    local byKey = {}
    if not symRoot then
        return {}
    end

    for _, d in ipairs(symRoot:GetDescendants()) do
        if (d:IsA("BasePart") or d:IsA("Folder")) and d:GetAttribute("WOT_SymbolKey") ~= nil then
            local key = attrString(d:GetAttribute("WOT_SymbolKey"))
            if key ~= "" and not byKey[key] then
                byKey[key] = {
                    key = key,
                    order = tonumber(d:GetAttribute("WOT_SymbolOrder")) or 999,
                    symbolName = attrString(d:GetAttribute("WOT_SymbolName")),
                    meaning = attrString(d:GetAttribute("WOT_SymbolMeaning")),
                    gemTitle = attrString(d:GetAttribute("WOT_SymbolGemTitle")),
                    gemLore = attrString(d:GetAttribute("WOT_SymbolGemLore")),
                    gemScience = attrString(d:GetAttribute("WOT_SymbolGemScience")),
                    gemSource = attrString(d:GetAttribute("WOT_SymbolGemSource")),
                }
            end
        end
    end

    local list = {}
    for _, entry in pairs(byKey) do
        list[#list + 1] = entry
    end

    table.sort(list, function(a, b)
        if a.order == b.order then
            return a.key < b.key
        end
        return a.order < b.order
    end)

    return list
end

local existing = playerGui:FindFirstChild("WOTSymbolCodexGui")
if existing then
    existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "WOTSymbolCodexGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 35
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "Toggle"
toggleButton.AnchorPoint = Vector2.new(1, 1)
toggleButton.Position = UDim2.fromScale(0.96, 0.97)
toggleButton.Size = UDim2.new(0, 138, 0, 34)
toggleButton.BackgroundColor3 = Color3.fromRGB(37, 43, 42)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "Codex [J]"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 14
toggleButton.TextColor3 = Color3.fromRGB(221, 211, 187)
toggleButton.AutoButtonColor = true
toggleButton.Parent = gui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 2)
toggleCorner.Parent = toggleButton

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 1)
panel.Position = UDim2.new(1, -16, 1, -58)
panel.Size = UDim2.fromScale(0.86, 0.72)
local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MaxSize = Vector2.new(420, 510)
sizeLimit.Parent = panel
panel.BackgroundColor3 = Color3.fromRGB(22, 27, 27)
panel.BackgroundTransparency = 0.12
panel.BorderSizePixel = 0
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 2)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(155, 121, 80)
panelStroke.Thickness = 1
panelStroke.Transparency = 0.22
panelStroke.Parent = panel

local header = Instance.new("TextLabel")
header.Name = "Header"
header.BackgroundTransparency = 1
header.Position = UDim2.new(0, 14, 0, 10)
header.Size = UDim2.new(1, -28, 0, 30)
header.TextXAlignment = Enum.TextXAlignment.Left
header.Font = Enum.Font.GothamBold
header.TextSize = 16
header.TextColor3 = Color3.fromRGB(221, 211, 187)
header.Text = "Mysterious Nine Codex"
header.Parent = panel

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.new(0, 14, 0, 36)
subtitle.Size = UDim2.new(1, -28, 0, 20)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 12
subtitle.TextColor3 = Color3.fromRGB(176, 174, 164)
subtitle.Text = "Symbols and field observations"
subtitle.Parent = panel

local progress = Instance.new("TextLabel")
progress.Name = "Progress"
progress.BackgroundTransparency = 1
progress.Position = UDim2.new(0, 14, 0, 56)
progress.Size = UDim2.new(1, -28, 0, 22)
progress.TextXAlignment = Enum.TextXAlignment.Left
progress.Font = Enum.Font.GothamMedium
progress.TextSize = 13
progress.TextColor3 = Color3.fromRGB(128, 182, 181)
progress.Text = "Unlocked 0/9"
progress.Parent = panel

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Entries"
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.Position = UDim2.new(0, 10, 0, 84)
scroll.Size = UDim2.new(1, -20, 1, -128)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = Color3.fromRGB(155, 121, 80)
scroll.Selectable = true
scroll.Parent = panel

local list = Instance.new("UIListLayout")
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, 2)
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.Parent = scroll

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 2)
pad.PaddingBottom = UDim.new(0, 2)
pad.Parent = scroll

local footer = Instance.new("TextLabel")
footer.Name = "Footer"
footer.BackgroundTransparency = 1
footer.Position = UDim2.new(0, 14, 1, -34)
footer.Size = UDim2.new(1, -28, 0, 24)
footer.TextXAlignment = Enum.TextXAlignment.Left
footer.Font = Enum.Font.Gotham
footer.TextSize = 11
footer.TextColor3 = Color3.fromRGB(176, 174, 164)
footer.Text = "Study symbol plates to decode additional entries."
footer.Parent = panel

local toastHost = Instance.new("Frame")
toastHost.Name = "ToastHost"
toastHost.AnchorPoint = Vector2.new(1, 0)
toastHost.Position = UDim2.new(1, -16, 0, 16)
toastHost.Size = UDim2.new(0, 360, 0, 76)
toastHost.BackgroundTransparency = 1
toastHost.Parent = gui

local toastCard = Instance.new("Frame")
toastCard.Name = "Toast"
toastCard.AnchorPoint = Vector2.new(1, 0)
toastCard.Position = UDim2.new(1, 22, 0, 0)
toastCard.Size = UDim2.new(1, 0, 1, 0)
toastCard.BackgroundColor3 = Color3.fromRGB(37, 43, 42)
toastCard.BackgroundTransparency = 0.06
toastCard.BorderSizePixel = 0
toastCard.Visible = false
toastCard.Parent = toastHost

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 2)
toastCorner.Parent = toastCard

local toastStroke = Instance.new("UIStroke")
toastStroke.Color = Color3.fromRGB(155, 121, 80)
toastStroke.Thickness = 1
toastStroke.Transparency = 0.2
toastStroke.Parent = toastCard

local toastTitle = Instance.new("TextLabel")
toastTitle.BackgroundTransparency = 1
toastTitle.Position = UDim2.new(0, 12, 0, 8)
toastTitle.Size = UDim2.new(1, -24, 0, 20)
toastTitle.TextXAlignment = Enum.TextXAlignment.Left
toastTitle.Font = Enum.Font.GothamBold
toastTitle.TextSize = 12
toastTitle.TextColor3 = Color3.fromRGB(213, 173, 109)
toastTitle.Text = "ROOT CHOIR REGISTERED"
toastTitle.Parent = toastCard

local toastBody = Instance.new("TextLabel")
toastBody.BackgroundTransparency = 1
toastBody.Position = UDim2.new(0, 12, 0, 30)
toastBody.Size = UDim2.new(1, -24, 0, 38)
toastBody.TextXAlignment = Enum.TextXAlignment.Left
toastBody.TextYAlignment = Enum.TextYAlignment.Top
toastBody.TextWrapped = true
toastBody.Font = Enum.Font.Gotham
toastBody.TextSize = 11
toastBody.TextColor3 = Color3.fromRGB(221, 211, 187)
toastBody.Text = ""
toastBody.Parent = toastCard

local isOpen = false
local openPos = UDim2.new(1, -16, 1, -58)
local closedPos = UDim2.new(1, 444, 1, -58)
panel.Position = closedPos

local function setOpen(nextOpen)
    isOpen = nextOpen
    gui:SetAttribute("WB_CodexOpen", isOpen)
    if isOpen then GuiService.SelectedObject = toggleButton
    elseif GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(gui) then GuiService.SelectedObject = nil end
    local lastInput = game:GetService("UserInputService"):GetLastInputType()
    local suffix = lastInput.Name:find("Gamepad") and "[MENU]" or lastInput == Enum.UserInputType.Touch and "" or "[J]"
    toggleButton.Text = (isOpen and "Close Codex " or "Codex ") .. suffix
    local goal = { Position = isOpen and openPos or closedPos }
    TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

local setOpenEvent = Instance.new("BindableEvent")
setOpenEvent.Name = "BE_SetOpen"
setOpenEvent.Parent = gui
setOpenEvent.Event:Connect(setOpen)

local toastNonce = 0
local function showUnlockToast(entry, knownCount, total)
    local title = (entry.gemTitle ~= "" and entry.gemTitle) or entry.symbolName or entry.key
    toastNonce += 1
    local nonce = toastNonce

    toastBody.Text = string.format("%s decoded (%d/%d).", title, knownCount, total)
    toastCard.Visible = true
    toastCard.Position = UDim2.new(1, 22, 0, 0)

    toastCard.BackgroundTransparency = 0.06
    toastTitle.TextTransparency = 1
    toastBody.TextTransparency = 1

    TweenService:Create(toastCard, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, 0, 0, 0),
    }):Play()
    TweenService:Create(toastTitle, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0,
    }):Play()
    TweenService:Create(toastBody, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0,
    }):Play()

    task.delay(2.8, function()
        if nonce ~= toastNonce then
            return
        end
        TweenService:Create(toastCard, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 22, 0, 0),
            BackgroundTransparency = 0.25,
        }):Play()
        TweenService:Create(toastTitle, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TextTransparency = 1,
        }):Play()
        TweenService:Create(toastBody, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TextTransparency = 1,
        }):Play()

        task.delay(0.25, function()
            if nonce == toastNonce then
                toastCard.Visible = false
            end
        end)
    end)
end

local function clearRows()
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
end

local function makeRow(entry, unlocked)
    local row = Instance.new("Frame")
    row.Name = entry.key .. "_Row"
    row.LayoutOrder = entry.order
    row.Size = UDim2.new(1, -10, 0, unlocked and 128 or 82)
    row.BackgroundColor3 = unlocked and Color3.fromRGB(37, 43, 42) or Color3.fromRGB(22, 27, 27)
    row.BackgroundTransparency = unlocked and 0.12 or 0.28
    row.BorderSizePixel = 0
    row.Parent = scroll

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 2)
    rowCorner.Parent = row

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Thickness = 1
    rowStroke.Transparency = unlocked and 0.25 or 0.5
    rowStroke.Color = unlocked and Color3.fromRGB(155, 121, 80) or Color3.fromRGB(52, 59, 58)
    rowStroke.Parent = row

    local order = Instance.new("TextLabel")
    order.BackgroundTransparency = 1
    order.Position = UDim2.new(0, 10, 0, 8)
    order.Size = UDim2.new(0, 38, 0, 18)
    order.TextXAlignment = Enum.TextXAlignment.Left
    order.Font = Enum.Font.GothamBold
    order.TextSize = 12
    order.TextColor3 = unlocked and Color3.fromRGB(213, 173, 109) or Color3.fromRGB(176, 174, 164)
    order.Text = string.format("%02d", entry.order)
    order.Parent = row

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 52, 0, 8)
    title.Size = UDim2.new(1, -62, 0, 20)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextColor3 = unlocked and Color3.fromRGB(221, 211, 187) or Color3.fromRGB(176, 174, 164)
    title.Text = unlocked and ((entry.gemTitle ~= "" and entry.gemTitle) or entry.symbolName) or "Locked Sigil"
    title.Parent = row

    local lore = Instance.new("TextLabel")
    lore.BackgroundTransparency = 1
    lore.Position = UDim2.new(0, 10, 0, 30)
    lore.Size = UDim2.new(1, -20, 0, unlocked and 44 or 32)
    lore.TextXAlignment = Enum.TextXAlignment.Left
    lore.TextYAlignment = Enum.TextYAlignment.Top
    lore.TextWrapped = true
    lore.Font = Enum.Font.Gotham
    lore.TextSize = 12
    lore.TextColor3 = unlocked and Color3.fromRGB(221, 211, 187) or Color3.fromRGB(176, 174, 164)
    lore.Text = unlocked and entry.gemLore or "Study this symbol plate to decode the archive fragment."
    lore.Parent = row

    if unlocked then
        local science = Instance.new("TextLabel")
        science.BackgroundTransparency = 1
        science.Position = UDim2.new(0, 10, 0, 78)
        science.Size = UDim2.new(1, -20, 0, 34)
        science.TextXAlignment = Enum.TextXAlignment.Left
        science.TextWrapped = true
        science.Font = Enum.Font.Gotham
        science.TextSize = 11
        science.TextColor3 = Color3.fromRGB(176, 174, 164)
        science.Text = entry.gemScience ~= "" and entry.gemScience or entry.meaning
        science.Parent = row

        local source = Instance.new("TextLabel")
        source.BackgroundTransparency = 1
        source.Position = UDim2.new(0, 10, 1, -16)
        source.Size = UDim2.new(1, -20, 0, 14)
        source.TextXAlignment = Enum.TextXAlignment.Left
        source.Font = Enum.Font.Gotham
        source.TextSize = 10
        source.TextColor3 = Color3.fromRGB(104, 136, 151)
        source.Text = entry.gemSource
        source.Visible = false -- Keep internal document references in metadata.
        source.Parent = row
    end
end

local knownSnapshot = {}
local hasKnownSnapshot = false

local function render()
    local entries = collectCatalog()
    local known = parseKnownKeys(player:GetAttribute("OL_SymbolKnownKeys"))

    local knownCount = tonumber(player:GetAttribute("OL_SymbolLexiconKnown")) or 0
    local total = tonumber(player:GetAttribute("OL_SymbolLexiconTotal")) or #entries
    if total <= 0 then
        total = #entries
    end

    progress.Text = string.format("Unlocked %d/%d", math.min(knownCount, total), total)

    clearRows()
    for _, entry in ipairs(entries) do
        makeRow(entry, known[entry.key] == true)
    end

    if hasKnownSnapshot then
        local delayStep = 0
        for _, entry in ipairs(entries) do
            if known[entry.key] and not knownSnapshot[entry.key] then
                local captureEntry = entry
                task.delay(delayStep, function()
                    showUnlockToast(captureEntry, knownCount, total)
                end)
                delayStep += 0.35
            end
        end
    end

    knownSnapshot = cloneKnownMap(known)
    hasKnownSnapshot = true
end

local function hookAttribute(attr)
    player:GetAttributeChangedSignal(attr):Connect(render)
end

hookAttribute("OL_SymbolLexiconKnown")
hookAttribute("OL_SymbolLexiconTotal")
hookAttribute("OL_SymbolKnownKeys")

list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 6)
end)

toggleButton.Activated:Connect(function()
    setOpen(not isOpen)
end)

local UIStyle = require(game:GetService("ReplicatedStorage").WildboundUI.UIStyle)
UIStyle.Icon("Journal", "IL_CodexGlyph", toggleButton, UDim2.fromOffset(6, 4), UDim2.fromOffset(26, 26))
toggleButton.Size = UDim2.fromOffset(170, 34)
toggleButton.TextTransparency = 1
local toggleCaption = UIStyle.Text("TL_ToggleCaption", toggleButton, toggleButton.Text, UDim2.fromOffset(38, 0), UDim2.new(1, -44, 1, 0), 13)
toggleCaption.TextXAlignment = Enum.TextXAlignment.Center
toggleCaption.TextTruncate = Enum.TextTruncate.AtEnd
toggleButton:GetPropertyChangedSignal("Text"):Connect(function() toggleCaption.Text = toggleButton.Text end)
UIStyle.Panel(toggleButton)
UIStyle.Button(toggleButton)
toggleButton.NextSelectionDown = scroll
scroll.NextSelectionUp = toggleButton
local scrollFocus = Instance.new("UIStroke")
scrollFocus.Name = "US_Focus"
scrollFocus.Color = UIStyle.Theme.Colors.BronzeBright
scrollFocus.Thickness = 2
scrollFocus.Transparency = 1
scrollFocus.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
scrollFocus.Parent = scroll
scroll.SelectionGained:Connect(function() scrollFocus.Transparency = 0 end)
scroll.SelectionLost:Connect(function() scrollFocus.Transparency = 1 end)
local UIS = game:GetService("UserInputService")
local function refreshGlyph()
    local input = UIS:GetLastInputType()
    local suffix = input.Name:find("Gamepad") and "[MENU]" or input == Enum.UserInputType.Touch and "" or "[J]"
    toggleButton.Text = (isOpen and "Close Codex " or "Codex ") .. suffix
end
UIS.LastInputTypeChanged:Connect(refreshGlyph)
refreshGlyph()
UIS.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.ButtonB and isOpen then setOpen(false); return end
    if gameProcessed then
        return
    end
    local sharedUI = playerGui:FindFirstChild("TethysUI")
    if input.KeyCode == Enum.KeyCode.J then
        setOpen(not isOpen)
    end
end)

render()

local catalogLibrary = game:GetService("ReplicatedStorage"):WaitForChild("WildboundUI")
local function bindCatalog(catalog)
    if catalog.Name ~= "SymbolCatalog" then return end
    local function watch(entry)
        for _, attribute in ipairs({ "WOT_SymbolKey", "WOT_SymbolName", "WOT_SymbolOrder", "WOT_SymbolGemTitle", "WOT_SymbolGemLore", "WOT_SymbolGemScience" }) do
            entry:GetAttributeChangedSignal(attribute):Connect(render)
        end
        render()
    end
    for _, entry in ipairs(catalog:GetChildren()) do watch(entry) end
    catalog.ChildAdded:Connect(watch)
    catalog.ChildRemoved:Connect(render)
end
for _, catalog in ipairs(catalogLibrary:GetChildren()) do bindCatalog(catalog) end
catalogLibrary.ChildAdded:Connect(bindCatalog)

-- Retry a few times on startup in case server attribute stamping arrives a moment later.
task.spawn(function()
    for _ = 1, 12 do
        task.wait(0.5)
        render()
    end
end)

print("[PC01_SymbolCodexClient_V1] ready")
