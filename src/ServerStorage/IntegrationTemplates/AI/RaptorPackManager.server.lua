-- Integration template: dependencies and acceptance are listed in docs/engineering/roblox-integration.md.
if script:GetAttribute("TethysTemplateEnabled") ~= true then return end
-- src/ServerScriptService/AI/RaptorPackManager.server.lua
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local PACK_STATE = {
    STALKING = 1,  -- Circling, out of sight
    DRIVING = 2,   -- One attacks from the front to distract
    AMBUSHING = 3, -- The rest attack from the blind spot
    SCATTERING = 4 -- Stryker arrives
}

-- The Pack Object
local RaptorPack = {
    State = PACK_STATE.STALKING,
    Members = {}, -- List of individual raptor models
    Target = nil,
    AmbushPoint = nil
}

local function calculateBlindSpot(targetCharacter)
    -- Get the direction the player is looking
    local lookVector = targetCharacter.PrimaryPart.CFrame.LookVector
    -- Calculate a point 30 studs directly behind the player
    local blindSpot = targetCharacter.PrimaryPart.Position - (lookVector * 30)
    return blindSpot
end

local function executeDriveTactic()
    -- 1. Assign roles
    local decoy = RaptorPack.Members[1]
    local strikers = {RaptorPack.Members[2], RaptorPack.Members[3]}

    -- 2. The Decoy attacks from the front/side to lock the player's camera focus
    decoy:SetAttribute("Role", "Decoy")
    decoy.TargetPosition.Value = RaptorPack.Target.PrimaryPart.Position

    -- 3. The Strikers move to the blind spot silently
    local blindSpot = calculateBlindSpot(RaptorPack.Target)
    for _, striker in ipairs(strikers) do
        striker:SetAttribute("Role", "Striker")
        striker.TargetPosition.Value = blindSpot
    end
end

-- Pack Heartbeat Loop
task.spawn(function()
    while true do
        task.wait(1)
        if RaptorPack.Target and RaptorPack.State == PACK_STATE.STALKING then
            -- Wait for the player to enter a dense jungle choke point
            -- Then initiate the drive
            RaptorPack.State = PACK_STATE.DRIVING
            executeDriveTactic()
        end
    end
end)
