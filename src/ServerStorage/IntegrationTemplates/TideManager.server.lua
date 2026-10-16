-- Integration template: dependencies and acceptance are listed in docs/engineering/roblox-integration.md.
if script:GetAttribute("TethysTemplateEnabled") ~= true then return end
-- src/ServerScriptService/TideManager.server.lua
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Configuration
local TIDE_CYCLE_MINUTES = 30 -- A full high-to-low cycle takes 30 real minutes
local TIDE_AMPLITUDE = 40 -- Tides rise and fall 40 studs
local BASE_WATER_HEIGHT = 10

local RockPointWater = Workspace:WaitForChild("RockPointWaterBlock")
local SubmergedTunnels = Workspace:WaitForChild("SubmergedTunnels")

RunService.Heartbeat:Connect(function()
    local timeNow = os.time()

    -- Calculate sine wave for smooth, continuous tidal flow
    local cyclePosition = (timeNow % (TIDE_CYCLE_MINUTES * 60)) / (TIDE_CYCLE_MINUTES * 60)
    local currentTideHeight = BASE_WATER_HEIGHT + (math.sin(cyclePosition * math.pi * 2) * TIDE_AMPLITUDE)

    -- Physically move the water volume
    local visibleDepth = math.max(0.1, currentTideHeight)
    RockPointWater.Size = Vector3.new(RockPointWater.Size.X, visibleDepth, RockPointWater.Size.Z)
    RockPointWater.CFrame = CFrame.new(RockPointWater.Position.X, visibleDepth / 2, RockPointWater.Position.Z)

    -- Drowning logic for the tunnels
    if currentTideHeight > 25 then
        -- High tide: The tunnels are flooded. Instantly crush/drown players inside.
        local partsInTunnel = Workspace:GetPartsInPart(SubmergedTunnels)
        for _, part in ipairs(partsInTunnel) do
            local humanoid = part.Parent:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                humanoid.Health = 0 -- The Watcher's tide shows no mercy
            end
        end
    end
end)
