local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Style = require(script.Parent.Parent.UIStyle)
local Effects = require(script.Parent.Parent.UIEffects)
local Policy = require(script.Parent.Parent.PresentationPolicy)
local Notice = {}
Notice.__index = Notice

function Notice.new(ui)
	local self = setmetatable({ui = ui, stack = ui.Notifications.SF_ToastStack,
		toasts = {}, toastRecords = {}, pendingToasts = {}, recent = {}, seenLocations = {},
		queuedLocations = {}, connections = {}, serial = 0, subtitleToken = 0}, Notice)
	self.banner = ui.LocationUI.FR_LocationBanner
	self.banner.Visible = false
	self.bannerEffects = Effects.new(self.banner, ui)
	self.subtitle = Style.New("Frame", "FR_Subtitle", ui.InteractionUI, {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.77),
		Size = UDim2.new(0.66, 0, 0, 76), Visible = false, ZIndex = 44,
	})
	Style.Panel(self.subtitle); Style.Fit(self.subtitle, 720, 100)
	self.subtitleLabel = Style.Text("TL_Subtitle", self.subtitle, "", UDim2.fromOffset(14, 8), UDim2.new(1, -28, 1, -16), 15)
	self.subtitleLabel.TextXAlignment = Enum.TextXAlignment.Center
	local function connect(signal, fn) table.insert(self.connections, signal:Connect(fn)) end
	connect(ui:GetAttributeChangedSignal("WB_SubtitlesEnabled"), function() self:_refreshSubtitle() end)
	connect(ui:GetAttributeChangedSignal("WB_MenuOpen"), function() self:_refreshSubtitle(); self:_refresh() end)
	connect(ui:GetAttributeChangedSignal("WB_ReturnNoticeActive"), function() self:_refreshSubtitle(); self:_refresh() end)
	connect(ui:GetAttributeChangedSignal("WB_PresentationProfile"), function() self:_refresh() end)
	connect(ui:GetAttributeChangedSignal("WB_ReducedMotion"), function() self:_refreshMotion() end)
	connect(GuiService:GetPropertyChangedSignal("ReducedMotionEnabled"), function() self:_refreshMotion() end)
	connect(self.subtitle:GetPropertyChangedSignal("Visible"), function() self:_refresh() end)
	connect(ui.InteractionUI.FR_PromptBar:GetPropertyChangedSignal("Visible"), function() self:_refresh() end)
	connect(RunService.Heartbeat, function(dt) self:_step(math.min(dt, 0.1)) end)
	connect(ui.Destroying, function() self:Destroy() end)
	self:_refresh()
	return self
end

function Notice:_busy()
	return self.ui:GetAttribute("WB_ReturnNoticeActive") == true or self.ui:GetAttribute("WB_MenuOpen") == true or self.subtitle.Visible or self.ui.InteractionUI.FR_PromptBar.Visible
end
function Notice:_refreshSubtitle()
	if self.dead then return end
	self.subtitle.Visible = self.ui:GetAttribute("WB_SubtitlesEnabled") ~= false
		and self.ui:GetAttribute("WB_MenuOpen") ~= true and self.ui:GetAttribute("WB_ReturnNoticeActive") ~= true
		and os.clock() < (self.subtitleExpires or 0)
end
function Notice:_refreshMotion()
	if self.dead or not Effects.Reduced(self.ui) then return end
	if self.currentLocation then self.bannerEffects:Fade(self.currentLocation.Phase == "Out" and 1 or 0, 0) end
	for _, record in pairs(self.toastRecords) do record.Effects:Fade(record.Leaving and 1 or 0, 0) end
