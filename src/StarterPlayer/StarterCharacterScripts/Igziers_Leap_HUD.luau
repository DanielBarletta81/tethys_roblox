local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
-- The shared HUD owns these cues when its binder is active.
local sharedUI = player:WaitForChild("PlayerGui"):WaitForChild("TethysUI", 2)
if sharedUI and player:GetAttribute("WOT_WildboundUIActive") == true then return end


local gui = playerGui:FindFirstChild("IgziersLeapHUD")
if not gui then
	gui = Instance.new("ScreenGui")
	gui.Name = "IgziersLeapHUD"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui
end

local panel = gui:FindFirstChild("QuestMessage")
if not panel then
	panel = Instance.new("TextLabel")
	panel.Name = "QuestMessage"
	panel.Size = UDim2.new(0, 450, 0, 154)
	panel.Position = UDim2.new(1, -470, 0, 20)
	panel.BackgroundColor3 = Color3.fromRGB(26, 39, 42)
	panel.BackgroundTransparency = 0.18
	panel.TextColor3 = Color3.fromRGB(242, 236, 214)
	panel.TextWrapped = true
	panel.TextXAlignment = Enum.TextXAlignment.Left
	panel.TextYAlignment = Enum.TextYAlignment.Top
	panel.TextSize = 17
	panel.Font = Enum.Font.GothamMedium
	panel.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel
end

local function update()
	local active = player:GetAttribute("IL_Active") == true or player:GetAttribute("IL_Complete") == true
	gui.Enabled = active
	if not active then return end
	local routeCount = player:GetAttribute("IL_RouteCount") or 7
	local step = player:GetAttribute("IL_Step") or 1
	local complete = player:GetAttribute("IL_Complete")
	local title = player:GetAttribute("IL_Title") or "Igzier's Leap"
	local message = player:GetAttribute("IL_Message") or "Start at The Weep."
	local weepClears = player:GetAttribute("IL_WeepClears") or 0
	local ledgeClears = player:GetAttribute("IL_LedgeClears") or 0
	local ravelAid = player:GetAttribute("IL_RavelAid") and "READY" or "SPENT"
	local fails = player:GetAttribute("IL_FailCount") or 0

	local progress
	if complete then
		progress = "Complete (" .. routeCount .. "/" .. routeCount .. ")"
	else
		progress = "Step " .. tostring(math.clamp(step, 1, routeCount)) .. " / " .. tostring(routeCount)
	end

	panel.Text = "IGZIER'S LEAP\n"
		.. progress .. "  |  Ravel Aid: " .. ravelAid .. "\n"
		.. "Weep Lanes: " .. tostring(weepClears) .. "/3  |  Ledge Hazards: " .. tostring(ledgeClears) .. "/4  |  Fails: " .. tostring(fails) .. "\n"
		.. title .. "\n\n"
		.. message
end

local tracked = {
	"IL_Step",
	"IL_Active",
	"IL_Complete",
	"IL_RouteCount",
	"IL_Title",
	"IL_Message",
	"IL_WeepClears",
	"IL_LedgeClears",
	"IL_RavelAid",
	"IL_FailCount",
}

for _, attr in ipairs(tracked) do
	player:GetAttributeChangedSignal(attr):Connect(update)
end

update()

