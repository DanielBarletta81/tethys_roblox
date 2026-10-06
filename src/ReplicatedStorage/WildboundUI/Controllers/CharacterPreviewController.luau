-- Optional static menu portrait. Finished models must be explicitly approved.
local CollectionService = game:GetService("CollectionService")
local Style = require(script.Parent.Parent.UIStyle)
local Preview = {}
Preview.__index = Preview

function Preview.Prepare(source)
	if not source or not source:IsA("Model") or source:GetAttribute("UI_PreviewApproved") ~= true then return nil end
	local count = 0
	for _, object in ipairs(source:GetDescendants()) do if object:IsA("BasePart") then count += 1 end end
	if count == 0 or count > 350 or not source.Archivable then return nil end
	local model = source:Clone()
	local objects = model:GetDescendants(); table.insert(objects, model)
	for _, object in ipairs(objects) do
		for _, tag in ipairs(CollectionService:GetTags(object)) do CollectionService:RemoveTag(object, tag) end
		if object:IsA("LuaSourceContainer") or object:IsA("Humanoid") or object:IsA("AnimationController")
			or object:IsA("Animator") or object:IsA("ProximityPrompt") or object:IsA("Sound") or object:IsA("ParticleEmitter")
			or object:IsA("Trail") or object:IsA("Beam") or object:IsA("LayerCollector") then object:Destroy()
		elseif object:IsA("BasePart") then object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery = true, false, false, false end
	end
	model:PivotTo(CFrame.new())
	return model
end
function Preview.new(ui, library)
	local self = setmetatable({UI = ui, Library = library, Connections = {}}, Preview)
	self.Panel = Style.New("Frame", "FR_CharacterPreview", ui.Menus, {
		AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(220, 300), Visible = false, ZIndex = 70,
	})
	Style.Panel(self.Panel)
	self.Caption = Style.Text("TL_CharacterName", self.Panel, "", UDim2.new(0, 12, 1, -38), UDim2.new(1, -24, 0, 26), 20)
	self.Caption.Font = Style.Theme.Typography.TitleFont
	self.View = Style.New("ViewportFrame", "VP_Character", self.Panel, {
		Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 1, -52), BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(150, 158, 154), LightColor = Color3.fromRGB(230, 212, 175), ZIndex = 71,
	})
	self.World = Style.New("WorldModel", "WM_Portrait", self.View)
	self.Camera = Style.New("Camera", "CAM_Portrait", self.View, {FieldOfView = 35})
	self.View.CurrentCamera = self.Camera
	local function refresh() if not self.Dead then self:Refresh() end end
	local function connect(signal) table.insert(self.Connections, signal:Connect(refresh)) end
	connect(ui:GetAttributeChangedSignal("WB_MenuOpen"))
	connect(ui:GetPropertyChangedSignal("AbsoluteSize"))
	connect(library:GetAttributeChangedSignal("CharacterPreviewKey"))
	connect(ui.Menus.FR_PauseMenu:GetPropertyChangedSignal("Visible"))
	table.insert(self.Connections, ui.Destroying:Connect(function() self:Destroy() end))
	self:Refresh()
	return self
end
function Preview:Refresh()
	local menu = self.UI.Menus.FR_PauseMenu
	local models = self.Library:FindFirstChild("CharacterModels")
	local key = self.Library:GetAttribute("CharacterPreviewKey")
	local source = type(key) == "string" and models and models:FindFirstChild(key)
	local eligible = self.UI:GetAttribute("WB_MenuOpen") == true and menu.Visible and self.UI.AbsoluteSize.X >= 1100
	if not eligible or not source or source:GetAttribute("UI_PreviewApproved") ~= true then
		self.Panel.Visible = false
		self.World:ClearAllChildren(); self.Source = nil
		return
	end
	if self.Source ~= source then
		self.World:ClearAllChildren()
		local model = Preview.Prepare(source)
		if not model then self.Panel.Visible = false; self.Source = nil; return end
		model.Parent = self.World; self.Source = source
		local cf, size = model:GetBoundingBox()
		local distance = math.max(size.Y, size.X / 0.72, size.Z) / (2 * math.tan(math.rad(35 / 2))) * 1.2
		self.Camera.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, size.Y * 0.05, -distance), cf.Position)
		local label = source:GetAttribute("UI_DisplayName")
		self.Caption.Text = type(label) == "string" and label or source.Name
	end
	self.Panel.Position = UDim2.fromOffset(menu.AbsolutePosition.X - self.UI.AbsolutePosition.X + menu.AbsoluteSize.X + 18, self.UI.AbsoluteSize.Y / 2)
	self.Panel.Visible = true
end
function Preview:Destroy()
	if self.Dead then return end
	self.Dead = true
	for _, connection in ipairs(self.Connections) do connection:Disconnect() end
	self.World:ClearAllChildren()
end
return Preview
