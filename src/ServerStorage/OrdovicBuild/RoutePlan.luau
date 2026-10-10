local Plan = {}
Plan.BuildId = "OrdovicV1_20261006"
-- User design lock: read water surfaces; the leaf lesson belongs to Sky City.
-- The blocked Wake upstream remains reserved for a later authored connection.
Plan.OpeningLock = "WaterSurface_RidgeTamed_UpstreamClosed1"
Plan.LayoutVersion = "RaisedRoutes_20261010"
function Plan.Resolve()
	local works = workspace.World["05_Mountain_Works"]
	local basin = workspace.World["98_MythLegend_Archive"].Batch_MysteriousStartMap.Western_Tethys_Plot["02_Waterways"].Ordovic_River3.Ord_River_3
	local intake = works.Givers_Intake["01_GiversFallsIntake"].FirstSort.MainIntake.GUIDE_MainIntakeFlow
	local source = basin.Position + Vector3.new(0, 4, 0)
	local finish = intake.Position + Vector3.new(72.573, 15.82, 38.013)
	local offsets = {
		{0,0,0}, {-25,-18,208}, {-235,-83,448}, {-435,-153,678}, {-635,-233,928},
		{-875,-333,1138}, {-1125,-433,1308}, {-1465,-533,1068}, {-1885,-663,868}, {-2435,-723,578}, {-2685,-883,1388},
	}
	local main = {}
	for _, o in ipairs(offsets) do table.insert(main, source + Vector3.new(o[1],o[2],o[3])) end
	table.insert(main, finish)
	for i=1,#main-1 do assert(main[i].Y >= main[i+1].Y, "Ordovic water cannot climb; re-survey moved anchors") end
	local bypass = { finish + Vector3.new(-8,0,14) }
	for _, o in ipairs({{-115,-10,80},{-230,-28,180},{-345,-52,290},{-455,-82,360},{-585,-130,410}}) do
		table.insert(bypass, finish + Vector3.new(o[1],o[2],o[3]))
	end
	local city = workspace.World["02_Upper_City"].Upper_Tier.Upper_Tier_Main
	return { Main = main, Bypass = bypass, Source = source, Intake = finish, Landing = bypass[#bypass],
		City = Vector3.new(city.Position.X, city.Position.Y+city.Size.Y/2, city.Position.Z+39),
		BasinPath = basin:GetFullName(), IntakePath = intake:GetFullName() }
end
return Plan
