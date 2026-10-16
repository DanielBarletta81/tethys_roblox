local Run = game:GetService("RunService")
local Stryker = {}
Stryker.__index = Stryker
function Stryker.new(root)
	return setmetatable({Scene = root["04_StrykerSequence"], Played = false, States = {}}, Stryker)
end
function Stryker:Trigger(state)
	if state.StrykerSeen or state.Humanoid.Health <= 0 then return false end
	state.StrykerSeen = true
	if self.Played then state.Player:SetAttribute("WB_StrykerCrashSeen", true); return true end
	state.Player:SetAttribute("WB_StrykerFirstPass", true)
	self.States[state] = true
	if self.Playing then return true end
	self.Playing = true
	task.spawn(function()
		local scene = self.Scene
		local rig = scene.StrykerSilhouetteProxy
		for _, p in ipairs(rig:GetDescendants()) do if p:IsA("BasePart") then p.Transparency = 0 end end
		local a,b,c = scene.FlyoverStart.Position, scene.FlyoverPass.Position, scene.CrashSite.Position
		local started = os.clock()
		repeat
			local t = math.clamp((os.clock()-started)/6, 0, 1)
			local p = a:Lerp(b,t):Lerp(b:Lerp(c,t),t)
			rig:PivotTo(CFrame.lookAt(p, c + Vector3.new(0,-2,0)) * CFrame.Angles(0,0,-t*0.5))
			Run.Heartbeat:Wait()
		until os.clock()-started >= 6
		rig:PivotTo(scene.CrashSite.CFrame * CFrame.Angles(0,0,math.rad(65)))
		self.Played = true; self.Playing = false
		for observer in pairs(self.States) do
			if observer.Player.Parent and observer.Player.Character == observer.Character and observer.Humanoid.Health > 0 then
				observer.Player:SetAttribute("WB_StrykerCrashSeen", true)
			end
		end
		self.States = {}
	end)
	return true
end
return Stryker
