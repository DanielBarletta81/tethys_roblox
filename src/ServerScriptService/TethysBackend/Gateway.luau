local Http = game:GetService("HttpService")
local Run = game:GetService("RunService")
local Gateway = {}
Gateway.__index = Gateway
function Gateway.new(config)
    local base = config:GetAttribute("BaseUrl")
    if type(base)~="string" or base=="" then return nil,"Set the gateway BaseUrl" end
    local localDevelopment = Run:IsStudio() and (base:match("^http://localhost:%d+$") or base:match("^http://127%.0%.0%.1:%d+$"))
    if not base:match("^https://[%w%.%-]+[:%d]*$") and not localDevelopment then
        return nil,"Use an HTTPS origin; loopback HTTP is Studio-only"
    end
    return setmetatable({Base=base,SecretName=config:GetAttribute("SecretName"),Config=config},Gateway)
end
function Gateway:Request(method, path, payload)
    local allowed = path=="/api/v1/tethys/lore/cms-stream" or path=="/api/v1/wildbound/survival/zone-update"
        or path=="/api/v1/tethys/instances/heartbeat-register"
    if not allowed or (method~="GET" and method~="POST") then return nil,"Unsupported gateway operation" end
    local ok,response = pcall(function()
        local headers = {["Content-Type"]="application/json"}
        if method=="POST" then
            local localToken = Run:IsStudio() and self.Config:GetAttribute("DevelopmentToken")
            if type(localToken)=="string" and localToken~="" then headers.Authorization="Bearer "..localToken
            else headers.Authorization=Http:GetSecret(self.SecretName):AddPrefix("Bearer ") end
        end
        local request = {Url=self.Base..path,Method=method,Headers=headers}
        if method=="POST" then request.Body=Http:JSONEncode(payload) end
        return Http:RequestAsync(request)
    end)
    if not ok or not response.Success then return nil,"Gateway unavailable" end
    local decoded,data = pcall(function()return Http:JSONDecode(response.Body)end)
    if not decoded or type(data)~="table" or data.success~=true then return nil,"Invalid gateway response" end
    return data
end
return Gateway
