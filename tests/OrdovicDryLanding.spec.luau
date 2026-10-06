local Controller = require(game.ServerScriptService.OrdovicOpening.Controller)
local results = {}
local function check(name, fn)
	local ok, err = pcall(fn)
	table.insert(results, {name = name, passed = ok, error = not ok and tostring(err) or nil})
end
local movement = Enum.HumanoidStateType.Running
local humanoid = {Health = 100, FloorMaterial = Enum.Material.Slate, GetState = function() return movement end}
local s = {Choice = "DOWNSTREAM", Root = {Position = Vector3.zero}, Humanoid = humanoid}
check("dry grounded refusal can complete", function() assert(Controller.CanLand(s, Vector3.zero)) end)
check("swimming, falling and unsupported arrival cannot complete", function()
	movement = Enum.HumanoidStateType.Swimming; assert(not Controller.CanLand(s, Vector3.zero))
	movement = Enum.HumanoidStateType.Freefall; assert(not Controller.CanLand(s, Vector3.zero))
	movement = Enum.HumanoidStateType.Running; humanoid.FloorMaterial = Enum.Material.Air
	assert(not Controller.CanLand(s, Vector3.zero)); humanoid.FloorMaterial = Enum.Material.Slate
end)
check("arrival must belong to an unfinished living refusal near its landing", function()
	s.Choice = "CITY"; assert(not Controller.CanLand(s, Vector3.zero)); s.Choice = "DOWNSTREAM"
	s.Landed = true; assert(not Controller.CanLand(s, Vector3.zero)); s.Landed = nil
	humanoid.Health = 0; assert(not Controller.CanLand(s, Vector3.zero)); humanoid.Health = 100
	assert(not Controller.CanLand(s, Vector3.new(31, 0, 0)))
	assert(not Controller.CanLand(s, Vector3.new(0, 6, 0)))
end)
return results
