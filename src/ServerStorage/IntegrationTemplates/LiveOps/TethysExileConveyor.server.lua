-- Integration template: dependencies and acceptance are listed in docs/engineering/roblox-integration.md.
if script:GetAttribute("TethysTemplateEnabled") ~= true then return end
--!strict
-- Place inside src/ServerScripts/TethysExileConveyor.lua
-- Authoritative City Quota Inspector and Forced Condemned Execution Loop

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local VERIFY_WEIGHT_URL = "http://localhost:3030/api/v1/wildbound/city/verify-weight"

local InspectionPlate = Workspace:WaitForChild("InspectionGatePlatform", 10) :: BasePart?
local ExecutionPlankNode = Workspace:WaitForChild("WeepExecutionPlankNode", 10) :: BasePart?
local isProcessorActive = false

if not InspectionPlate or not ExecutionPlankNode then
	warn("⚠️ [Exile Conveyor] Missing crucial boundary markers from workspace geometry layout.")
end

local function executeForcedExileMarch(character: Model, player: Player)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?

	if humanoid and rootPart and ExecutionPlankNode then
		-- 1. STRIP PLAYER INPUT CONTROL
		humanoid.WalkSpeed = 0
		humanoid.JumpHeight = 0

		print(string.format("⛓️ [EXILE ENFORCED] Commencing forced march sequence for: %s", player.Name))
		task.wait(2.0)

		-- 2. PROGRAMMATIC MARCH TWEEN: Force the character to walk out to the edge of the Weep cliff
		local tweenInfo = TweenInfo.new(4.0, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
		local marchTween = TweenService:Create(rootPart, tweenInfo, {
			CFrame = ExecutionPlankNode.CFrame
		})

		humanoid.WalkSpeed = 4 -- Set animation state to slow shuffle walk
		marchTween:Play()

		marchTween.Completed:Connect(function()
			-- 3. THE FINAL CONDEMNED DROPOUT PUSH
			print("💀 [EXILE ENFORCED] Reached edge of the Weep. Disengaging anchor constraints...")

			-- Instantly push the character off the ledge with a forward physics velocity impulse
			rootPart.AssemblyLinearVelocity = rootPart.CFrame.LookVector * 35 + Vector3.new(0, -10, 0)
		end)
	end
end

local function handleInspectionTouch(otherPart: BasePart)
	if isProcessorActive then return end

	local character = otherPart.Parent
	if not character then return end

	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if player and humanoid and humanoid.Health > 0 then
		isProcessorActive = true
		print(string.format("🛰️ [Inspection Gate] Gathering quota metrics for user: %s", player.Name))

		-- Gather current mock inventory tallies to pass to your Node server check
		-- Replace these with true variable links once your inventory arrays are finished
		local structuralCheckPayload = {
			userId = tostring(player.UserId),
			vinesCollectedCount = 3,  -- Low count (failing metrics)
			basaltCoreTokens = 1,     -- Low count
			laborHoursElapsed = 2
		}

		local success, jsonString = pcall(function()
			return HttpService:JSONEncode(structuralCheckPayload)
		end)

		if success and jsonString then
			task.spawn(function()
				local postSuccess, responseRaw = pcall(function()
					return HttpService:PostAsync(VERIFY_WEIGHT_URL, jsonString, Enum.HttpContentType.ApplicationJson)
				end)

				if postSuccess and responseRaw then
					local parseSuccess, response = pcall(function()
						return HttpService:JSONDecode(responseRaw)
					end)

					if parseSuccess and response.success then
						print("[Express Output] " .. response.announcementMessage)

						if response.assignedState == "Condemned_Exile" then
							executeForcedExileMarch(character, player)
						else
							-- PASSED CITIZEN WORKER CASE: Open the mechanical gate walls
							print("🟢 Gate permissions verified. Access granted to Sky City lower tiers.")
							humanoid.WalkSpeed = 16
						end
					end
				end
				task.wait(4.0)
				isProcessorActive = false
			end)
		else
			isProcessorActive = false
		end
	end
end

if InspectionPlate then
	InspectionPlate.Touched:Connect(handleInspectionTouch)
	print("🛡️ [Tethys Quota Guard] Inspection grid platform successfully armed and scanning.")
end
