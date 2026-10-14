--!strict
-- Place inside ServerScriptService -> TethysEnvironmentEngine
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Terrain = workspace:WaitForChild("Terrain")
local LocalClouds = Terrain:FindFirstChildOfClass("Clouds")

if not LocalClouds then
    local newClouds = Instance.new("Clouds")
    newClouds.Name = "PrehistoricVolumetricClouds"
    newClouds.Parent = Terrain -- FIX: Nesting it cleanly inside Terrain
    LocalClouds = newClouds
end

local WEATHER_API_URL = "http://localhost:3030/api/v1/tethys/weather"
local CONTEXT_SYNC_RATE = 10.0 -- Sync atmospheric overheads every 10 seconds

-- Defensive configuration check: Ensure standard Atmosphere instance is available
local Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if not Atmosphere then
	Atmosphere = Instance.new("Atmosphere")
	Atmosphere.Parent = Lighting
end

-- Utility converter: Translates hex data safely into Roblox Color3 values
local function hexToColor3(hex: string): Color3
	hex = hex:gsub("#","")
	return Color3.fromRGB(
		tonumber(hex:sub(1,2), 16) or 0,
		tonumber(hex:sub(3,4), 16) or 0,
		tonumber(hex:sub(5,6), 16) or 0
	)
end

-- Safe fallback: provision global volumetric clouds if missing from workspace
if not LocalClouds then
	local newClouds = Instance.new("Clouds")
	newClouds.Name = "PrehistoricVolumetricClouds"
	newClouds.Parent = Workspace
	LocalClouds = newClouds
end

local function interpolatePrehistoricStorm(weather: WeatherResponsePayload)
	local targetColor = hexToColor3(weather.fogColorHex)
	local targetDensity = weather.atmosphereDensity
	local tweenInfo = TweenInfo.new(5.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	
	-- 1. Tween Modern Physical Lighting Parameters
	local atmosphereTween = TweenService:Create(Atmosphere, tweenInfo, {
		Density = targetDensity,
		Haze = targetDensity * 4.5,
		Color = targetColor,
		Decay = Color3.fromRGB(48, 26, 36)
	})
	
	local colorCorrectionTween = TweenService:Create(ColorCorrection, tweenInfo, {
		TintColor = targetColor,
		Brightness = targetDensity > 0.5 and -0.12 or 0,
		Contrast = targetDensity > 0.5 and 0.15 or 0
	})
	
	-- 2. TWEEN VOLUMETRIC CLOUDS (Smoke and Mirrors Sky Coverage)
	local cloudTween = TweenService:Create(LocalClouds, tweenInfo, {
		Cover = targetDensity > 0.5 and 0.85 or 0.25, -- Drastically thickens coverage during eruptions
		Density = targetDensity > 0.5 and 0.80 or 0.20,
		Color = targetColor
	})
	
	atmosphereTween:Play()
	colorCorrectionTween:Play()
	cloudTween:Play()
	
	-- 3. LIVE PARTICLE RE-REGISTRATION
	-- Seamlessly syncs particle output rates with your Express API data streams
	local globalAnchor = workspace:FindFirstChild("GlobalAshAnchor")
	if globalAnchor then
		local ashEmitter = globalAnchor:FindFirstChild("AshFallParticles") :: ParticleEmitter?
		if ashEmitter then
			local targetRate = targetDensity > 0.5 and (weather.windSpeed * 6) or 0
			TweenService:Create(ashEmitter, tweenInfo, { Rate = targetRate }):Play()
			print(string.format("[ELO Sync] Volcanic Ash Particle Rate adjusted to: %d", targetRate))
		end
	end
	
	-- Run local flash loops across our sync frequency window
	local segmentsCount = 5
	local segmentDuration = CONTEXT_SYNC_RATE / segmentsCount
	
	for _ = 1, segmentsCount do
		executeVisualLightningFlash(weather.lightningFrequency, targetDensity, Lighting.OutdoorAmbient)
		task.wait(segmentDuration)
	end
end

-- Smoke and mirrors lightning generator that scales performance-wise
local function executeVisualLightningFlash(frequency: number)
	if frequency == 0 or math.random() > frequency then return end
	
	task.spawn(function()
		local originalColor = Lighting.OutdoorAmbient
		local flashColor = Color3.fromRGB(180, 210, 255) -- Intense storm blue/white flash
		
		-- Instant blinding flash onset
		Lighting.OutdoorAmbient = flashColor
		if Atmosphere then (Atmosphere :: Atmosphere).Density = 0.1 end -- Suddenly slices through fog visibility
		task.wait(math.random(0.05, 0.15))
		
		-- Quick secondary flicker structure
		Lighting.OutdoorAmbient = originalColor
		task.wait(0.05)
		Lighting.OutdoorAmbient = flashColor
		task.wait(0.05)
		
		-- Smooth cinematic atmospheric recovery
		local tweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(Lighting, tweenInfo, {OutdoorAmbient = originalColor})
		tween:Play()
		if Atmosphere then
			TweenService:Create(Atmosphere, tweenInfo, {Density = 0.65}):Play()
		end
	end)
end

local function synchronizePrehistoricEnvironment()
	while true do
		local success, jsonRaw = pcall(function()
			return HttpService:GetAsync(WEATHER_API_URL)
		end)
		
		if success and jsonRaw then
			local parseSuccess, response = pcall(function() return HttpService:JSONDecode(jsonRaw) end)
			if parseSuccess and response.success then
				local weather = response.currentWeather
				
				-- Mutate engine properties based on remote data profiles
				local targetFogColor = hexToColor3(weather.fogColorHex)
				
				Lighting.FogColor = targetFogColor
				Lighting.Ambient = targetFogColor
				
				if Atmosphere then
					local atm = Atmosphere :: Atmosphere
					atm.Density = weather.atmosphereDensity
					atm.FogColor = targetFogColor
				end
				
				-- Run local high-performance flash loop within our tick sequence window
				for _ = 1, 5 do
					executeVisualLightningFlash(weather.lightningFrequency)
					task.wait(CONTEXT_SYNC_RATE / 5)
				end
			end
		else
			task.wait(CONTEXT_SYNC_RATE)
		end
	end
end

task.spawn(synchronizePrehistoricEnvironment)