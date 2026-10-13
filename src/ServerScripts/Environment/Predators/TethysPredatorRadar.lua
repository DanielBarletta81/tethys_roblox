--!strict
-- Place inside ServerScriptService -> TethysPredatorRadar
-- Programmatic Predator Threat Tracker for World of Tethys Public Server Deployments

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local THREAT_API_URL = "http://localhost:3030/api/v1/tethys/predator/evaluate-threat"
local RADAR_TICK_RATE = 1.0 -- Rapid polling cycle for instant responsive danger updates

-- Global threat networking channel
local ThreatEvent = ReplicatedStorage:FindFirstChild("PredatorThreatAlert") :: RemoteEvent?
if not ThreatEvent then
	local remote = Instance.new("RemoteEvent")
	remote.Name = "PredatorThreatAlert"
	remote.Parent = ReplicatedStorage
	ThreatEvent = remote
end

local function trackIndividualPlayerThreatProfile(player: Player)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChildOfClass("Humanoid") then return end
	
	local rootPart = character.HumanoidRootPart :: Part
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
	local playerPos = rootPart.Position
	
	-- Compile core telemetry body payload
	local telemetryBody = {
		playerX = math.round(playerPos.X),
		playerZ = math.round(playerPos.Z),
		userId = player.UserId,
		currentHealth = math.round(humanoid.Health)
	}
	
	local serializeSuccess, jsonBody = pcall(function()
		return HttpService:JSONEncode(telemetryBody)
	end)
	
	if not serializeSuccess or not jsonBody then return end
	
	-- Transmit coordinates over the bridge for asynchronous distance evaluation
	task.spawn(function()
		local networkSuccess, httpResponseRaw = pcall(function()
			return HttpService:PostAsync(THREAT_API_URL, jsonBody, Enum.HttpContentType.ApplicationJson)
		end)
		
		if networkSuccess and httpResponseRaw then
			local parseSuccess, responseData = pcall(function()
				return HttpService:JSONDecode(httpResponseRaw)
			end)
			
			if parseSuccess and responseData.success then
				-- Broadcast threat level downstream to the specific client's interface
				if ThreatEvent then
					(ThreatEvent :: RemoteEvent):FireClient(player, responseData.threatLevel, responseData.alertLog, responseData.evasiveActionRequired)
				end
				
				-- Engine-side Gameplay Mechanics Interception:
				-- If the threat level is catastrophic (5/5), dynamically alter global parameters
				if responseData.threatLevel == 5 then
					-- Smoke and mirrors lighting shift: tint the atmosphere blood-red locally to induce terror
					local ambientTween = game:GetService("TweenService"):Create(
						game:GetService("Lighting"), 
						TweenInfo.new(1.0), 
						{OutdoorAmbient = Color3.fromRGB(130, 30, 30)}
					)
					ambientTween:Play()
				end
			end
		end
	end)
end

local function initializeRadarScanningGrid()
	while true do
		task.wait(RADAR_TICK_RATE)
		for _, player in ipairs(Players:GetPlayers()) do
			trackIndividualPlayerThreatProfile(player)
		end
	end
end

task.spawn(initializeRadarScanningGrid)
print("[Tethys Radar] Threat calculus synchronization framework ready for player connection handling.")