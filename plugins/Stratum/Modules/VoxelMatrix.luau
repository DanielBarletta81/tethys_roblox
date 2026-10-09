--!strict
local Matrix={}
local materials: {[number]:Enum.Material}={}
for _,material in ipairs(Enum.Material:GetEnumItems()) do materials[material.Value]=material end
function Matrix.Flatten(channels: any, bounds: any): any
	local x,y,z=bounds.Width/4,bounds.Height/4,bounds.Length/4
	local ids,solid,liquid=table.create(x*y*z),table.create(x*y*z),table.create(x*y*z)
	local index=1
	for i=1,x do for j=1,y do for k=1,z do
		local material=channels.SolidMaterial[i][j][k]
		assert(typeof(material)=="EnumItem" and material.EnumType==Enum.Material and material~=Enum.Material.Water,"Invalid solid material")
		ids[index],solid[index],liquid[index]=material.Value,channels.SolidOccupancy[i][j][k],channels.LiquidOccupancy[i][j][k]
		index+=1
	end end end
	return {SizeX=x,SizeY=y,SizeZ=z,Materials=ids,Solid=solid,Liquid=liquid}
end
function Matrix.Expand(chunk: any): any
	local out={SolidMaterial={},SolidOccupancy={},LiquidOccupancy={}}
	local index=1
	for x=1,chunk.SizeX do
		out.SolidMaterial[x],out.SolidOccupancy[x],out.LiquidOccupancy[x]={},{},{}
		for y=1,chunk.SizeY do
			out.SolidMaterial[x][y],out.SolidOccupancy[x][y],out.LiquidOccupancy[x][y]=table.create(chunk.SizeZ),table.create(chunk.SizeZ),table.create(chunk.SizeZ)
			for z=1,chunk.SizeZ do
				local material=materials[chunk.Materials[index]]
				assert(material and material~=Enum.Material.Water,"Unknown solid material ID")
				out.SolidMaterial[x][y][z],out.SolidOccupancy[x][y][z],out.LiquidOccupancy[x][y][z]=material,chunk.Solid[index],chunk.Liquid[index]
				index+=1
			end
		end
	end
	return out
end
return Matrix
