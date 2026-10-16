local Math = require(script.Parent.FlowMath)
local Ride = require(script.Parent.FlumeRide)
local Flow = {}
Flow.__index = Flow
function Flow.new(root)
	return setmetatable({Zones = root["03_FlowZones"]:GetChildren()}, Flow)
end
function Flow:Clear(state)
	Ride.Clear(state)
	if state.Force then state.Force:Destroy(); state.Force = nil end
	if state.FlowAttachment then state.FlowAttachment:Destroy(); state.FlowAttachment = nil end
end
function Flow:Step(state)
	local root, humanoid = state.Root, state.Humanoid
	if state.Captured or state.Landed or humanoid.Health <= 0 then self:Clear(state); return nil end
	local zone = Math.Select(self.Zones, root.Position, state.Choice == "DOWNSTREAM")
	if not zone then self:Clear(state); state.FlumeRecovery = nil; return nil end
	local sliding = zone:GetAttribute("PhaseName") == "FLUME_DROP"
	if sliding then
		if state.RideStarted and os.clock() - state.RideStarted > 8 then
			state.FlumeRecovery = true; self:Clear(state); return nil
		end
		if state.FlumeRecovery then self:Clear(state); return nil end
		Ride.Enter(state)
	else Ride.Clear(state); state.FlumeRecovery = nil end
	-- River volumes include dry banks. Only the flume owns force on dry slide footing.
	if zone:GetAttribute("PhaseName") ~= "FLUME_DROP" and humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then
		self:Clear(state); return nil
	end
	local speed = zone:GetAttribute("FlowSpeed")
	if speed <= 0 then self:Clear(state); return zone:GetAttribute("PhaseName") end
	if not state.Force then
		local attachment = Instance.new("Attachment")
		attachment.Name = "OrdovicFlowAttachment"; attachment.Parent = root
		local force = Instance.new("LinearVelocity")
		force.Name = "OrdovicCurrent"; force.Attachment0 = attachment
		force.RelativeTo = Enum.ActuatorRelativeTo.World
		force.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
		force.ForceLimitsEnabled = true
		force.Parent = root
		state.FlowAttachment, state.Force = attachment, force
	end
	-- One constrained axis leaves lateral steering free. Faster downstream momentum
	-- coasts without braking, allowing native drag to settle into the next reach.
	local direction = zone.CFrame.LookVector
	state.Force.LineDirection = direction
	state.Force.LineVelocity = speed
	state.Force.MaxForce = root.AssemblyMass * (sliding and 650 or 500)
	state.Force.Enabled = root.AssemblyLinearVelocity:Dot(direction) < speed
	return zone:GetAttribute("PhaseName")
end
return Flow
