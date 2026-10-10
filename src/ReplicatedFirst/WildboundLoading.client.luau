-- Cover the world before StarterPlayer binding; the full intro takes ownership.
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContextActionService = game:GetService("ContextActionService")
local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local curtain = Instance.new("ScreenGui")
curtain.Name, curtain.ResetOnSpawn, curtain.DisplayOrder = "WOTLoading", false, 109
curtain.ScreenInsets = Enum.ScreenInsets.None
local background = Instance.new("Frame")
background.Size, background.BackgroundColor3, background.BorderSizePixel = UDim2.fromScale(1,1), Color3.fromRGB(22,27,27), 0
background.Parent = curtain
local title = Instance.new("TextLabel")
title.AnchorPoint, title.Position, title.Size = Vector2.new(0.5,0.5), UDim2.fromScale(0.5,0.45), UDim2.new(0.9,0,0,90)
title.BackgroundTransparency, title.Text = 1, "WORLD OF\nT E T H Y S"
title.Font, title.TextSize, title.TextColor3 = Enum.Font.Garamond, 36, Color3.fromRGB(221,211,187)
title.Parent = background
curtain.Parent = playerGui
ContextActionService:BindActionAtPriority("WB_LoadingMovement", function() return Enum.ContextActionResult.Sink end, false, 4001,
	Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward, Enum.PlayerActions.CharacterLeft,
	Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump)
ReplicatedFirst:RemoveDefaultLoadingScreen()
local done, connections = false, {}
local function finish()
	if done then return end
	done = true
	ContextActionService:UnbindAction("WB_LoadingMovement")
	for _, connection in ipairs(connections) do connection:Disconnect() end
	curtain:Destroy()
end
local function watch(gui)
	if gui.Name ~= "WOTIntro" then return end
	local function ready() if gui:GetAttribute("WB_IntroReady") == true then finish() end end
	table.insert(connections, gui:GetAttributeChangedSignal("WB_IntroReady"):Connect(ready))
	ready()
end
table.insert(connections, playerGui.ChildAdded:Connect(watch))
for _, gui in ipairs(playerGui:GetChildren()) do watch(gui) end
-- A failed UI bind must not strand the player behind an indefinite loading cover.
task.delay(20, finish)
