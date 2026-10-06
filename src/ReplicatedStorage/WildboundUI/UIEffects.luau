local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Effects = {}
Effects.__index = Effects

function Effects.Reduced(ui)
	return ui:GetAttribute("WB_ReducedMotion") == true or GuiService.ReducedMotionEnabled
end
function Effects.new(root, ui)
	local self = setmetatable({Root = root, UI = ui, Values = {}, Tweens = {}}, Effects)
	local objects = root:GetDescendants(); table.insert(objects, root)
	for _, object in ipairs(objects) do
		local values = {}
		if object:IsA("GuiObject") then values.BackgroundTransparency = object.BackgroundTransparency end
		if object:IsA("TextLabel") or object:IsA("TextButton") then values.TextTransparency = object.TextTransparency end
		if object:IsA("ImageLabel") or object:IsA("ImageButton") then values.ImageTransparency = object.ImageTransparency end
		if object:IsA("UIStroke") then values.Transparency = object.Transparency end
		if next(values) then self.Values[object] = values end
	end
	return self
end
function Effects:Cancel()
	for _, tween in ipairs(self.Tweens) do tween:Cancel() end
	table.clear(self.Tweens)
end
function Effects:Fade(alpha, duration)
	self:Cancel()
	local time = Effects.Reduced(self.UI) and 0 or (duration or 0)
	for object, values in pairs(self.Values) do
		if object.Parent then
			local goal = {}
			for property, baseline in pairs(values) do goal[property] = baseline + (1 - baseline) * math.clamp(alpha, 0, 1) end
			if time == 0 then for property, value in pairs(goal) do object[property] = value end
			else
				local tween = TweenService:Create(object, TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), goal)
				table.insert(self.Tweens, tween); tween:Play()
			end
		end
	end
end
return Effects
