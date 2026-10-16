-- Accept the existing /cms-stream schema after the headless owner fetches it.
local Lore = {}
function Lore.Apply(cave, payload)
	if type(payload) ~= "table" or payload.success ~= true or type(payload.narrativeStream) ~= "table" then return 0 end
	local byId = {}
	for _, item in ipairs(payload.narrativeStream) do
		if type(item) == "table" and type(item.nodeId) == "number" and type(item.bodyText) == "string" then
			byId[tostring(item.nodeId)] = item.bodyText:sub(1,700)
		end
	end
	local count = 0
	for _, node in ipairs(cave:GetChildren()) do
		local id = node:GetAttribute("LoreId")
		local text = id ~= nil and byId[tostring(id)]
		if node:GetAttribute("ObservationId") and text then node:SetAttribute("LoreBodyText", text); count += 1 end
	end
	return count
end
return Lore
