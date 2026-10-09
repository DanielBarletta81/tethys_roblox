--!strict
local Plan = require(script.Parent.R1BPlan)
local Guides = { Generator = "StratumR1B" }

-- Prepare an unparented pass. The caller must acquire an Undo recording before
-- attaching it to the scene. Planning geometry never writes Terrain.
function Guides.Prepare(bounds: any, id: string): Folder
	assert(type(id) == "string" and #id > 0 and #id <= 96, "Invalid planning pass ID")
	local plan = Plan.Create(bounds)
	local pass = Instance.new("Folder")
	pass.Name = "Plan_" .. id
	pass:SetAttribute("Generator", Guides.Generator)
	pass:SetAttribute("PassId", id)
	pass:SetAttribute("PlanningOnly", true)
	pass:SetAttribute("Orientation", plan.Orientation)
	pass:SetAttribute("Version", plan.Version)
	pass:SetAttribute("BoundsMin", Vector3.new(bounds.X, bounds.Y, bounds.Z))
	pass:SetAttribute("BoundsSize", Vector3.new(bounds.Width, bounds.Height, bounds.Length))
	local function guide(name: string, b: any, color: Color3, purpose: string): Part
		local part = Instance.new("Part")
		part.Name = name
		part.Size = Vector3.new(b.Width, b.Height, b.Length)
		part.Position = Vector3.new(b.X + b.Width / 2, b.Y + b.Height / 2, b.Z + b.Length / 2)
		part.Anchored = true
		part.CanCollide, part.CanTouch, part.CanQuery, part.Transparency = false, false, false, 1
		part:SetAttribute("Generator", Guides.Generator)
		part:SetAttribute("PlanningOnly", true)
		part:SetAttribute("Purpose", purpose)
		part.Parent = pass
		local box = Instance.new("SelectionBox")
		box.Name, box.Adornee, box.Color3 = "Outline", part, color
		box.LineThickness, box.SurfaceTransparency = 0.05, 1
		box:SetAttribute("Generator", Guides.Generator)
		box.Parent = part
		return part
	end
	for _, zone in ipairs(plan.Zones) do
		local part = guide(zone.Id, zone.Bounds, Color3.fromRGB(table.unpack(zone.Color)), zone.Purpose)
		part:SetAttribute("HeightBandLow", zone.Low)
		part:SetAttribute("HeightBandHigh", zone.High)
	end
	for _, route in ipairs(plan.Routes) do
		for index, point in ipairs(route.Points) do
			local part = guide("Route_" .. route.Id .. "_" .. index,
				{ X = point.X - 2, Y = point.Y - 2, Z = point.Z - 2, Width = 4, Height = 4, Length = 4 },
				Color3.fromRGB(198, 181, 137), route.Name)
			part:SetAttribute("Reserved", route.Reserved == true)
		end
	end
	return pass
end

function Guides.Validate(pass: Instance)
	local id = pass:GetAttribute("PassId")
	assert(pass:IsA("Folder") and pass:GetAttribute("Generator") == Guides.Generator
		and pass:GetAttribute("PlanningOnly") == true and type(id) == "string"
		and #id > 0 and #id <= 96 and pass.Name == "Plan_" .. id, "Planning pass identity mismatch")
	for _, child in ipairs(pass:GetDescendants()) do
		assert(child:GetAttribute("Generator") == Guides.Generator,
			"Unowned content inside planning pass; remove it manually")
	end
end
return Guides
