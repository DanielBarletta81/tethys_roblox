--!strict
assert(plugin,"Install Stratum as a local Studio plugin")
local modules=script:WaitForChild("Modules")
local backend=require(modules.RobloxBackend).new(plugin)
local session=require(modules.Session).new(backend)
local toolbar=plugin:CreateToolbar("Tethys")
local button=toolbar:CreateButton("Stratum","Capture Terrain archives and plan R1B landforms","","Stratum")
button.ClickableWhenViewportHidden=true
local widget=plugin:CreateDockWidgetPluginGuiAsync("TethysStratum_v1",DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right,false,false,370,750,320,400))
widget.Title="Stratum · Terrain + R1B"
backend.CancelPending()
local cleanup=require(modules.Panel).mount(widget,session,backend)
local connections={button.Click:Connect(function() widget.Enabled=not widget.Enabled end),widget:GetPropertyChangedSignal("Enabled"):Connect(function() button:SetActive(widget.Enabled) end)}
button:SetActive(widget.Enabled)
plugin.Unloading:Connect(function()
	session:Cancel();backend.CancelPending();cleanup()
	for _,connection in ipairs(connections) do connection:Disconnect() end
	widget:Destroy();toolbar:Destroy()
end)
