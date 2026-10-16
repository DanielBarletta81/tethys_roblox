if script:GetAttribute("TethysTemplateEnabled") ~= true then return end
--!strict
-- Place inside src/StarterGui/PathSelectionGui/ConfirmPathButton/PathSelectionController.lua
-- Pure Client UI controller: Completely isolated from raw HttpService tasks

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- FIX: Cast script.Parent through 'any' first to satisfy the Luau strict null-safety compiler
local CurrentButton = (script.Parent :: any) :: TextButton

-- Secure bridge channel locator link
local RequestPathFunction = ReplicatedStorage:WaitForChild("RequestPathAlignment") :: RemoteFunction

local function onConfirmButtonClicked()
	if not CurrentButton.Active then return end
	CurrentButton.Active = false
	CurrentButton.Text = "📡 TRANSMITTING SELECTION..."

	-- Change this string dynamically based on what path button they select (Creature/Mystic/Triumvirate)
	local chosenPathOption = "Mystic"

	-- INTERFACE ARCHITECTURE NOTE: RemoteFunction:InvokeServer yields the thread natively.
	-- If your server-side handler throws an error, InvokeServer crashes here.
	-- We wrap this in a type-safe pcall block to prevent thread termination during network partitions.
	local networkSuccess, serverSuccess, callbackMessage = pcall(function()
		return RequestPathFunction:InvokeServer(chosenPathOption)
	end)

	-- Evaluate both the network transport state and the server's database write status
	if networkSuccess and serverSuccess then
		CurrentButton.BackgroundColor3 = Color3.fromRGB(0, 255, 204) -- Crisp green confirm tone
		CurrentButton.Text = "✅ ALIGNMENT ARCHIVED"
		print("[Wildbound Client] Cloud profiles updated perfectly: " .. tostring(callbackMessage))
	else
		local errorMessage = if not networkSuccess then tostring(serverSuccess) else tostring(callbackMessage)
		CurrentButton.BackgroundColor3 = Color3.fromRGB(255, 51, 68) -- Error crimson red
		CurrentButton.Text = "❌ ACCESS REJECTED"
		warn("[Wildbound Client] Transaction dropped by gateway: " .. errorMessage)

		task.wait(2.0)
		CurrentButton.Active = true
		CurrentButton.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
		CurrentButton.Text = "CONFIRM ALIGNMENT"
	end
end

CurrentButton.MouseButton1Click:Connect(onConfirmButtonClicked)
