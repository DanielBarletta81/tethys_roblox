if script:GetAttribute("TethysTemplateEnabled") ~= true then return end
--!strict
-- Place inside src/ServerScripts/WildboundBootstrap.lua
-- Authoritative Master Game Loop for Wildbound Opening Cinema Sequences

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ZONE_UPDATE_URL = "http://localhost:3030/api/v1/wildbound/survival/zone-update"

-- 1. THE ARNN RIDGE CAVE INITIALIZATION
local function handlePlayerSpawning(player: Player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
		
		-- MOUNTAIN SURVIVORS STATE INITIALIZATION
		print(string.format("🦖 [Wildbound Core] Spawning Mountain Survivor: %s inside Arnn Ridge Cave", player.Name))
		
		-- Force initial placement inside your physical cave configuration coordinates
		rootPart.CFrame = CFrame.new(8000, 4500, 8000) 
		humanoid.JumpHeight = 0 -- DISABLE JUMPING NATIVELY: Forcing choices, climbing disabled here
		
		-- Register initial baseline session zone with your Node Express server
		task.spawn(function()
			local payload = { userId = tostring(player.UserId), targetZone = "Arnn_Ridge_Cave", applyInjury = 0 }
			HttpService:PostAsync(ZONE_UPDATE_URL, HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
		end)
	end)
end

-- 2. THE CINEMATIC ORDOVIC RAPIDS FLUSH TRIGGER
-- Call this function when the player touches your cave water exit block
function triggerOrdovicRapidsFlush(player: Player)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	
	if humanoid and rootPart then
		print(string.format("🌊 [Cinema Loop] %s took the exit! Flushing character into Ordovic Rapids...", player.Name))
		
		-- Visual Feedback: Flash camera water spray HUD effects
		ReplicatedStorage:SetAttribute("ScreenWaterSprayActive", true)
		
		-- Simulate being swept down canyon walls into the riverbank context coordinates
		task.wait(3.0) 
		rootPart.CFrame = CFrame.new(2000, 150, 2000) -- Riverbank coordinates
		
		-- Apply small atmospheric injury over the wire so they see the game mechanics early
		task.spawn(function()
			local payload = { userId = tostring(player.UserId), targetZone = "Riverbank_Shallows", applyInjury = 15 }
			local rawResponse = HttpService:PostAsync(ZONE_UPDATE_URL, HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
			
			-- Recover player health back to 100 once they gather the edible items on the riverbank
			task.wait(4.0)
			humanoid.Health = 100
			print(string.format("🟢 [Cinema Loop] %s caught their breath on the riverbank. Health restored.", player.Name))
		end)
	end
end

-- 3. STRYKER SMASH-LANDING OVERVIEW EVENT
-- Call this function when players cross into the area of perfectly round rocks
function triggerStrykerSmashLanding(player: Player)
	print("🦅 [Cinema Loop] Triggering Stryker flyover shriek sequence...")
	
	-- Play spatial shriek audio file at position
	-- Instantiate falling rock debris and boulders using simple unanchored workspace part simulation mechanics
	local debrisPart = Instance.new("Part")
	debrisPart.Size = Vector3.new(8, 8, 8)
	debrisPart.Position = Vector3.new(2100, 180, 2050) -- Directly above the shallows
	debrisPart.Material = Enum.Material.Rock
	debrisPart.Parent = workspace
	
	-- Force the player to go prone by adjusting camera and speed restrictions
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.WalkSpeed = 4 end -- Slashing walk speed to simulate prone crawling
	end
end

Players.PlayerAdded:Connect(handlePlayerSpawning)