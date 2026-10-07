-- Isolated engine fixture: owns its ground, kit and prompts; changes no live camp.
local folder = Instance.new("Folder"); folder.Name, folder.Parent = "CampPromptFixture", workspace
local modules = Instance.new("Folder"); modules.Parent = folder
for _, name in ipairs({"RestService", "CampRestKit"}) do game.ServerScriptService.DeathExperience[name]:Clone().Parent = modules end
local Kit, Rest = require(modules.CampRestKit), require(modules.RestService)
local results = {}
local function test(name, fn)
	local ok, err = pcall(fn); table.insert(results, {name=name, passed=ok, error=not ok and tostring(err) or nil})
	assert(ok, name .. ": " .. tostring(err))
end
local ok, err = pcall(function()
	local floor = Instance.new("Part"); floor.Size, floor.Position, floor.Anchored, floor.Parent = Vector3.new(40,4,40), Vector3.new(8400,500,8400), true, folder
	local site = Instance.new("Folder"); site.Name, site.Parent = "AlphaCampBuild", folder; Rest.Register(site, "Camp_A_CreekShelf")
	local anchor = Instance.new("Part"); anchor.Name, anchor.Anchored, anchor.CanCollide, anchor.Parent = "BuildAnchor_RestSpot", true, false, site
	local prompt = Instance.new("ProximityPrompt"); prompt.Name, prompt.Parent = "RestAtCampPrompt", anchor
	test("Costs describe the actual six kit choices", function()
		assert(Kit.Description("Shelter") == "Covered shelter · 1 fiber + 1 stone")
		assert(Kit.Description("HeatPit") == "Heat pit · 1 fiber + 2 stone")
		for kind, spec in pairs(Kit.Specs) do
			local label = Kit.Description(kind)
			for material, amount in pairs(spec.cost) do assert(label:find(amount .. " " .. material:lower(), 1, true)) end
		end
	end)
	test("An unfinished camp does not invite a Rest claim", function()
		assert(not Kit.RefreshRest(site, "Camp_A_CreekShelf") and not prompt.Enabled)
	end)
	for kind in pairs(Kit.Specs) do Kit.Build(site, kind, Kit.Anchor(floor, kind)) end
	task.wait()
	test("An assembled dry camp explains the missing water but cannot grant Rest", function()
		assert(not Kit.RefreshRest(site, "Camp_A_CreekShelf"))
		assert(prompt.Enabled and prompt.ActionText == "Check Rest" and prompt.ObjectText == "Store water before settling here.")
		assert(site:GetAttribute("WB_RestReady") == false and not Rest.Claim({UserId=-2608}, site))
	end)
	test("Water and heat produce a quiet ready prompt with a readable location", function()
		site.Built_WaterBasin.Basin:SetAttribute("StoredWater", 1)
		assert(Kit.RefreshRest(site, "Camp_A_CreekShelf"), site:GetAttribute("WB_RestStatus"))
		assert(prompt.ActionText == "Rest until morning" and prompt.ObjectText == "Creek Shelf")
		assert(site:GetAttribute("WB_RestReady") == true)
	end)
	test("Cooling or damaged cover returns to Check Rest without granting a claim", function()
		site.Built_HeatPit.Heat:SetAttribute("WarmUntil", 0)
		assert(not Kit.RefreshRest(site, "Camp_A_CreekShelf") and prompt.Enabled)
		assert(prompt.ObjectText == "The heat needs fuel." and not Rest.Claim({UserId=-2608}, site))
		site.Built_HeatPit.Heat:SetAttribute("WarmUntil", os.clock()+600)
		site.Built_Shelter.Cover:SetAttribute("WB_Condition", 0)
		assert(not Kit.RefreshRest(site, "Camp_A_CreekShelf") and prompt.ActionText == "Check Rest")
		assert(not Rest.Claim({UserId=-2608}, site))
	end)
	Rest.Unregister(site)
end)
folder:Destroy(); assert(ok, tostring(err))
return results
