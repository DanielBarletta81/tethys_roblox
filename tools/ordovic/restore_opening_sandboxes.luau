-- Restore the exact previously reviewed limits after a fresh source sync.
-- Existing sandbox drift fails closed; no ancestor or existing owner is changed.
local definitions = {
	{game.ServerStorage.OrdovicBuild, {"RunServerScript","Basic","CreateInstances","AccessOutsideWrite","Physics","Environment","UI","Input","Players"}},
	{game.ServerScriptService.OrdovicOpening, {"RunServerScript","Basic","CreateInstances","AccessOutsideWrite","Physics","Players","AvatarBehavior","UI","Input"}},
	{game.StarterPlayer.StarterPlayerScripts.OrdovicOpening, {"RunClientScript","Basic","AccessOutsideWrite","Players","UI","Input"}},
}
for _, definition in ipairs(definitions) do
	local folder, names = unpack(definition)
	local items = {}; for _, name in ipairs(names) do table.insert(items,Enum.SecurityCapability[name]) end
	local expected = SecurityCapabilities.new(unpack(items))
	if folder.Sandboxed then assert(tostring(folder.Capabilities)==tostring(expected),"Reviewed scope drift: "..folder:GetFullName())
	else folder.Capabilities=expected;folder.Sandboxed=true end
end
return "Historical opening boundaries restored; Network, RemoteEvent and DataStore are not granted"
