local RunService = game:GetService("RunService")
local Stryker = {}
Stryker.__index = Stryker
function Stryker.new(root)
	local scene = root["04_StrykerSequence"]
	return setmetatable({Rig = scene.StrykerSilhouetteProxy, Shadow = scene.ShadowProxy,
		Origin = scene.StrykerSilhouetteProxy:GetPivot(), Busy = false}, Stryker)
end
function Stryker:Trigger(state)
	if state.StrykerSeen then return end
	state.StrykerSeen = true
	state.Player:SetAttribute("WB_StrykerFirstPass", true)
	if self.Busy then return end
	self.Busy = true
	task.spawn(function()
		-- Graybox silhouette only. Authored shriek/wing assets remain pending.
		self.Shadow.Transparency = 0.65
		task.wait(1.4)
		self.Shadow.Transparency = 1
		task.wait(1.2)
		for _, part in ipairs(self.Rig:GetChildren()) do if part:IsA("BasePart") then part.Transparency = 0 end end
		local start = os.clock()
		repeat
			local t = (os.clock() - start) / 7
			self.Rig:PivotTo(self.Origin * CFrame.new(-120 + t * 240, math.sin(t * math.pi) * 12, 0))
			RunService.Heartbeat:Wait()
		until os.clock() - start >= 7
		for _, part in ipairs(self.Rig:GetChildren()) do if part:IsA("BasePart") then part.Transparency = 1 end end
		self.Rig:PivotTo(self.Origin); self.Busy = false
	end)
end
return Stryker
