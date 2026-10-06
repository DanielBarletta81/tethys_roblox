-- User explicitly approved on 2026-10-06: "permission to build ordovic opener".
-- Applies only the exact new-folder sets reviewed in docs/Ordovic-opening-capabilities.md.
local APPROVED = true
assert(APPROVED, "Explicit Ordovic capability approval is required")
local definitions = {
	{game.ServerStorage, "OrdovicBuild", {"Basic", "CreateInstances", "AccessOutsideWrite", "Physics", "Environment", "UI", "Input"}},
	{game.ServerScriptService, "OrdovicOpening", {"RunServerScript", "Basic", "CreateInstances", "AccessOutsideWrite", "Physics", "Players", "AvatarBehavior", "UI", "Input"}},
	{game.StarterPlayer.StarterPlayerScripts, "OrdovicOpening", {"RunClientScript", "Basic", "AccessOutsideWrite", "Players", "UI", "Input"}},
}
for _, definition in ipairs(definitions) do
	assert(not definition[1]:FindFirstChild(definition[2]), "Existing scope requires review: " .. definition[2])
end
local result = {}
for _, definition in ipairs(definitions) do
	local folder = Instance.new("Folder")
	folder.Name = definition[2]
	local capabilities = {}
	for _, name in ipairs(definition[3]) do table.insert(capabilities, Enum.SecurityCapability[name]) end
	folder.Capabilities = SecurityCapabilities.new(unpack(capabilities))
	folder.Sandboxed = true
	folder:SetAttribute("BuildId", "OrdovicV1_20261006")
	folder.Parent = definition[1]
	table.insert(result, {Path = folder:GetFullName(), Capabilities = tostring(folder.Capabilities), Sandboxed = folder.Sandboxed})
end
return result
