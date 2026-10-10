local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
if not player then
	return
end

local world = workspace:FindFirstChild("World")
local VOICE_MODE_ATTR = "WOT_VoiceoverMode"
local VOICE_MODE_ENABLED = "Enabled"

local OPENER_RUNTIME_ROOT = "Workspace.World.21_ProductionPass.57_SweepAJ_AdultOpeningLoopRevealHook_V1.11_RiverCaveStrykerTauntOpener_V1"

local function dbToLinear(db)
	return math.pow(10, (tonumber(db) or -18) / 20)
end

local function findPath(path)
	local cur = game
	for token in string.gmatch(path, "[^%.]+") do
		cur = cur:FindFirstChild(token)
		if not cur then
			return nil
		end
	end
	return cur
end

local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "PC01_RiverCinematicHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 95
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui
local function sharedUI() return playerGui:FindFirstChild("TethysUI") end
local function reducedMotion()
	local ui = sharedUI()
	return GuiService.ReducedMotionEnabled or (ui and ui:GetAttribute("WB_ReducedMotion") == true)
end
local function introActive()
	local ui = sharedUI()
	return ui and ui:GetAttribute("WB_IntroActive") == true
end
local function refreshOwner() gui.Enabled = player:GetAttribute("WOT_WildboundUIActive") ~= true end
player:GetAttributeChangedSignal("WOT_WildboundUIActive"):Connect(refreshOwner)
refreshOwner()

local card = Instance.new("Frame")
card.Name = "SubtitleCard"
card.AnchorPoint = Vector2.new(0.5, 1)
card.Position = UDim2.new(0.5, 0, 1, -64)
card.Size = UDim2.new(0, 740, 0, 96)
card.BackgroundColor3 = Color3.fromRGB(8, 12, 17)
card.BackgroundTransparency = 0.22
card.BorderSizePixel = 0
card.Visible = false
card.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = card

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(115, 158, 186)
stroke.Thickness = 1.3
stroke.Transparency = 0.25
stroke.Parent = card

local speakerLabel = Instance.new("TextLabel")
speakerLabel.Name = "Speaker"
speakerLabel.BackgroundTransparency = 1
speakerLabel.Position = UDim2.new(0, 14, 0, 8)
speakerLabel.Size = UDim2.new(1, -28, 0, 20)
speakerLabel.Font = Enum.Font.GothamBold
speakerLabel.TextSize = 13
speakerLabel.TextXAlignment = Enum.TextXAlignment.Left
speakerLabel.TextColor3 = Color3.fromRGB(164, 205, 231)
speakerLabel.Text = ""
speakerLabel.Parent = card

local lineLabel = Instance.new("TextLabel")
lineLabel.Name = "Line"
lineLabel.BackgroundTransparency = 1
lineLabel.Position = UDim2.new(0, 14, 0, 30)
lineLabel.Size = UDim2.new(1, -28, 1, -38)
lineLabel.Font = Enum.Font.GothamSemibold
lineLabel.TextSize = 25
lineLabel.TextWrapped = true
lineLabel.TextYAlignment = Enum.TextYAlignment.Top
lineLabel.TextXAlignment = Enum.TextXAlignment.Left
lineLabel.TextColor3 = Color3.fromRGB(234, 237, 242)
lineLabel.Text = ""
lineLabel.Parent = card

local subtitleToken = 0

local function refreshSubtitleLayout()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local width = math.clamp(viewport.X - 44, 360, 740)
	local height = math.clamp(math.floor(viewport.Y * 0.14), 84, 110)

	card.Size = UDim2.new(0, width, 0, height)
	lineLabel.TextSize = math.clamp(math.floor(width / 30), 18, 25)
end

local viewportConn
local function bindViewportResize()
	if viewportConn then
		viewportConn:Disconnect()
		viewportConn = nil
	end

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	viewportConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshSubtitleLayout)
end

