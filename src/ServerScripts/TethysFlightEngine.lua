--!strict
-- Place inside ServerScriptService -> TethysFlightEngine
-- Ingests backend aerodynamic metrics to drive custom character flight physics fluidly

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AERO_API_URL = "http://localhost:3030/api/v1/tethys/flight/aero-calculate"
local ServerJobId = game.JobId == "" and "dev_studio_local_sandbox" or game.JobId

-- RemoteEvent to tell Stryker's camera and screen interface to trigger particle embers and indicators
local PredatorThreatAlert = ReplicatedStorage:WaitForChild("PredatorThreatAlert") :: RemoteEvent

local function handleStrykerFlightPhysics(strykerRoot: BasePart, linearVelocityInstance: LinearVelocity)
	local altitude = strykerRoot.Position.Y
	local speed = strykerRoot.AssemblyLinearVelocity.Magnitude
	
	-- Pack coordinates tightly matching our Express schema shapes
	local telemetryPayload = {
		serverJobId = ServerJobId,
		altitudeStuds = altitude,
		coordinateX = strykerRoot.Position.X,
		coordinateZ = strykerRoot.Position.Z,
		-- FIX: math.round is lowercased to match the standard Luau library
		currentSpeedKnots = math.round(speed * 0.6) 
	}
	
	local serializeSuccess, jsonBody = pcall(function()
		return HttpService:JSONEncode(telemetryPayload)
	end)
	
	if not serializeSuccess or not jsonBody then return end
	
	-- Non-blocking thread block dispatches calculations to your Node backend
	task.spawn(function()
		local networkSuccess, responseRaw = pcall(function()
			return HttpService:PostAsync(AERO_API_URL, jsonBody, Enum.HttpContentType.ApplicationJson)
		end)
		
		if networkSuccess and responseRaw then
			local parseSuccess, response = pcall(function()
				return HttpService:JSONDecode(responseRaw)
			end)
			
			if parseSuccess and response.success then
				-- 1. APPLY DYNAMIC EXPRESS PHYSICS OVER THE CORE FLIGHT MODEL
				local turbulence = response.ashTurbulenceVector
				local liftForce = response.thermalUpdraftForce
				
				-- Adjust Stryker's velocity attachment properties instantly matching aerodynamic drag
				linearVelocityInstance.VectorVelocity = Vector3.new(
					strykerRoot.AssemblyLinearVelocity.X + turbulence.x,
					strykerRoot.AssemblyLinearVelocity.Y + liftForce + turbulence.y,
					strykerRoot.AssemblyLinearVelocity.Z + turbulence.z
				)
				
				-- 2. DISPATCH VISUAL BROADCASTS BACK TO THE CLIENT INTERFACE LAYER
				local targetedPlayer = Players:GetPlayerFromCharacter(strykerRoot.Parent)
				if targetedPlayer then
					PredatorThreatAlert:FireClient(targetedPlayer, {
						emberRate = response.emberDensitySpawnRate,
						wardenDanger = response.vestigeWardenHarpoonActive,
						exitUnlocked = response.skyCityExitVisible
					})
				end
			end
		end
	end)
end

-- Hook the flight loop when Stryker spawns into the workspace matrix
local function trackStrykerSpawning(character: Model)
	if character.Name ~= "Stryker" then return end
	
	local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
	
	-- Verify or inject a structural LinearVelocity physics modifier for flight control
	local attachment = rootPart:FindFirstChild("FlightAttachment") :: Attachment?
	if not attachment then
		local newAttachment = Instance.new("Attachment")
		newAttachment.Name = "FlightAttachment"
		newAttachment.Parent = rootPart
		attachment = newAttachment
	end
	
	local velocityConstraint = rootPart:FindFirstChild("FlightVelocity") :: LinearVelocity?
	if not velocityConstraint then
		local lv = Instance.new("LinearVelocity")
		lv.Name = "FlightVelocity"
		lv.Attachment0 = attachment
		lv.MaxForce = 50000 -- Give it enough power to counter standard gravity curves
		lv.Parent = rootPart
		velocityConstraint = lv
	end
	
	task.spawn(function()
		while character:IsDescendantOf(Workspace) and velocityConstraint do
			handleStrykerFlightPhysics(rootPart, velocityConstraint)
			task.wait(0.1) -- Run at a high-speed, smooth 10Hz sampling check pass
		end
	end)
end

Workspace.ChildAdded:Connect(trackStrykerSpawning)
print("🦅 [Tethys Flight Engine] Aerodynamic calculation loop fully armed