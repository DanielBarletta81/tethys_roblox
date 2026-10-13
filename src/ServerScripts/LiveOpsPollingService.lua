--!strict
-- Upgraded LiveOpsPollingService inside ServerScriptService
local HttpService = game:GetService("HttpService")
local Terrain = workspace:WaitForChild("Terrain")

-- We pull the exact unique execution container ID allocated to this active game instance
local ServerJobId: string = game.JobId
if ServerJobId == "" then
	ServerJobId = "local_studio_development_sandbox_override"
end

local BASE_API_URL = "http://localhost:3030/api/v1/liveops/variant-stream?jobId=" .. HttpService:UrlEncode(ServerJobId)
local POLLING_INTERVAL_SECONDS = 5.0

type SegmentPayload = {
	id: string,
	name: string,
	targetMaterial: string,
	centerStuds: { x: number, y: number, z: number },
	sizeStuds: { x: number, y: number, z: number }
}

local function startLiveOpsExperimentLoop()
	print(string.format("[ELO Telemetry] Client running with Core Job Token: %s", ServerJobId))
	
	while true do
		local success, jsonRaw = pcall(function()
			return HttpService:GetAsync(BASE_API_URL)
		end)
		
		if success then
			local parseSuccess, payload = pcall(function()
				return HttpService:JSONDecode(jsonRaw)
			end)
			
			if parseSuccess and payload.success then
				print(string.format("[ELO Cell Tracker] Confirmed allocated server pipeline: %s", payload.variantAssigned))
				-- Process voxel geometry loops here based on assignment payloads
			end
		else
			warn("[ELO Network Failure] System could not evaluate experiment parameters.")
		end
		task.wait(POLLING_INTERVAL_SECONDS)
	end
end

task.spawn(startLiveOpsExperimentLoop)
