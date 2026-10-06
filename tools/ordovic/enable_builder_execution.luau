-- One-capability correction after Studio refused WorldBuilder with
-- "lacking capability RunServerScript". Auto-review requires explicit approval
-- of this delta; approval of the earlier seven-capability set is already applied.
-- User explicitly approved this one-folder correction on 2026-10-06.
local APPROVED = true
assert(APPROVED, "Approval of RunServerScript on OrdovicBuild is pending")
local folder = game.ServerStorage:FindFirstChild("OrdovicBuild")
assert(folder and folder.Sandboxed and folder:GetAttribute("BuildId") == "OrdovicV1_20261006")
local names = {"Basic", "CreateInstances", "AccessOutsideWrite", "Physics", "Environment", "UI", "Input"}
local capabilities = {}
for _, name in ipairs(names) do table.insert(capabilities, Enum.SecurityCapability[name]) end
assert(tostring(folder.Capabilities) == tostring(SecurityCapabilities.new(unpack(capabilities))), "Builder scope drifted; review before changing")
table.insert(capabilities, Enum.SecurityCapability.RunServerScript)
folder.Capabilities = SecurityCapabilities.new(unpack(capabilities))
return {Path = folder:GetFullName(), Sandboxed = folder.Sandboxed, Capabilities = tostring(folder.Capabilities)}
