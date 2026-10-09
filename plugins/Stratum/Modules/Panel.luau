--!strict
local Selection=game:GetService("Selection")
local Plan=require(script.Parent.R1BPlan)
local Panel={}
function Panel.mount(parent:Instance,session:any,backend:any): any
	local connections,buttons,dead,busy={}, {},false,false
	local root=Instance.new("ScrollingFrame");root.Name="StratumPanel";root.Size=UDim2.fromScale(1,1);root.BackgroundColor3=Color3.fromRGB(24,30,33)
	root.BorderSizePixel=0;root.ScrollBarThickness=6;root.AutomaticCanvasSize=Enum.AutomaticSize.Y;root.CanvasSize=UDim2.new();root.Parent=parent
	local padding=Instance.new("UIPadding");padding.PaddingLeft=UDim.new(0,12);padding.PaddingRight=UDim.new(0,12);padding.PaddingTop=UDim.new(0,12);padding.PaddingBottom=UDim.new(0,12);padding.Parent=root
	local layout=Instance.new("UIListLayout");layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Padding=UDim.new(0,10);layout.Parent=root
	local order=0
	local function label(text:string,height:number): TextLabel
		order+=1;local node=Instance.new("TextLabel");node.LayoutOrder=order;node.Size=UDim2.new(1,0,0,height);node.BackgroundTransparency=1
		node.Font,node.TextSize,node.TextColor3=Enum.Font.Gotham,14,Color3.fromRGB(220,216,201)
		node.TextWrapped,node.TextXAlignment,node.TextYAlignment,node.Text=true,Enum.TextXAlignment.Left,Enum.TextYAlignment.Top,text;node.Parent=root;return node
	end
	label("STRATUM · TERRAIN ARCHIVES + R1B PLANNING",40)
	label("Select one unrotated bounds Part. Preview reads Terrain; Save stores an archive in ServerStorage. R1B creates planning outlines, never Terrain.",80)
	local selectionCaption=label("",44);selectionCaption.Name="Selection"
	local function updateSelection()
		local selected=Selection:Get()
		selectionCaption.Text=if #selected==1 then "Selected: "..selected[1].Name.." ("..selected[1].ClassName..")" else "Selected: "..#selected.." instances; use one bounds Part, archive or guide pass."
	end
	updateSelection()
	local status=label("Ready. Archive selections are limited to 262144 voxels / 64 chunks.",110);status.Name="Status"
	local function refresh()
		for _,button in ipairs(buttons) do button.Active=not busy;button.BackgroundTransparency=if busy then 0.6 else 0 end
	end
	local function run(fn:()->string)
		if busy or dead then return end;busy=true;refresh()
		task.spawn(function()
			local ok,result=pcall(fn)
			if dead then return end
			busy=false;status.Text=if ok then result else tostring(result);refresh()
		end)
	end
	local function button(name:string,caption:string,fn:()->string)
		order+=1;local node=Instance.new("TextButton");node.Name,node.LayoutOrder,node.Size=name,order,UDim2.new(1,0,0,42)
		node.Text,node.TextSize,node.Font=caption,14,Enum.Font.GothamMedium;node.TextColor3=Color3.fromRGB(236,225,201)
		node.BackgroundColor3,node.BorderSizePixel,node.AutoButtonColor=Color3.fromRGB(66,73,75),0,true;node.Parent=root
		table.insert(buttons,node);table.insert(connections,node.Activated:Connect(function() run(fn) end))
	end
	local function summary(capture:any): string
		local s=capture.Stats
		return string.format("%d chunks · %d voxels\nBinary: %d bytes · stored Base64: %d bytes\nDense STV1: %d bytes",s.Chunks,s.Voxels,s.EncodedBytes,s.StoredTextBytes,s.DenseBytes)
	end
	button("PreviewArchive","Preview selected Terrain",function()
		local capture=session:Preview(backend.SelectionBounds(),function(i:number,total:number) if not dead then status.Text=string.format("Capturing chunk %d / %d…",i,total) end end)
		return summary(capture)..string.format("\nCapture: %.3f s. Save rereads Terrain to reject stale snapshots.",capture.Stats.CaptureSeconds)
	end)
	button("SaveArchive","Save preview as archive",function() local archive=session:Publish();return "Saved "..archive.Name.." in ServerStorage.StratumArchives. Terrain is unchanged." end)
	button("InspectArchive","Validate selected archive",function() return summary(backend.ReadSelected()).."\nManifest, bounds, lengths and checksums passed." end)
	label("R1B · SKY CITY / CIMMERIA\nInland -Z; seaward +Z. Select a regional bounds Part (128–2048 studs wide/deep, 64–2048 tall).",70)
	order+=1;local map=Instance.new("Frame");map.Name,map.LayoutOrder,map.Size="R1BPreview",order,UDim2.new(1,0,0,190);map.BackgroundColor3=Color3.fromRGB(39,47,50);map.BorderSizePixel=0;map.Parent=root
	local lastPlan:any=nil
	button("PreviewR1B","Preview R1B zone sketch",function()
		lastPlan=Plan.Create(backend.SelectionBounds());map:ClearAllChildren()
		for _,zone in ipairs(lastPlan.Zones) do
			local frame=Instance.new("TextLabel");frame.Name=zone.Id;frame.Position=UDim2.fromScale(zone.U,zone.V);frame.Size=UDim2.fromScale(zone.W,zone.D)
			frame.BackgroundColor3=Color3.fromRGB(table.unpack(zone.Color));frame.BackgroundTransparency=0.4;frame.BorderSizePixel=1
			frame.Text,frame.TextSize,frame.TextColor3=zone.Id:sub(1,2):gsub("_",""),12,Color3.fromRGB(243,233,214);frame.Parent=map
		end
		return "A Backbone · B Cradle · C Weep · D Exposed ledge · E Working slopes · F Hazard pockets.\nSketch only; shape the land before placing districts."
	end)
	button("CreateR1B","Create R1B planning guides",function()
		assert(lastPlan,"Preview R1B first")
		local current=backend.SelectionBounds()
		for key,value in pairs(lastPlan.Bounds) do assert(current[key]==value,"Bounds moved; preview R1B again") end
		local pass=backend.CreateGuides(lastPlan);return "Created "..pass.Name.." in Workspace.Generated.StratumR1B. Outlines have no collision, triggers or route unlocks."
	end)
	button("RemoveSelected","Remove selected owned archive / guides",function() backend.RemoveSelected();return "Removed selected Stratum content. Terrain and original assets are unchanged." end)
	order+=1;local cancel=Instance.new("TextButton");cancel.Name,cancel.LayoutOrder,cancel.Size,cancel.Text="Cancel",order,UDim2.new(1,0,0,38),"Cancel capture / verification"
	cancel.Font,cancel.TextSize,cancel.TextColor3,cancel.BackgroundColor3=Enum.Font.Gotham,13,Color3.fromRGB(225,216,198),Color3.fromRGB(51,57,59);cancel.Parent=root
	table.insert(connections,cancel.Activated:Connect(function() session:Cancel();if not dead then status.Text="Cancellation requested. No Terrain was written." end end))
	-- Programmatic selection after Save/Create must not erase its success result.
	table.insert(connections,Selection.SelectionChanged:Connect(function() if not dead then updateSelection() end end))
	return function()
		if dead then return end;dead=true;session:Cancel()
		for _,connection in ipairs(connections) do connection:Disconnect() end
		root:Destroy()
	end
end
return Panel
