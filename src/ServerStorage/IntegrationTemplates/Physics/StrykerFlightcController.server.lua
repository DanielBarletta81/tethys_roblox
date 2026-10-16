-- Integration template: dependencies and acceptance are listed in docs/engineering/roblox-integration.md.
if script:GetAttribute("TethysTemplateEnabled") ~= true then return end
-- src/ServerScriptService/Physics/StrykerFlightController.server.lua
local RunService = game:GetService("RunService")

local stryker = workspace:WaitForChild("StrykerModel")
local rootPart = stryker.PrimaryPart or stryker:FindFirstChild("HumanoidRootPart")
if not rootPart or not rootPart:IsA("BasePart") then return end

-- Apply a baseline VectorForce to counteract *some* gravity, simulating wing surface area
local glideForce = Instance.new("VectorForce")
glideForce.Name = "GlideForce"
glideForce.RelativeTo = Enum.ActuatorRelativeTo.World
glideForce.ApplyAtCenterOfMass = true
glideForce.Attachment0 = rootPart:WaitForChild("CenterOfMassAttachment")
glideForce.Force = Vector3.new(0, workspace.Gravity * rootPart.AssemblyMass * 0.8, 0)
glideForce.Parent = rootPart

local STAMINA = 100
local FLAP_COOLDOWN = 1.5

local function executeWingFlap()
    if STAMINA < 10 then return end -- Exhausted, forces a glide/stall

    STAMINA = STAMINA - 15

    -- Audio: Heavy, leathery snap
    stryker.Audio.HeavyFlap:Play()

    -- Apply a violent, instantaneous impulse upward and forward
    local flapImpulse = (rootPart.CFrame.UpVector * 5000) + (rootPart.CFrame.LookVector * 8000)
    rootPart:ApplyImpulse(flapImpulse)

    -- Broadcast the exertion event to the client (for the Bond-Pull)
    game.ReplicatedStorage.Events.StrykerExertion:FireAllClients(rootPart.Position)
end

-- AI Loop for circling the jungle
task.spawn(function()
    while true do
        task.wait(FLAP_COOLDOWN)
        -- Regenerate stamina during the glide
        STAMINA = math.clamp(STAMINA + 5, 0, 100)

        -- Logic: If altitude drops below the Asphodel canopy threshold, flap.
        if rootPart.Position.Y < 200 then
            executeWingFlap()
        end
    end
end)
