-- Integration template: dependencies and acceptance are listed in docs/engineering/roblox-integration.md.
if script:GetAttribute("TethysTemplateEnabled") ~= true then return end
-- TETHYS WILDBOUND: STORM PRECIPITATION (SERVER STUB)
-- Rain rendering was moved client-side for local performance gating.

local Players = game:GetService("Players")

local LEGACY_RIG_NAME = "WB_StormRainVolume"

local function cleanupLegacyRig(character)
	local rig = character:FindFirstChild(LEGACY_RIG_NAME)
	if rig then
		rig:Destroy()
	end
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(cleanupLegacyRig)
	if player.Character then
		task.defer(function()
			cleanupLegacyRig(player.Character)
		end)
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
