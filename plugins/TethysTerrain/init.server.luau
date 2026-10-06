-- Local Studio plugin entry point. Modules stay separate in the model artifact.
assert(plugin, "Install Tethys Terrain as a local Studio plugin")
local modules = script:WaitForChild("Modules")
local Backend = require(modules.RobloxBackend)
local EditSession = require(modules.EditSession)
local Panel = require(modules.Panel)
local toolbar = plugin:CreateToolbar("Tethys")
local button = toolbar:CreateButton("TethysTerrain", "Preview and sculpt seeded Terrain patches", "", "Terrain")
button.ClickableWhenViewportHidden = true
local info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 360, 700, 320, 420)
local widget = plugin:CreateDockWidgetPluginGuiAsync("TethysTerrain_v1", info)
widget.Title = "Tethys Terrain"
local backend = Backend.new(plugin)
backend.CancelPending()
local session = EditSession.new(backend)
local cleanup = Panel.mount(widget, session, backend)
local connections = {}
table.insert(connections, button.Click:Connect(function() widget.Enabled = not widget.Enabled end))
table.insert(connections, widget:GetPropertyChangedSignal("Enabled"):Connect(function() button:SetActive(widget.Enabled) end))
button:SetActive(widget.Enabled)
plugin.Unloading:Connect(function()
	backend.CancelPending()
	cleanup()
	for _, connection in ipairs(connections) do connection:Disconnect() end
	widget:Destroy()
	toolbar:Destroy()
end)
