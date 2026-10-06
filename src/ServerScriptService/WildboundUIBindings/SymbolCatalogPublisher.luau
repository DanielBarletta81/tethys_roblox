-- Publish existing authored metadata for UI independently of terrain streaming.
-- Study prompts and player unlocks remain owned by the existing symbology system.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local library = ReplicatedStorage:WaitForChild("WildboundUI")
local catalog = library:FindFirstChild("SymbolCatalog")
if not catalog then catalog = Instance.new("Folder"); catalog.Name = "SymbolCatalog"; catalog.Parent = library end
catalog:SetAttribute("Generator", "WildboundUI")
local root = workspace:FindFirstChild("World")
root = root and root:FindFirstChild("22_ImmediateCityFortressLoop_V1")
root = root and root:FindFirstChild("09_ContextSymbology_V1")
if not root then warn("[SymbolCatalogPublisher] Existing symbol root missing"); return end
local fields = {
	"WOT_SymbolKey", "WOT_SymbolName", "WOT_SymbolMeaning", "WOT_SymbolOrder",
	"WOT_SymbolGemTitle", "WOT_SymbolGemLore", "WOT_SymbolGemScience", "WOT_SymbolGemSource",
}
local tracked = {}
local function bind(plate)
	if not plate:IsA("BasePart") or tracked[plate] then return end
	local key = plate:GetAttribute("WOT_SymbolKey")
	if type(key) ~= "string" or key == "" then return end
	local entry = catalog:FindFirstChild(key) or Instance.new("Folder")
	entry.Name = key
	local function copy()
		for _, field in ipairs(fields) do entry:SetAttribute(field, plate:GetAttribute(field)) end
		entry:SetAttribute("SourcePath", plate:GetFullName())
	end
	copy()
	entry.Parent = catalog
	local connections = {}
	for _, field in ipairs(fields) do table.insert(connections, plate:GetAttributeChangedSignal(field):Connect(copy)) end
	tracked[plate] = { entry = entry, connections = connections }
end
for _, plate in ipairs(root:GetDescendants()) do bind(plate) end
root.DescendantAdded:Connect(bind)
root.DescendantRemoving:Connect(function(plate)
	local record = tracked[plate]
	if not record then return end
	for _, connection in ipairs(record.connections) do connection:Disconnect() end
	record.entry:Destroy()
	tracked[plate] = nil
end)
print("[SymbolCatalogPublisher] Existing symbol metadata available to UI")
