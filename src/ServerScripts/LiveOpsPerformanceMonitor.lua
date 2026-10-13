--!strict
-- Place inside ServerScriptService -> LiveOpsPerformanceMonitor
-- Monitors server hardware telemetry and streams data back to ELO Early Harm Gateway

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local TELEMETRY_URL = "http://localhost:3030/api/v1/liveops/telemetry/report-harm"
local MONITOR_HEARTBEAT_SECONDS = 3.0 -- Frequency of automated health checks

-- Tracks frames per second over an isolated window block
local frameCount = 0
local timeAccumulator = 0
local calculatedFps = 60.0

RunService.Heartbeat:Connect(function(deltaTime: number)
	frameCount += 1
	timeAccumulator += deltaTime
	
	if timeAccumulator >= 1.0 then
		calculatedFps = frameCount / timeAccumulator
		frameCount = 0
		timeAccumulator = 0
	end
end)

local function beginSafetyTelemetryReporting()
	-- Replace this with the active cell identifier returned by your variant-stream client script
	local activeVariantContext = "Volcanic_B" 
	local jobId = game.JobId == "" and "dev_studio_sandbox" or game.JobId

	while true do
		task.wait(MONITOR_HEARTBEAT_SECONDS)
		
		-- Gather platform-native performance diagnostics
		local serverMemoryUsage = Stats:GetTotalMemoryUsageMb()
		
		local telemetryPayload = {
			serverJobId = jobId,
			activeVariant = activeVariantContext,
			averageFps = math.round(calculatedFps),
			memoryUsageMb = math.round(serverMemoryUsage)
		}
		
		local success, jsonString = pcall(function()
			return HttpService:JSONEncode(telemetryPayload)
		end)
		
		if success then
			-- Stream telemetry to our Express Node gateway
			task.spawn(function()
				local postSuccess, httpResponseRaw = pcall(function()
					return HttpService:PostAsync(TELEMETRY_URL, jsonString, Enum.HttpContentType.ApplicationJson)
				end)
				
				if postSuccess and httpResponseRaw then
					local parseSuccess, responseObj = pcall(function()
						return HttpService:JSONDecode(httpResponseRaw)
					end)
					
					if parseSuccess and responseObj.circuitBreakerTripped then
						-- System telemetry has detected an active platform rollback instruction
						print("⚠️ [ELO MONITOR] Server flagged for automated rollback enforcement! Re-aligning voxels to safe Control cell...")
						-- Invoke your local voxel painter here to safely wipe the unstable volcano geometry!
					end
				end
			end)
		end
	end
end

task.spawn(beginSafetyTelemetryReporting)