local function showSubtitle(speaker, line, duration, shake)
	if player:GetAttribute("WOT_WildboundUIActive") == true then card.Visible = false; return end
	if not line or line == "" then
		return
	end

	subtitleToken += 1
	local myToken = subtitleToken

	duration = math.clamp(tonumber(duration) or 3.4, 1.8, 7.8)
	speakerLabel.Text = (speaker and speaker ~= "") and speaker or "NARRATOR"
	lineLabel.Text = line
	card.Visible = true
	card.BackgroundTransparency = 0.28
	card.Position = UDim2.new(0.5, 0, 1, -52)
	lineLabel.TextTransparency = 1
	speakerLabel.TextTransparency = 1

	if (tonumber(shake) or 0) >= 0.5 then
		stroke.Color = Color3.fromRGB(204, 151, 95)
		speakerLabel.TextColor3 = Color3.fromRGB(233, 177, 118)
	else
		stroke.Color = Color3.fromRGB(115, 158, 186)
		speakerLabel.TextColor3 = Color3.fromRGB(164, 205, 231)
	end

	TweenService:Create(card, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 1, -88),
		BackgroundTransparency = 0.18,
	}):Play()
	TweenService:Create(lineLabel, TweenInfo.new(0.22, Enum.EasingStyle.Linear), { TextTransparency = 0 }):Play()
	TweenService:Create(speakerLabel, TweenInfo.new(0.22, Enum.EasingStyle.Linear), { TextTransparency = 0 }):Play()

	task.delay(duration, function()
		if subtitleToken ~= myToken then
			return
		end
		TweenService:Create(card, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 1, -54),
			BackgroundTransparency = 0.4,
		}):Play()
		TweenService:Create(lineLabel, TweenInfo.new(0.28, Enum.EasingStyle.Linear), { TextTransparency = 1 }):Play()
		TweenService:Create(speakerLabel, TweenInfo.new(0.28, Enum.EasingStyle.Linear), { TextTransparency = 1 }):Play()
		task.delay(0.34, function()
			if subtitleToken == myToken then
				card.Visible = false
			end
		end)
	end)
end

local shakeTimeLeft = 0
local shakeDuration = 0
local shakeAmplitude = 0

local lookCueTarget = nil
local lookCueTimeLeft = 0
local lookCueDuration = 0
local lookCueStrength = 0

local function getHumanoid()
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

local function startShake(intensity, duration)
	if reducedMotion() or introActive() then return end
	shakeAmplitude = math.clamp(tonumber(intensity) or 0, 0, 1) * 0.28
	shakeDuration = math.max(tonumber(duration) or 0.7, 0.45)
	shakeTimeLeft = shakeDuration
end

local function startLookCue(targetPos, duration, strength)
	if reducedMotion() or introActive() then return end
	if typeof(targetPos) ~= "Vector3" then
		return
	end
	lookCueTarget = targetPos
	lookCueDuration = math.clamp(tonumber(duration) or 1.4, 0.45, 4.5)
	lookCueTimeLeft = lookCueDuration
	lookCueStrength = math.clamp(tonumber(strength) or 0.85, 0.1, 1)
end

player.CharacterAdded:Connect(function()
	task.delay(0.2, function()
		local humanoid = getHumanoid()
		if humanoid then
			humanoid.CameraOffset = Vector3.zero
		end
	end)
end)

local soundGroup = SoundService:FindFirstChild("PC01_RiverCinematicGroup")
if not soundGroup then
	soundGroup = Instance.new("SoundGroup")
	soundGroup.Name = "PC01_RiverCinematicGroup"
	soundGroup.Parent = SoundService
end

local gravityEq = soundGroup:FindFirstChild("PC01_GravityEQ")
if not gravityEq then
	gravityEq = Instance.new("EqualizerSoundEffect")
	gravityEq.Name = "PC01_GravityEQ"
	gravityEq.LowGain = 0
	gravityEq.MidGain = 0
	gravityEq.HighGain = 0
	gravityEq.Parent = soundGroup
end

local gravityDistortion = soundGroup:FindFirstChild("PC01_GravityDistortion")
if not gravityDistortion then
	gravityDistortion = Instance.new("DistortionSoundEffect")
	gravityDistortion.Name = "PC01_GravityDistortion"
	gravityDistortion.Level = 0
	gravityDistortion.Parent = soundGroup
