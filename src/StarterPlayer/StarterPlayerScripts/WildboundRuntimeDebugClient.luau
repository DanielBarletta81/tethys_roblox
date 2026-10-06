local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WildboundRuntimeDebug"
screenGui.ResetOnSpawn = false
screenGui.Enabled = script:GetAttribute("WB_DebugVisibleOnStart") == true
screenGui.DisplayOrder = 1000
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Panel"
frame.AnchorPoint = Vector2.new(0, 0)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.Size = UDim2.new(0, 300, 0.85, 0)
frame.BackgroundColor3 = Color3.fromRGB(10, 14, 18)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Parent = screenGui

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1
stroke.Color = Color3.fromRGB(74, 101, 117)
stroke.Parent = frame

local text = Instance.new("TextLabel")
text.Name = "Text"
text.BackgroundTransparency = 1
text.Size = UDim2.new(1, -12, 1, -12)
text.Position = UDim2.new(0, 6, 0, 6)
text.TextXAlignment = Enum.TextXAlignment.Left
text.TextYAlignment = Enum.TextYAlignment.Top
text.Font = Enum.Font.Code
text.TextSize = 11
text.TextColor3 = Color3.fromRGB(214, 227, 234)
text.RichText = false
text.TextWrapped = false
text.Text = ""
text.Parent = frame

local function nz(value, fallback)
	if value == nil or value == "" then
		return fallback
	end
	return tostring(value)
end

local function update()
	local r = nz(player:GetAttribute("WB_Region"), "ORDOVIC")
	local z = nz(player:GetAttribute("WB_Zone"), "WAKE")
	local cp = nz(player:GetAttribute("WB_Checkpoint"), "CP_01_Wake")
	local intake = nz(player:GetAttribute("WB_IntakeOutcome"), "UNDECIDED")
	local cityEntry = nz(player:GetAttribute("WB_CityEntry"), "NONE")
	local firstHome = nz(player:GetAttribute("WB_FirstHome"), "NONE")
	local activeHome = nz(player:GetAttribute("WB_ActiveHome"), "NONE")
	local firstCommunity = nz(player:GetAttribute("WB_FirstCommunity"), "NONE")
	local silurian = nz(player:GetAttribute("WB_SilurianStatus"), "UNSEEN")
	local lastTrigger = nz(player:GetAttribute("WB_LastTrigger"), "NONE")
	local lastAction = nz(player:GetAttribute("WB_LastAction"), "NONE")

	local kR = player:GetAttribute("WB_Knowledge_Return") == true and 1 or 0
	local kB = player:GetAttribute("WB_Knowledge_Break") == true and 1 or 0
	local kH = player:GetAttribute("WB_Knowledge_Hold") == true and 1 or 0
	local kS = player:GetAttribute("WB_Knowledge_Scour") == true and 1 or 0

	text.Text = string.format(
		"REGION\n%s\n\nZONE\n%s\n\nCHECKPOINT\n%s\n\nINTAKE\n%s\n\nCITY ENTRY\n%s\n\nFIRST HOME\n%s\n\nACTIVE HOME\n%s\n\nFIRST COMMUNITY\n%s\n\nSILURIAN\n%s\n\nKNOWLEDGE\nR:%d B:%d H:%d S:%d\n\nLAST TRIGGER\n%s\n\nLAST ACTION\n%s",
		r,
		z,
		cp,
		intake,
		cityEntry,
		firstHome,
		activeHome,
		firstCommunity,
		silurian,
		kR,
		kB,
		kH,
		kS,
		lastTrigger,
		lastAction
	)
end

local watched = {
	"WB_Region",
	"WB_Zone",
	"WB_Checkpoint",
	"WB_IntakeOutcome",
	"WB_CityEntry",
	"WB_FirstHome",
	"WB_ActiveHome",
	"WB_FirstCommunity",
	"WB_SilurianStatus",
	"WB_Knowledge_Return",
	"WB_Knowledge_Break",
	"WB_Knowledge_Hold",
	"WB_Knowledge_Scour",
	"WB_LastTrigger",
	"WB_LastAction",
}

for _, attr in ipairs(watched) do
	player:GetAttributeChangedSignal(attr):Connect(update)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == Enum.KeyCode.F7 then
		screenGui.Enabled = not screenGui.Enabled
	end
end)

update()
