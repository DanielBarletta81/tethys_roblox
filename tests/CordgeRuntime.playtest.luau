-- Run as a temporary Script beneath the approved OrdovicOpening sandbox.
-- Disposable Play session only: moves and kills the first live character.
local Cordge = require(script.Parent.CordgeController)
local active = assert(Cordge.Active, "Bootstrap must start Cordge first")
local cave, player = active.Cave, game.Players:GetPlayers()[1]
local character = assert(player.Character)
local root, humanoid = character.HumanoidRootPart, character.Humanoid
local guides, actor = cave["00_Guides"], cave.Cordge
local results = {}
local function check(name, fn)
	local ok, err = pcall(fn)
	table.insert(results, {name = name, passed = ok, error = not ok and tostring(err) or nil})
end
local function place(marker, offset)
	root.CFrame = CFrame.new(marker.Position + (offset or Vector3.zero))
	root.AssemblyLinearVelocity = Vector3.zero
	task.wait(0.35)
end
local salt, masonry, drain = guides.CLUE_Cave_SaltLine, guides.CLUE_Cave_Masonry, guides.CLUE_Cave_DrainCut
check("startup is idempotent", function() assert(Cordge.Start(cave) == active) end)
check("distant and duplicate observations are rejected", function()
	assert(not active.Inspect(player, salt, salt.Inspect))
	local lower = guides.CLUE_Cave_LowerRoute
	assert(player:GetAttribute("WB_Clue_Cave_LowerRoute") == true)
	assert(not active.Inspect(player, lower, lower.Inspect))
end)
check("unowned targets are rejected", function()
	local unowned = guides.CLUE_Cave_LowerRoute:Clone(); unowned.Parent = workspace.WildboundOpening_Ordovic["90_DEBUG"]
	local accepted = active.Inspect(player, unowned, unowned.Inspect)
	unowned:Destroy(); assert(not accepted)
end)
check("a solid wall blocks server-side inspection", function()
	place(drain, Vector3.new(0, 0, 8))
	local wall = Instance.new("Part"); wall.Size = Vector3.new(6, 8, 2)
	wall.Anchored, wall.CanCollide = true, true
	wall.Position = drain.Position + Vector3.new(0, 0, 4); wall.Parent = cave["01_Collision"]
	local accepted = active.Inspect(player, drain, drain.Inspect)
	wall:Destroy(); assert(not accepted and not player:GetAttribute("WB_Clue_Cave_DrainCut"))
	assert(active.Inspect(player, drain, drain.Inspect))
end)
check("absent Cordge permits observation and stays silent", function()
	actor:SetAttribute("WB_CordgeEnabled", false); place(masonry, Vector3.new(0, 0, 1))
	assert(active.Inspect(player, masonry, masonry.Inspect)); task.wait(0.35)
	assert(player:GetAttribute("WB_CordgePresent") == false)
	assert(player:GetAttribute("WB_CordgeSpeechText") == "")
	assert(not player:GetAttribute("WB_CordgeSeen_CAVE_MASONRY_01"))
end)
check("returning Cordge reacts to the observed clue", function()
	actor:SetAttribute("WB_CordgeEnabled", true); task.wait(0.35)
	assert(player:GetAttribute("WB_CordgeLineId") == "CAVE_MASONRY_01")
end)
check("higher priority salt observation interrupts live speech", function()
	place(salt, Vector3.new(0, 0, 2))
	assert(active.Inspect(player, salt, salt.Inspect)); task.wait(0.35)
	assert(player:GetAttribute("WB_CordgeLineId") == "CAVE_SALT_01")
	assert(active.States[player].Current.Priority == 3)
end)
check("leaving the route clears current speech", function()
	place(workspace.WildboundOpening_Ordovic["00_Guides"].GUIDE_IntakeLanding)
	assert(player:GetAttribute("WB_CordgePresent") == false and player:GetAttribute("WB_CordgeSpeechText") == "")
end)
check("entry plays once across exit and re-entry", function()
	local entry = cave["06_Triggers"].DBG_Cordge_CaveEntry
	place(entry); assert(player:GetAttribute("WB_CordgeLineId") == "CAVE_ENTRY_01")
	place(workspace.WildboundOpening_Ordovic["00_Guides"].GUIDE_IntakeLanding)
	place(entry); assert(player:GetAttribute("WB_CordgeLineId") == nil)
end)
check("inspections award no XP or formal knowledge", function()
	assert(player:GetAttribute("SC_XP") == 0)
	for _, key in ipairs({"Return", "Break", "Hold", "Scour"}) do assert(player:GetAttribute("WB_Knowledge_" .. key) == false) end
end)
check("death clears active speech and presence", function()
	local zone = cave["06_Triggers"].DBG_Cordge_CaveEntry:Clone()
	zone.Name = "TemporaryDeathSpeechProbe"
	zone:SetAttribute("DialogueId", "CAVE_BLOCKED_02"); zone:SetAttribute("Priority", 4)
	zone.Parent = cave["06_Triggers"]; task.wait(0.35)
	assert(player:GetAttribute("WB_CordgeLineId") == "CAVE_BLOCKED_02")
	humanoid.Health = 0; task.wait(0.35); zone:Destroy()
	assert(player:GetAttribute("WB_CordgePresent") == false and player:GetAttribute("WB_CordgeSpeechText") == "")
end)
script:SetAttribute("Results", game.HttpService:JSONEncode(results))
script:SetAttribute("Complete", true)
