-- Supplied UI frames only. Image imports are filled after inspecting the originals.
-- Normalized regions avoid assumptions about Roblox's served texture dimensions.
local function band(image, top, bottom, left, right, fillTop, fillBottom)
	return table.freeze({Image = image, Aspect = 3, Top = top, Bottom = bottom,
		Left = left, Right = right, FillTop = fillTop, FillBottom = fillBottom})
end
return table.freeze({
	Health = band("rbxassetid://75299383879083", 0.29, 0.70, 0.145, 0.935, 0.425, 0.58),
	Stamina = band("", 0.28, 0.69, 0.145, 0.935, 0.425, 0.58),
	Thirst = band("rbxassetid://74147329697425", 0.29, 0.70, 0.145, 0.935, 0.425, 0.58),
	Exposure = band("rbxassetid://127272808705185", 0.29, 0.70, 0.145, 0.935, 0.425, 0.58),
	Button = band("rbxassetid://78050270596989", 0.20, 0.80, 0.14, 0.87),
	Quickbar = table.freeze({Image = "rbxassetid://110112619083753", Aspect = 1}),
	Masthead = table.freeze({Image = "rbxassetid://122280663345125", Aspect = 3}),
})
