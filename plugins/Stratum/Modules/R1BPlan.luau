--!strict
-- An authored planning sketch, not a terrain generator or a route unlock.
local Plan={}
local zones={
	{Id="A_Backbone",Name="Cimmerian backbone",U=0,V=0,W=1,D=0.28,Low=5,High=6,Color={115,131,145},Purpose="Broad source mountains; future upland passes."},
	{Id="B_Cradle",Name="Sky City cradle",U=0.28,V=0.26,W=0.42,D=0.34,Low=3,High=5,Color={189,160,100},Purpose="Author a protected folded shelf; city adapts to the land."},
	{Id="C_Weep",Name="Weep water corridor",U=0.45,V=0.18,W=0.1,D=0.77,Low=1,High=6,Color={73,143,156},Purpose="Water first: gather inland, work beside it, constrict and spill seaward."},
	{Id="D_Ledge",Name="Watcher-facing escarpment",U=0,V=0.78,W=1,D=0.22,Low=1,High=4,Color={181,105,76},Purpose="Exposed coastal drops, ledges and failed outward ambitions."},
	{Id="E_Working",Name="Lower working slopes",U=0.2,V=0.56,W=0.55,D=0.22,Low=2,High=3,Color={116,145,103},Purpose="Practical waterworks, hatchery and workshop terraces."},
	{Id="F1_Hazard",Name="Localized broken stone",U=0.05,V=0.62,W=0.12,D=0.16,Low=2,High=5,Color={163,99,91},Purpose="One selective hazard pocket; preserve broad mountain silhouettes."},
	{Id="F2_Hazard",Name="Localized stone ribs",U=0.82,V=0.34,W=0.12,D=0.14,Low=2,High=5,Color={163,99,91},Purpose="A second accent hazard; do not turn the whole tile into spikes."},
}
local routes={
	{Id="SafeCity",Name="Sheltered city route",Points={{.34,.48,3},{.42,.4,4},{.59,.34,5}}},
	{Id="ExposedLedge",Name="Watcher-side exposed route",Points={{.7,.57,3},{.8,.71,3},{.8,.87,2}}},
	{Id="Waterworks",Name="Lower waterworks route",Points={{.43,.55,3},{.43,.68,2},{.49,.84,1}}},
	{Id="HiddenRuin",Name="Hidden ruin route",Points={{.35,.58,2},{.31,.49,3},{.36,.4,3}}},
	{Id="CimmerianRise",Name="Reserved future upland route",Reserved=true,Points={{.59,.34,5},{.62,.2,6},{.63,.08,6}}},
}
function Plan.Create(bounds: any): any
	for _,key in ipairs({"X","Y","Z","Width","Height","Length"}) do
		local n=bounds[key];assert(type(n)=="number" and n==n and math.abs(n)<=1000000 and n%4==0,"Plan bounds must use finite 4-stud coordinates")
	end
	-- Studio clamps Part dimensions to 2048. Keep guide geometry faithful to
	-- this authored tile; larger regions need an explicit tiled design later.
	assert(bounds.Width>=128 and bounds.Width<=2048 and bounds.Length>=128 and bounds.Length<=2048,"R1B footprint must be 128..2048 studs")
	assert(bounds.Height>=64 and bounds.Height<=2048,"R1B height must be 64..2048 studs")
	local out={Bounds=table.clone(bounds),Zones={},Routes={},Orientation="Inland -Z; seaward +Z",Version="R1B sketch 1"}
	local function point(u:number,v:number,band:number): any
		return {X=bounds.X+u*bounds.Width,Y=bounds.Y+(band-1)/5*bounds.Height,Z=bounds.Z+v*bounds.Length}
	end
	for _,zone in ipairs(zones) do
		local copy=table.clone(zone);copy.Color=table.clone(zone.Color)
		local low=point(zone.U,zone.V,zone.Low)
		copy.Bounds={X=low.X,Y=low.Y,Z=low.Z,Width=zone.W*bounds.Width,Height=math.max(4,(zone.High-zone.Low)/5*bounds.Height),Length=zone.D*bounds.Length}
		table.insert(out.Zones,copy)
	end
	for _,route in ipairs(routes) do
		local copy=table.clone(route);copy.Points={}
		for _,p in ipairs(route.Points) do table.insert(copy.Points,point(p[1],p[2],p[3])) end
		table.insert(out.Routes,copy)
	end
	return out
end
return Plan
