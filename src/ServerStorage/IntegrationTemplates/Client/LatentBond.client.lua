-- Integration template: dependencies and acceptance are listed in docs/engineering/roblox-integration.md.
if script:GetAttribute("TethysTemplateEnabled") ~= true then return end
-- src/StarterPlayer/StarterPlayerScripts/LatentBond.client.lua
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")

-- UX Elements
local bondAudio = Instance.new("Sound", camera)
bondAudio.SoundId = "rbxassetid://YOUR_LOW_FREQUENCY_RUMBLE_ID"
bondAudio.Looped = true
bondAudio.PlayOnRemove = false
bondAudio.Volume = 0
bondAudio:Play()

local colorShift = Instance.new("ColorCorrectionEffect", game.Lighting)
colorShift.Saturation = 0

-- Passive Proximity Sense
RunService.RenderStepped:Connect(function()
    local stryker = workspace:FindFirstChild("StrykerModel")
    if not stryker or not localPlayer.Character then return end

    local playerPos = localPlayer.Character.PrimaryPart.Position
    local distance = (playerPos - stryker.PrimaryPart.Position).Magnitude

    -- As Stryker gets closer (e.g., under 500 studs), the ambient headache grows
    if distance < 500 then
        local intensity = 1 - (distance / 500)
        bondAudio.Volume = intensity * 0.5
        colorShift.Saturation = -(intensity * 0.3) -- World slightly drains of color
    else
        bondAudio.Volume = 0
        colorShift.Saturation = 0
    end
end)

-- The Active Throb (Triggered by Stryker's wing flaps)
Events.StrykerExertion.OnClientEvent:Connect(function(strykerPos)
    local playerPos = localPlayer.Character.PrimaryPart.Position
    local distance = (playerPos - strykerPos).Magnitude

    if distance < 800 then
        -- A momentary, sharp spike in the player's FOV and audio to mimic a migraine pulse
        local fovTween = TweenService:Create(camera, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true), {FieldOfView = 68})
        fovTween:Play()

        local heartbeat = Instance.new("Sound", camera)
        heartbeat.SoundId = "rbxassetid://YOUR_HEARTBEAT_THUD_ID"
        heartbeat.Volume = 1 - (distance / 800)
        heartbeat:Play()

        game.Debris:AddItem(heartbeat, 1)
    end
end)
