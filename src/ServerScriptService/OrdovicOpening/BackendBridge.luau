-- Narrow hook for the existing headless owner. No HTTP or persistence in this sandbox.
local Bridge = {}
Bridge.__index = Bridge
function Bridge.new(root)
	return setmetatable({Root = root, Sent = {}}, Bridge)
end
function Bridge:Zone(player, zone)
	if zone ~= "Ordovic_Rapids" or self.Sent[player] == zone then return end
	local endpoint = script.Parent:FindFirstChild("BE_OpeningZoneMirror")
	if not endpoint or not endpoint:IsA("BindableEvent") then
		player:SetAttribute("WB_OpenerTelemetryStatus", "NotConnected"); return
	end
	self.Sent[player] = zone
	endpoint:Fire(player, {userId = tostring(player.UserId), targetZone = zone, applyInjury = 0})
	player:SetAttribute("WB_OpenerTelemetryStatus", "Queued")
end
function Bridge:Forget(player) self.Sent[player] = nil end
return Bridge
