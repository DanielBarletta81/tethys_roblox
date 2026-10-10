-- Client Play, isolated presentation inputs. No live progression is changed.
local data = require(game.ReplicatedStorage.WildboundUI.RuntimeData)
local attributes = {WT_WaterStageIndex=0,WT_WaterObjective="Start at Ordovic Source."}
local player = {GetAttribute=function(_,key) return attributes[key] end}
local preview = {GetAttribute=function() return nil end}
local results = {}
local function check(name,fn)
	local ok,err=pcall(fn)
	table.insert(results,{name=name,passed=ok,error=not ok and tostring(err) or nil})
end
check("Opening guidance remains available before arrival",function()
	assert(data.Route(player)=="Follow the Water")
end)
check("Chapter arrival suppresses the stale opening objective",function()
	attributes.WB_Chapter=2
	assert(data.Route(player)==nil)
	assert(data.Profile(player,preview)=="Exploration")
end)
check("An explicit quiet preview still wins",function()
	assert(data.Profile(player,{GetAttribute=function() return "Game1" end})=="Game1")
end)
check("Later active route guidance remains available",function()
	attributes.OL_ObjectiveTrack="Workshop"
	attributes.WOT_NextPull="Inspect the working screen."
	local title,text=data.Route(player)
	assert(title=="Workshop Shift" and text==attributes.WOT_NextPull)
end)
return results
