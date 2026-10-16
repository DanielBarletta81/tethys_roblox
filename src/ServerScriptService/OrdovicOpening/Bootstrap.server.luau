local root = workspace:WaitForChild("WildboundOpening_Ordovic", 15)
if not root or not root:GetAttribute("CaveOpenerReady") or not root:GetAttribute("OpeningEnabled") then return end
require(script.Parent.Controller).Start(root)
require(script.Parent.WaterSurfaceService).Start(root)
local cave = root:FindFirstChild("08_HiddenCaveVein")
if cave and cave:GetAttribute("BuildReady") then require(script.Parent.CordgeController).Start(cave) end
