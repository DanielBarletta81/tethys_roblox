-- Template; the authoritative justice owner handles the consequences.
if script:GetAttribute("TethysTemplateEnabled") ~= true then return end
local Players = game:GetService("Players")
local gate = workspace:FindFirstChild("MainGateScanner", true)
local request = game.ServerScriptService:FindFirstChild("TethysArrestRequested")
if not gate or not gate:IsA("BasePart") or not request or not request:IsA("BindableEvent") then return end
local last = {}
gate.Touched:Connect(function(hit)
    local character = hit:FindFirstAncestorOfClass("Model")
    local player = character and Players:GetPlayerFromCharacter(character)
    local human = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not player or not human or human.Health <= 0 or not root or (root.Position-gate.Position).Magnitude > gate.Size.Magnitude/2+6 then return end
    if os.clock()-(last[player] or -5)<5 or typeof(_G.GetPlayerData)~="function" then return end
    local data = _G.GetPlayerData(player.UserId)
    if data and data.IsMarked then last[player]=os.clock();request:Fire(player) end
end)
Players.PlayerRemoving:Connect(function(player)last[player]=nil end)
