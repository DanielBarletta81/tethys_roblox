-- Integration template: dependencies and acceptance are listed in docs/engineering/roblox-integration.md.
if script:GetAttribute("TethysTemplateEnabled") ~= true then return end
-- src/ServerScriptService/JusticeManager.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Events = ReplicatedStorage:WaitForChild("Events")

-- Biometric Thresholds for Varek's Vanguard (The "6'6, 275lb" equivalent)
local VANGUARD_STRENGTH_MIN = 85
local VANGUARD_RESILIENCE_MIN = 80

local triggerPublicExecution, triggerVarekBypass

local function processArrest(player)
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    -- 1. Strip Agency: Disable movement and jumping
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    character:SetPrimaryPartCFrame(Workspace.CityGate.HoldingCell.CFrame)

    -- 2. Fetch Player Data (Assume this pulls from your Next.js backend/DataStore)
    local ledger = typeof(_G.GetPlayerData) == "function" and _G.GetPlayerData(player.UserId)
    local stats = ledger and ledger.Stats
    if not stats then humanoid.WalkSpeed = 16; humanoid.JumpPower = 50; return end

    -- 3. The Biometric Calculus
    if stats.Strength >= VANGUARD_STRENGTH_MIN and stats.Resilience >= VANGUARD_RESILIENCE_MIN then
        -- Path B: The Special Athlete Override
        task.wait(2) -- Suspense pause
        triggerVarekBypass(player, character)
    else
        -- Path A: The Public Stakes
        task.wait(2)
        triggerPublicExecution(player, character)
    end
end

-- Continuing in JusticeManager.server.lua

triggerPublicExecution = function(player, character)
    local stakes = Workspace.ExecutionPlaza.Stakes:GetChildren()
    local openStake = nil

    -- Find an empty stake
    for _, stake in ipairs(stakes) do
        if not stake:FindFirstChild("OccupiedWeld") then
            openStake = stake
            break
        end
    end

    if not openStake then
        -- Overflow handling: instantly kill if plaza is full
        character.Humanoid.Health = 0
        return
    end

    -- 1. Mount the Player to the Stake
    character:PivotTo(openStake.CFrame * CFrame.new(0, 0, -1.5))

    local weld = Instance.new("WeldConstraint")
    weld.Name = "OccupiedWeld"
    weld.Part0 = character.PrimaryPart
    weld.Part1 = openStake
    weld.Parent = openStake

    -- 2. Strip Inventory (Send API call to drop items)
    if typeof(_G.ClearPlayerInventory) == "function" then _G.ClearPlayerInventory(player.UserId) end

    -- 3. Start the Humiliation Timer on the Client
    local EXECUTION_TIME = 180 -- 3 minutes
    Events.ExecutionUI:FireClient(player, "START", EXECUTION_TIME)

    print("[JUSTICE] Player " .. player.Name .. " mounted to the stakes.")

    -- 4. The Server-Side Death Timer
    task.spawn(function()
        task.wait(EXECUTION_TIME)
        if character and character:FindFirstChild("Humanoid") and weld.Parent then
            weld:Destroy()
            character.Humanoid.Health = 0 -- Triggers standard death and Wild respawn

            -- Clear the Mark upon death so they can re-enter society later
            _G.UpdatePlayerState(player.UserId, { IsMarked = false })
        end
    end)
end
triggerVarekBypass = function(player, character)
    if player.Character ~= character then return end
    local barracks = Workspace:FindFirstChild("VarekBarracks")
    local destination = barracks and barracks:FindFirstChild("InterrogationRoom")
    local human = character:FindFirstChildOfClass("Humanoid")
    if not human then return end
    human.WalkSpeed, human.JumpPower = 16, 50
    if not destination or not destination:IsA("BasePart") then return end
    character:PivotTo(destination.CFrame)
    if typeof(_G.UpdatePlayerState) == "function" then
        _G.UpdatePlayerState(player.UserId, {Faction="Vanguard_Conscript", IsMarked=false, SpawnRouting="HoldingCell"})
    end
end
-- A client must never be able to arrest another player. The authoritative guard
-- owner may provide this server-only BindableEvent after validating an arrest.
local request = game.ServerScriptService:FindFirstChild("TethysArrestRequested")
if request and request:IsA("BindableEvent") then request.Event:Connect(processArrest) end
