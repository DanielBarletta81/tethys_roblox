-- Integration template: dependencies and acceptance are listed in docs/engineering/roblox-integration.md.
if script:GetAttribute("TethysTemplateEnabled") ~= true then return end

-- Place inside src/ServerScripts/TethysGuiBridge.lua
-- Authoritative Server Container: Safely completes HTTP transactions out of untrusted client reach

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MUTATE_PROFILE_URL = "http://localhost:3030/api/v1/tethys/profile/mutate"

local RequestPathFunction = ReplicatedStorage:WaitForChild("RequestPathAlignment") :: RemoteFunction

local function handlePlayerPathMutation(player: Player, requestedPath: string): (boolean, string)
	print(string.format("[Tethys Security] Ingesting UI alignment parameters from user %s for path: %s", player.Name, requestedPath))

	-- Validation gate: Check for structural parameter injection attempts
	if requestedPath ~= "Creature" and requestedPath ~= "Mystic" and requestedPath ~= "Triumvirate" then
		return false, "Security Rejection: Invalid path constraints."
	end

	local pipelinePayload = {
		userId = tostring(player.UserId),
		username = player.Name,
		guildAlignment = requestedPath,
		lastSavedTimestamp = os.date("!Y-%m-%dT%H:%M:%SZ")
	}

	-- Compile data strings securely on the server-side tier
	local serializeSuccess, jsonBody = pcall(function()
		return HttpService:JSONEncode(pipelinePayload)
	end)

	if not serializeSuccess or not jsonBody then
		return false, "Internal Server Error: Serialization failed."
	end

	-- SERVER-ONLY EXECUTION VALVE: Safe from client-side sandbox restrictions
	local networkSuccess, responseRaw = pcall(function()
		return HttpService:PostAsync(MUTATE_PROFILE_URL, jsonBody, Enum.HttpContentType.ApplicationJson)
	end)

	if not networkSuccess then
		warn("🚨 [ELO Connection Failure] Express gateway microservice on Port 3030 is currently offline!")
		return false, "Gateway Timeout: Central live ops database is currently unreachable."
	end

	local parseSuccess, responseObj = pcall(function()
		return HttpService:JSONDecode(responseRaw)
	end)

	if parseSuccess and responseObj.success then
		return true, responseObj.message
	else
		return false, responseObj.error or "Unknown database mutation error."
	end
end

RequestPathFunction.OnServerInvoke = handlePlayerPathMutation
print("🟢 [Tethys GUI Bridge] Secure network listener actively bound and standing by.")
