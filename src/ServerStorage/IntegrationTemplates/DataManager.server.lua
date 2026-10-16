-- Integration template: dependencies and acceptance are listed in docs/engineering/roblox-integration.md.
if script:GetAttribute("TethysTemplateEnabled") ~= true then return end
-- src/ServerScriptService/DataManager.server.lua
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

-- Assume ProfileService module is installed in ServerScriptService
local profileModule = ServerScriptService:FindFirstChild("ProfileService")
if not profileModule or not profileModule:IsA("ModuleScript") then
    warn("DataManager template requires the existing approved profile owner")
    return
end
local ProfileService = require(profileModule)

-- The Base Ledger: What a brand new player starts with
local ProfileTemplate = {
    Faction = "Wild",          -- "Wild", "SkyCity_Citizen", "RootListener", "Vanguard", etc.
    CurrentJob = "None",       -- "Hatchery", "Transient", "Engineer"
    Scrip = 0,                 -- Sky City Currency
    IsMarked = false,          -- The Biometric Execution Flag
    Stats = {
        Strength = 10,
        Resilience = 10,
        Level = 1
    },
    UnlockedLoreNodes = {},    -- Forensic echoes or Tethyan history nodes discovered
    SpawnRouting = "Mountain"  -- "Mountain", "Basin", "City", "HoldingCell"
}

-- Create the DataStore (Change the key when wiping data for Beta/Release)
local PlayerProfileStore = ProfileService.GetProfileStore(
    "TethysPlayerData_Alpha_V1",
    ProfileTemplate
)

-- Global table to hold active profiles in this server
local Profiles = {}

-- 2. Global Access API (For our other scripts to read/write)
-- Using _G for rapid access across the server architecture as established in previous scripts
_G.GetPlayerData = function(userId)
    local player = typeof(userId) == "Instance" and userId or Players:GetPlayerByUserId(userId)
    local profile = player and Profiles[player]
    if profile then
        return profile.Data
    end
    return nil
end

_G.UpdatePlayerState = function(userId, updates)
    local player = typeof(userId) == "Instance" and userId or Players:GetPlayerByUserId(userId)
    local profile = player and Profiles[player]
    if profile then
        for key, value in pairs(updates) do
            profile.Data[key] = value
        end
    end
end
-- Continuing in DataManager.server.lua

local function PlayerAdded(player)
    local profile = PlayerProfileStore:LoadProfileAsync("Player_" .. player.UserId)

    if profile ~= nil then
        profile:AddUserId(player.UserId) -- GDPR compliance
        profile:Reconcile() -- Fills in missing keys from the template if we update the game

        -- Listen for profile release (if another server tries to load it, or session ends)
        profile:ListenToRelease(function()
            Profiles[player] = nil
            player:Kick("Tethys Network: Session transferred or dropped. Please reconnect.")
        end)

        if player:IsDescendantOf(Players) == true then
            Profiles[player] = profile

            -- Spawn Routing Logic
            player.CharacterAdded:Connect(function(character)
                task.wait(0.1) -- Wait for character to fully assemble

                local data = profile.Data

                -- The Justice System catches combat-loggers
                if data.IsMarked then
                    print("[JUSTICE API] Marked subject re-entered the world. Routing to Holding Cell.")
                    character:PivotTo(Workspace.CityGate.HoldingCell.CFrame)
                    return
                end

                -- Standard Faction Routing
                if data.Faction == "SkyCity_Citizen" then
                    character:PivotTo(Workspace.SkyCity.CitizenSpawn.CFrame)
                elseif data.Faction == "Vanguard_Conscript" then
                    character:PivotTo(Workspace.VarekBarracks.Spawn.CFrame)
                elseif data.SpawnRouting == "Basin" then
                    character:PivotTo(Workspace.WatcherBasin.ShoreSpawn.CFrame)
                else
                    -- Default: The High Mountain Cave (The Weep Flume intro)
                    character:PivotTo(Workspace.MountainCave.Spawn.CFrame)
                end
            end)

            -- If they died while marked in the last session, we can optionally clear it here
            -- if data.IsMarked and data.Health == 0 then data.IsMarked = false end

        else
            -- Player left before profile finished loading
            profile:Release()
        end
    else
        -- Roblox DataStore outage
        player:Kick("Tethys Network: Biological registry unavailable. Try again later.")
    end
end

-- Cleanup when they leave
local function PlayerRemoving(player)
    local profile = Profiles[player]
    if profile ~= nil then
        profile:Release()
    end
end

Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoving)

-- Handle players already in the server (useful for Studio testing)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(PlayerAdded, player)
end
