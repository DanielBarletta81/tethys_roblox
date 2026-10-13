--!strict
-- Place inside ServerScriptService -> GameProductionBootstrapper
-- Standardizes startup sequences, registers frameworks, and manages error tracking

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- System Registry Types
type OperationalService = {
	Init: () -> (),
	ServiceName: string
}

print("================================================================")
print("🌌 INITIALIZING CORE PRODUCTION ENGINE: WORLD OF TETHYS")
print("================================================================")

-- Locate your decoupled framework services in the workspace
local TethysStreamingService = require(script.Parent:WaitForChild("TethysStreamingServiceModule") :: ModuleScript)
local TethysEnvironmentEngine = require(script.Parent:WaitForChild("TethysEnvironmentEngineModule") :: ModuleScript)
local TethysPredatorRadar = require(script.Parent:WaitForChild("TethysPredatorRadarModule") :: ModuleScript)

local CoreServicesManifest: {OperationalService} = {
	{ ServiceName = "Dynamic Spatial Voxel Streamer", Init = (TethysStreamingService :: any).Init },
	{ ServiceName = "Prehistoric Weather Atmospheric Sync", Init = (TethysEnvironmentEngine :: any).Init },
	{ ServiceName = "Apex Predator Proximity Telemetry Radar", Init = (TethysPredatorRadar :: any).Init }
}

-- Safe Bootstrapper Loop with Crash Isolation Protection
local function launchCriticalInfrastructure()
	local successfulInitializations = 0
	
	for index, service in ipairs(CoreServicesManifest) do
		print(string.format("[Boot Sequence %d/%d] Spinning up: %s...", index, #CoreServicesManifest, service.ServiceName))
		
		local bootstrapSuccess, err = pcall(function()
			service.Init()
		end)
		
		if bootstrapSuccess then
			successfulInitializations += 1
			print(string.format("✅ Service Operational: %s", service.ServiceName))
		else
			-- Defensive Design: Prevents an isolated system failure from crashing the entire game loop
			warn(string.format("❌ CRITICAL BOOT FAILURE on %s: %s", service.ServiceName, tostring(err)))
			-- Trigger local telemetry data dispatch to your external dashboard API
		end
	end
	
	print("================================================================")
	print(string.format("📡 LAUNCH COMPLETE: %d of %d Services Fully Synchronized.", successfulInitializations, #CoreServicesManifest))
	print("================================================================")
end

task.spawn(launchCriticalInfrastructure)