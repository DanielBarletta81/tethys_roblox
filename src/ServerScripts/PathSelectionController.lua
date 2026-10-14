--!strict
-- Place inside StarterGui -> PathSelectionGui -> ConfirmPathButton -> PathSelectionController
-- Manages immediate visual inputs feedback loop layers and invokes server pipeline events

local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- FIX: Upgraded from 'as TextButton' to standard Luau strict double-colon casting
local CurrentButton = script.Parent :: TextButton

-- FIX: Upgraded from 'as RemoteFunction' to standard Luau strict double-colon casting
local RequestPathFunction = ReplicatedStorage:WaitForChild("RequestPathAlignment") :: RemoteFunction

local function onConfirmButtonClicked()
	-- Disable the interaction interface immediately to prevent double-click transaction flooding
	CurrentButton.Active = false
	CurrentButton.Text = "📡 TRANSMITTING SELECTION..."

	-- Change this target variable dynamically based on what path the player selects in your UI layout
	local chosenPathOption = "Mystic" 

	-- Invoke the server-authoritative backend pipeline route and wait for verification response
	local success, callbackMessage = RequestPathFunction:InvokeServer(chosenPathOption)

	if success then
		CurrentButton.BackgroundColor3 = Color3.fromRGB(0, 255, 204) -- High-vibrancy green confirm tone
		CurrentButton.Text = "✅ ALIGNMENT ARCHIVED!"
		print("[Tethys Client] Cloud profile updated successfully: " .. callbackMessage)
	else
		CurrentButton.BackgroundColor3 = Color3.fromRGB(255, 51, 68) -- Error crimson red tone
		CurrentButton.Text = "❌ ACCESS REJECTED"
		warn("[Tethys Client] LiveOps API transaction dropped: " .. callbackMessage)

		-- Re-enable button after 2 seconds to allow retry cycles
		task.wait(2.0)
		CurrentButton.Active = true
		CurrentButton.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
		CurrentButton.Text = "CONFIRM PATH SELECTION"
	end
end

CurrentButton.MouseButton1Click:Connect(onConfirmButtonClicked)