end

local gravityPressureSmoothed = math.clamp(tonumber(player:GetAttribute("OL_GravityPressure")) or 0.15, 0, 1)
local lastGravityPulseTick = tonumber(player:GetAttribute("OL_GravityPulseTick")) or -1

local voCueSound = SoundService:FindFirstChild("PC01_CinematicVOCue")
if not voCueSound then
	voCueSound = Instance.new("Sound")
	voCueSound.Name = "PC01_CinematicVOCue"
	voCueSound.Parent = SoundService
end
voCueSound.SoundGroup = soundGroup
voCueSound.Volume = 0
voCueSound.RollOffMode = Enum.RollOffMode.Linear
voCueSound.RollOffMaxDistance = 80
voCueSound.RollOffMinDistance = 10

local zoneSpec = {
	CaveMouth = { partName = "Zone_CaveMouth", soundName = "Loop_Cave", radius = 115 },
	Basin = { partName = "Zone_Basin", soundName = "Loop_Basin", radius = 130 },
	Rapids = { partName = "Zone_Rapids", soundName = "Loop_Rapids", radius = 145 },
	FirstSort = { partName = "Zone_FirstSort", soundName = "Loop_FirstSort", radius = 140 },
}

local zoneRefs = {}
local nextResolveAttempt = 0

local LEGACY_SPLASH_SPECS = {
	{ path = "Workspace.World.02_Upper_City.Givers_Falls.Falls_CascadeVisual.Falls_Ambience", openingScale = 0.06 },
	{ path = "Workspace.00_RECOVERY.CANDIDATE_GiversFalls.HIDDEN_GEMS_LIFTED.GEM_01_Givers_Falls.Falls_CascadeVisual.Falls_Ambience", openingScale = 0.06 },
	{ path = "Workspace.World.21_ProductionPass.45_PC01_VisualRescue.05_AudioStadium.Zone_FallsReveal.SND_FallsWideRoar", openingScale = 0.09 },
	{ path = "Workspace.World.21_ProductionPass.45_PC01_VisualRescue.05_AudioStadium.Zone_MistThreshold.SND_MistEmergence", openingScale = 0.12 },
	{ path = "Workspace.World.21_ProductionPass.45_PC01_VisualRescue.05_AudioStadium.Zone_WatcherRumble.SND_WatcherRumble", openingScale = 0.18 },
	{ path = "Workspace.World.21_ProductionPass.45_PC01_VisualRescue.11_HighRoute_AudioStadium.HR_FallsReveal.SND_HR_FallsWide", openingScale = 0.10 },
	{ path = "Workspace.World.21_ProductionPass.45_PC01_VisualRescue.11_HighRoute_AudioStadium.HR_MistThreshold.SND_HR_MistEmergence", openingScale = 0.13 },
	{ path = "Workspace.World.21_ProductionPass.45_PC01_VisualRescue.11_HighRoute_AudioStadium.HR_WatcherRumble.SND_HR_WatcherRumble", openingScale = 0.20 },
	{ path = "Workspace.World.21_ProductionPass.45_PC01_VisualRescue.11_HighRoute_AudioStadium.HR_ApproachPressure.SND_HR_InteriorBass", openingScale = 0.17 },
	{ path = "Workspace.World.21_ProductionPass.45_PC01_VisualRescue.05_AudioStadium.Zone_ApproachPressure.SND_InteriorMuffledWater", openingScale = 0.16 },
	{ path = "Workspace.World.LowerTiers.00_Foundation.LT_SubfloorChannels.LT_UnderSpawn_Audio.LT_WaterUnderflow", openingScale = 0.12 },
}

local legacySplashRefs = {}
local nextLegacyResolveAttempt = 0

