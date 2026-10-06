local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
-- The shared HUD owns these cues when its binder is active.
local sharedUI = player:WaitForChild("PlayerGui"):WaitForChild("TethysUI", 2)
if sharedUI and player:GetAttribute("WOT_WildboundUIActive") == true then return end

local gui=Instance.new("ScreenGui")
gui.Name="FirstDayQuietCue"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.DisplayOrder=5
gui.Parent=player:WaitForChild("PlayerGui")
local label=Instance.new("TextLabel")
label.Name="Cue"
label.AnchorPoint=Vector2.new(0.5,1)
label.Position=UDim2.new(0.5,0,1,-36)
label.Size=UDim2.new(0.72,0,0,40)
label.BackgroundColor3=Color3.fromRGB(20,27,28)
label.BackgroundTransparency=0.22
label.BorderSizePixel=0
label.TextColor3=Color3.fromRGB(238,236,221)
label.Font=Enum.Font.Gotham
label.TextSize=17
label.TextWrapped=true
label.Text=""
label.Visible=false
label.Parent=gui
local corner=Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,10)
corner.Parent=label
local generation=0
local function showMessage()
	local message=player:GetAttribute("SC_Message")
	if typeof(message)~="string" or message=="" then return end
	generation+=1
	local current=generation
	label.Text=message
	label.TextTransparency=0
	label.BackgroundTransparency=0.22
	label.Visible=true
	task.delay(8,function()
		if current~=generation or not label.Parent then return end
		local tween=TweenService:Create(label,TweenInfo.new(0.8),{TextTransparency=1,BackgroundTransparency=1})
		tween:Play();tween.Completed:Wait()
		if current==generation then label.Visible=false end
	end)
end
player:GetAttributeChangedSignal("SC_Message"):Connect(showMessage)
task.defer(showMessage)

