local Intake = {}
Intake.__index = Intake
function Intake.new(root)
	return setmetatable({Catch = root["00_Guides"].GUIDE_IntakeCatch.Position,
		Landing = root["00_Guides"].GUIDE_IntakeLanding.Position,
		Mouth = root["00_Guides"].GUIDE_BypassMouth.Position,
		Bypass = root["03_FlowZones"].FZBypass_1,
		AcceptPrompt = root["06_IntakeWorks"].Prompt_TakeLine.ProximityPrompt,
		RejectPrompt = root["06_IntakeWorks"].Prompt_BreakFree.ProximityPrompt}, Intake)
end
function Intake:Release(state)
	for _, key in ipairs({"CaptureAlign", "CaptureAttachment"}) do
		if state[key] then state[key]:Destroy(); state[key] = nil end
	end
	local h = state.Humanoid
	if state.PriorMovement and h.Parent then
		h.WalkSpeed, h.JumpPower, h.JumpHeight, h.AutoRotate = unpack(state.PriorMovement)
	end
	state.PriorMovement = nil; state.Captured = false
end
function Intake:Capture(state)
	if state.Captured or state.Choice or state.Humanoid.Health <= 0 then return false end
	if (state.Root.Position - self.Catch).Magnitude > 14 then return false end
	state.PriorMovement = {state.Humanoid.WalkSpeed, state.Humanoid.JumpPower,
		state.Humanoid.JumpHeight, state.Humanoid.AutoRotate}
	state.Humanoid.WalkSpeed, state.Humanoid.JumpPower, state.Humanoid.JumpHeight = 0, 0, 0
	local attachment = Instance.new("Attachment"); attachment.Name = "OrdovicIntakeAttachment"; attachment.Parent = state.Root
	local align = Instance.new("AlignPosition"); align.Name = "OrdovicIntakeHold"
	align.Mode = Enum.PositionAlignmentMode.OneAttachment; align.Attachment0 = attachment
	align.Position = self.Catch + Vector3.new(0, 3, 0)
	align.MaxForce, align.MaxVelocity, align.Responsiveness = 100000, 24, 30
	align.Parent = state.Root
	state.CaptureAttachment, state.CaptureAlign, state.Captured = attachment, align, true
	state.Player:SetAttribute("OpeningPhase", "INTAKE_CHOICE")
	state.Player:SetAttribute("WB_IntakeCaptured", true)
	return true
end
function Intake:Choose(state, choice, prompt)
	if not state or not state.Captured or state.Choice or state.Humanoid.Health <= 0 then return false end
	if choice ~= "CITY" and choice ~= "DOWNSTREAM" then return false end
	local expected = choice == "CITY" and self.AcceptPrompt or self.RejectPrompt
	if not expected or prompt ~= expected or not prompt.Enabled then return false end
	if (state.Root.Position - prompt.Parent.Position).Magnitude > prompt.MaxActivationDistance + 2 then return false end
	state.Choice = choice
	self:Release(state)
	state.Player:SetAttribute("WB_IntakeCaptured", false)
	if choice == "CITY" then
		state.Landed = true
		state.Root.CFrame = CFrame.new(self.Landing)
		state.Root.AssemblyLinearVelocity = Vector3.zero
		state.Player:SetAttribute("OpeningPhase", "INTAKE_WORKS")
		state.Player:SetAttribute("WB_OrdovicActive", false)
	else
		local mouth = self.Mouth or self.Bypass.CFrame:PointToWorldSpace(Vector3.new(0, 1, self.Bypass.Size.Z / 2 - 14))
		state.Root.CFrame = CFrame.lookAt(mouth, mouth + self.Bypass.CFrame.LookVector)
		state.Root.AssemblyLinearVelocity = self.Bypass.CFrame.LookVector * 12
		state.Player:SetAttribute("OpeningPhase", "REJECT_CASCADE")
		state.Player:SetAttribute("WB_CascadeSurvivalFloor", true)
	end
	-- Existing Wildbound runtime owns its state. It observes this server-authored decision.
	state.Player:SetAttribute("WildboundOpeningChoice", choice)
	return true
end
return Intake