local function resolveAudioZones(now)
	if now < nextResolveAttempt then
		return
	end
	nextResolveAttempt = now + 2.5

	local runtimeRoot = findPath(OPENER_RUNTIME_ROOT)
	local audioFolder = runtimeRoot and runtimeRoot:FindFirstChild("03_AudioZones")
	if not audioFolder then
		return
	end

	for zoneName, spec in pairs(zoneSpec) do
		local part = audioFolder:FindFirstChild(spec.partName)
		local sound = part and part:FindFirstChild(spec.soundName)
		if part and sound and sound:IsA("Sound") then
			sound.SoundGroup = soundGroup
			sound.Looped = true
			if not sound.Playing then
				sound:Play()
			end
			zoneRefs[zoneName] = {
				part = part,
				sound = sound,
				baseVolume = sound:GetAttribute("BaseVolume") or 0.3,
				radius = spec.radius,
			}
		end
	end
end

local function resolveLegacySplash(now)
	if now < nextLegacyResolveAttempt then
		return
	end
	nextLegacyResolveAttempt = now + 2.5

	for _, spec in ipairs(LEGACY_SPLASH_SPECS) do
		local sound = findPath(spec.path)
		if sound and sound:IsA("Sound") then
			local cached = legacySplashRefs[spec.path]
			if not cached or cached.sound ~= sound then
				legacySplashRefs[spec.path] = {
					sound = sound,
					defaultVolume = sound.Volume,
					defaultSpeed = sound.PlaybackSpeed,
					openingScale = spec.openingScale or 0.1,
				}
			end
		end
	end
end

local function isOpeningAudioFocusActive()
	local phase = tostring(player:GetAttribute("OL_OpeningPhase") or "")
	local riverZone = tostring(player:GetAttribute("OL_RiverAudioZone") or "")
	local chase = tostring(player:GetAttribute("OL_RiverChaseState") or "")
	local watcherFallsActive = player:GetAttribute("OL_WatcherFallsActive") == true

	return phase ~= "" or riverZone ~= "" or chase ~= "" or watcherFallsActive
end

local function resolveFocusZone(zoneName)
	if zoneName == "RiverRun" or zoneName == "BasinCatch" or zoneName == "ShadowTaunt" then
		return "Basin"
	end
	if zoneName == "RapidsCommit" then
		return "Rapids"
	end
	if zoneName == "FirstSortArrival" or zoneName == "BranchFork" or zoneName == "CityWork" or zoneName == "LeaveRoutes" then
		return "FirstSort"
	end
	if zoneName == "RiverCaveStart" then
		return "CaveMouth"
	end
	return zoneName
end

local function isVoiceEnabled()
	if not world then
		return false
	end
	return world:GetAttribute(VOICE_MODE_ATTR) == VOICE_MODE_ENABLED
end

local function playVoiceCue(soundId, voDb, shake)
	if not isVoiceEnabled() then
		if voCueSound.Playing then
			voCueSound:Stop()
		end
		return
	end
	if type(soundId) ~= "string" or soundId == "" then
		return
	end
	if not string.find(soundId, "rbxassetid://", 1, true) then
		return
	end

	voCueSound:Stop()
	voCueSound.SoundId = soundId
	voCueSound.Volume = dbToLinear(voDb or -14)
	voCueSound.PlaybackSpeed = math.clamp(1 + ((tonumber(shake) or 0) * 0.06), 0.85, 1.25)
	voCueSound.TimePosition = 0
	voCueSound:Play()
end

local lastCueTick = -1
local function onCueTick()
	local cueTick = player:GetAttribute("OL_CineTick")
	if type(cueTick) ~= "number" or cueTick == lastCueTick then
		return
	end
	lastCueTick = cueTick

	local speaker = player:GetAttribute("OL_CineSpeaker") or "NARRATOR"
	local line = player:GetAttribute("OL_CineLine") or ""
	local duration = tonumber(player:GetAttribute("OL_CineDuration")) or 3
	local shake = tonumber(player:GetAttribute("OL_CineShake")) or 0
	local voId = player:GetAttribute("OL_CineVOId") or ""
	local voDb = tonumber(player:GetAttribute("OL_CineVODb")) or -14

	-- Suppress spoken subtitle copy for Stryker cues; keep non-verbal audio/jolt feedback.
	local lineUpper = string.upper(tostring(line))
	local speakerUpper = string.upper(tostring(speaker))
	local isStrykerSpeech = (lineUpper ~= "" or speakerUpper ~= "")
		and (lineUpper:find("STRYKER", 1, true)
			or lineUpper:find("CURRENT%-RAT", 1)
			or speakerUpper:find("STRYKER", 1, true))

	if not isStrykerSpeech then
		showSubtitle(speaker, line, duration, shake)
	end
	playVoiceCue(voId, voDb, shake)
	if shake > 0 then
		startShake(shake, math.min(duration, 2.2))
	end
