-- Integration template: dependencies and acceptance are listed in docs/engineering/roblox-integration.md.
if script:GetAttribute("TethysTemplateEnabled") ~= true then return end
-- src/ServerScriptService/AI/StrykerImpactEvent.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Events = ReplicatedStorage:WaitForChild("Events")

local PACK_STATE_SCATTERING = 4

local function executeTerminalStrike(stryker, decoyRaptor, remainingRaptors, ravelCharacter)
    -- 1. The Terminal Velocity Drop
    local rootPart = stryker.PrimaryPart
    local targetPos = decoyRaptor.PrimaryPart.Position

    -- Strip glide forces and apply massive downward velocity
    if rootPart:FindFirstChild("GlideForce") then
        rootPart.GlideForce:Destroy()
    end

    rootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 150, 0), targetPos)
    rootPart.AssemblyLinearVelocity = Vector3.new(0, -300, 0)

    -- Wait for impact calculation (simplified raycast or height check)
    local impactDeadline = os.clock() + 5
    repeat task.wait(0.05) until not rootPart.Parent or rootPart.Position.Y - targetPos.Y < 10 or os.clock() > impactDeadline
    if not rootPart.Parent or os.clock() > impactDeadline then return end

    -- 2. The Crush (Decoy Elimination)
    local decoyHum = decoyRaptor:FindFirstChild("Humanoid")
    if decoyHum then
        decoyHum.Health = 0
        -- Apply immediate ragdoll physics to the Decoy
        decoyRaptor:SetAttribute("Ragdoll", true)
    end

    -- 3. The Radial Kinetic Blast
    local blast = Instance.new("Explosion")
    blast.Position = rootPart.Position
    blast.BlastRadius = 40
    blast.BlastPressure = 500000 -- High pressure to throw heavy raptors
    blast.DestroyJointRadiusPercent = 0 -- Prevents shattering the map/models
    blast.Parent = Workspace

    -- Audio and VFX
    stryker.Audio.MassiveImpact:Play()
    -- Instantiate dust cloud particle emitters here

    -- 4. Scatter the Survivors
    for _, raptor in ipairs(remainingRaptors) do
        local hum = raptor:FindFirstChild("Humanoid")
        if hum and hum.Health > 0 then
            -- The blast knocks them down; as they get up, they scatter
            raptor:SetAttribute("Role", "Fleeing")
            if typeof(_G.UpdatePackState) == "function" then _G.UpdatePackState(PACK_STATE_SCATTERING) end -- Tells the AI manager to run
        end
    end

    task.wait(2) -- Let the dust settle

    -- 5. Trigger the Standoff
    Events.StrykerStandoff:FireAllClients(stryker, ravelCharacter)
end
