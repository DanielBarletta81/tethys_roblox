-- Category defaults are placement rules, not biome or canon definitions.
return {
	Defaults = {
		Seed = 20261005,
		Count = 100,
		AttemptsPerPlacement = 12,
		RaycastPadding = 2,
		GroundOffset = 0,
		UseAssetFootprints = true,
	},
	Categories = {
		Trees = { MinScale = 0.85, MaxScale = 1.15, MaxSlopeDegrees = 35, MinSpacing = 12 },
		Rocks = { MinScale = 0.8, MaxScale = 1.25, MaxSlopeDegrees = 65, MinSpacing = 6 },
		Understory = { MinScale = 0.85, MaxScale = 1.2, MaxSlopeDegrees = 40, MinSpacing = 3 },
		GroundCover = { MinScale = 0.8, MaxScale = 1.2, MaxSlopeDegrees = 30, MinSpacing = 2 },
	},
}
