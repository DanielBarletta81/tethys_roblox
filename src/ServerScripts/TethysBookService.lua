--!strict
-- Place inside ServerScriptService -> TethysLoreBookService
-- Dynamically binds Headless WordPress post streams directly onto physical in-game assets

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CMS_API_ENDPOINT = "http://localhost:3030/api/v1/tethys/lore/cms-stream"

local function deployDynamicLoreAssets()
	task.wait(2.0) -- Allow bootstrap matrices to settle

	local success, jsonRaw = pcall(function()
		return HttpService:GetAsync(CMS_API_ENDPOINT)
	end)

	if not success or not jsonRaw then
		warn("[Tethys CMS Client] Could not resolve narrative stream link from central Node server.")
		return
	end

	local parseSuccess, response = pcall(function()
		return HttpService:JSONDecode(jsonRaw)
	end)

	if parseSuccess and response.success and response.narrativeStream then
		print(string.format("📡 [Tethys CMS Client] Stream synchronized! Mapping %d narrative keys to workspace nodes...", #response.narrativeStream))

		for _, dataNode in ipairs(response.narrativeStream) do
			-- SMOKE AND MIRRORS PATTERN: Look for an existing plaque or item container model matching the title
			-- If you place an empty book or stone plaque model named exactly "The Founding Pact of Sky City",
			-- this block will catch it and dynamically write your WordPress body text directly onto its UI text face!
			local targetModel = workspace:FindFirstChild(dataNode.title)

			if targetModel and targetModel:FindFirstChild("SurfaceGui") then
				local textLabel = targetModel.SurfaceGui:FindFirstChildOfClass("TextLabel")
				if textLabel then
					textLabel.Text = dataNode.bodyText
					print(string.format("📜 [CMS Injector] Successfully wrote post contents onto Model: %s", dataNode.title))
				end
			end
		end
	end
end

task.spawn(deployDynamicLoreAssets)