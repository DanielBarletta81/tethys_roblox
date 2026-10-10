-- Static decoration around existing live GUI objects. No gameplay or input owner.
local artwork = require(script.Parent.PlayerArtwork)
local Layers = {}

function Layers.Available(key)
	local entry = artwork[key]
	return entry ~= nil and entry.Image:match("^rbxassetid://%d+$") ~= nil
end

local function frame(parent, name)
	local object = Instance.new("Frame")
	object.Name, object.BackgroundTransparency, object.BorderSizePixel = name, 1, 0
	object.Active, object.ClipsDescendants, object.ZIndex = false, true, parent.ZIndex
	object.Parent = parent
	return object
end

local function image(parent, name, entry)
	local object = Instance.new("ImageLabel")
	object.Name, object.Image = name, entry.Image
	object.BackgroundTransparency, object.BorderSizePixel, object.ImageTransparency = 1, 0, 0
	object.Active, object.ZIndex, object.ScaleType = false, parent.ZIndex, Enum.ScaleType.Stretch
	object.Parent = parent
	return object
end

function Layers.Whole(parent, key, name)
	if not Layers.Available(key) then return nil end
	local object = image(parent, name, artwork[key])
	object.Size, object.ScaleType = UDim2.fromScale(1,1), Enum.ScaleType.Fit
	return object
end

function Layers.Band(parent, key, name)
	if not Layers.Available(key) then return nil end
	local entry = artwork[key]
	local root = frame(parent, name)
	root.Size, root.ZIndex = UDim2.fromScale(1,1), parent.ZIndex + 2
	local segments, textures = {}, {}
	for index, bounds in ipairs({{0,entry.Left},{entry.Left,entry.Right},{entry.Right,1}}) do
		local clip = frame(root, "FR_Segment_" .. index)
		local texture = image(clip, "IL_Artwork", entry)
		texture.ImageTransparency = 1
		local width, height = bounds[2] - bounds[1], entry.Bottom - entry.Top
		texture.Size = UDim2.fromScale(1 / width, 1 / height)
		texture.Position = UDim2.fromScale(-bounds[1] / width, -entry.Top / height)
		table.insert(segments, clip)
		table.insert(textures, texture)
	end
	local function loaded()
		local ready = true
		for _, texture in ipairs(textures) do if not texture.IsLoaded then ready = false end end
		root:SetAttribute("WB_ArtworkLoaded", ready)
		for _, texture in ipairs(textures) do texture.ImageTransparency = ready and 0 or 1 end
	end
	for _, texture in ipairs(textures) do texture:GetPropertyChangedSignal("IsLoaded"):Connect(loaded) end
	loaded()
	local function layout()
		local height = parent.AbsoluteSize.Y
		if height == 0 then height = parent.Size.Y.Offset end
		local capScale = height * entry.Aspect / (entry.Bottom - entry.Top)
		local left, right = capScale * entry.Left, capScale * (1 - entry.Right)
		segments[1].Position, segments[1].Size = UDim2.new(), UDim2.new(0,left,1,0)
		segments[2].Position, segments[2].Size = UDim2.fromOffset(left,0), UDim2.new(1,-left-right,1,0)
		segments[3].Position, segments[3].Size = UDim2.new(1,-right,0,0), UDim2.new(0,right,1,0)
	end
	parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout); layout()
	return root, entry
end

function Layers.Meter(row, key)
	local decoration, entry = Layers.Band(row, key, "FR_MeterArtwork")
	if not decoration then return false end
	local back, label, value = row.FR_BarBack, row.TL_Label, row.TL_Value
	local glyph = row:FindFirstChild("IL_StatusGlyph")
	local original = {BackPosition = back.Position, BackSize = back.Size, LabelPosition = label.Position,
		LabelSize = label.Size, LabelTextSize = label.TextSize, ValuePosition = value.Position,
		ValueSize = value.Size, ValueTextSize = value.TextSize, GlyphVisible = glyph and glyph.Visible}
	back.ClipsDescendants, back.BorderSizePixel, back.ZIndex = true, 0, row.ZIndex + 1
	back.FR_BarFill.ZIndex = back.ZIndex + 1
	label.ZIndex, value.ZIndex = row.ZIndex + 3, row.ZIndex + 3
	local function layout()
		if decoration:GetAttribute("WB_ArtworkLoaded") ~= true then
			back.Position, back.Size = original.BackPosition, original.BackSize
			label.Position, label.Size, label.TextSize = original.LabelPosition, original.LabelSize, original.LabelTextSize
			value.Position, value.Size, value.TextSize = original.ValuePosition, original.ValueSize, original.ValueTextSize
			if glyph then glyph.Visible = original.GlyphVisible end
			return
		end
		local height = row.AbsoluteSize.Y > 0 and row.AbsoluteSize.Y or row.Size.Y.Offset
		local bandHeight = entry.Bottom - entry.Top
		local left = height * entry.Aspect * entry.Left / bandHeight
		local right = height * entry.Aspect * (1 - entry.Right) / bandHeight
		back.Position = UDim2.new(0,left+1,(entry.FillTop-entry.Top)/bandHeight,1)
		back.Size = UDim2.new(1,-left-right-2,(entry.FillBottom-entry.FillTop)/bandHeight,-2)
		label.Position, label.Size = UDim2.new(0,left+4,0,0), UDim2.new(1,-left-right-66,1,0)
		value.Position, value.Size = UDim2.new(1,-right-60,0,0), UDim2.new(0,56,1,0)
		label.TextSize, value.TextSize = 11, 12
		if glyph then glyph.Visible = false end
	end
	row:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	decoration:GetAttributeChangedSignal("WB_ArtworkLoaded"):Connect(layout); layout()
	return true
end

return Layers
