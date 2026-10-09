--!strict
local Grid={Resolution=4,ChunkStuds=128,MaxCells=262144,MaxChunks=64}
export type Bounds={X:number,Y:number,Z:number,Width:number,Height:number,Length:number}
local function coordinate(n: number)
	assert(type(n)=="number" and n==n and math.abs(n)<=1000000 and n%4==0,"Bounds must use finite 4-stud grid coordinates")
end
function Grid.Validate(b: Bounds)
	coordinate(b.X);coordinate(b.Y);coordinate(b.Z)
	for _,n in ipairs({b.Width,b.Height,b.Length}) do coordinate(n);assert(n>0 and n<=1024,"Dimension must be 4..1024 studs") end
	assert(b.Width*b.Height*b.Length/64<=Grid.MaxCells,"Selection exceeds 262144 cells")
end
function Grid.Plan(b: Bounds): {Bounds}
	Grid.Validate(b)
	local function segments(low: number, size: number)
		local out={};local high=low+size
		while low<high do local edge=math.min(high,(math.floor(low/128)+1)*128);table.insert(out,{Low=low,Size=edge-low});low=edge end
		return out
	end
	local out={}
	for _,x in ipairs(segments(b.X,b.Width)) do for _,y in ipairs(segments(b.Y,b.Height)) do for _,z in ipairs(segments(b.Z,b.Length)) do
		table.insert(out,{X=x.Low,Y=y.Low,Z=z.Low,Width=x.Size,Height=y.Size,Length=z.Size})
		assert(#out<=Grid.MaxChunks,"Selection crosses more than 64 chunks")
	end end end
	return out
end
function Grid.Key(b: Bounds): string
	return string.format("V_%d_%d_%d",b.X/4,b.Y/4,b.Z/4)
end
return table.freeze(Grid)
