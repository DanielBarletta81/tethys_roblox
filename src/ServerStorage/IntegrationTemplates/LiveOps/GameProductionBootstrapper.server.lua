-- Optional template runner; only explicitly supplied service modules can start.
if script:GetAttribute("TethysTemplateEnabled") ~= true then return end
for _, module in ipairs(script:GetChildren()) do
    if not module:IsA("ModuleScript") or module:GetAttribute("Enabled") ~= true then continue end
    local ok, service = pcall(require, module)
    if ok and type(service)=="table" and type(service.Init)=="function" then
        local started, reason = pcall(service.Init)
        if not started then warn(module.Name..": "..tostring(reason)) end
    else warn(module.Name.." must export Init()") end
end
