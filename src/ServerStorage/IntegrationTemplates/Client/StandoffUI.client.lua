-- Integration template: dependencies and acceptance are listed in docs/engineering/roblox-integration.md.
if script:GetAttribute("TethysTemplateEnabled") ~= true then return end
-- src/StarterPlayer/StarterPlayerScripts/StandoffUI.client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events")
local playerClass = localPlayer:GetAttribute("Faction") -- "Igzier" or "RootListener"

local function displayCinematicText(text, isSensory)
    local screenGui = localPlayer.PlayerGui:WaitForChild("CinematicUI")
    local textLabel = screenGui.SubtitleLabel

    textLabel.Text = text
    textLabel.TextColor3 = isSensory and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(200, 200, 200)
    textLabel.TextTransparency = 1

    local tweenIn = TweenService:Create(textLabel, TweenInfo.new(0.5), {TextTransparency = 0})
    tweenIn:Play()

    task.wait(4)
    local tweenOut = TweenService:Create(textLabel, TweenInfo.new(1), {TextTransparency = 1})
    tweenOut:Play()
end

Events.StrykerStandoff.OnClientEvent:Connect(function(stryker, ravelCharacter)
    -- Play the client-side animation of Stryker stepping toward Ravel
    local animator = stryker:FindFirstChild("Humanoid"):FindFirstChild("Animator")
    local approachAnim = animator:LoadAnimation(ReplicatedStorage.Animations.StrykerApproach)
    approachAnim:Play()

    -- Wait for the moment Stryker stops and "chuffs"
    task.wait(1.5)
    stryker.Audio.RecognitionChuff:Play()

    if playerClass == "RootListener" or localPlayer.Name == "Ravel" then
        -- Ravel's Secret UI: Reading the biochemical output
        displayCinematicText("[PHEROMONES: RECOGNITION // AGGRESSION: ZERO]", true)

        -- Unlock an interaction prompt to hold ground and place a hand on the beak
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Hold Ground"
        prompt.HoldDuration = 1
        prompt.Parent = stryker.PrimaryPart

        prompt.Triggered:Connect(function()
            -- Ravel accepts the greeting, unlocking unique dialogue options later
            prompt:Destroy()
            print("Secret history acknowledged.")
        end)

    elseif playerClass == "Igzier" then
        -- Igzier's UI: Complete confusion
        -- Apply a slight camera zoom to Ravel to emphasize Igzier's focus on the anomaly
        local camera = workspace.CurrentCamera
        local zoomTween = TweenService:Create(camera, TweenInfo.new(2, Enum.EasingStyle.Sine), {FieldOfView = 50})
        zoomTween:Play()

        displayCinematicText("[Stryker... recognizes him?]", false)

        task.wait(3)
        local zoomReset = TweenService:Create(camera, TweenInfo.new(1), {FieldOfView = 70})
        zoomReset:Play()
    end
end)
