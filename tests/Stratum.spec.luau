-- Portable tests of the real format, grid, R1B plan and capture lifecycle.
local Codec=require("../plugins/Stratum/Modules/VoxelCodec")
local Text=require("../plugins/Stratum/Modules/Base64")
local Grid=require("../plugins/Stratum/Modules/ChunkGrid")
local Plan=require("../plugins/Stratum/Modules/R1BPlan")
local Session=require("../plugins/Stratum/Modules/Session")
local results={}
local function test(name,fn) local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));table.insert(results,{name=name,passed=true});print("PASS "..name) end
local function denied(fn) local ok=pcall(fn);assert(not ok,"Expected rejection") end
local function chunk(x,y,z,diverse)
	local n=x*y*z;local m,s,w={},{},{}
	for i=1,n do m[i]=if diverse then 256+i%3000 else 512;s[i]=if diverse then (i%4)/4 else 0;w[i]=if diverse then ((i+1)%4)/4 else 0 end
	return {SizeX=x,SizeY=y,SizeZ=z,Materials=m,Solid=s,Liquid=w}
end
local function copy(data) local out=buffer.create(buffer.len(data));buffer.copy(out,0,data);return out end
local function rechecksum(data)
	local a,b=1,0;for i=24,buffer.len(data)-1 do a=(a+buffer.readu8(data,i))%65521;b=(b+a)%65521 end;buffer.writeu32(data,20,b*65536+a)
