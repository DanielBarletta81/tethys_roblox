-- Supplied UI frames only. Image imports are filled after inspecting the originals.
-- Normalized regions avoid assumptions about Roblox's served texture dimensions.
local function band(image, top, bottom, left, right, fillTop, fillBottom)
	return table.freeze({Image = image, Aspect = 3, Top = top, Bottom = bottom,
		Left = left, Right = right, FillTop = fillTop, FillBottom = fillBottom})
end
return table.freeze({
	Health = band("", 0.29, 0.70, 0.145, 0.935, 0.425, 0.58),
	Stamina = band("", 0.28, 0.69, 0.145, 0.935, 0.425, 0.58),
	Thirst = band("", 0.29, 0.70, 0.145, 0.935, 0.425, 0.58),
	Button = band("", 0.20, 0.80, 0.14, 0.87),
	Quickbar = table.freeze({Image = "", Aspect = 1}),
	Masthead = table.freeze({Image = "", Aspect = 3}),
})
