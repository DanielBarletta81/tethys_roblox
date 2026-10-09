--!strict
local Grid=require(if script then script.Parent.ChunkGrid else "./ChunkGrid")
local Codec=require(if script then script.Parent.VoxelCodec else "./VoxelCodec")
local Text=require(if script then script.Parent.Base64 else "./Base64")
local Capture={}
function Capture.Validate(capture: any): any
	assert(type(capture)=="table" and type(capture.Bounds)=="table" and type(capture.Chunks)=="table","Invalid capture")
	local plan=Grid.Plan(capture.Bounds)
	assert(#plan==#capture.Chunks,"Chunk count differs from the bounded grid")
	local bytes,textBytes,voxels=0,0,0
	for i,bounds in ipairs(plan) do
		local record=capture.Chunks[i]
		for key,value in pairs(bounds) do assert(record.Bounds[key]==value,"Chunk bounds differ from manifest") end
		local chunk=Codec.Decode(record.Data)
		assert(chunk.SizeX==bounds.Width/4 and chunk.SizeY==bounds.Height/4 and chunk.SizeZ==bounds.Length/4,"Chunk dimensions differ from manifest")
		assert(type(record.Text)=="string" and buffer.tostring(Text.Decode(record.Text))==buffer.tostring(record.Data),"Stored text differs from binary data")
		bytes+=buffer.len(record.Data);textBytes+=#record.Text;voxels+=chunk.SizeX*chunk.SizeY*chunk.SizeZ
	end
	return {Chunks=#plan,Voxels=voxels,EncodedBytes=bytes,StoredTextBytes=textBytes,DenseBytes=voxels*10+#plan*24}
end
return Capture
