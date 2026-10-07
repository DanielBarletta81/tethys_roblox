-- A quiet, non-modal death cue. No input capture, vignette, shake or defeat screen.
local Style = require(script.Parent.Parent.UIStyle)
local Effects = require(script.Parent.Parent.UIEffects)
local Return = {}
Return.__index = Return
function Return.new(player, ui, onReturn)
	local self = setmetatable({Token = 0, Seen = nil}, Return)
	self.Frame = Style.New("Frame", "FR_ReturnNotice", ui.InteractionUI, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.65),
		Size = UDim2.new(0.9, 0, 0, 82), Visible = false, ZIndex = 48,
	})
	Style.Panel(self.Frame); Style.Fit(self.Frame, 420, 102)
	self.Frame.BackgroundTransparency = 0.22
	local title = Style.Text("TL_ReturnTitle", self.Frame, "Tethys got you.", UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 30), 22)
	title.Font = Style.Theme.Typography.TitleFont
	title.TextXAlignment = Enum.TextXAlignment.Center
	self.Message = Style.Text("TL_ReturnExperience", self.Frame, "", UDim2.fromOffset(12, 43), UDim2.new(1, -24, 0, 25), 15)
	self.Message.TextXAlignment = Enum.TextXAlignment.Center
	self.Message.TextColor3 = Style.Theme.Colors.Ash
	local function layout()
		-- Keep body text readable; a narrow card gets two lines instead of tiny type.
		local narrow = self.Frame.AbsoluteSize.X < 340
		self.Frame.Size = UDim2.new(0.9, 0, 0, narrow and 102 or 82)
		self.Message.Size = UDim2.new(1, -24, 0, narrow and 44 or 25)
	end
	self.LayoutConnection = self.Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	layout()
	self.Effects = Effects.new(self.Frame, ui)
	local function show()
		local revision = player:GetAttribute("WB_DeathExperienceRevision")
		if type(revision) ~= "number" or revision == self.Seen then return end
		self.Seen, self.Token = revision, self.Token + 1
		if onReturn then onReturn() end
		local token = self.Token
		local amount = player:GetAttribute("WB_DeathExperience")
		self.Message.Text = type(amount) == "number" and amount > 0
			and string.format("+%d Experience — exploration", amount) or "Experience carried forward."
		self.Frame.Visible = true
		ui:SetAttribute("WB_ReturnNoticeActive", true)
		self.Effects:Fade(1, 0); self.Effects:Fade(0, 0.2)
		task.delay(5.8, function()
			if self.Token ~= token or not self.Frame.Parent then return end
			self.Effects:Fade(1, 0.2)
			task.delay(0.2, function()
				if self.Token ~= token or not self.Frame.Parent then return end
				self.Frame.Visible = false; ui:SetAttribute("WB_ReturnNoticeActive", false)
			end)
		end)
	end
	self.Connection = player:GetAttributeChangedSignal("WB_DeathExperienceRevision"):Connect(show)
	local function reduced()
		if self.Frame.Visible and Effects.Reduced(ui) then self.Effects:Fade(0, 0) end
	end
	self.MotionConnection = ui:GetAttributeChangedSignal("WB_ReducedMotion"):Connect(reduced)
	self.SystemMotionConnection = game:GetService("GuiService"):GetPropertyChangedSignal("ReducedMotionEnabled"):Connect(reduced)
	self.DestroyConnection = ui.Destroying:Connect(function()
		self.Token += 1; self.Connection:Disconnect(); self.MotionConnection:Disconnect(); self.SystemMotionConnection:Disconnect(); self.LayoutConnection:Disconnect(); self.Effects:Cancel()
	end)
	show()
	return self
end
return Return
