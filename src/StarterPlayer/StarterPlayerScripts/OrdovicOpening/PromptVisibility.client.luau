local Players = game:GetService("Players")
local player = Players.LocalPlayer
local root = workspace:WaitForChild("WildboundOpening_Ordovic")
if not root:GetAttribute("BuildReady") then return end
local works = root:WaitForChild("06_IntakeWorks")
local function refresh()
	local captured = player:GetAttribute("WB_IntakeCaptured") == true
	for _, name in ipairs({"Prompt_TakeLine", "Prompt_BreakFree"}) do
		local host = works:FindFirstChild(name)
		if host then
			local prompt = host:FindFirstChildOfClass("ProximityPrompt")
			if prompt then prompt.Enabled = captured end
		end
	end
end
player:GetAttributeChangedSignal("WB_IntakeCaptured"):Connect(refresh)
works.DescendantAdded:Connect(refresh)
refresh()
