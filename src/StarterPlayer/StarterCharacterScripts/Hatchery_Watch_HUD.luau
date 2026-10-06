local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
-- The shared HUD owns these cues when its binder is active.
local sharedUI = player:WaitForChild("PlayerGui"):WaitForChild("TethysUI", 2)
if sharedUI and player:GetAttribute("WOT_WildboundUIActive") == true then return end


local THEME = {
    Ash = Color3.fromRGB(12, 10, 9),
    AshLift = Color3.fromRGB(21, 18, 16),
    Slate = Color3.fromRGB(34, 39, 43),
    SlateEdge = Color3.fromRGB(68, 64, 60),
    Fog = Color3.fromRGB(231, 229, 228),
    FogSoft = Color3.fromRGB(168, 162, 158),
    Teal = Color3.fromRGB(120, 180, 170),
    Moss = Color3.fromRGB(16, 185, 129),
    Sulfur = Color3.fromRGB(251, 191, 36),
    Ember = Color3.fromRGB(249, 115, 22),
    Rust = Color3.fromRGB(180, 83, 9),
}

local function lerpColor(a, b, t)
    local alpha = math.clamp(t, 0, 1)
    return Color3.new(
        a.R + (b.R - a.R) * alpha,
        a.G + (b.G - a.G) * alpha,
        a.B + (b.B - a.B) * alpha
    )
end

local gui = playerGui:FindFirstChild("HatcheryWatchHUD")
if not gui then
    gui = Instance.new("ScreenGui")
    gui.Name = "HatcheryWatchHUD"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui
end

local oldPanel = gui:FindFirstChild("PilotPanel")
if oldPanel then
    oldPanel:Destroy()
end

local panel = Instance.new("Frame")
panel.Name = "PilotPanel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -16, 0, 16)
panel.Size = UDim2.new(0, 360, 0, 156)
panel.BackgroundColor3 = THEME.Ash
panel.BackgroundTransparency = 0.22
panel.BorderSizePixel = 0
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1
stroke.Color = THEME.SlateEdge
stroke.Transparency = 0.38
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 14, 0, 10)
title.Size = UDim2.new(0.62, 0, 0, 20)
title.Font = Enum.Font.GothamSemibold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = THEME.Fog
title.Text = "Hatchery Watch Pilot"
title.Parent = panel

local modeChip = Instance.new("TextLabel")
modeChip.Name = "ModeChip"
modeChip.BackgroundColor3 = THEME.Teal
modeChip.BackgroundTransparency = 0.5
modeChip.Position = UDim2.new(1, -122, 0, 10)
modeChip.Size = UDim2.new(0, 106, 0, 20)
modeChip.Font = Enum.Font.GothamSemibold
modeChip.TextSize = 11
modeChip.TextColor3 = THEME.Fog
modeChip.Text = "MINORS"
modeChip.Parent = panel

local modeCorner = Instance.new("UICorner")
modeCorner.CornerRadius = UDim.new(0, 8)
modeCorner.Parent = modeChip

local statusLine = Instance.new("TextLabel")
statusLine.Name = "StatusLine"
statusLine.BackgroundTransparency = 1
statusLine.Position = UDim2.new(0, 14, 0, 30)
statusLine.Size = UDim2.new(1, -28, 0, 16)
statusLine.Font = Enum.Font.Gotham
statusLine.TextSize = 12
statusLine.TextXAlignment = Enum.TextXAlignment.Left
statusLine.TextColor3 = THEME.FogSoft
statusLine.Text = "Stand by for pilot briefing."
statusLine.Parent = panel

local objectiveHeader = Instance.new("TextLabel")
objectiveHeader.Name = "ObjectiveHeader"
objectiveHeader.BackgroundTransparency = 1
objectiveHeader.Position = UDim2.new(0, 14, 0, 52)
objectiveHeader.Size = UDim2.new(1, -28, 0, 14)
objectiveHeader.Font = Enum.Font.GothamSemibold
objectiveHeader.TextSize = 11
objectiveHeader.TextXAlignment = Enum.TextXAlignment.Left
objectiveHeader.TextColor3 = THEME.FogSoft
objectiveHeader.Text = "CURRENT OBJECTIVE"
objectiveHeader.Parent = panel

local objectiveBody = Instance.new("TextLabel")
objectiveBody.Name = "ObjectiveBody"
objectiveBody.BackgroundTransparency = 1
objectiveBody.Position = UDim2.new(0, 14, 0, 66)
objectiveBody.Size = UDim2.new(1, -28, 0, 48)
objectiveBody.Font = Enum.Font.Gotham
objectiveBody.TextSize = 13
objectiveBody.TextWrapped = true
objectiveBody.TextXAlignment = Enum.TextXAlignment.Left
objectiveBody.TextYAlignment = Enum.TextYAlignment.Top
objectiveBody.TextColor3 = THEME.Fog
objectiveBody.Text = "Visit Brood Raceways and begin Hatchery Watch."
objectiveBody.Parent = panel

local progressTrack = Instance.new("Frame")
progressTrack.Name = "ProgressTrack"
progressTrack.BackgroundColor3 = THEME.Slate
progressTrack.BorderSizePixel = 0
progressTrack.Position = UDim2.new(0, 14, 1, -28)
progressTrack.Size = UDim2.new(1, -28, 0, 7)
progressTrack.Parent = panel

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 999)
progressCorner.Parent = progressTrack

