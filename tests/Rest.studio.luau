-- Engine fixture: uses only its own Parts and an isolated character, never live camps or Terrain.
local results, folder, fake = {}, Instance.new("Folder"), nil
folder.Name = "DeathExperience_RestFixture"
folder.Parent = workspace
-- Fresh module instances prevent an Edit command's require cache from testing an older source.
local modules = Instance.new("Folder"); modules.Name, modules.Parent = "FixtureModules", folder
for _, name in ipairs({"RestService", "CampRestKit"}) do game.ServerScriptService.DeathExperience[name]:Clone().Parent = modules end
local Kit, Rest = require(modules.CampRestKit), require(modules.RestService)
local site = Instance.new("Folder"); site.Name = "AlphaCampBuild"; site.Parent = folder
local function test(name, fn)
	local ok, err = pcall(fn)
	table.insert(results, {name = name, passed = ok, error = not ok and tostring(err) or nil})
	assert(ok, name .. ": " .. tostring(err))
end
local ok, err = pcall(function()
	local plot = Instance.new("Part")
	plot.Name, plot.Size, plot.CFrame, plot.Anchored, plot.Parent = "Plot", Vector3.new(40, 4, 40), CFrame.new(8000, 500, 8000), true, folder
	Rest.Register(site, "FixtureRest")
	local character = Instance.new("Model"); character.Name, character.Parent = "FixtureCharacter", folder
	local root = Instance.new("Part"); root.Name, root.Size, root.Anchored, root.CanCollide, root.Parent = "HumanoidRootPart", Vector3.new(2, 2, 1), true, false, character
	local h = Instance.new("Humanoid"); h.HipHeight, h.Parent = 2, character
	fake = {UserId = -2607, Character = character, Attributes = {}}
	function fake:SetAttribute(name, value) self.Attributes[name] = value end
	test("Unbuilt camp cannot be Rest", function() assert(not Rest.CanUse(site, fake)) end)
	for kind in pairs(Kit.Specs) do Kit.Build(site, kind, Kit.Anchor(plot, kind)) end
	task.wait()
	local sleep, roof, basin, heat = site.Built_RestSpot.SleepPlatform, site.Built_Shelter.Cover, site.Built_WaterBasin.Basin, site.Built_HeatPit.Heat
	root.CFrame = sleep.CFrame + Vector3.new(0, 3, 1)
	test("Non-colliding guides permit interaction; solid walls block it", function()
		local wall = Instance.new("Part"); wall.Size, wall.CFrame, wall.Anchored, wall.CanQuery, wall.Parent = Vector3.new(6, 0.5, 6), sleep.CFrame + Vector3.new(0, 1.5, 0.5), true, true, folder
		wall.CanCollide = false; task.wait(); assert(Rest.InRange(fake, sleep, 10))
		wall.CanCollide = true; task.wait(); assert(not Rest.InRange(fake, sleep, 10)); wall:Destroy()
	end)
	test("Basin must contain water", function() assert(not Rest.CanUse(site, fake)); basin:SetAttribute("StoredWater", 1) end)
	test("Raised sleep and actual overhead cover qualify", function() assert(sleep.Position.Y > plot.Position.Y + plot.Size.Y/2); assert(Rest.CanUse(site, fake)) end)
	test("Missing or steep ground invalidates Rest", function()
		local cf = plot.CFrame; plot.CFrame -= Vector3.new(0, 10, 0); task.wait(); assert(not Rest.CanUse(site, fake))
		plot.CFrame = cf * CFrame.Angles(math.rad(45), 0, 0); task.wait(); assert(not Rest.CanUse(site, fake)); plot.CFrame = cf; task.wait()
	end)
	test("Water surface cannot qualify as supporting ground", function()
		local point = Vector3.new(8200, 504, 8200)
		local region = Region3.new(point-Vector3.new(4,4,4), point+Vector3.new(4,4,4)):ExpandToGrid(4)
		local oldM, oldO = workspace.Terrain:ReadVoxels(region, 4)
		local materials, occupancies = {}, {}
		for x = 1, 2 do materials[x], occupancies[x] = {}, {}; for y = 1, 2 do materials[x][y], occupancies[x][y] = {}, {}; for z = 1, 2 do
			assert(oldM[x][y][z] == Enum.Material.Air and oldO[x][y][z] == 0, "Water fixture requires empty Terrain")
			materials[x][y][z], occupancies[x][y][z] = Enum.Material.Water, 1
		end end end
		local testOK, failure = pcall(function()
			workspace.Terrain:WriteVoxels(region, 4, materials, occupancies)
			local guide = Instance.new("Part"); guide.CFrame, guide.CanCollide, guide.Parent = CFrame.new(point), false, folder
			assert(not Kit.Anchor(guide, "RestSpot")); guide:Destroy()
		end)
		workspace.Terrain:WriteVoxels(region, 4, oldM, oldO)
		assert(testOK, tostring(failure))
	end)
	test("Moved cover invalidates Rest", function() local cf = roof.CFrame; roof.CFrame += Vector3.new(20, 0, 0); task.wait(); assert(not Rest.CanUse(site, fake)); roof.CFrame = cf; task.wait() end)
	test("Broken sleeping platform invalidates Rest", function() sleep:SetAttribute("WB_Condition", 0); assert(not Rest.CanUse(site, fake)); sleep:SetAttribute("WB_Condition", 1) end)
	test("Cold heat invalidates Rest", function() heat:SetAttribute("WarmUntil", 0); assert(not Rest.CanUse(site, fake)); heat:SetAttribute("WarmUntil", os.clock()+600) end)
	test("Distant and dead characters cannot claim", function()
		local cf = root.CFrame; root.CFrame += Vector3.new(50, 0, 0); assert(not Rest.Claim(fake, site)); root.CFrame = cf
		h.Health = 0; assert(not Rest.Claim(fake, site)); h.Health = 100
	end)
	test("Ownership is enforced when a Fieldhold is private", function() site:SetAttribute("OwnerUserId", 10); assert(not Rest.Claim(fake, site)); site:SetAttribute("OwnerUserId", nil) end)
	test("Claim preserves the active Rest through death", function() assert(Rest.Claim(fake, site)); Rest.MarkDeath(fake); assert(fake.Attributes.WB_ActiveRestId == "FixtureRest") end)
	test("Stale character cannot consume pending return", function() assert(not Rest.TryRespawn(fake, Instance.new("Model"))) end)
	test("Return uses raised sleep and consumes the pending death once", function()
		root.CFrame += Vector3.new(50, 0, 0); assert(Rest.TryRespawn(fake, character)); assert((root.Position - sleep.Position).Magnitude < 5)
		assert(not Rest.TryRespawn(fake, character))
	end)
	test("Weather-invalidated Rest falls back without deleting the home", function()
		Rest.MarkDeath(fake); heat:SetAttribute("WarmUntil", 0); assert(not Rest.TryRespawn(fake, character))
		assert(fake.Attributes.WB_RestReturn == "Fallback" and site.Parent and #site:GetChildren() == 6)
	end)
	test("Destroyed Rest falls back cleanly", function() Rest.MarkDeath(fake); site.Parent = nil; assert(not Rest.TryRespawn(fake, character)); site.Parent = folder end)
end)
if fake then Rest.Remove(fake) end
Rest.Unregister(site); folder:Destroy()
assert(ok, tostring(err))
print("Rest engine: " .. #results .. " groups passed")
return results
