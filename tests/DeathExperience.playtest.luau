-- Temporary ModuleScript invoked by the existing server bootstrap, in a disposable Play session.
-- Pass its actual Service/Rest/Kit instances so diagnostics use the native runtime's module cache.
-- Fixtures seed a Rest's supplies; native resource spending is a separate acceptance step.
local Probe = {}
function Probe.Start(Experience, Rest, Kit)
	task.delay(2, function()
		local player = game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
		local character = player.Character or player.CharacterAdded:Wait()
		local root = character:WaitForChild("HumanoidRootPart")
		local folder = Instance.new("Folder"); folder.Name, folder.Parent = "_26G_WalkFixture", workspace
		local floor = Instance.new("Part")
		floor.Name, floor.Size, floor.CFrame, floor.Anchored, floor.Parent = "Floor", Vector3.new(512, 4, 512), CFrame.new(20000, 400, 20000), true, folder
		local area = Instance.new("Part")
		area.Name, area.Size, area.CFrame, area.Anchored = "Area", Vector3.new(512, 50, 512), CFrame.new(20000, 410, 20000), true
		area.CanCollide, area.CanQuery, area.Transparency, area.Parent = false, false, 1, folder
		area:SetAttribute("AreaId", "FixtureRoute"); game:GetService("CollectionService"):AddTag(area, "WB_ExplorationArea")
		local site = Instance.new("Folder"); site.Name, site.Parent = "AlphaCampBuild", folder
		Rest.Register(site, "FixtureRest")
		for kind in pairs(Kit.Specs) do Kit.Build(site, kind, assert(Kit.Anchor(floor, kind))) end
		site.Built_WaterBasin.Basin:SetAttribute("StoredWater", 1)
		character:PivotTo(CFrame.new(site.Built_RestSpot.SleepPlatform.Position + Vector3.new(0, 3.5, 1)))
		root.AssemblyLinearVelocity = Vector3.zero; task.wait(0.5)
		assert(Rest.Claim(player, site), "Fixture Rest must pass production validation")
		folder:SetAttribute("BeforeXP", player:GetAttribute("WB_PlayerXP"))
		folder:SetAttribute("BeforeLegacyXP", player:GetAttribute("SC_XP"))
		for _, key in ipairs({"Return", "Break", "Hold", "Scour"}) do folder:SetAttribute("BeforeKnowledge_" .. key, player:GetAttribute("WB_Knowledge_" .. key)) end
		character:PivotTo(CFrame.new(19840, 406, 20000)); root.AssemblyLinearVelocity = Vector3.zero
		folder:SetAttribute("Ready", true)
		while folder.Parent do
			local state = Experience.States[player]
			local life = state and state.Ledger.Life
			if life then
				folder:SetAttribute("ActiveSeconds", life.Active); folder:SetAttribute("Distance", life.Distance)
				folder:SetAttribute("Cells", life.Cells); folder:SetAttribute("LifeId", life.Id)
			end
			folder:SetAttribute("LedgerXP", state and state.Ledger.XP)
			task.wait(0.5)
		end
	end)
end
return Probe
