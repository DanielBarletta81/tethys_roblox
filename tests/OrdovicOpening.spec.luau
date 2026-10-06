-- Run after scoped capability approval. Isolated fixtures stay in ServerStorage.
local modules = game.ServerScriptService.OrdovicOpening
local Math = require(modules.FlowMath)
local Flow = require(modules.FlowService)
local Intake = require(modules.IntakeService)
local Hazard = require(modules.HazardService)
local Checkpoint = require(modules.CheckpointService)
local fixture = Instance.new("Folder")
fixture.Name = "OrdovicOpening_TestFixture"
assert(not game.ServerStorage:FindFirstChild(fixture.Name))
fixture.Parent = game.ServerStorage
local results = {}
local function check(name, action)
	local ok, err = pcall(action)
	table.insert(results, {name = name, passed = ok, error = not ok and tostring(err) or nil})
end
local function zone(name, position, phase, priority)
	local p = Instance.new("Part"); p.Name = name; p.Anchored = true
	p.Size = Vector3.new(20, 20, 40); p.CFrame = CFrame.new(position)
	p:SetAttribute("PhaseName", phase); p:SetAttribute("Priority", priority)
	p:SetAttribute("Active", true); p:SetAttribute("FlowSpeed", 14); p:SetAttribute("ResponseTime", 0.65)
	p.Parent = fixture; return p
end
local main = zone("Main", Vector3.zero, "RAPIDS", 1)
local bypass = zone("Bypass", Vector3.zero, "REJECT_CASCADE", 2)
local function state(position)
	local part = Instance.new("Part"); part.Anchored = true; part.CFrame = CFrame.new(position); part.Parent = fixture
	local attrs = {}
	local player = {SetAttribute = function(_, key, value) attrs[key] = value end, Parent = true}
	local humanoid = {Health = 100, MaxHealth = 100, WalkSpeed = 18, JumpPower = 45, JumpHeight = 6, AutoRotate = true, Parent = true}
	return {Root = part, Humanoid = humanoid, Player = player, Attributes = attrs}
