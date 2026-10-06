local U=require(script.Parent.BuildUtil)
local Scene={}
function Scene.Build(root,plan)
	local guides=U.Folder(root,"00_Guides")
	local intake=U.Folder(root,"06_IntakeWorks")
	local p=plan.Intake
	U.Guide(guides,"GUIDE_OrdovicOpeningOrigin",plan.Source)
	U.Guide(guides,"GUIDE_IntakeCatch",p)
	U.Guide(guides,"GUIDE_IntakeLanding",p+Vector3.new(17,10,16))
	local direction=(plan.Bypass[2]-plan.Bypass[1]).Unit
	U.Guide(guides,"GUIDE_BypassMouth",plan.Bypass[1]+direction*10+Vector3.new(0,5,0))
	U.Guide(guides,"GUIDE_RefusalLowerPool",plan.Bypass[2]+(plan.Bypass[3]-plan.Bypass[2]).Unit*20+Vector3.new(0,5,0))
	local platform=U.Part(intake,"IntakeLanding",Vector3.new(38,6,40),CFrame.new(p+Vector3.new(22,4,16)),Enum.Material.Cobblestone,Color3.fromRGB(95,96,78))
	local grateCF=CFrame.lookAt(p,plan.Main[#plan.Main-1])
	for i=-3,3 do U.Part(intake,"GrateBar_"..i,Vector3.new(1.6,18,2),grateCF*CFrame.new(i*4,2,-13),Enum.Material.Wood,Color3.fromRGB(65,60,46)) end
	U.Part(intake,"GrateHeader",Vector3.new(32,4,5),grateCF*CFrame.new(0,11,-13),Enum.Material.Cobblestone)
	for i=1,5 do U.Part(intake,"CutStone_"..i,Vector3.new(7,12,11),CFrame.new(p+Vector3.new(25,0,-(i*12))),Enum.Material.Cobblestone) end
	local line=U.Part(intake,"CrewLine",Vector3.new(0.8,0.8,20),CFrame.new(p+Vector3.new(5,6,6))*CFrame.Angles(math.rad(20),0,0),Enum.Material.Fabric,Color3.fromRGB(146,127,87),false)
	local function prompt(name,object,action,key,button,offset)
		local part=U.Part(intake,name,Vector3.new(1,1,1),CFrame.new(p+offset),nil,nil,false)
		part.Transparency,part.CanQuery=1,false
		local pr=Instance.new("ProximityPrompt")
		pr.Name="ProximityPrompt";pr.ObjectText,pr.ActionText=object,action
		pr.KeyboardKeyCode,pr.GamepadKeyCode=key,button
		pr.HoldDuration,pr.MaxActivationDistance,pr.RequiresLineOfSight=0.65,10,false
		pr.Exclusivity=Enum.ProximityPromptExclusivity.AlwaysShow
		pr.UIOffset=Vector2.new(name=="Prompt_TakeLine" and -110 or 110,0)
		U.Mark(pr);pr.Parent=part;return pr
	end
	prompt("Prompt_TakeLine","Intake Crew","Take the line",Enum.KeyCode.E,Enum.KeyCode.ButtonX,Vector3.new(4,3,0))
	prompt("Prompt_BreakFree","Downstream","Break free",Enum.KeyCode.Q,Enum.KeyCode.ButtonB,Vector3.new(-4,3,0))
	local sequence=U.Folder(root,"04_StrykerSequence")
	local rig=Instance.new("Model");rig.Name="StrykerSilhouetteProxy";U.Mark(rig);rig.Parent=sequence
	local pos=plan.Main[5]+Vector3.new(0,70,0)
	local body=U.Part(rig,"Body",Vector3.new(3,3,13),CFrame.new(pos),Enum.Material.SmoothPlastic,Color3.fromRGB(29,33,31),false)
	body.Shape=Enum.PartType.Ball
	for _,sign in ipairs({-1,1}) do
		U.Part(rig,"Wing_"..sign,Vector3.new(25,0.6,8),CFrame.new(pos+Vector3.new(sign*14,0,1))*CFrame.Angles(0,0,sign*0.08),Enum.Material.SmoothPlastic,body.Color,false)
	end
	U.Part(rig,"Beak",Vector3.new(1.4,1.4,9),CFrame.new(pos+Vector3.new(0,0,-10)),Enum.Material.SmoothPlastic,body.Color,false)
	rig.PrimaryPart=body
	local shadow=U.Part(sequence,"ShadowProxy",Vector3.new(52,0.1,12),CFrame.new(plan.Main[5]+Vector3.new(0,6,0)),Enum.Material.SmoothPlastic,Color3.new(0,0,0),false)
	shadow.Transparency=1
	for _,o in ipairs(rig:GetDescendants()) do if o:IsA("BasePart") then o.Transparency=1 end end
	sequence:SetAttribute("AudioPending",true)
	sequence:SetAttribute("ProxyArt",true)
	-- A short stepped rock face makes the last loss of height visibly irreversible.
	U.Part(root["07_RejectCascade"],"FinalDropFace",Vector3.new(65,44,10),CFrame.new(plan.Landing+Vector3.new(0,14,-35)),Enum.Material.Rock)
	return platform
end
return Scene
