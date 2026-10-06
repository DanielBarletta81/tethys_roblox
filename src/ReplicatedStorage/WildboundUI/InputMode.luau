local UserInputService = game:GetService("UserInputService")

local InputMode = {}
InputMode.__index = InputMode

local MODE = {
	Controller = "Controller",
	KeyboardMouse = "KeyboardMouse",
	Touch = "Touch",
}

function InputMode.new()
	local self = setmetatable({}, InputMode)
	self.mode = MODE.KeyboardMouse
	self.changed = Instance.new("BindableEvent")
	self:_bind()
	return self
end

function InputMode:_setMode(nextMode)
	if self.mode == nextMode then
		return
	end
	self.mode = nextMode
	self.changed:Fire(nextMode)
end

function InputMode:_bind()
	local function recompute()
		if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.GamepadEnabled then
			self:_setMode(MODE.Touch)
			return
		end
		if UserInputService.GamepadEnabled then
			self:_setMode(MODE.Controller)
			return
		end
		self:_setMode(MODE.KeyboardMouse)
	end

	recompute()
	UserInputService.LastInputTypeChanged:Connect(function(inputType)
		if inputType.Name:find("Gamepad") then
			self:_setMode(MODE.Controller)
		elseif inputType == Enum.UserInputType.Touch then
			self:_setMode(MODE.Touch)
		elseif inputType == Enum.UserInputType.MouseMovement
			or inputType == Enum.UserInputType.MouseButton1
			or inputType == Enum.UserInputType.Keyboard then
			self:_setMode(MODE.KeyboardMouse)
		end
	end)
	UserInputService.GamepadConnected:Connect(recompute)
	UserInputService.GamepadDisconnected:Connect(recompute)
end

function InputMode:GetMode()
	return self.mode
end

function InputMode:GetInteractGlyph()
	if self.mode == MODE.Controller then
		return "X"
	end
	if self.mode == MODE.Touch then
		return "TAP"
	end
	return "E"
end

function InputMode:GetQuickGlyph(direction)
	if self.mode == MODE.Controller then
		return "D-PAD " .. string.upper(tostring(direction or ""))
	end
	if self.mode == MODE.Touch then
		return "TAP"
	end
	local keyMap = {
		Up = "1",
		Left = "2",
		Right = "3",
		Down = "4",
	}
	return keyMap[direction] or ""
end

function InputMode:GetPauseGlyph()
	if self.mode == MODE.Controller then
		return "MENU"
	end
	if self.mode == MODE.Touch then
		return "PAUSE"
	end
	return "ESC"
end

function InputMode:ModeChangedSignal()
	return self.changed.Event
end

return {
	Mode = MODE,
	new = InputMode.new,
}
