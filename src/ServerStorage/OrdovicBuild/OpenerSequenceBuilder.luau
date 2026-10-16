local U = require(script.Parent.BuildUtil)
local Sequence = {}
function Sequence.Build(root)
	local scene, zone = root["04_StrykerSequence"], root["03_FlowZones"].FZMain_5
	for name, offset in pairs({FlyoverStart = Vector3.new(-90, 38, 45),
		FlyoverPass = Vector3.new(0, 24, -20), CrashSite = Vector3.new(30, 6, -90)}) do
		local guide = U.Guide(scene, name, zone.CFrame:PointToWorldSpace(offset))
		guide.CFrame = zone.CFrame * CFrame.new(offset)
	end
	local crash = scene.CrashSite
	local shelf = U.Part(scene, "CrashShelf", Vector3.new(26, 6, 32),
		crash.CFrame * CFrame.new(0, -5, 0), Enum.Material.Slate)
	shelf:SetAttribute("ProxyArt", true)
	local cage = U.Folder(root["06_IntakeWorks"], "RescueCageProxy")
	cage:SetAttribute("ProxyArt", true)
	local catch = root["00_Guides"].GUIDE_IntakeCatch.CFrame
	-- Open upstream face; the player is held by the existing intake owner.
	U.Part(cage, "Floor", Vector3.new(12, 1, 12), catch * CFrame.new(0, -3, 0), Enum.Material.WoodPlanks, nil, false)
	for _, x in ipairs({-6, 6}) do for _, z in ipairs({-6, 6}) do
		U.Part(cage, "Post_" .. x .. "_" .. z, Vector3.new(0.6, 13, 0.6),
			catch * CFrame.new(x, 3, z), Enum.Material.Wood, nil, false)
	end end
	U.Part(cage, "HoistFrame", Vector3.new(13, 1, 13), catch * CFrame.new(0, 10, 0), Enum.Material.Wood, nil, false)
	local accept = root["06_IntakeWorks"].Prompt_TakeLine.ProximityPrompt
	accept.ObjectText = "Rescue cage"; accept.ActionText = "Take the rescue"
	root["06_IntakeWorks"].Prompt_BreakFree.ProximityPrompt.ActionText = "Continue downstream"
	scene:SetAttribute("CrashProxy", true)
	scene:SetAttribute("AudioPending", true)
end
return Sequence
