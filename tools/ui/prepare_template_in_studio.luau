-- Edit-only cleanup of the existing TethysUI template. Preserves all layout/art
-- instances. The connector's edit recording supplies Studio Undo/Redo.
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before preparing the template")
local ui = game:GetService("StarterGui"):WaitForChild("TethysUI")
local module = game:GetService("ReplicatedStorage").WildboundUI.TemplateState
-- Evaluate this pure module in the reviewed caller context; do not change the
-- legacy UI library's capability configuration to make Edit require succeed.
local prepare = assert(loadstring(module.Source))()
prepare.Prepare(ui)
return { Enabled = ui.Enabled, Version = ui:GetAttribute("WB_TemplateVersion") }
