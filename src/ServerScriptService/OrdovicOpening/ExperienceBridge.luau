-- Uses the existing Ordovic sandbox; it never requires an unrestricted service.
-- The bindable is server-only and its callback accepts three fixed operations.
local endpoint = script.Parent:WaitForChild("BF_DeathExperience", 10)
assert(endpoint and endpoint:IsA("BindableFunction"), "Death experience bridge was not started")
local Bridge = {}
function Bridge.Record(player, kind, id) return endpoint:Invoke("Observation", player, kind, id) end
function Bridge.Hazard(player, id) return endpoint:Invoke("Hazard", player, id) end
function Bridge.TryRespawn(player, character) return endpoint:Invoke("RestReturn", player, character) end
return Bridge
