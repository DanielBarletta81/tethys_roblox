-- Integration template: dependencies and acceptance are listed in docs/engineering/roblox-integration.md.
if script:GetAttribute("TethysTemplateEnabled") ~= true then return end
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

-- Smoke and mirrors lightning generator that scales performance-wise
local function executeVisualLightningFlash(frequency: number)
	if frequency == 0 or math.random() > frequency then return end
	
	task.spawn(function()
		local originalColor = Lighting.OutdoorAmbient
		local flashColor = Color3.fromRGB(180, 210, 255) -- Intense storm blue/white flash
		
		-- Instant blinding flash onset
		Lighting.OutdoorAmbient = flashColor
		if Atmosphere then (Atmosphere :: Atmosphere).Density = 0.1 end -- Suddenly slices through fog visibility
		task.wait(Random.new():NextNumber(0.05, 0.15))
		
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
					atm.Color = targetFogColor
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