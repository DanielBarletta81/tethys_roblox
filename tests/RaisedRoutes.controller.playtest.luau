-- Disposable Client Play probe. Supply local targetData from a Server geometry
-- snapshot: {RouteId=...,Targets={{Name=...,Point={x,y,z}},...}}.
-- A Client GetChildren snapshot omits distant streamed Parts and is invalid.
-- Place the character at the route's start separately; that relocation is assisted.
-- MoveTo exercises the native avatar along floor endpoints, without jumping,
-- teleporting between targets, or writing authoritative progression attributes.
local player = game.Players.LocalPlayer
assert(targetData and type(targetData.RouteId)=="string" and #targetData.Targets>0,"Server target snapshot required")
local character = assert(player.Character)
local human, root = character.Humanoid, character.HumanoidRootPart
local targets = {}
for _, target in ipairs(targetData.Targets) do
	table.insert(targets,{Name=target.Name,Point=Vector3.new(table.unpack(target.Point))})
end
player:SetAttribute("RouteWalkProbe", "RUNNING")
player:SetAttribute("RouteWalkRoute", targetData.RouteId)
player:SetAttribute("RouteWalkFailure", nil)
player:SetAttribute("RouteWalkSeconds", nil)
player:SetAttribute("RouteWalkCompletedTargets", 0)
task.spawn(function()
	local started = os.clock()
	local function fail(message)
		human:MoveTo(root.Position)
		player:SetAttribute("RouteWalkFailure", message.." at "..tostring(root.Position))
		player:SetAttribute("RouteWalkProbe", "BLOCKED")
	end
	for index, target in ipairs(targets) do
		local at, previous, lastProgress = os.clock(), math.huge, os.clock()
		while true do
			if player.Character ~= character or human.Health <= 0 then fail("Character lost"); return end
			local offset = root.Position-target.Point
			local distance = Vector3.new(offset.X,0,offset.Z).Magnitude
			if distance < 2 then
				if offset.Y < 1 or offset.Y > 7 or human.FloorMaterial == Enum.Material.Air then
					fail("No supported arrival at "..target.Name); return
				end
				break
			end
			if distance < previous-0.5 then previous=distance; lastProgress=os.clock() end
			if os.clock()-lastProgress > 4 or os.clock()-at > 14 then fail(target.Name); return end
			human:MoveTo(target.Point)
			task.wait(0.2)
		end
		player:SetAttribute("RouteWalkCompletedTargets", index)
	end
	human:MoveTo(root.Position)
	player:SetAttribute("RouteWalkSeconds", os.clock()-started)
	player:SetAttribute("RouteWalkProbe", "PASS")
end)
return "Assisted native controller probe started: "..targetData.RouteId..", "..#targets.." targets"
