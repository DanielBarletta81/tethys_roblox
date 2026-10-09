--!strict
local Grid=require(script.Parent.ChunkGrid)
local Codec=require(script.Parent.VoxelCodec)
local Text=require(script.Parent.Base64)
local Capture=require(script.Parent.Capture)
local Storage={Generator="StratumArchive",Version="0.1.0"}
local function vector(b: any,dimensions: boolean): Vector3
	return if dimensions then Vector3.new(b.Width,b.Height,b.Length) else Vector3.new(b.X,b.Y,b.Z)
end
function Storage.Prepare(capture: any,id: string): Folder
	local stats=Capture.Validate(capture)
	assert(type(id)=="string" and #id>0 and #id<=96,"Invalid archive ID")
	local archive=Instance.new("Folder");archive.Name="Archive_"..id
	for key,value in pairs({Generator=Storage.Generator,Version=Storage.Version,ArchiveId=id,Format="STV1",Resolution=4,
		ChunkCount=stats.Chunks,VoxelCount=stats.Voxels,EncodedBytes=stats.EncodedBytes,StoredTextBytes=stats.StoredTextBytes}) do archive:SetAttribute(key,value) end
	archive:SetAttribute("BoundsMin",vector(capture.Bounds,false));archive:SetAttribute("BoundsSize",vector(capture.Bounds,true))
	for _,record in ipairs(capture.Chunks) do
		local node=Instance.new("StringValue");node.Name=Grid.Key(record.Bounds);node.Value=record.Text
		node:SetAttribute("BoundsMin",vector(record.Bounds,false));node:SetAttribute("BoundsSize",vector(record.Bounds,true));node.Parent=archive
	end
	return archive
end
function Storage.Read(archive: Instance): any
	assert(archive:IsA("Folder") and archive:GetAttribute("Generator")==Storage.Generator and archive:GetAttribute("Format")=="STV1","Select a Stratum archive")
	local id=archive:GetAttribute("ArchiveId")
	assert(type(id)=="string" and #id>0 and #id<=96 and archive.Name=="Archive_"..id,"Archive identity mismatch")
	local low,size=archive:GetAttribute("BoundsMin"),archive:GetAttribute("BoundsSize")
	assert(typeof(low)=="Vector3" and typeof(size)=="Vector3","Missing archive bounds")
	local bounds={X=low.X,Y=low.Y,Z=low.Z,Width=size.X,Height=size.Y,Length=size.Z}
	local plan=Grid.Plan(bounds);assert(#archive:GetChildren()==#plan,"Unexpected archive children")
	local capture={Bounds=bounds,Chunks={}}
	for _,b in ipairs(plan) do
		local node=archive:FindFirstChild(Grid.Key(b))
		assert(node and node:IsA("StringValue") and node:GetAttribute("BoundsMin")==vector(b,false) and node:GetAttribute("BoundsSize")==vector(b,true),"Missing or misplaced chunk")
		local data=Text.Decode(node.Value);Codec.Decode(data)
		table.insert(capture.Chunks,{Bounds=b,Data=data,Text=node.Value})
	end
	capture.Stats=Capture.Validate(capture)
	for key,field in pairs({ChunkCount="Chunks",VoxelCount="Voxels",EncodedBytes="EncodedBytes",StoredTextBytes="StoredTextBytes"}) do
		assert(archive:GetAttribute(key)==capture.Stats[field],"Archive summary differs from payload")
	end
	assert(archive:GetAttribute("Resolution")==4,"Unknown voxel resolution")
	return capture
end
return Storage
