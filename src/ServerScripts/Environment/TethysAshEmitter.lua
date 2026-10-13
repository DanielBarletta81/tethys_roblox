--!strict
-- Place inside ServerScriptService -> TethysAshEmitter
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local TELEMETRY_URL = "http://localhost:3030/api/v1/tethys/telemetry/heartbeat"
local EMISSION_TICK_RATE = 3.0

-- Local client engine performance frames tracker variables
local frameCount = 0
local elapsedSeconds = 0.0
local activeFpsTrackingNode = 60.0

RunService.Heartbeat:Connect(function(deltaTime: number)
	frameCount += 1
	elapsedSeconds += deltaTime
	if elapsedSeconds >= 1.0 then
		activeFpsTrackingNode = frameCount / elapsedSeconds
		frameCount = 0
		elapsedSeconds = 0.0
	end
end)

-- Smoke and Mirrors Trick: Create a single global particle collector instance at world origin
local AshParticleEmitter: ParticleEmitter? = nil
local function verifyAshEmitterInfrastructure()
	local localAnchor = workspace:FindFirstChild("GlobalAshAnchor") :: Part?
	if not localAnchor then
		local anchor = Instance.new("Part")
		anchor.Name = "GlobalAshAnchor"
		anchor.Size = Vector3.new(500, 2, 500)
		anchor.Position = Vector3.new(0, 180, 0) -- Elevated above basic map bounds coordinates
		anchor.Transparency = 1
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.Parent = workspace
		
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "AshFallParticles"
		emitter.Lifetime = NumberRange.new(6.0, 12.0)
		emitter.Speed = NumberRange.new(5, 15)
		emitter.SpreadAngle = Vector2.new(45, 45)
		-- Lightweight, high-ambience smoky coloration profile representation
		emitter.Color = ColorSequence.new(Color3.fromRGB(45, 42, 46)) 
		emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 2.0)})
		emitter.Transparency = NumberSequence.new(0.4)
		emitter.Rate = 0 -- Programmatically dictated down-stream below
		emitter.Parent = anchor
		AshParticleEmitter = emitter
	else
		AshParticleEmitter = localAnchor:FindFirstChild("AshFallParticles") :: ParticleEmitter?
	end
end

local function executeTelemetryEmissionLoop()
	verifyAshEmitterInfrastructure()
	local jobId = game.JobId == "" and "local_studio_sandbox" or game.JobId
	
	while true do
		task.wait(EMISSION_TICK_RATE)
		
		-- Speculative biology calculation scenario logic tracking
		-- As the server updates its parameters, scale atmospheric ash particle density simulation rates
		local currentMockAshSaturation = math.random(15, 88) 
		
		if AshParticleEmitter then
			-- Shift emissions directly without triggering heavy mesh creation pipelines
			AshParticleEmitter.Rate = currentMockAshSaturation * 4
		end
		
		local serverMemory = Stats:GetTotalMemoryUsageMb()
		local payload = {
			jobId = jobId,
			fps = math.round(activeFpsTrackingNode),
			memoryMb = math.round(serverMemory),
			activePlayerCount = #game:GetService("Players"):GetPlayers(),
			ashSaturationPercent = currentMockAshSaturation,
			regionId = currentMockAshSaturation > 60 and "Watcher_Plume_Zone" or "Sky_City_Tier_4"
		}
		
		local serializeSuccess, jsonString = pcall(function()
			return HttpService:JSONEncode(payload)
		end)
		
		if serializeSuccess then
			task.spawn(function()
				pcall(function()
					HttpService:PostAsync(TELEMETRY_URL, jsonString, Enum.HttpContentType.ApplicationJson)
				end)
			end)
		end
	end
end

task.spawn(executeTelemetryEmissionLoop)