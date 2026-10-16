-- The slide needs Physics state to avoid the walking controller braking to a stop.
local Ride = {}
function Ride.Enter(state)
	if state.RideMovement then return end
	local h = state.Humanoid
	state.RideMovement = {h.PlatformStand, h.AutoRotate}
	h.PlatformStand = true; h.AutoRotate = false
	h:ChangeState(Enum.HumanoidStateType.Physics)
	state.RideServerOwned = pcall(function() state.Root:SetNetworkOwner(nil) end)
	state.RideStarted = os.clock()
end
function Ride.Clear(state)
	if not state.RideMovement then return end
	local h = state.Humanoid
	if h.Parent then
		h.PlatformStand, h.AutoRotate = unpack(state.RideMovement)
		if h.Health > 0 then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
	end
	if state.Root.Parent and state.RideServerOwned then pcall(function() state.Root:SetNetworkOwnershipAuto() end) end
	state.RideMovement = nil; state.RideServerOwned = nil; state.RideStarted = nil
end
return Ride