end
function Notice:_refresh()
	if self.dead then return end
	local job, busy = self.currentLocation, self:_busy()
	self.banner.Visible = job ~= nil and not busy and Policy.LocationAllowed(self.ui:GetAttribute("WB_PresentationProfile"), job.Authored)
	if job then
		if busy and not job.Paused then self.bannerEffects:Cancel(); job.Paused = true
		elseif not busy and job.Paused then
			job.Paused = false
			local time = job.Phase == "In" and math.max(0, Policy.RevealFadeIn - job.Elapsed)
				or job.Phase == "Out" and math.max(0, Policy.RevealFadeIn + Policy.RevealHold + Policy.RevealFadeOut - job.Elapsed) or 0
			self.bannerEffects:Fade(job.Phase == "Out" and 1 or 0, time)
		end
	end
	self.stack.Visible = not busy and not job
	for _, toast in ipairs(self.toasts) do
		toast.Visible = self.stack.Visible and Policy.ToastAllowed(self.ui:GetAttribute("WB_PresentationProfile"), toast:GetAttribute("WB_NoticeKind"))
	end
	local transient = job ~= nil or (self.stack.Visible and #self.toasts > 0)
	if self.ui:GetAttribute("WB_TransientBusy") ~= transient then self.ui:SetAttribute("WB_TransientBusy", transient) end
end
function Notice:_removeToast(toast)
	local record = self.toastRecords[toast]
	if record then record.Effects:Cancel(); self.toastRecords[toast] = nil end
	local index = table.find(self.toasts, toast)
	if index then table.remove(self.toasts, index) end
	toast:Destroy()
end
function Notice:_showToast(job)
	local template = self.stack:FindFirstChild("FR_Toast_" .. job.Kind) or self.stack.FR_Toast_Discovery
	local toast = template:Clone()
	self.serial += 1
	toast.Name, toast.LayoutOrder, toast.Visible = "FR_ToastRuntime_" .. self.serial, self.serial, true
	toast:SetAttribute("WB_NoticeKind", job.Kind)
	toast.TL_Title.Text, toast.TL_Message.Text = job.Title, job.Message
	toast.Parent = self.stack
	if job.Kind == "Item" or job.Kind == "Discovery" or job.Kind == "Quest" then
		Style.Icon(job.Kind == "Item" and "Inventory" or job.Kind == "Quest" and "Journal" or "Tracks", "IL_ArtGlyph", toast, UDim2.fromOffset(8, 15), UDim2.fromOffset(42, 42))
		toast.TL_Title.Position, toast.TL_Title.Size = UDim2.fromOffset(60, 8), UDim2.new(1, -72, 0, 20)
		toast.TL_Message.Position, toast.TL_Message.Size = UDim2.fromOffset(60, 31), UDim2.new(1, -72, 0, 33)
	end
	local effects = Effects.new(toast, self.ui)
	self.toastRecords[toast] = {Effects = effects, Remaining = job.Duration, Deadline = job.Deadline}
	table.insert(self.toasts, toast)
	effects:Fade(1, 0); effects:Fade(0, 0.18)
end
function Notice:Toast(kind, title, message, duration)
	if self.dead or type(kind) ~= "string" or type(title) ~= "string" or type(message) ~= "string" or message == "" then return false end
	if not Policy.ToastAllowed(self.ui:GetAttribute("WB_PresentationProfile"), kind) then return false end
	local signature, now = kind .. "|" .. title .. "|" .. message, os.clock()
	if now - (self.recent[signature] or -math.huge) < Policy.DuplicateWindow then return false end
	self.recent[signature] = now
	table.insert(self.pendingToasts, {Kind = kind, Title = title, Message = message,
		Duration = type(duration) == "number" and math.clamp(duration, 2, 6) or Policy.ToastDuration,
		Deadline = now + Policy.ToastQueueLifetime})
	while #self.pendingToasts > Policy.MaxPendingToasts do table.remove(self.pendingToasts, 1) end
	return true
end
function Notice:ClearSubtitle(source)
	if self.dead or (source and source ~= self.lastSubtitleSource) then return end
	self.subtitleToken += 1; self.subtitleExpires = 0
	self.lastSubtitle, self.lastSubtitleSource = nil, nil
	self.subtitleLabel.Text = ""; self.subtitle.Visible = false
end
function Notice:Subtitle(text, source)
	if self.dead or type(text) ~= "string" or text == "" then return end
	local signature = tostring(source) .. "|" .. text
	if signature == self.lastSubtitle and os.clock() - (self.lastSubtitleAt or 0) < 1 then return end
	self.lastSubtitle, self.lastSubtitleAt, self.lastSubtitleSource = signature, os.clock(), source
	self.subtitleToken += 1
	local token = self.subtitleToken
	self.subtitleLabel.Text = text
	local duration = math.clamp(2.5 + #text / 35, 3, 9)
	self.subtitleExpires = os.clock() + duration
	self:_refreshSubtitle()
	task.delay(duration, function() if not self.dead and token == self.subtitleToken then self.subtitle.Visible = false end end)
end
function Notice:Location(title, context, options)
	if self.dead or type(title) ~= "string" or title == "" then return false end
	options = type(options) == "table" and options or {}
	if not Policy.LocationAllowed(self.ui:GetAttribute("WB_PresentationProfile"), options.Authored) then return false end
	local id = options.Id or title:upper()
	if self.seenLocations[id] or self.queuedLocations[id] then return false end
	if self.pendingLocation then self.queuedLocations[self.pendingLocation.Id] = nil end
	self.queuedLocations[id] = true
	self.pendingLocation = {Id = id, Title = title, Context = type(context) == "string" and context or "",
		Icon = options.Icon or Style.Assets.Region(title), Authored = options.Authored == true,
		Deadline = os.clock() + Policy.RevealQueueLifetime}
	return true
end
function Notice:_showLocation(job)
	self.currentLocation, self.pendingLocation = job, nil
	job.Elapsed, job.Phase, job.Paused = 0, "In", false
	self.queuedLocations[job.Id], self.seenLocations[job.Id] = nil, true
	Style.Assets.Apply(self.banner.IL_RegionBadge, job.Icon)
	Style.Assets.ApplyScene(self.banner.IL_SceneAccent, job.Icon)
	self.banner.TL_Kicker.Text, self.banner.TL_LocationName.Text, self.banner.TL_Subtitle.Text = "", job.Title, job.Context
	Style.Layout(self.ui, self.ui.AbsoluteSize)
	self.bannerEffects:Fade(1, 0); self.bannerEffects:Fade(0, Policy.RevealFadeIn)
	self.ui:SetAttribute("WB_LastPresentedTitle", job.Id)
end
function Notice:_step(dt)
	if self.dead then return end
	local now, profile = os.clock(), self.ui:GetAttribute("WB_PresentationProfile")
	for key, at in pairs(self.recent) do if now - at >= Policy.DuplicateWindow then self.recent[key] = nil end end
	for index = #self.pendingToasts, 1, -1 do
		local job = self.pendingToasts[index]
		if now >= job.Deadline or not Policy.ToastAllowed(profile, job.Kind) then table.remove(self.pendingToasts, index) end
	end
	if self.pendingLocation and now >= self.pendingLocation.Deadline then
		self.queuedLocations[self.pendingLocation.Id] = nil; self.pendingLocation = nil
	end
	local job = self.currentLocation
	if job then
		if not self:_busy() then job.Elapsed += dt end
		local duration = Policy.RevealFadeIn + Policy.RevealHold + Policy.RevealFadeOut
		if job.Elapsed >= duration or now >= job.Deadline then
			self.currentLocation = nil; self.banner.Visible = false; self.bannerEffects:Cancel()
		else
			local phase = job.Elapsed < Policy.RevealFadeIn and "In" or job.Elapsed < Policy.RevealFadeIn + Policy.RevealHold and "Hold" or "Out"
			if phase ~= job.Phase then
				job.Phase = phase
				self.bannerEffects:Fade(phase == "Out" and 1 or 0, phase == "Out" and Policy.RevealFadeOut or 0)
			end
		end
	end
	for index = #self.toasts, 1, -1 do
		local toast = self.toasts[index]
		local record = self.toastRecords[toast]
		if record and toast.Visible and self.stack.Visible then record.Remaining -= dt end
		if not record or not toast.Parent or record.Remaining <= 0 or now >= record.Deadline or not Policy.ToastAllowed(profile, toast:GetAttribute("WB_NoticeKind")) then self:_removeToast(toast)
		elseif record.Remaining <= 0.2 and not record.Leaving then record.Leaving = true; record.Effects:Fade(1, 0.2) end
	end
	if not self:_busy() and not self.currentLocation then
		if self.pendingLocation then self:_showLocation(self.pendingLocation)
		else
			while #self.toasts < Policy.VisibleLimit(profile) and #self.pendingToasts > 0 do self:_showToast(table.remove(self.pendingToasts, 1)) end
		end
	end
	self:_refresh()
end
function Notice:Destroy()
	if self.dead then return end
	self.dead = true; self.subtitleToken += 1
	for _, connection in ipairs(self.connections) do connection:Disconnect() end
	self.bannerEffects:Cancel()
	for index = #self.toasts, 1, -1 do self:_removeToast(self.toasts[index]) end
end
return Notice
