--!strict
-- Place inside ServerScriptService -> TethysGuiBridge
-- Bridges client UI requests safely across external Open Cloud web gates

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MUTATE_PROFILE_URL = "http://localhost:3030/api/v1/tethys/profile/mutate"

-- Secure tracking token link allocation mapping
local RequestPathFunction = ReplicatedStorage:WaitForChild("RequestPathAlignment") :: RemoteFunction

-- Server validation handling routine
local function handlePlayerPathMutation(player: Player, requestedPath: string): (boolean, string)
	print(string.format("[Tethys Auth] Evaluating UI mutation request from user %s for path: %s", player.Name, requestedPath))

	-- DEFENSIVE LAYER: Catch malicious client spoofing attempts before they hit the wire
	if requestedPath ~= "Creature" and requestedPath ~= "Mystic" and requestedPath ~= "Triumvirate" then
		return false, "Security Exception: Invalid path allocation parameters submitted."
	end

	-- Compile your payload data structures matching your TypeScript backend specifications
	local pipelinePayload = {
		userId = tostring(player.UserId),
		username = player.Name,
		guildAlignment = requestedPath,
		lastSavedTimestamp = os.date("!Y-%m-%dT%H:%M:%SZ") -- ISO 8601 formatting timestamp profile
	}

	local serializeSuccess, jsonBody = pcall(function()
		return HttpService:JSONEncode(pipelinePayload)
	end)

	if not serializeSuccess or not jsonBody then
		return false, "Internal Exception: Serialization pipeline failure."
	end

	-- Dispatch HTTP transaction to your local Express server instance
	local networkSuccess, responseRaw = pcall(function()
		return HttpService:PostAsync(MUTATE_PROFILE_URL, jsonBody, Enum.HttpContentType.ApplicationJson)
	end)

	if not networkSuccess then
		warn("[Tethys Network Failure] Unable to connect to Express LiveOps server. API fallback engaged.")
		return false, "Gateway Timeout: LiveOps cloud bridge is currently offline."
	end

	local parseSuccess, responseObj = pcall(function()
		return HttpService:JSONDecode(responseRaw)
	end)

	if parseSuccess and responseObj.success then
		print(string.format("✅ [Tethys Sync] Profile mutation committed successfully for %s", player.Name))
		return true, responseObj.message
	else
		return false, responseObj.error or "Unknown database mutation error."
	end
end

-- Bind our handler to listen to the client remote node interface link
RequestPathFunction.OnServerInvoke = handlePlayerPathMutation
print("[Tethys Auth] Authoritative GUI networking bridge fully engaged and standing by.")