end
test("Full material IDs and independent solid/water survive a dense round trip",function()
	local input=chunk(3,2,4,true);local data=Codec.Encode(input);local output=Codec.Decode(data)
	assert(buffer.readu8(data,5)==0)
	for i=1,24 do assert(output.Materials[i]==input.Materials[i] and output.Solid[i]==input.Solid[i] and output.Liquid[i]==input.Liquid[i]) end
end)
test("Encoding is deterministic and occupancy is explicitly f32",function()
	local input=chunk(2,1,1,true);input.Solid[1]=1/3
	local a,b=Codec.Encode(input),Codec.Encode(input);assert(buffer.tostring(a)==buffer.tostring(b))
	assert(math.abs(Codec.Decode(a).Solid[1]-1/3)<0.00000003)
end)
test("Uniform 32-cube compresses into one bounded run",function()
	local data=Codec.Encode(chunk(32,32,32,false));assert(buffer.len(data)==36 and buffer.readu8(data,5)==1)
	local result=Codec.Decode(data);assert(#result.Materials==32768 and result.Materials[32768]==512)
end)
test("Diverse data falls back to a bounded dense payload",function()
	local data=Codec.Encode(chunk(32,32,32,true));assert(buffer.len(data)==327704 and buffer.readu8(data,5)==0);assert(#Codec.Decode(data).Liquid==32768)
end)
test("Non-cubic edge chunks preserve dimensions and cell ordering",function()
	local input=chunk(1,7,3,true);local out=Codec.Decode(Codec.Encode(input));assert(out.SizeX==1 and out.SizeY==7 and out.SizeZ==3)
	for i=1,21 do assert(out.Materials[i]==input.Materials[i]) end
end)
test("Invalid dimensions, sparse channels and nonfinite input are rejected",function()
	for _,n in ipairs({0,33,1.5,math.huge}) do local c=chunk(1,1,1,false);c.SizeX=n;denied(function()Codec.Encode(c)end) end
	local c=chunk(2,2,2,false);c.Materials[4]=nil;denied(function()Codec.Encode(c)end)
	for _,n in ipairs({-1,1.01,math.huge,0/0}) do c=chunk(1,1,1,false);c.Solid[1]=n;denied(function()Codec.Encode(c)end) end
	c=chunk(1,1,1,false);c.Materials[1]=65536;denied(function()Codec.Encode(c)end)
end)
test("Truncated, appended and oversized buffers are rejected",function()
	local good=Codec.Encode(chunk(1,1,1,false))
	for _,n in ipairs({0,23,buffer.len(good)-1,buffer.len(good)+1,327705}) do local b=buffer.create(n);buffer.copy(b,0,good,0,math.min(n,buffer.len(good)));denied(function()Codec.Decode(b)end) end
end)
test("Unknown versions, modes, reserved flags and dimension counts are rejected",function()
	local good=Codec.Encode(chunk(2,2,2,false))
	for _,change in ipairs({{0,0},{4,2},{5,2},{6,0},{9,1},{10,1},{12,1},{16,1}}) do local b=copy(good);buffer.writeu8(b,change[1],change[2]);denied(function()Codec.Decode(b)end) end
end)
test("Corruption is detected before expanding matrices",function()
	local b=Codec.Encode(chunk(2,2,2,true));buffer.writeu8(b,24,buffer.readu8(b,24)+1);denied(function()Codec.Decode(b)end)
end)
test("Forged zero, short and oversized runs cannot exceed declared volume",function()
	local good=Codec.Encode(chunk(4,4,4,false))
	for _,count in ipairs({0,63,65,65535}) do local b=copy(good);buffer.writeu16(b,24,count);rechecksum(b);denied(function()Codec.Decode(b)end) end
end)
test("Checksummed invalid occupancy is still rejected",function()
	local good=Codec.Encode(chunk(1,1,1,false))
	for _,value in ipairs({-1,2,math.huge,0/0}) do local b=copy(good);buffer.writef32(b,26,value);rechecksum(b);denied(function()Codec.Decode(b)end) end
end)
test("Base64 matches known vectors and preserves every byte value",function()
	for input,expected in pairs({[""]="",f="Zg==",fo="Zm8=",foo="Zm9v",hello="aGVsbG8="}) do assert(Text.Encode(buffer.fromstring(input))==expected);assert(buffer.tostring(Text.Decode(expected))==input) end
	local bytes=buffer.create(256);for i=0,255 do buffer.writeu8(bytes,i,i) end;assert(buffer.tostring(Text.Decode(Text.Encode(bytes)))==buffer.tostring(bytes))
end)
test("Text decoding rejects invalid characters, padding and size bombs",function()
	for _,s in ipairs({"A","====","AA=A","A%==","/x=="}) do denied(function()Text.Decode(s)end) end
	denied(function()Text.Encode(buffer.create(327705))end);denied(function()Text.Decode(string.rep("A",436944))end)
end)
test("Negative world coordinates and partial edges share a deterministic global grid",function()
	local plan=Grid.Plan({X=-4,Y=0,Z=0,Width=136,Height=4,Length=4})
	assert(#plan==3 and plan[1].Width==4 and plan[2].Width==128 and plan[3].Width==4)
	assert(Grid.Key(plan[1])=="V_-1_0_0" and Grid.Key(plan[3])=="V_32_0_0")
end)
test("Selections reject off-grid, excessive volume and excessive chunk counts",function()
	for _,b in ipairs({{X=.5,Y=0,Z=0,Width=4,Height=4,Length=4},{X=0,Y=0,Z=0,Width=512,Height=512,Length=512},{X=124,Y=124,Z=0,Width=1024,Height=1024,Length=4}}) do denied(function()Grid.Plan(b)end) end
end)
test("R1B provides authored shelves, a water corridor and localized hazards",function()
	local input={X=-512,Y=0,Z=-512,Width=1024,Height=256,Length=1024};local p=Plan.Create(input)
	assert(#p.Zones==7 and #p.Routes==5 and p.Orientation=="Inland -Z; seaward +Z")
	assert(p.Zones[2].Id=="B_Cradle" and p.Zones[3].Id=="C_Weep" and p.Zones[6].W<.2)
	assert(p.Routes[5].Reserved==true)
	for _,z in ipairs(p.Zones) do assert(z.Bounds.Width>0 and z.Bounds.Height>0 and z.Low>=1 and z.High<=6) end
	p.Bounds.X=0;p.Zones[1].Color[1]=0;assert(input.X==-512 and Plan.Create(input).Zones[1].Color[1]==115)
end)
test("R1B rejects tiny, nonfinite and unreasonable regional bounds",function()
	for _,width in ipairs({0,64,2052,math.huge,0/0}) do denied(function()Plan.Create({X=0,Y=0,Z=0,Width=width,Height=128,Length=128})end) end
	denied(function()Plan.Create({X=0,Y=0,Z=0,Width=128,Height=2052,Length=128})end)
end)
local function backend()
	local b={Edit=true,Published=0,Reads=0,Material=512}
	function b.IsEditMode()return b.Edit end
	function b.Read(bounds) b.Reads+=1;local c=chunk(bounds.Width/4,bounds.Height/4,bounds.Length/4,false);for i=1,#c.Materials do c.Materials[i]=b.Material end;return c end
	function b.Yield()if b.OnYield then b.OnYield()end end
	function b.Publish(capture)b.Published+=1;return {Stats=capture.Stats}end
	return b
end
local bounds={X=0,Y=0,Z=0,Width=8,Height=8,Length=8}
test("Preview reads without publishing, and Save revalidates every chunk",function()
	local b=backend();local s=Session.new(b);local c=s:Preview(bounds);assert(b.Published==0 and c.Stats.Voxels==8)
	s:Publish();assert(b.Reads==2 and b.Published==1 and not s.Busy)
end)
test("Artist edits after preview prevent stale publication",function()
	local b=backend();local s=Session.new(b);s:Preview(bounds);b.Material=832;denied(function()s:Publish()end);assert(b.Published==0 and not s.Busy)
end)
test("Save runs pending edits before a serial recheck of all chunks",function()
	local b=backend();local changed=false
	b.Read=function(box)
		local out=chunk(box.Width/4,box.Height/4,box.Length/4,false)
		if changed and box.X==0 then for i=1,#out.Materials do out.Materials[i]=832 end end
		return out
	end
	local s=Session.new(b)
	s:Preview({X=0,Y=0,Z=0,Width=256,Height=4,Length=4})
	-- Yielding after chunk 0 was verified would miss this edit to that chunk.
	b.OnYield=function()changed=true end
	denied(function()s:Publish()end);assert(b.Published==0 and not s.Busy)
end)
test("Cancellation and read failures release operation state without publishing",function()
	local b=backend();local s=Session.new(b);b.OnYield=function()s:Cancel()end;denied(function()s:Preview(bounds)end);assert(not s.Busy and not s.Last and b.Published==0)
	b.OnYield=nil;b.Read=function()error("fixture read failed")end;denied(function()s:Preview(bounds)end);assert(not s.Busy and not s.Last)
	b=backend();s=Session.new(b);s:Preview(bounds);b.OnYield=function()s:Cancel()end
	denied(function()s:Publish()end);assert(not s.Busy and not s.Last and b.Published==0)
end)
test("Play mode, concurrent operations and corrupt captures cannot publish",function()
	local b=backend();local s=Session.new(b);b.Edit=false;denied(function()s:Preview(bounds)end);assert(b.Reads==0)
	b.Edit=true;s.Busy=true;denied(function()s:Preview(bounds)end);s.Busy=false;s:Preview(bounds)
	buffer.writeu8(s.Last.Chunks[1].Data,24,1);denied(function()s:Publish()end);assert(b.Published==0)
end)
print("Stratum: "..#results.." groups passed")
return results
