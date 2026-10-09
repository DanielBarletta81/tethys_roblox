--!strict
-- Instance attributes cannot store buffer values. Archives use bounded ASCII StringValues.
local Base64={MaxBytes=327704}
local alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local values: {[string]:number}={}
for i=1,64 do values[alphabet:sub(i,i)]=i-1 end
function Base64.Encode(data: buffer): string
	local n=buffer.len(data);assert(n<=Base64.MaxBytes,"Archive chunk exceeds byte limit")
	local out={}
	for p=0,n-1,3 do
		local a=buffer.readu8(data,p);local b=if p+1<n then buffer.readu8(data,p+1) else 0;local c=if p+2<n then buffer.readu8(data,p+2) else 0
		local v=a*65536+b*256+c
		local s=""
		for shift=3,0,-1 do local digit=math.floor(v/64^shift)%64;s..=alphabet:sub(digit+1,digit+1) end
		if p+2>=n then s=s:sub(1,if p+1<n then 3 else 2)..(if p+1<n then "=" else "==") end
		table.insert(out,s)
	end
	return table.concat(out)
end
function Base64.Decode(text: string): buffer
	assert(type(text)=="string" and #text%4==0 and #text<=math.ceil(Base64.MaxBytes/3)*4,"Invalid Base64 length")
	local pad=if text:sub(-2)=="==" then 2 elseif text:sub(-1)=="=" then 1 else 0
	local n=#text/4*3-pad;assert(n>=0 and n<=Base64.MaxBytes,"Invalid decoded length")
	local output=buffer.create(n);local p=0
	for i=1,#text,4 do
		local v=0
		for j=0,3 do
			local c=text:sub(i+j,i+j)
			local digit=values[c]
			if c=="=" then assert(i+j>#text-pad,"Padding is only allowed at the end");digit=0 end
			assert(digit~=nil,"Invalid Base64 character");v=v*64+(digit :: number)
		end
		for shift=2,0,-1 do if p<n then buffer.writeu8(output,p,math.floor(v/256^shift)%256);p+=1 end end
	end
	assert(Base64.Encode(output)==text,"Noncanonical Base64 padding")
	return output
end
return table.freeze(Base64)
