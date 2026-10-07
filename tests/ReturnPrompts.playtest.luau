-- Client-only acceptance against the live prompt owner. No rewards or world progression.
local player, service = game.Players.LocalPlayer, game:GetService("ProximityPromptService")
local ui = player.PlayerGui:WaitForChild("TethysUI")
assert(not ui:GetAttribute("WB_MenuOpen") and not ui:GetAttribute("WB_ReturnNoticeActive"), "Run with menus and return cue closed")
local oldMenu, oldReturn, enabled = ui:GetAttribute("WB_MenuOpen"), ui:GetAttribute("WB_ReturnNoticeActive"), service.Enabled
local host = Instance.new("Part"); host.Name, host.Size, host.Anchored, host.CanCollide, host.Transparency = "ReturnPromptFixture", Vector3.one, true, false, 1
host.CFrame, host.Parent = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3), workspace
local prompt = Instance.new("ProximityPrompt")
prompt.Name, prompt.ActionText, prompt.ObjectText, prompt.HoldDuration = "FixturePrompt", "Tend heat", "Heat pit · 1 dry fiber", 5
prompt.KeyboardKeyCode, prompt.GamepadKeyCode, prompt.RequiresLineOfSight, prompt.Parent = Enum.KeyCode.F, Enum.KeyCode.ButtonX, false, host
local results, ended, triggered = {}, 0, 0
local endConnection = service.PromptButtonHoldEnded:Connect(function(p) if p == prompt then ended += 1 end end)
local triggerConnection = prompt.Triggered:Connect(function() triggered += 1 end)
local function test(name, fn)
	local ok, err = pcall(fn); table.insert(results, {name=name, passed=ok, error=not ok and tostring(err) or nil}); assert(ok, name .. ": " .. tostring(err))
end
local function waitFor(fn)
	local limit = os.clock()+3
	repeat if fn() then return true end task.wait(0.05) until os.clock() >= limit
	return false
end
local function view()
	for _, frame in ipairs(ui.InteractionUI.FR_PromptBar:GetChildren()) do
		if frame:IsA("Frame") and frame:GetAttribute("WB_PromptPath") == prompt:GetFullName() then return frame end
	end
end
local ok, err = pcall(function()
	test("Native prompt shows its complete supply cost", function()
		assert(waitFor(view), "Fixture prompt was not shown")
		local frame = view(); assert(frame.TL_Object.Text == prompt.ObjectText)
		assert(frame.TL_Object.TextBounds.Y <= frame.TL_Object.AbsoluteSize.Y + 1)
	end)
	test("Return priority ends a hold and hides native interactions", function()
		prompt:InputHoldBegin(); task.wait(0.2); ui:SetAttribute("WB_ReturnNoticeActive", true); task.wait(0.15)
		assert(not service.Enabled and not ui.InteractionUI.FR_PromptBar.Visible)
		assert(ended > 0 and triggered == 0)
	end)
	test("A menu remains blocked when the return cue ends", function()
		ui:SetAttribute("WB_MenuOpen", true); ui:SetAttribute("WB_ReturnNoticeActive", false); task.wait()
		assert(not service.Enabled and not ui.InteractionUI.FR_PromptBar.Visible)
	end)
	test("Prompts recover after both blockers clear", function()
		ui:SetAttribute("WB_MenuOpen", false); task.wait()
		assert(service.Enabled == enabled and waitFor(view) and ui.InteractionUI.FR_PromptBar.Visible)
		assert(triggered == 0)
	end)
end)
prompt:InputHoldEnd(); host:Destroy(); endConnection:Disconnect(); triggerConnection:Disconnect()
ui:SetAttribute("WB_MenuOpen", oldMenu); ui:SetAttribute("WB_ReturnNoticeActive", oldReturn)
task.wait(); assert(ok, tostring(err))
return results