end
local s, other = state(Vector3.zero), state(Vector3.zero)
local intake = setmetatable({Catch = Vector3.zero, Landing = Vector3.new(10, 5, 10), Bypass = bypass}, Intake)
local host = Instance.new("Part"); host.Anchored = true; host.Parent = fixture
local prompt = Instance.new("ProximityPrompt"); prompt.MaxActivationDistance = 10; prompt.Parent = host
check("rotated volume boundaries", function()
	main.CFrame = CFrame.Angles(0, math.pi / 3, 0)
	assert(Math.Contains(main, main.CFrame:PointToWorldSpace(Vector3.new(9.9, 0, 0))))
	assert(not Math.Contains(main, main.CFrame:PointToWorldSpace(Vector3.new(10.1, 0, 0))))
	main.CFrame = CFrame.new()
end)
check("current preserves lateral and vertical velocity", function()
	local force = Math.Acceleration(Vector3.new(0, 0, -1), Vector3.new(8, 3, -4), 14, 0.65)
	assert(force.X == 0 and force.Y == 0 and force.Z < 0)
end)
check("current never brakes faster downstream momentum", function()
	assert(Math.Acceleration(Vector3.new(0, 0, -1), Vector3.new(0, 0, -30), 14, 0.65) == Vector3.zero)
end)
check("current acceleration is bounded", function()
	assert(Math.Acceleration(Vector3.new(0, 0, -1), Vector3.new(0, 0, 100), 14, 0).Magnitude <= 55)
end)
check("main and reject flow are isolated", function()
	assert(Math.Select({main, bypass}, Vector3.zero, false) == main)
	assert(Math.Select({main, bypass}, Vector3.zero, true) == bypass)
	bypass:SetAttribute("Active", false)
	assert(Math.Select({main, bypass}, Vector3.zero, true) == nil)
	bypass:SetAttribute("Active", true)
end)
check("distant player cannot be captured", function()
	s.Root.CFrame = CFrame.new(100, 0, 0)
	assert(not intake:Capture(s)); s.Root.CFrame = CFrame.new()
end)
check("capture preserves movement and keeps players separate", function()
	assert(intake:Capture(s)); assert(s.Humanoid.WalkSpeed == 0)
	assert(s.CaptureAlign and s.CaptureAttachment)
	assert(not other.Captured and other.Humanoid.WalkSpeed == 18)
end)
check("invalid and out-of-range choices do not release capture", function()
	assert(not intake:Choose(s, "INVALID", prompt))
	s.Root.CFrame = CFrame.new(100, 0, 0)
	assert(not intake:Choose(s, "CITY", prompt))
	assert(s.Captured); s.Root.CFrame = CFrame.new()
end)
check("accept restores movement and commits exactly once", function()
	assert(intake:Choose(s, "CITY", prompt))
	assert(s.Humanoid.WalkSpeed == 18 and s.Humanoid.JumpPower == 45 and s.Humanoid.JumpHeight == 6)
	assert(s.Attributes.WildboundOpeningChoice == "CITY" and s.Landed)
	assert(not s.CaptureAlign and not s.CaptureAttachment)
	assert(not intake:Choose(s, "DOWNSTREAM", prompt))
end)
check("reject restores movement and enters survival phase", function()
	assert(intake:Capture(other)); assert(intake:Choose(other, "DOWNSTREAM", prompt))
	assert(other.Humanoid.WalkSpeed == 18 and not other.Captured)
	assert(other.Attributes.WB_CascadeSurvivalFloor == true and other.Attributes.WildboundOpeningChoice == "DOWNSTREAM")
end)
check("death cleanup releases constraints", function()
	local dead = state(Vector3.zero); assert(intake:Capture(dead))
	dead.Humanoid.Health = 0; intake:Release(dead)
	assert(not dead.CaptureAlign and not dead.Captured and dead.Humanoid.WalkSpeed == 18)
end)
check("landing injures living players without healing or resurrection", function()
	local h = {Health = 90, MaxHealth = 100}
	assert(Hazard.ClampAlive(h, 0.4) and h.Health == 40)
	h.Health = 28; assert(Hazard.ClampAlive(h, 0.4) and h.Health == 28)
	h.Health = 0; assert(not Hazard.ClampAlive(h, 0.4) and h.Health == 0)
end)
check("current attachment cleanup outside zones and on death", function()
	local fs = setmetatable({Zones = {main}}, Flow)
	local moving = state(Vector3.zero)
	moving.Root.Anchored = false
	assert(fs:Step(moving) == "RAPIDS" and moving.Force)
	moving.Root.CFrame = CFrame.new(100, 0, 0); fs:Step(moving)
	assert(not moving.Force and not moving.FlowAttachment)
	moving.Root.CFrame = CFrame.new(); fs:Step(moving)
	moving.Humanoid.Health = 0; fs:Step(moving)
	assert(not moving.Force and not moving.FlowAttachment)
end)
check("refusal respawn does not skip an unfinished cascade", function()
	local attrs = {}
	local player = {GetAttribute = function(_, key) return attrs[key] end}
	local root = {["00_Guides"] = {GUIDE_BypassMouth = {Position = Vector3.new(0, 100, 0)},
		GUIDE_RefusalLowerPool = {Position = Vector3.new(0, 90, 40)}, GUIDE_WatcherLanding = {Position = Vector3.new(0, -30, 200)}}}
	local p, done = Checkpoint.RefusalSpawn(root, player)
	assert(p == Vector3.new(0, 100, 0) and not done)
	attrs.WB_OrdovicLowerPoolReached = true
	p, done = Checkpoint.RefusalSpawn(root, player)
	assert(p == Vector3.new(0, 90, 40) and not done)
	attrs.WB_OrdovicCascadeComplete = true
	p, done = Checkpoint.RefusalSpawn(root, player)
	assert(p == Vector3.new(0, -29, 200) and done)
end)
fixture:Destroy()
return results
