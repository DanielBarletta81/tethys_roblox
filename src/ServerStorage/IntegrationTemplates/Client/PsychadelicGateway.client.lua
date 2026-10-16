-- Integration template: dependencies and acceptance are listed in docs/engineering/roblox-integration.md.
if script:GetAttribute("TethysTemplateEnabled") ~= true then return end
-- src/StarterPlayer/StarterPlayerScripts/PsychedelicGateway.client.lua
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")

local camera = game.Workspace.CurrentCamera

-- Create the distortion effects
local colorCorrection = Instance.new("ColorCorrectionEffect", Lighting)
local blur = Instance.new("BlurEffect", Lighting)
blur.Size = 0

local function triggerVeilTearerTrip()
    print("[SENSORY OVERRIDE] Ingested Veil-Tearer. Binding to mycelial network.")

    -- 1. The Breathing FOV
    local fovTweenIn = TweenService:Create(camera, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {FieldOfView = 90})
    fovTweenIn:Play()

    -- 2. Color Shifting & Blur
    local colorTween = TweenService:Create(colorCorrection, TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, true), {
        TintColor = Color3.fromRGB(150, 50, 255),
        Contrast = 1.5,
        Saturation = 2
    })
    colorTween:Play()

    local blurTween = TweenService:Create(blur, TweenInfo.new(2, Enum.EasingStyle.Bounce), {Size = 15})
    blurTween:Play()

    -- 3. Enable the Hidden Root Data Layer
    -- This toggles the visibility of the Forensic Nodes scattered in the Woods
    local rootNodes = game.Workspace.MysticWoods.HiddenNodes:GetChildren()
    for _, node in ipairs(rootNodes) do
        if node:IsA("BasePart") then
            node.Transparency = 0.2 -- Reveal the hidden forensic triggers

            -- Apply a glowing highlight that only this client can see
            local highlight = Instance.new("Highlight", node)
            highlight.FillColor = Color3.fromRGB(0, 255, 100)
        end
    end

    -- 4. The Come Down
    task.wait(45) -- The trip lasts 45 seconds

    fovTweenIn:Cancel()
    camera.FieldOfView = 70
    colorCorrection:Destroy()
    blur:Destroy()

    -- Ping server to permanently flag the player as a Root-Listener Initiate
    Events.UnlockListenerPath:FireServer("VeilTearer_Survived")
end

-- Listen for the consumption event
Events.ConsumeFungi.OnClientEvent:Connect(function(fungiType)
    if fungiType == "VeilTearer" then
        triggerVeilTearerTrip()
    end
end)