local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.BackgroundColor3 = THEME.Teal
progressFill.BorderSizePixel = 0
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.Parent = progressTrack

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 999)
fillCorner.Parent = progressFill

local progressLabel = Instance.new("TextLabel")
progressLabel.Name = "ProgressLabel"
progressLabel.BackgroundTransparency = 1
progressLabel.Position = UDim2.new(0, 14, 1, -44)
progressLabel.Size = UDim2.new(1, -28, 0, 14)
progressLabel.Font = Enum.Font.GothamSemibold
progressLabel.TextSize = 11
progressLabel.TextXAlignment = Enum.TextXAlignment.Left
progressLabel.TextColor3 = THEME.FogSoft
progressLabel.Text = "Progress 0/6"
progressLabel.Parent = panel

local function clamp(v, a, b)
    return math.max(a, math.min(v, b))
end

local function formatClock(totalSeconds)
    totalSeconds = math.max(0, math.floor(totalSeconds + 0.5))
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    return string.format("%02d:%02d", minutes, seconds)
end

local lastRefreshSec = -1

local function refresh()
    local mode = player:GetAttribute("HW_Mode") or "Minors"
    local total = player:GetAttribute("HW_TotalSteps") or 6
    local step = player:GetAttribute("HW_Step") or 1
    local complete = player:GetAttribute("HW_Complete") == true
    local strikes = player:GetAttribute("HW_Strikes") or 0
    local rating = player:GetAttribute("HW_Rating") or "Unrated"
    local message = player:GetAttribute("HW_Message") or "Awaiting pilot briefing."
    local status = player:GetAttribute("HW_Status") or "Briefing"
    local visible = status == "InProgress" or complete
    gui.Enabled = visible
    if not visible then return end

    local startUnix = player:GetAttribute("HW_StartUnix") or 0
    local elapsed = player:GetAttribute("HW_ElapsedSec") or 0
    if status == "InProgress" and startUnix > 0 and not complete then
        elapsed = math.max(elapsed, os.time() - startUnix)
    end

    local target = player:GetAttribute("HW_TargetSec") or (mode == "Adults" and 270 or 420)
    local shownStep = complete and total or clamp(step, 1, total)
    local solvedCount = complete and total or clamp(step - 1, 0, total)
    local progress = total > 0 and (solvedCount / total) or 0

    local strikePressure = total > 0 and clamp(strikes / math.max(1, total * 0.8), 0, 1) or 0
    local timePressure = 0
    if not complete and target > 0 then
        local ratio = elapsed / target
        timePressure = clamp((ratio - 0.4) / 0.5, 0, 1)
    end

    local modePressure = mode == "Adults" and 0.24 or 0.08
    local danger = clamp(math.max(strikePressure, timePressure) + modePressure, 0, 1)
    if complete then
        danger *= 0.45
    end

    local visualDanger = clamp(danger * 1.15 + 0.07, 0, 1)

    local baseSignal = mode == "Adults" and THEME.Ember or THEME.Teal
    local hotSignal = mode == "Adults" and THEME.Rust or THEME.Ember
    local signalColor = lerpColor(baseSignal, hotSignal, visualDanger)

    if mode == "Adults" then
        modeChip.Text = "ADULTS"
    else
        modeChip.Text = "MINORS"
    end

    modeChip.BackgroundColor3 = signalColor
    progressFill.BackgroundColor3 = signalColor
    stroke.Color = lerpColor(THEME.SlateEdge, THEME.Rust, visualDanger * 0.9)
    statusLine.TextColor3 = lerpColor(THEME.FogSoft, THEME.Sulfur, visualDanger * 0.5)
    progressLabel.TextColor3 = lerpColor(THEME.FogSoft, THEME.Sulfur, visualDanger * 0.62)
    objectiveHeader.TextColor3 = lerpColor(THEME.FogSoft, THEME.Sulfur, visualDanger * 0.42)

    progressFill.Size = UDim2.new(clamp(progress, 0, 1), 0, 1, 0)
    progressLabel.Text = string.format("Progress %d/%d  |  Strikes %d  |  Target %s", shownStep, total, strikes, formatClock(target))

    local elapsedText = formatClock(elapsed)
    if complete then
        statusLine.Text = string.format("Status: Complete  |  Rating: %s  |  Time: %s", rating, elapsedText)
    else
        statusLine.Text = string.format("Status: %s  |  Elapsed: %s", status, elapsedText)
    end

    objectiveBody.Text = message
end

local tracked = {
    "HW_Mode",
    "HW_TotalSteps",
    "HW_Step",
    "HW_Complete",
    "HW_Strikes",
    "HW_Rating",
    "HW_Message",
    "HW_Status",
    "HW_StartUnix",
    "HW_ElapsedSec",
    "HW_TargetSec",
}

for _, attr in ipairs(tracked) do
    player:GetAttributeChangedSignal(attr):Connect(refresh)
end

RunService.Heartbeat:Connect(function()
    local status = player:GetAttribute("HW_Status")
    local complete = player:GetAttribute("HW_Complete") == true
    if status == "InProgress" and not complete then
        local nowSec = os.time()
        if nowSec ~= lastRefreshSec then
            lastRefreshSec = nowSec
            refresh()
        end
    end
end)

refresh()

