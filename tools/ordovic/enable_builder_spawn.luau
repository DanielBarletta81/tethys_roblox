-- Studio denied SpawnLocation creation without Players. This exact delta
-- requires separate approval; no ancestor or runtime permissions change.
-- User gave approval to continue document systems/structures, including the
-- pending cave-spawn grant, on 2026-10-06.
local APPROVED = true
assert(APPROVED, "Approval of Players on OrdovicBuild is pending")
local folder = game.ServerStorage:FindFirstChild("OrdovicBuild")
assert(folder and folder.Sandboxed and folder:GetAttribute("BuildId") == "OrdovicV1_20261006")
local names = {"Basic", "CreateInstances", "AccessOutsideWrite", "Physics", "Environment", "UI", "Input", "RunServerScript"}
local capabilities = {}
for _, name in ipairs(names) do table.insert(capabilities, Enum.SecurityCapability[name]) end
assert(tostring(folder.Capabilities) == tostring(SecurityCapabilities.new(unpack(capabilities))), "Builder scope drifted; review before changing")
table.insert(capabilities, Enum.SecurityCapability.Players)
folder.Capabilities = SecurityCapabilities.new(unpack(capabilities))
return {Path = folder:GetFullName(), Sandboxed = folder.Sandboxed, Capabilities = tostring(folder.Capabilities)}
