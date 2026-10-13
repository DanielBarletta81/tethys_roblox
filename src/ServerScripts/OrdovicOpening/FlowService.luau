local Math = require(script.Parent.FlowMath)
local Flow = {}
Flow.__index = Flow
function Flow.new(root)
	return setmetatable({Zones = root["03_FlowZones"]:GetChildren()}, Flow)
end
function Flow:Clear(state)
	if state.Force then state.Force:Destroy(); state.Force = nil end
	if state.FlowAttachment then state.FlowAttachment:Destroy(); state.FlowAttachment = nil end
end
function Flow:Step(state)
	local root, humanoid = state.Root, state.Humanoid
	if state.Captured or state.Landed or humanoid.Health <= 0 then self:Clear(state); return nil end
	local zone = Math.Select(self.Zones, root.Position, state.Choice == "DOWNSTREAM")
	if not zone then self:Clear(state); return nil end
	if not state.Force then
		local attachment = Instance.new("Attachment")
		attachment.Name = "OrdovicFlowAttachment"; attachment.Parent = root
		local force = Instance.new("VectorForce")
		force.Name = "OrdovicCurrent"; force.Attachment0 = attachment
		force.RelativeTo = Enum.ActuatorRelativeTo.World; force.ApplyAtCenterOfMass = true
		force.Parent = root
		state.FlowAttachment, state.Force = attachment, force
	end
	state.Force.Force = Math.Acceleration(zone.CFrame.LookVector, root.AssemblyLinearVelocity,
		zone:GetAttribute("FlowSpeed"), zone:GetAttribute("ResponseTime")) * root.AssemblyMass
	return zone:GetAttribute("PhaseName")
end
return Flow
