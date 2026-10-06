-- Optional family skin; Wildbound keeps the existing Theme by default.
return {
	Colors = {
		Obsidian = Color3.fromRGB(243, 230, 200), Basalt = Color3.fromRGB(214, 191, 145),
		WetStone = Color3.fromRGB(218, 204, 172), Ash = Color3.fromRGB(101, 82, 57),
		Bone = Color3.fromRGB(65, 48, 31), Bronze = Color3.fromRGB(129, 93, 48),
		BronzeBright = Color3.fromRGB(160, 98, 30), Amber = Color3.fromRGB(175, 104, 26),
		MistTeal = Color3.fromRGB(34, 121, 136), WaterPale = Color3.fromRGB(36, 148, 180),
		HealthMuted = Color3.fromRGB(187, 80, 64), StaminaMuted = Color3.fromRGB(83, 135, 57),
		Danger = Color3.fromRGB(174, 61, 42), Watcher = Color3.fromRGB(202, 93, 31),
	},
	Transparency = { Panel = 0.12, PanelSoft = 0.2, Backdrop = 0.45 },
	Radii = { Panel = UDim.new(0, 6), Input = UDim.new(0, 4), Toast = UDim.new(0, 6) },
	Stroke = { Thin = 1, Medium = 1.4 },
	Typography = { TitleFont = Enum.Font.Garamond, BodyFont = Enum.Font.Gotham,
		StrongFont = Enum.Font.GothamSemibold, MicroFont = Enum.Font.GothamMedium },
	ZIndex = { Base = 10, Overlay = 30, Toast = 40 },
}
