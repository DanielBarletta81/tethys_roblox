local U = {}
local Plan = require(script.Parent.RoutePlan)
function U.Mark(o)
	o:SetAttribute("Generator", "OrdovicOpening")
	o:SetAttribute("BuildId", Plan.BuildId)
	return o
end
function U.Folder(parent, name)
	local o = parent:FindFirstChild(name)
	if o then assert(o:IsA("Folder"), "Folder collision: " .. name); return o end
	o=Instance.new("Folder"); o.Name=name; U.Mark(o); o.Parent=parent; return o
end
function U.Part(parent, name, size, cf, material, color, collide)
	assert(not parent:FindFirstChild(name), "Existing build part: " .. name)
	local p=Instance.new("Part")
	p.Name,p.Size,p.CFrame=name,size,cf
	p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,collide~=false,false,true
	p.Material,p.Color=material or Enum.Material.Slate,color or Color3.fromRGB(58,65,63)
	p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
	U.Mark(p);p.Parent=parent;return p
end
function U.Guide(parent,name,position)
	local p=U.Part(parent,name,Vector3.new(2,2,2),CFrame.new(position),nil,nil,false)
	p.Transparency,p.CanQuery=1,false;return p
end
function U.Zone(parent,name,a,b,width,speed,phase,priority)
	local delta=b-a
	local p=U.Part(parent,name,Vector3.new(width,24,delta.Magnitude+12),CFrame.lookAt((a+b)/2,b),nil,nil,false)
	p.Transparency,p.CanQuery=1,false
	p:SetAttribute("FlowSpeed",speed);p:SetAttribute("ResponseTime",0.65)
	p:SetAttribute("PhaseName",phase);p:SetAttribute("Priority",priority or 1)
	p:SetAttribute("Active",true)
	return p
end
return U
