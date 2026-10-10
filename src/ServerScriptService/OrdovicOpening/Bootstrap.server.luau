local root = workspace:WaitForChild("WildboundOpening_Ordovic")
if root:GetAttribute("BuildReady") and root:GetAttribute("OpeningEnabled") then
require(script.Parent.Controller).Start(root)
require(script.Parent.WaterSurfaceService).Start(root)
if root:FindFirstChild("10_RouteConnections") then
	require(script.Parent.RouteProgressService).Start(root)
	require(script.Parent.MaintenanceService).Start(root)
end
local cave = root:FindFirstChild("08_HiddenCaveVein")
if cave and cave:GetAttribute("BuildReady") then require(script.Parent.CordgeController).Start(cave) end
end
