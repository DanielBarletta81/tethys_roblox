--!strict
local Run=game:GetService("RunService")
local History=game:GetService("ChangeHistoryService")
local Selection=game:GetService("Selection")
local Http=game:GetService("HttpService")
local Matrix=require(script.Parent.VoxelMatrix)
local Storage=require(script.Parent.ArchiveStorage)
local Guides=require(script.Parent.R1BGuides)
local Backend={}
local function region(b:any): Region3
	local low=Vector3.new(b.X,b.Y,b.Z);return Region3.new(low,low+Vector3.new(b.Width,b.Height,b.Length))
end
local function ownedRoot(parent:Instance,name:string,generator:string): Instance?
	local root=parent:FindFirstChild(name)
	assert(not root or (root:IsA("Folder") and root:GetAttribute("Generator")==generator),name.." is occupied by unrelated content")
	return root
end
function Backend.new(pluginInstance:any): any
	local backend={}
	function backend.IsEditMode(): boolean return Run:IsEdit() end
	function backend.Yield() task.wait() end
	function backend.Read(b:any): any
		return Matrix.Flatten(workspace.Terrain:ReadVoxelChannels(region(b),4,{"SolidMaterial","SolidOccupancy","LiquidOccupancy"}),b)
	end
	function backend.SelectionBounds(): any
		local selected=Selection:Get()
		assert(#selected==1 and selected[1]:IsA("BasePart"),"Select one bounds Part in Explorer")
		local p=selected[1] :: BasePart
		assert((p.CFrame.RightVector-Vector3.xAxis).Magnitude<0.0001 and (p.CFrame.UpVector-Vector3.yAxis).Magnitude<0.0001,"Use a bounds Part with zero rotation")
		local low,high=p.Position-p.Size/2,p.Position+p.Size/2
		low=Vector3.new(math.floor(low.X/4)*4,math.floor(low.Y/4)*4,math.floor(low.Z/4)*4)
		high=Vector3.new(math.ceil(high.X/4)*4,math.ceil(high.Y/4)*4,math.ceil(high.Z/4)*4)
		return {X=low.X,Y=low.Y,Z=low.Z,Width=high.X-low.X,Height=high.Y-low.Y,Length=high.Z-low.Z}
	end
	local function record(label:string,action:()->any,rollback:()->())
		assert(backend.IsEditMode(),"Stratum authoring requires Edit mode")
		local began,id=pcall(function() return History:TryBeginRecording("StratumEdit",label) end)
		if not began or not id then
			rollback()
			error("Studio declined an Undo recording; nothing changed"..(if began then "" else ": "..tostring(id)))
		end
		local ok,result=pcall(function()
			pluginInstance:SetAttribute("StratumRecording",id)
			return action()
		end)
		if ok then
			local committed,err=pcall(function() History:FinishRecording(id,Enum.FinishRecordingOperation.Commit) end)
			if not committed then ok,result=false,err end
		end
		if not ok then
			pcall(function() History:FinishRecording(id,Enum.FinishRecordingOperation.Cancel) end)
			local restored,err=pcall(rollback)
			pluginInstance:SetAttribute("StratumRecording",nil)
			assert(restored,"Operation and rollback failed: "..tostring(result).."; "..tostring(err))
			error(tostring(result))
		end
		pluginInstance:SetAttribute("StratumRecording",nil)
		return result
	end
	function backend.CancelPending()
		local id=pluginInstance:GetAttribute("StratumRecording")
		if id then History:FinishRecording(id,Enum.FinishRecordingOperation.Cancel);pluginInstance:SetAttribute("StratumRecording",nil) end
	end
	function backend.Publish(capture:any): Folder
		local root=ownedRoot(game.ServerStorage,"StratumArchives",Storage.Generator)
		local archive=Storage.Prepare(capture,Http:GenerateGUID(false))
		local created:Instance?=nil
		return record("Save Stratum Terrain archive",function()
			if not root then root=Instance.new("Folder");root.Name="StratumArchives";root:SetAttribute("Generator",Storage.Generator);created=root;root.Parent=game.ServerStorage end
			archive.Parent=root;Selection:Set({archive});return archive
		end,function() archive:Destroy();if created then created:Destroy() end end)
	end
	function backend.ReadSelected(): any
		local selected=Selection:Get();assert(#selected==1,"Select one archive")
		return Storage.Read(selected[1])
	end
	function backend.CreateGuides(plan:any): Folder
		local generated=workspace:FindFirstChild("Generated")
		assert(not generated or generated:IsA("Folder"),"Workspace.Generated must be a Folder")
		local root=if generated then ownedRoot(generated,"StratumR1B","StratumR1B") else nil
		local pass=Guides.Prepare(plan.Bounds,Http:GenerateGUID(false))
		local madeGenerated,madeRoot:Instance?=nil,nil
		return record("Create R1B planning guides",function()
			if not generated then generated=Instance.new("Folder");generated.Name="Generated";madeGenerated=generated;generated.Parent=workspace end
			if not root then root=Instance.new("Folder");root.Name="StratumR1B";root:SetAttribute("Generator","StratumR1B");madeRoot=root;root.Parent=generated end
			pass.Parent=root;Selection:Set({pass});return pass
		end,function() pass:Destroy();if madeRoot then madeRoot:Destroy() end;if madeGenerated then madeGenerated:Destroy() end end)
	end
	function backend.RemoveSelected()
		local selected=Selection:Get();assert(#selected==1,"Select one archive or planning pass")
		local target=selected[1];local generator=target:GetAttribute("Generator")
		local parent=target.Parent;local root=if generator==Storage.Generator then ownedRoot(game.ServerStorage,"StratumArchives",Storage.Generator)
			elseif generator=="StratumR1B" and workspace:FindFirstChild("Generated") then ownedRoot(workspace.Generated,"StratumR1B","StratumR1B") else nil
		assert(target:IsA("Folder") and root~=nil and parent==root,"Selection is not an owned archive or planning pass")
		if generator==Storage.Generator then Storage.Read(target) else Guides.Validate(target) end
		-- Destroy locks Parent links and loses the native Undo hierarchy. Detach
		-- the original; Studio history retains the instance and its descendants.
		record("Remove selected Stratum content",function() target.Parent=nil end,function()
			if target.Parent==nil then target.Parent=parent end
		end)
	end
	return backend
end
return Backend
