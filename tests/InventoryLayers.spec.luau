-- Run in Studio Edit. Detached GUI and inventory fixtures; no real player awards.
local cache = {}
local function readModule(module)
	if cache[module] then return cache[module] end
	assert(module:IsDescendantOf(game.ReplicatedStorage.WildboundUI))
	local chunk = assert(loadstring(module.Source))
	setfenv(chunk, setmetatable({script = module, require = readModule}, {__index = getfenv()}))
	cache[module] = chunk(); return cache[module]
end
local library = game.ReplicatedStorage.WildboundUI
local Style = readModule(library.UIStyle)
local Inventory = readModule(library.Controllers.InventoryController)
local owner, attributes = Instance.new("Folder"), Instance.new("Folder")
local inventory = Instance.new("Folder"); inventory.Name, inventory.Parent = "Inventory", owner
local backpack = Instance.new("Backpack"); backpack.Parent = owner
local character = Instance.new("Model"); character.Parent = owner
local characterAdded = Instance.new("BindableEvent")
local mock = {Character = character, ChildAdded = owner.ChildAdded, ChildRemoved = owner.ChildRemoved, CharacterAdded = characterAdded.Event}
function mock:FindFirstChild(name) return owner:FindFirstChild(name) end
function mock:GetAttribute(name) return attributes:GetAttribute(name) end
function mock:GetAttributeChangedSignal(name) return attributes:GetAttributeChangedSignal(name) end
local ui = game.StarterGui.TethysUI:Clone()
Style.Apply(ui); ui:SetAttribute("WB_PresentationProfile", "Exploration")
local controller = Inventory.new(mock, ui)
local result = {passed = {}, failed = {}}
local function test(name, callback)
	local ok, message = pcall(callback)
	table.insert(ok and result.passed or result.failed, ok and name or {name = name, error = tostring(message)})
end
local value = Instance.new("IntValue")
value.Name, value.Value = "FieldBandage", 3
value:SetAttribute("WB_InventoryImage", Style.Assets.ReferenceSheet.Image)
value.Parent = inventory
task.wait(0.1)
local function slotFor(id)
	for _, slot in ipairs(controller.slots) do if slot:GetAttribute("WB_ItemId") == id then return slot end end
	error("Missing slot: " .. id)
end
test("Meter fill, labels and values remain separate live objects", function()
	local row = ui.HUD.FR_StatusPanel.FR_Health
	assert(row.FR_BarBack.FR_BarFill:IsA("Frame") and row.TL_Value:IsA("TextLabel") and row.TL_Label:IsA("TextLabel"))
	row.FR_BarBack.FR_BarFill.Size = UDim2.fromScale(0.37,1); row.TL_Value.Text = "37 / 100"
	assert(math.abs(row.FR_BarBack.FR_BarFill.Size.X.Scale - 0.37) < 0.00001 and row.TL_Value.Text == "37 / 100")
end)
test("Quickbar icons and changing quantities have separate identities", function()
	local slot = slotFor(value.Name)
	assert(slot.IL_ItemImage:IsA("ImageLabel") and slot.TL_Count:IsA("TextLabel"))
	assert(slot.IL_ItemImage.Image == value:GetAttribute("WB_InventoryImage") and slot.TL_Count.Text == "x3")
	assert(slot.IL_ItemImage.ImageRectSize == Vector2.zero and slot.IL_ItemImage.BorderSizePixel == 0)
	value.Value = 5; task.wait(0.1)
	assert(slot.TL_Count.Text == "x5" and slot.IL_ItemImage.Image == value:GetAttribute("WB_InventoryImage"))
end)
test("Image metadata updates independently and missing images reveal the name", function()
	local slot = slotFor(value.Name)
	value:SetAttribute("WB_InventoryImage", Style.Assets.RegionalSheet.Image); task.wait(0.1)
	assert(slot.IL_ItemImage.Image == Style.Assets.RegionalSheet.Image and slot.TL_Count.Text == "x5")
	value:SetAttribute("WB_InventoryImage", nil); task.wait(0.1)
	assert(not slot.IL_ItemImage.Visible and slot.IL_ItemImage.Image == "" and slot.TL_Name.Visible)
	assert(slot.TL_Name.Text == "Field Bandage" and slot.TL_Count.Text == "x5")
end)
test("Inventory rows preserve image, label and count layers with readable headings", function()
	value:SetAttribute("WB_InventoryImage", Style.Assets.ReferenceSheet.Image); task.wait(0.1)
	controller:SetOpen(true)
	local row = controller.list.FR_Item_1
	assert(row.IL_ItemImage.Image == value:GetAttribute("WB_InventoryImage") and row.TL_Count.Text == "x5")
	assert(row.TL_Name.Text == "Field Bandage" and row.TL_Name.Font == Style.Theme.Typography.BodyFont)
	assert(controller.panel.TL_Title.Font == Style.Theme.Typography.TitleFont and controller.panel.TL_Title.TextColor3 == Style.Theme.Colors.Bone)
	controller:SetOpen(false)
end)
test("Removing an item clears its image and quantity without altering other items", function()
	local slot = slotFor(value.Name)
	value.Value = 0; task.wait(0.1)
	assert(not slot.Visible and slot.TL_Count.Text == "" and slot.TL_Name.Text == "")
	assert(slot.IL_ItemImage.Image == "" and not slot.IL_ItemImage.Visible)
end)
test("Tool texture changes refresh icons and teardown cancels future updates", function()
	local tool = Instance.new("Tool"); tool.Name, tool.TextureId, tool.Parent = "StoneSpear", Style.Assets.ReferenceSheet.Image, backpack
	task.wait(0.1)
	local slot = slotFor(tool.Name)
	assert(slot.IL_ItemImage.Image == tool.TextureId and slot.TL_Count.Text == "x1")
	tool.TextureId = Style.Assets.RegionalSheet.Image; task.wait(0.1)
	assert(slot.IL_ItemImage.Image == tool.TextureId and slot.TL_Count.Text == "x1")
	local before = slot.IL_ItemImage.Image
	controller:Destroy(); tool.TextureId = ""; task.wait(0.1)
	assert(slot.IL_ItemImage.Image == before)
	tool:Destroy()
end)
controller:Destroy(); ui:Destroy(); owner:Destroy(); attributes:Destroy(); characterAdded:Destroy()
return result
