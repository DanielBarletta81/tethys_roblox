--!strict
-- STV1 stores actual u16 material IDs and independent f32 solid/liquid occupancy.
local Codec = {Version = 1, HeaderBytes = 24, CellBytes = 10, MaxCells = 32^3}
export type Chunk = {SizeX: number, SizeY: number, SizeZ: number, Materials: {number}, Solid: {number}, Liquid: {number}}
local function integer(n: number, low: number, high: number): boolean
	return type(n) == "number" and n == n and n >= low and n <= high and n % 1 == 0
end
local function volume(x: number, y: number, z: number): number
	assert(integer(x,1,32) and integer(y,1,32) and integer(z,1,32), "Chunk dimensions must be integers from 1 to 32")
	return x*y*z
end
local function occupancy(n: number)
	assert(type(n)=="number" and n==n and n>=0 and n<=1, "Invalid occupancy")
end
local function checksum(data: buffer, start: number, length: number): number
	local a, b = 1, 0
	for i=start,start+length-1 do a=(a+buffer.readu8(data,i))%65521; b=(b+a)%65521 end
	return b*65536+a
end
local function equal(data: buffer, a: number, b: number): boolean
	return buffer.readu16(data,a)==buffer.readu16(data,b)
		and buffer.readu32(data,a+2)==buffer.readu32(data,b+2) and buffer.readu32(data,a+6)==buffer.readu32(data,b+6)
end
function Codec.Encode(chunk: Chunk): buffer
	local n=volume(chunk.SizeX,chunk.SizeY,chunk.SizeZ)
	assert(#chunk.Materials==n and #chunk.Solid==n and #chunk.Liquid==n, "Channel lengths must match dimensions")
	local dense=buffer.create(n*10)
	for i=1,n do
		local m,s,w=chunk.Materials[i],chunk.Solid[i],chunk.Liquid[i]
		assert(integer(m,0,65535), "Material ID must fit u16"); occupancy(s); occupancy(w)
		local p=(i-1)*10
		buffer.writeu16(dense,p,m);buffer.writef32(dense,p+2,s);buffer.writef32(dense,p+6,w)
	end
	local runs=1
	for i=2,n do if not equal(dense,(i-2)*10,(i-1)*10) then runs+=1 end end
	local rle=runs*12<n*10
	local length=if rle then runs*12 else n*10
	local output=buffer.create(24+length)
	buffer.writestring(output,0,"STV1");buffer.writeu8(output,4,1);buffer.writeu8(output,5,if rle then 1 else 0)
	buffer.writeu8(output,6,chunk.SizeX);buffer.writeu8(output,7,chunk.SizeY);buffer.writeu8(output,8,chunk.SizeZ)
	buffer.writeu32(output,12,n);buffer.writeu32(output,16,length)
	if rle then
		local first,offset=0,24
		for i=1,n do
			if i==n or not equal(dense,first,i*10) then
				buffer.writeu16(output,offset,i-first/10);buffer.copy(output,offset+2,dense,first,10)
				first,offset=i*10,offset+12
			end
		end
	else buffer.copy(output,24,dense) end
	buffer.writeu32(output,20,checksum(output,24,length))
	return output
end
function Codec.Decode(data: buffer): Chunk
	assert(typeof(data)=="buffer" and buffer.len(data)>=24 and buffer.len(data)<=24+Codec.MaxCells*10, "Invalid buffer length")
	assert(buffer.readstring(data,0,4)=="STV1" and buffer.readu8(data,4)==1, "Unsupported voxel format")
	assert(buffer.readu8(data,9)==0 and buffer.readu16(data,10)==0, "Reserved header fields must be zero")
	local mode=buffer.readu8(data,5);assert(mode==0 or mode==1, "Unknown encoding mode")
	local x,y,z=buffer.readu8(data,6),buffer.readu8(data,7),buffer.readu8(data,8)
	local n=volume(x,y,z)
	local length=buffer.readu32(data,16)
	assert(buffer.readu32(data,12)==n and buffer.len(data)==24+length, "Inconsistent or truncated chunk")
	assert((mode==0 and length==n*10) or (mode==1 and length%12==0 and length>0 and length<n*10), "Invalid payload length")
	assert(buffer.readu32(data,20)==checksum(data,24,length), "Voxel checksum mismatch")
	local materials,solid,liquid=table.create(n),table.create(n),table.create(n)
	local index,offset=1,24
	while offset<24+length do
		local count=if mode==1 then buffer.readu16(data,offset) else 1
		local p=offset+(if mode==1 then 2 else 0)
		assert(count>0 and index+count-1<=n, "Run exceeds chunk dimensions")
		local m,s,w=buffer.readu16(data,p),buffer.readf32(data,p+2),buffer.readf32(data,p+6)
		occupancy(s);occupancy(w)
		for i=index,index+count-1 do materials[i],solid[i],liquid[i]=m,s,w end
		index+=count;offset+=if mode==1 then 12 else 10
	end
	assert(index==n+1, "Runs do not cover the chunk")
	return {SizeX=x,SizeY=y,SizeZ=z,Materials=materials,Solid=solid,Liquid=liquid}
end
return table.freeze(Codec)
