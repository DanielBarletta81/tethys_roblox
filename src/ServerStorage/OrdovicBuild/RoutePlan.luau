local Plan = {}
Plan.BuildId = "OrdovicV1_20261006"
-- User design lock: read water surfaces; the leaf lesson belongs to Sky City.
-- The blocked Wake upstream remains reserved for a later authored connection.
Plan.OpeningLock = "WaterSurface_RidgeTamed_UpstreamClosed1"
function Plan.Resolve()
	local works = workspace.World["05_Mountain_Works"]
	local basin = works.Ordovic_River.Ordovic_Upper_Basin
	local intake = works.Givers_Intake["01_GiversFallsIntake"].FirstSort.MainIntake.GUIDE_MainIntakeFlow
	local source = Vector3.new(basin.Position.X + 179.8, basin.Position.Y + 25, basin.Position.Z + 219.35)
	local finish = intake.Position + Vector3.new(72.573, 15.82, 38.013)
	local offsets = {
		{0,0,0}, {0,-10,160}, {-206,-36,400}, {-416,-66,670}, {-636,-96,870},
		{-846,-118,950}, {-1076,-136,945}, {-1346,-146,1050}, {-1636,-152,1100}, {-1976,-160,1230}, {-2316,-166,1410},
	}
	local main = {}
	for _, o in ipairs(offsets) do table.insert(main, source + Vector3.new(o[1],o[2],o[3])) end
	table.insert(main, finish)
	local bypass = { finish + Vector3.new(-8,0,14) }
	for _, o in ipairs({{-115,-10,55},{-230,-28,-50},{-345,-52,-110},{-455,-82,-145},{-585,-130,-190}}) do
		table.insert(bypass, finish + Vector3.new(o[1],o[2],o[3]))
	end
	return { Main = main, Bypass = bypass, Source = source, Intake = finish, Landing = bypass[#bypass],
		BasinPath = basin:GetFullName(), IntakePath = intake:GetFullName() }
end
return Plan
