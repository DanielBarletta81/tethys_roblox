local Players = game:GetService("Players")
local Service = {}
Service.__index = Service
function Service.new(gateway,opening)
    return setmetatable({Gateway=gateway,Opening=opening,Sent={},Busy={},Connections={},Running=false},Service)
end
function Service:RefreshLore()
    local payload=self.Gateway:Request("GET","/api/v1/tethys/lore/cms-stream")
    local cave=self.Opening and self.Opening:FindFirstChild("01_High_Cave")
    local addition=cave and cave:FindFirstChild("CaveExpansion")
    local metadata=game.ServerScriptService:FindFirstChild("OrdovicOpening")
    metadata=metadata and metadata:FindFirstChild("LoreMetadata")
    if not payload or not addition or not metadata then return false end
    require(metadata).Apply(addition,payload)
    return true
end
function Service:Mirror(player,payload)
    if typeof(player)~="Instance" or not player:IsA("Player") then return false end
    local character=player.Character
    local human=character and character:FindFirstChildOfClass("Humanoid")
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if player.Parent~=Players or not human or human.Health<=0 or not root or not self.Opening
        or type(payload)~="table" or payload.userId~=tostring(player.UserId)
        or payload.targetZone~="Ordovic_Rapids" or payload.applyInjury~=0
        or self.Sent[player] or self.Busy[player] then return false end
    local flow=self.Opening:FindFirstChild("03_FlowZones")
    local inside=false
    if flow then for _,zone in ipairs(flow:GetChildren())do
        if not zone:IsA("BasePart") or zone:GetAttribute("PhaseName")=="REJECT_CASCADE"
            or zone:GetAttribute("PhaseName")=="FLUME_DROP" then continue end
        local p=zone.CFrame:PointToObjectSpace(root.Position);local h=zone.Size/2
        if math.abs(p.X)<=h.X and math.abs(p.Y)<=h.Y and math.abs(p.Z)<=h.Z then inside=true;break end
    end end
    if not inside then return false end
    self.Busy[player]=true
    task.spawn(function()
        local response=self.Gateway:Request("POST","/api/v1/wildbound/survival/zone-update",payload)
        self.Busy[player]=nil
        if player.Parent==Players then
            if response then self.Sent[player]=true end
            player:SetAttribute("WB_OpenerTelemetryStatus",response and "Sent" or "Unavailable")
        end
    end)
    return true
end
function Service:Start()
    if self.Running then return self end
    self.Running=true
    local owner=game.ServerScriptService:FindFirstChild("OrdovicOpening")
    if owner then
        local event=owner:FindFirstChild("BE_OpeningZoneMirror")
        if not event then event=Instance.new("BindableEvent");event.Name="BE_OpeningZoneMirror";event.Parent=owner end
        assert(event:IsA("BindableEvent"),"Existing zone hook has a different owner")
        table.insert(self.Connections,event.Event:Connect(function(player,payload)self:Mirror(player,payload)end))
    end
    table.insert(self.Connections,Players.PlayerRemoving:Connect(function(player)self.Sent[player]=nil;self.Busy[player]=nil end))
    task.spawn(function()
        while self.Running do
            self:RefreshLore()
            self.Gateway:Request("POST","/api/v1/tethys/instances/heartbeat-register",{
                jobId=game.JobId~="" and game.JobId or "studio-local",serverPlaceId=game.PlaceId,
                activePlayerCount=#Players:GetPlayers(),maxPlayersCapacity=Players.MaxPlayers,
                serverUptimeSeconds=math.floor(workspace.DistributedGameTime),assignedTestingCell="Control_A",
            })
            task.wait(30)
        end
    end)
    return self
end
function Service:Stop()
    self.Running=false
    for _,connection in ipairs(self.Connections)do connection:Disconnect()end
    self.Connections={}
end
return Service
