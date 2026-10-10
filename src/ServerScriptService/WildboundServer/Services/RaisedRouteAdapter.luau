local Players=game:GetService("Players")
local Runtime=require(script.Parent.RuntimeService)
local Title=require(script.Parent.TitleService)
local Adapter={}
local destinations={
	CITY={Marker="GUIDE_CityThreshold",Region="SKY_CITY",Zone="UPPER_CITY_ARRIVAL",Chapter=2,Title="SKY_CITY",Context="Inside the Machine"},
	WATCHER={Marker="GUIDE_WatcherApproach",Region="WATCHER",Zone="RIDGE_APPROACH",Chapter=2,Title="WATCHER_VOLCANO",Context="The mountain ahead"},
}
function Adapter.Commit(id,player)
	local destination=destinations[id]
	if not destination or typeof(player)~="Instance" or player.Parent~=Players or not player:IsA("Player") then return false end
	local state=Runtime:Get(player)
	local root=workspace:FindFirstChild("WildboundOpening_Ordovic")
	local character=player.Character
	local human=character and character:FindFirstChildOfClass("Humanoid")
	local part=character and character:FindFirstChild("HumanoidRootPart")
	local marker=root and root["00_Guides"]:FindFirstChild(destination.Marker)
	if not state or not state.IntakeOutcome or not marker or not root:GetAttribute("BuildReady")
		or not human or human.Health<=0 or not part or human.FloorMaterial==Enum.Material.Air
		or human:GetState()==Enum.HumanoidStateType.Swimming then return false end
	local p=marker.CFrame:PointToObjectSpace(part.Position)
	local half=marker.Size/2
	if math.abs(p.X)>half.X or math.abs(p.Y)>half.Y or math.abs(p.Z)>half.Z then return false end
	Runtime:Set(player,"Region",destination.Region)
	Runtime:Set(player,"Zone",destination.Zone)
	Runtime:Set(player,"Checkpoint",id=="CITY" and "CP_G2_UpperCityArrival" or "CP_G2_WatcherRidge")
	Runtime:MarkLandmarkKnown(player,destination.Region)
	Runtime:SetLastAction(player,"ARRIVAL -> "..destination.Region)
	player:SetAttribute("WB_Chapter",math.max(tonumber(player:GetAttribute("WB_Chapter")) or 1,destination.Chapter))
	Title:TryReveal(player,destination.Title,destination.Context)
	return true
end
function Adapter.Start()
	local opening=game.ServerScriptService.OrdovicOpening
	local endpoint=opening:FindFirstChild("BF_RouteProgress") or Instance.new("BindableFunction")
	endpoint.Name="BF_RouteProgress";endpoint.Parent=opening;endpoint.OnInvoke=Adapter.Commit
end
return Adapter
