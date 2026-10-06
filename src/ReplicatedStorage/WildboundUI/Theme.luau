local Theme = {
	Colors = {
		Obsidian = Color3.fromRGB(22, 27, 27),
		Basalt = Color3.fromRGB(37, 43, 42),
		WetStone = Color3.fromRGB(52, 59, 58),
		Ash = Color3.fromRGB(176, 174, 164),

		Bone = Color3.fromRGB(221, 211, 187),
		Bronze = Color3.fromRGB(155, 121, 80),
		BronzeBright = Color3.fromRGB(213, 173, 109),

		Amber = Color3.fromRGB(214, 148, 66),
		MistTeal = Color3.fromRGB(128, 182, 181),
		WaterPale = Color3.fromRGB(127, 199, 207),

		HealthMuted = Color3.fromRGB(168, 90, 82),
		StaminaMuted = Color3.fromRGB(114, 131, 78),
		Danger = Color3.fromRGB(168, 90, 82),
		Watcher = Color3.fromRGB(196, 76, 31),
	},

	Transparency = {
		Panel = 0.34,
		PanelSoft = 0.42,
		Backdrop = 0.5,
	},

	Radii = {
		Panel = UDim.new(0, 2),
		Input = UDim.new(0, 2),
		Toast = UDim.new(0, 2),
	},

	Stroke = {
		Thin = 1,
		Medium = 1.4,
	},

	Typography = {
		TitleFont = Enum.Font.Garamond,
		BodyFont = Enum.Font.Gotham,
		StrongFont = Enum.Font.GothamSemibold,
		MicroFont = Enum.Font.GothamMedium,
	},

	ZIndex = {
		Base = 10,
		Overlay = 30,
		Toast = 40,
	},
}

return Theme
