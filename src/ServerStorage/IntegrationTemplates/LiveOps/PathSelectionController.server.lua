-- Integration template: dependencies and acceptance are listed in docs/engineering/roblox-integration.md.
if script:GetAttribute("TethysTemplateEnabled") ~= true then return end
--!strict
-- Place inside src/StarterGui/PathSelectionGui/ConfirmPathButton/PathSelectionController.lua
-- Corrected Luau Type Assertions for Wildbound Onboarding UIs

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- FIX: Strict Luau uses double colons (::), never the 'as' keyword
local CurrentButton = script.Parent :: TextButton
local RequestPathFunction = ReplicatedStorage:WaitForChild("RequestPathAlignment") :: RemoteFunction

local function onConfirmButtonClicked()
	if not CurrentButton.Active then return end
	CurrentButton.Active = false
	CurrentButton.Text = "📡 TRANSMITTING..."

	local chosenPathOption = "Mystic"
	local success, callbackMessage = RequestPathFunction:InvokeServer(chosenPathOption)

	if success then
		CurrentButton.BackgroundColor3 = Color3.fromRGB(0, 255, 204)
		CurrentButton.Text = "✅ ALIGNMENT ARCHIVED"
	else
		CurrentButton.BackgroundColor3 = Color3.fromRGB(255, 51, 68)
		CurrentButton.Text = "❌ ACCESS REJECTED"
		task.wait(2.0)
		CurrentButton.Active = true
		CurrentButton.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
		CurrentButton.Text = "CONFIRM ALIGNMENT"
	end
end

CurrentButton.MouseButton1Click:Connect(onConfirmButtonClicked)
