--!strict
-- Place inside ServerScriptService -> TethysLoreBookService
-- Defensive content injector handling automated schema verification and data recovery gates

local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local CMS_API_ENDPOINT = "http://localhost:3030/api/v1/tethys/lore/cms-stream"

type NarrativeNode = {
	nodeId: number,
	title: string,
	bodyText: string,
	quadrant: string,
	eraYear: number,
	faction: string
}

local function bindNarrativeToWorkspace(stream: {NarrativeNode})
	for _, dataNode in ipairs(stream) do
		-- Core Guardrail Validation: Verify that vital string parameters are resident
		if not dataNode.title or dataNode.title == "" or not dataNode.bodyText then
			warn("[CMS Ingestion Warning] Skipped corrupted or empty narrative payload element.")
			continue
		end
		
		-- Search the Workspace for a plaque, stone tablet, or book named exactly after the post title
		local targetAsset = Workspace:FindFirstChild(dataNode.title)
		
		if targetAsset and targetAsset:FindFirstChild("SurfaceGui") then
			local textLabel = targetAsset.SurfaceGui:FindFirstChildOfClass("TextLabel")
			if textLabel then
				-- Safe injection pass
				textLabel.Text = dataNode.bodyText
				print(string.format("📜 [CMS Injector] Successfully mounted post onto physical asset: %s", dataNode.title))
			end
		else
			-- Defensive Design: If a story element exists in the CMS but isn't built into the map yet,
			-- cache the parameters as a global server attribute so player items or dialogue boxes can still read it!
			local cleanKey = "Lore_" .. dataNode.title:gsub("%s+", "")
			Workspace:SetAttribute(cleanKey, dataNode.bodyText)
		end
	end
end

local function executeDynamicCmsSync()
	task.wait(3.0) -- Allow server bootstrapping loops to settle completely
	print("🛰️ [Tethys CMS Client] Pinging central API gateway for narrative streams...")
	
	local networkSuccess, jsonRaw = pcall(function()
		return HttpService:GetAsync(CMS_API_ENDPOINT)
	end)
	
	if not networkSuccess or not jsonRaw then
		warn("🚨 [Tethys CMS Client Failure] Gateway server unreachable. Engaging local fallback arrays.")
		return
	end
	
	local parseSuccess, response = pcall(function()
		return HttpService:JSONDecode(jsonRaw)
	end)
	
	if parseSuccess and response and response.success and type(response.narrativeStream) == "table" then
		bindNarrativeToWorkspace(response.narrativeStream)
	else
		warn("❌ [Tethys CMS Client Failure] Received corrupted JSON formatting payload from Express API.")
	end
end

task.spawn(executeDynamicCmsSync)