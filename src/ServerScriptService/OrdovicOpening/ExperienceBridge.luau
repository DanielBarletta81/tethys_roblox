-- Optional integration with the existing death/Rest owner. No replacement ledger.
local Bridge = {}
local function invoke(operation, ...)
	local endpoint = script.Parent:FindFirstChild("BF_DeathExperience")
	if endpoint and endpoint:IsA("BindableFunction") then return endpoint:Invoke(operation, ...) end
	return false
end
function Bridge.Record(player, kind, id) return invoke("Observation", player, kind, id) end
function Bridge.Hazard(player, id) return invoke("Hazard", player, id) end
function Bridge.TryRespawn(player, character) return invoke("RestReturn", player, character) end
return Bridge