end

player:GetAttributeChangedSignal("OL_CineTick"):Connect(onCueTick)

local lastLookTick = -1
local function onLookCueTick()
	local cueTick = player:GetAttribute("OL_CineLookTick")
	if type(cueTick) ~= "number" or cueTick == lastLookTick then
		return
	end
	lastLookTick = cueTick

	local x = tonumber(player:GetAttribute("OL_CineLookX"))
	local y = tonumber(player:GetAttribute("OL_CineLookY"))
	local z = tonumber(player:GetAttribute("OL_CineLookZ"))
	if not (x and y and z) then
		return
	end

	startLookCue(
		Vector3.new(x, y, z),
		tonumber(player:GetAttribute("OL_CineLookDuration")) or 1.4,
		tonumber(player:GetAttribute("OL_CineLookStrength")) or 0.85
	)
end

player:GetAttributeChangedSignal("OL_CineLookTick"):Connect(onLookCueTick)

if world then
	world:GetAttributeChangedSignal(VOICE_MODE_ATTR):Connect(function()
		if not isVoiceEnabled() and voCueSound.Playing then
			voCueSound:Stop()
		end
	end)
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	bindViewportResize()
	refreshSubtitleLayout()
end)

bindViewportResize()
refreshSubtitleLayout()

task.delay(0.8, function()
	onCueTick()
	onLookCueTick()
end)

