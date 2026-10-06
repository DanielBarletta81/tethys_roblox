local U = require(script.Parent.BuildUtil)
local Surface = {}
function Surface.Build(root, plan)
	assert(not root:FindFirstChild("09_WaterSurface"), "Surface cues already exist")
	local folder = U.Folder(root, "09_WaterSurface")
	folder:SetAttribute("CueKind", "WaterFoam")
	folder:SetAttribute("ProxyArt", true)
	folder:SetAttribute("NavigationSource", "WaterSurface")
	local function foam(name, zoneName, lane, offset)
		local p = U.Part(folder, name, Vector3.new(1.1, 0.06, 4), CFrame.new(plan.Source),
			Enum.Material.SmoothPlastic, Color3.fromRGB(196, 215, 210), false)
		p.CanQuery, p.CanTouch, p.CastShadow, p.Transparency = false, false, false, 1
		p:SetAttribute("ZoneName", zoneName)
		p:SetAttribute("Lane", lane)
		p:SetAttribute("CycleOffset", offset)
		p:SetAttribute("BaseTransparency", 0.45)
	end
	for _, zone in ipairs(root["03_FlowZones"]:GetChildren()) do
		-- Falls already read as drops. Foam stays on the runs and recovery water.
		if string.match(zone.Name, "^FZMain_") or string.match(zone.Name, "^FZBypass_") or string.match(zone.Name, "^FZ_Recovery_") then
			local count = zone:GetAttribute("FlowSpeed") == 0 and 3 or math.max(3, math.ceil((zone.Size.Z - 12) / 45))
			for n = 1, count do
				local lane = ({-0.22, 0, 0.22})[(n - 1) % 3 + 1]
				foam(zone.Name .. "_Foam_" .. n, zone.Name, lane, (n - 1) / count)
			end
		end
	end
	foam("Wake_Foam_1", "WAKE", 0, 0)
	foam("Wake_Foam_2", "WAKE", 0.18, 0.5)
	folder:SetAttribute("SurfaceCueCount", #folder:GetChildren())
	return folder
end
return Surface
