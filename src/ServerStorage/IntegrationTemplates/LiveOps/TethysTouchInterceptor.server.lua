-- Integration template: dependencies and acceptance are listed in docs/engineering/roblox-integration.md.
if script:GetAttribute("TethysTemplateEnabled") ~= true then return end
--!strict
-- Place inside src/ServerScripts/TethysTouchInterceptor.lua
-- Captures physical player entry steps and dispatches zone state updates to Express

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ZONE_UPDATE_URL = "http://localhost:3030/api/v1/wildbound/survival/zone-update"

-- Locate your transparent cave water boundary part
local TriggerPart = Workspace:WaitForChild("CaveWaterExitTrigger", 10) :: BasePart?
local isTriggerLocked = false -- Debounce gate to prevent network flood spikes

if not TriggerPart then
	warn("⚠️ [Touch Interceptor] Missing 'CaveWaterExitTrigger' geometry asset from Workspace.")
end

local function onPartTouched(otherPart: BasePart)
	if isTriggerLocked then return end

	local character = otherPart.Parent
	if not character then return end

	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if player and humanoid and humanoid.Health > 0 then
		isTriggerLocked = true -- Lock the trigger valve immediately

		print(string.format("🌊 [Touch Ingestion] %s hit the rapids flush threshold block!", player.Name))

		-- 1. HARD ENFORCE GAMEPLAY MOVEMENT RESTRICTIONS
		humanoid.JumpHeight = 0 -- Stop climbing/jumping attempts
		humanoid.WalkSpeed = 8  -- Drag them down matching rapid heavy current stutters

		-- 2. DISPATCH VISUAL DISTORTION SIGNALS TO THE SCREEN CAPTURE LAYER
		ReplicatedStorage:SetAttribute("ScreenWaterSprayActive", true)

		-- 3. ASYNCHRONOUS EXPRESS STATE INGESTION SYNC PASS
		local payload = {
			userId = tostring(player.UserId),
			targetZone = "Ordovic_Rapids",
			applyInjury = 0 -- The main riverbank injury happens right at washout destination
		}

		local serializeSuccess, jsonBody = pcall(function()
			return HttpService:JSONEncode(payload)
		end)

		if serializeSuccess and jsonBody then
			task.spawn(function()
				local postSuccess, responseRaw = pcall(function()
					return HttpService:PostAsync(ZONE_UPDATE_URL, jsonBody, Enum.HttpContentType.ApplicationJson)
				end)

				if postSuccess and responseRaw then
					print(string.format("✅ [Express Ingestion] Session zone state updated to 'Ordovic_Rapids' for user %s", player.Name))
				end
			end)
		end

		-- Optional 5-second recovery window before letting another player trigger the loop
		task.wait(5.0)
		isTriggerLocked = false
	end
end

if TriggerPart then
	TriggerPart.Touched:Connect(onPartTouched)
	print("🟢 [Tethys Touch Interceptor] Cave water boundary sensor armed and scanning for steps.")
end
