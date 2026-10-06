-- A sketch of visited water stages, not a geographic/GPS map.
local Data = require(script.Parent.RuntimeData)
local Navigation = {}
Navigation.Stages = {
	{ Id = "ORDOVIC_SOURCE", Label = "Ordovic Source", Short = "Source", Path = "05_Mountain_Works.Ordovic_River.Ordovic_Upper_Basin", Sketch = Vector2.new(0.38, 0.18) },
	{ Id = "GIVERS_FALLS", Label = "Giver's Falls", Short = "Falls", Path = "02_Upper_City.Givers_Falls.GiversFallsLip", Sketch = Vector2.new(0.62, 0.32) },
	{ Id = "THE_WEEP", Label = "The Weep", Short = "Weep", Path = "01_Weep_Plaza.WeepHeadBox.00_Guides.GUIDE_HeadBox_Outflow", Sketch = Vector2.new(0.37, 0.49) },
	{ Id = "POTABLE_DISTRIBUTION", Label = "Potable Distribution", Short = "Niche", Path = "02_Upper_City.Potable_Distribution.Upper_Drinking_Niche.00_Guides.GUIDE_Upper_Drinking_Niche", Sketch = Vector2.new(0.61, 0.65) },
	{ Id = "HATCHERY_SYSTEM", Label = "Hatchery System", Short = "Hatchery", Path = "02_Upper_City.Hatchery.01_Upper_Brood.Brood_Floor", Sketch = Vector2.new(0.4, 0.79) },
}

function Navigation.KnownCount(player)
	return math.clamp(math.floor(Data.Number(player:GetAttribute("WT_WaterStageIndex")) or 0), 0, #Navigation.Stages)
end

function Navigation.Delta(bearing, heading)
	return (bearing - heading + 180) % 360 - 180
end

function Navigation.Anchor(stage)
	local anchor = workspace:FindFirstChild("World")
	for segment in stage.Path:gmatch("[^%.]+") do
		anchor = anchor and anchor:FindFirstChild(segment)
	end
	if anchor and anchor:IsA("BasePart") then return anchor.Position end
	if anchor and anchor:IsA("Model") then return anchor:GetPivot().Position end
	-- Streaming may withhold a visited anchor; never invent its position.
	return nil
end

return Navigation
