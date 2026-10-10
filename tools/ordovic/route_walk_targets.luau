-- Server Play, read-only. Supply local routeId before this source if desired.
-- Feed the returned snapshot into RaisedRoutes.controller.playtest in Client.
local route=workspace.WildboundOpening_Ordovic["10_RouteConnections"][routeId or "G2_IntakeToCity"]
local floors={}
for _,part in ipairs(route:GetChildren())do
	if part.Name:match("^Floor")then table.insert(floors,part)end
end
table.sort(floors,function(a,b)return a.Name<b.Name end)
local targets={}
for _,floor in ipairs(floors)do
	local point=floor.CFrame:PointToWorldSpace(Vector3.new(0,1.5,-floor.Size.Z/2+2))
	table.insert(targets,{Name=floor.Name,Point={point.X,point.Y,point.Z}})
end
local point=route.Arrival.Position+Vector3.new(0,1.5,0)
table.insert(targets,{Name="Arrival",Point={point.X,point.Y,point.Z}})
return game.HttpService:JSONEncode({RouteId=route.Name,Targets=targets})
