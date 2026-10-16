-- Integration template: dependencies and acceptance are listed in docs/engineering/roblox-integration.md.
if script:GetAttribute("TethysTemplateEnabled") ~= true then return end
--!strict
-- Place inside ServerScriptService -> TethysClusterNode
-- Continuously streams low-level hardware orchestration details back to the master API gateway

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage") -- FIX: Add this missing service link!

local REGISTRATION_URL = "http://localhost:3030/api/v1/tethys/instances/heartbeat-register"

local HEARTBEAT_TICK_RATE = 10.0 -- Ping our Express gateway every 10 seconds

local ServerJobId = game.JobId == "" and "local_studio_development_sandbox" or game.JobId
local StartTime = os.time()

local function processClusterHeartbeatRegistration()
	while true do
		local uptime = os.time() - StartTime

		-- Compile hardware orchestration telemetry data packet
		local registrationPayload = {
			jobId = ServerJobId,
			serverPlaceId = game.PlaceId,
			activePlayerCount = #Players:GetPlayers(),
			maxPlayersCapacity = Players.MaxPlayers,
			assignedTestingCell = ReplicatedStorage:GetAttribute("VariantAssigned") or "Control_A",
			serverUptimeSeconds = uptime
		}

		local serializeSuccess, jsonString = pcall(function()
			return HttpService:JSONEncode(registrationPayload)
		end)

		if serializeSuccess and jsonString then
			-- Asynchronously dispatch server check-in over the wire
			task.spawn(function()
				local postSuccess, responseRaw = pcall(function()
					return HttpService:PostAsync(REGISTRATION_URL, jsonString, Enum.HttpContentType.ApplicationJson)
				end)

				if postSuccess and responseRaw then
					local parseSuccess, responseObj = pcall(function()
						return HttpService:JSONDecode(responseRaw)
					end)

					if parseSuccess and responseObj.success then
						-- Heartbeat transaction completed perfectly!
						-- In a production tracking setup, skip logging here to prevent output window spamming
					end
				end
			end)
		end

		task.wait(HEARTBEAT_TICK_RATE)
	end
end

-- Launch the node daemon loop immediately
task.spawn(processClusterHeartbeatRegistration)
print("[Tethys Cluster Node] Orchestration daemon initialized. Heartbeat target locked on Port 3030.")

