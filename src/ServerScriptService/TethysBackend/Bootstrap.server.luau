-- Networking belongs to this owner, outside the reviewed Ordovic gameplay sandbox.
local config=game.ServerStorage:WaitForChild("TethysBackendConfig",10)
if not config or config:GetAttribute("Enabled")~=true then return end
local gateway,reason=require(script.Parent.Gateway).new(config)
if not gateway then warn("Tethys backend: "..reason);return end
local service=require(script.Parent.Service).new(gateway,workspace:FindFirstChild("WildboundOpening_Ordovic")):Start()
game:BindToClose(function()service:Stop()end)
