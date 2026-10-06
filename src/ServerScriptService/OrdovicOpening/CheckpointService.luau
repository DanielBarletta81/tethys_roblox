local Checkpoint = {}
function Checkpoint.RefusalSpawn(root, player)
	local guides = root["00_Guides"]
	if player:GetAttribute("WB_OrdovicCascadeComplete") then
		return guides.GUIDE_WatcherLanding.Position + Vector3.new(0, 1, 0), true
	end
	local guide = player:GetAttribute("WB_OrdovicLowerPoolReached") and guides.GUIDE_RefusalLowerPool or guides.GUIDE_BypassMouth
	return guide.Position, false
end
function Checkpoint.Update(root, state)
	if state.Choice ~= "DOWNSTREAM" or state.Landed then return end
	local pool = root["00_Guides"].GUIDE_RefusalLowerPool.Position
	if (state.Root.Position - pool).Magnitude < 26 and state.Root.Position.Y <= pool.Y + 2 then
		state.Player:SetAttribute("WB_OrdovicLowerPoolReached", true)
	end
end
return Checkpoint
