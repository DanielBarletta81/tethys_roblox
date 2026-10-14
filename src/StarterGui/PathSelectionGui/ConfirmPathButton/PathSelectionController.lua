--!strict
-- Place inside src/StarterGui/PathSelectionGui/ConfirmPathButton/PathSelectionController.lua
-- Handles decision matrices at the "First Sort" checkpoint over the Express bridge

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local ZONE_UPDATE_URL = "http://localhost:3030/api/v1/wildbound/survival/zone-update"

local function handleFirstSortDecision(chosenRoute: "Human_Rescue_Cage" | "Ordovic_River_Deep_Run")
	print("[First Sort] Dispatching decision parameters to ELO backend: " .. chosenRoute)
	
	local payload = {
		userId = tostring(LocalPlayer.UserId),
		targetZone = chosenRoute == "Human_Rescue_Cage" and "Lower_Tiers_Gate" or "Ordovic_River_Deep_Run",
		applyInjury = 0,
		routeSelection = chosenRoute
	}
	
	-- Dispatch choice securely over the wire
	task.spawn(function()
		local success, response = pcall(function()
			return HttpService:PostAsync(ZONE_UPDATE_URL, HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
		end)
		
		if success then
			if chosenRoute == "Human_Rescue_Cage" then
				print("🔒 En route to Lower Tiers inspection gate. Prepare for work-ability questioning.")
			else
				print("🌊 Diving into Watcher's Falls. Locating Silurian adaptations camp of NPC Cordge.")
			end
		end
	end)
end

-- Bind this logic directly to your custom UI choice buttons inside your screen layers