RunService.RenderStepped:Connect(function(dt)
	local now = os.clock()
	resolveAudioZones(now)
	resolveLegacySplash(now)

	local openerAudioFocus = isOpeningAudioFocusActive()
	for _, ref in pairs(legacySplashRefs) do
		if ref.sound and ref.sound.Parent then
			local volumeTarget = ref.defaultVolume
			local speedTarget = ref.defaultSpeed

			if openerAudioFocus then
				volumeTarget = 0
				speedTarget = math.clamp(ref.defaultSpeed * 0.70, 0.35, 1.0)
			elseif ref.sound.SoundId == "rbxasset://sounds/impact_water.mp3" then
				volumeTarget = math.min(volumeTarget, 0.12)
			end

			ref.sound.Volume += (volumeTarget - ref.sound.Volume) * math.clamp(dt * 3.4, 0, 1)
			ref.sound.PlaybackSpeed += (speedTarget - ref.sound.PlaybackSpeed) * math.clamp(dt * 2.8, 0, 1)
		end
	end

	local pressureTarget = math.clamp(tonumber(player:GetAttribute("OL_GravityPressure")) or 0, 0, 1)
	gravityPressureSmoothed += (pressureTarget - gravityPressureSmoothed) * math.clamp(dt * 2.4, 0, 1)
	local pressure = gravityPressureSmoothed

	local tone = tostring(player:GetAttribute("OL_GravityTone") or "Steady")
	local pathChoice = tostring(player:GetAttribute("OL_PathChoice") or "")
	local watcherFallsActive = player:GetAttribute("OL_WatcherFallsActive") == true

	local pulseTick = tonumber(player:GetAttribute("OL_GravityPulseTick")) or 0
	if pulseTick ~= lastGravityPulseTick then
		lastGravityPulseTick = pulseTick
		startShake(math.max(0.2, pressure * 0.75), 0.45 + (pressure * 0.3))
	end

	local moodLerp = math.clamp(dt * (2.2 + pressure), 0, 1)
	local targetBg = Color3.fromRGB(8, 12, 17)
	local targetStroke = Color3.fromRGB(115, 158, 186)
	local targetSpeaker = Color3.fromRGB(164, 205, 231)
	local targetLine = Color3.fromRGB(234, 237, 242)

	if tone == "Duty" then
		targetBg = Color3.fromRGB(7, 14, 18)
		targetStroke = Color3.fromRGB(96, 168, 157)
		targetSpeaker = Color3.fromRGB(172, 232, 220)
	elseif tone == "Decision" or tone == "Tense" then
		targetBg = Color3.fromRGB(15, 12, 10)
		targetStroke = Color3.fromRGB(194, 156, 98)
		targetSpeaker = Color3.fromRGB(234, 191, 127)
	elseif tone == "NoReturn" or tone == "Strained" then
		targetBg = Color3.fromRGB(20, 13, 10)
		targetStroke = Color3.fromRGB(212, 132, 78)
		targetSpeaker = Color3.fromRGB(246, 176, 115)
	elseif tone == "Critical" then
		targetBg = Color3.fromRGB(28, 11, 9)
		targetStroke = Color3.fromRGB(232, 104, 82)
		targetSpeaker = Color3.fromRGB(255, 156, 135)
	elseif tone == "Fatal" then
		targetBg = Color3.fromRGB(35, 10, 10)
		targetStroke = Color3.fromRGB(238, 78, 78)
		targetSpeaker = Color3.fromRGB(255, 146, 146)
	elseif tone == "Aftershock" then
		targetBg = Color3.fromRGB(12, 14, 18)
		targetStroke = Color3.fromRGB(125, 136, 156)
		targetSpeaker = Color3.fromRGB(176, 188, 210)
	end

	card.BackgroundColor3 = card.BackgroundColor3:Lerp(targetBg, moodLerp)
	stroke.Color = stroke.Color:Lerp(targetStroke, moodLerp)
	speakerLabel.TextColor3 = speakerLabel.TextColor3:Lerp(targetSpeaker, moodLerp)
	lineLabel.TextColor3 = lineLabel.TextColor3:Lerp(targetLine, moodLerp)

	local targetBgTransparency = math.clamp(0.24 - (pressure * 0.08), 0.12, 0.28)
	if tone == "Fatal" then
		targetBgTransparency = 0.1
	end
	if card.Visible then
		card.BackgroundTransparency += (targetBgTransparency - card.BackgroundTransparency) * math.clamp(dt * 5.5, 0, 1)
	end
	local targetStrokeTransparency = math.clamp(0.34 - (pressure * 0.2), 0.08, 0.36)
	stroke.Transparency += (targetStrokeTransparency - stroke.Transparency) * math.clamp(dt * 4.4, 0, 1)

	if gravityEq then
		local lowTarget = -0.25 + (pressure * 4.5)
		local midTarget = -0.4 - (pressure * 2.8)
		local highTarget = -0.3 - (pressure * 4.8)
		if tone == "Duty" then
			midTarget += 1.1
			highTarget += 0.75
		end
		if tone == "Critical" or tone == "Fatal" then
			lowTarget += 1.4
			midTarget -= 0.6
		end
		gravityEq.LowGain += (lowTarget - gravityEq.LowGain) * math.clamp(dt * 2.2, 0, 1)
		gravityEq.MidGain += (midTarget - gravityEq.MidGain) * math.clamp(dt * 2.2, 0, 1)
		gravityEq.HighGain += (highTarget - gravityEq.HighGain) * math.clamp(dt * 2.2, 0, 1)
	end

	if gravityDistortion then
		local distortionTarget = pressure * 0.06
		if tone == "Critical" then
			distortionTarget += 0.05
		elseif tone == "Fatal" then
			distortionTarget += 0.11
		elseif tone == "Duty" then
			distortionTarget *= 0.55
		end
		distortionTarget = math.clamp(distortionTarget, 0, 0.24)
		gravityDistortion.Level += (distortionTarget - gravityDistortion.Level) * math.clamp(dt * 2.4, 0, 1)
	end

	if voCueSound.Playing then
		local targetSpeed = math.clamp(1 + (pressure * 0.035), 0.92, 1.12)
		voCueSound.PlaybackSpeed += (targetSpeed - voCueSound.PlaybackSpeed) * math.clamp(dt * 1.5, 0, 1)
	end

	local motionBlocked = reducedMotion() or introActive()
	if motionBlocked then shakeTimeLeft, lookCueTimeLeft, lookCueTarget = 0, 0, nil end
	local humanoid = getHumanoid()
	if shakeTimeLeft > 0 then
		shakeTimeLeft = math.max(0, shakeTimeLeft - dt)
	end

	if humanoid then
		local targetOffset = Vector3.zero
		if shakeTimeLeft > 0 then
			local falloff = (shakeDuration > 0) and (shakeTimeLeft / shakeDuration) or 0
			local amp = shakeAmplitude * math.max(0.05, falloff)
			local t = now * 24
			targetOffset = Vector3.new(math.noise(t, 0, 0) * amp, math.noise(0, t, 0) * amp * 0.75, 0)
		else
			local ambientAmp = pressure * 0.055
			if tone == "Critical" or tone == "Fatal" then
				ambientAmp += 0.018
			elseif tone == "Duty" then
				ambientAmp *= 0.65
			end
			if ambientAmp > 0.001 then
				local t = now * (6 + pressure * 15)
				targetOffset = Vector3.new(math.noise(t, 4, 0) * ambientAmp, math.noise(4, t, 0) * ambientAmp * 0.68, 0)
			end
		end
		if motionBlocked then targetOffset = Vector3.zero end
		local camAlpha = motionBlocked and 1 or math.clamp(dt * (shakeTimeLeft > 0 and 16 or (8 + pressure * 4.5)), 0, 1)
		humanoid.CameraOffset = humanoid.CameraOffset:Lerp(targetOffset, camAlpha)
	end

	if lookCueTimeLeft > 0 and lookCueTarget then
		lookCueTimeLeft = math.max(0, lookCueTimeLeft - dt)
		local camera = workspace.CurrentCamera
		if camera then
			local camPos = camera.CFrame.Position
			local desired = CFrame.new(camPos, lookCueTarget)
			local alpha = math.clamp(dt * (4.8 + (lookCueStrength * 6.2)), 0, 1)
			camera.CFrame = camera.CFrame:Lerp(desired, alpha)
		end
		if lookCueTimeLeft <= 0 then
			lookCueTarget = nil
		end
	end

	local focusZone = resolveFocusZone(player:GetAttribute("OL_RiverAudioZone") or "")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	for zoneName, ref in pairs(zoneRefs) do
		if ref.sound.Parent ~= nil then
			local target = 0
			if root and ref.part and ref.part.Parent then
				local distance = (root.Position - ref.part.Position).Magnitude
				local distanceWeight = math.clamp(1 - (distance / ref.radius), 0, 1)
				local floor = (zoneName == focusZone) and (0.16 + (pressure * 0.2)) or 0

				local zoneBias = 1
				if zoneName == focusZone then
					zoneBias += 0.22 + (pressure * 0.28)
				else
					zoneBias *= math.clamp(1 - (pressure * 0.44), 0.42, 1)
				end

				if zoneName == "Rapids" then
					if pathChoice == "LeaveCity" then
						zoneBias += 0.16 + (pressure * 0.22)
					end
					if watcherFallsActive then
						zoneBias += 0.18
					end
				elseif zoneName == "FirstSort" and pathChoice == "RiseHatchery" then
					zoneBias += 0.12 * (1 - pressure)
				end
				if tone == "Fatal" and zoneName ~= "Rapids" then
					zoneBias *= 0.82
				end

				target = ref.baseVolume * math.max(distanceWeight, floor) * math.clamp(zoneBias, 0.22, 2.1)
			end
			ref.sound.Volume += (target - ref.sound.Volume) * math.clamp(dt * (2.7 + pressure), 0, 1)
		end
	end
end)

print("[PC01_RiverCinematicClient_V1] ready")
