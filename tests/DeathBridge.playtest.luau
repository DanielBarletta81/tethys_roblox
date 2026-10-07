-- Temporary Script inside the existing OrdovicOpening sandbox; disposable Play session only.
task.wait(3)
local Cordge, Bridge = require(script.Parent.CordgeController), require(script.Parent.ExperienceBridge)
local active = assert(Cordge.Active)
local player = assert(game.Players:GetPlayers()[1])
local character = assert(player.Character)
local root, original = character.HumanoidRootPart, character:GetPivot()
local marker = active.Cave["00_Guides"].CLUE_Cave_DrainCut
local id = marker:GetAttribute("ClueId")
local oldRecord, credited = Bridge.Record, nil
local results = {}
local function check(name, fn)
	local ok, err = pcall(fn); table.insert(results, {name=name, passed=ok, error=not ok and tostring(err) or nil})
	assert(ok, name .. ": " .. tostring(err))
end
local ok, err = pcall(function()
	check("An unobserved clue cannot claim bridge credit", function() assert(not Bridge.Record(player,"Observations","Cordge:Unobserved")) end)
	Bridge.Record = function(...)
		credited = oldRecord(...)
		return credited
	end
	character:PivotTo(CFrame.new(marker.Position+Vector3.new(0,0,8)));root.AssemblyLinearVelocity=Vector3.zero;task.wait(0.35)
	check("Validated native inspection reaches the authoritative ledger", function() assert(active.Inspect(player,marker,marker.Inspect) and credited==true) end)
	check("The same observation cannot earn credit again", function() assert(not oldRecord(player,"Observations","Cordge:"..id)) end)
	check("Inspection alone grants no XP, access or formal knowledge", function()
		assert(player:GetAttribute("WB_PlayerXP")==0 and player:GetAttribute("SC_XP")==0)
		for _,key in ipairs({"Return","Break","Hold","Scour"}) do assert(player:GetAttribute("WB_Knowledge_"..key)==false) end
	end)
end)
Bridge.Record=oldRecord
if player.Character==character then character:PivotTo(original);root.AssemblyLinearVelocity=Vector3.zero end
script:SetAttribute("Results",game:GetService("HttpService"):JSONEncode(results));script:SetAttribute("Complete",true)
assert(ok,tostring(err))
