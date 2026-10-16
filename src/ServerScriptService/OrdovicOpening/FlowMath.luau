local Math = {}
function Math.Contains(zone, position)
	local p = zone.CFrame:PointToObjectSpace(position)
	local h = zone.Size / 2
	return math.abs(p.X) <= h.X and math.abs(p.Y) <= h.Y and math.abs(p.Z) <= h.Z
end
function Math.Acceleration(direction, velocity, speed, response)
	-- Only accelerate downstream. Lateral steering and existing momentum survive.
	local missing = math.max(0, speed - velocity:Dot(direction))
	return direction * math.min(55, missing / math.max(0.1, response))
end
function Math.Select(zones, position, rejected)
	local chosen
	for _, zone in ipairs(zones) do
		local cascade = zone:GetAttribute("PhaseName") == "REJECT_CASCADE"
		if zone:GetAttribute("Active") and cascade == rejected and Math.Contains(zone, position) then
			if not chosen or (zone:GetAttribute("Priority") or 1) > (chosen:GetAttribute("Priority") or 1) then chosen = zone end
		end
	end
	return chosen
end
return Math
