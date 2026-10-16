-- Integration template: dependencies and acceptance are listed in docs/engineering/roblox-integration.md.
if script:GetAttribute("TethysTemplateEnabled") ~= true then return end
-- src/ServerScriptService/AI/RaptorBrain.server.lua
-- (This script lives inside the actual Raptor model)

local PathfindingService = game:GetService("PathfindingService")
local raptor = script.Parent
local humanoid = raptor:WaitForChild("Humanoid")
local targetPosValue = raptor:WaitForChild("TargetPosition")

local STAMINA = 100
local IS_SPRINTING = false

targetPosValue.Changed:Connect(function(newPos)
    local role = raptor:GetAttribute("Role")

    if role == "Decoy" then
        -- Decoys snap branches, make noise, and approach from the front
        humanoid.WalkSpeed = 22
        -- Fire audio cue for the client to hear
        raptor.Vocalizations.Hiss:Play()
        humanoid:MoveTo(newPos)

    elseif role == "Striker" then
        -- Strikers crouch, move slower to reduce footstep audio, and flank
        humanoid.WalkSpeed = 14
        -- Utilize Roblox Pathfinding to weave through the Asphodel trees
        local path = PathfindingService:CreatePath({
            AgentRadius = 3,
            AgentHeight = 5,
            AgentCanJump = true
        })

        path:ComputeAsync(raptor.PrimaryPart.Position, newPos)

        if path.Status == Enum.PathStatus.Success then
            for _, waypoint in ipairs(path:GetWaypoints()) do
                humanoid:MoveTo(waypoint.Position)
                humanoid.MoveToFinished:Wait()
                -- If the Pack Manager signals the AMBUSH state, break stealth and sprint
                if raptor:GetAttribute("ExecuteKill") then break end
            end
        end
    end
end)
