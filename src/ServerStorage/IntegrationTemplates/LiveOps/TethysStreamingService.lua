-- Read-only layout adapter. Runtime HTTP data must not overwrite authored Terrain.
local Streaming = {}
function Streaming.Preview(segments)
    if type(segments) ~= "table" then return nil, "Expected layout segments" end
    local plan = {}
    for _, segment in ipairs(segments) do
        local center, size = segment.centerStuds, segment.sizeStuds
        if type(center) ~= "table" or type(size) ~= "table" then return nil, "Malformed segment" end
        for _, axis in ipairs({"x","y","z"}) do
            if type(center[axis])~="number" or math.abs(center[axis])>32768
                or type(size[axis])~="number" or not(size[axis]>0 and size[axis]<=32768) then
                return nil, "Invalid region coordinates"
            end
        end
        table.insert(plan,{Id=segment.id,Center=Vector3.new(center.x,center.y,center.z),Size=Vector3.new(size.x,size.y,size.z),Material=segment.targetMaterial})
    end
    return plan
end
return Streaming
