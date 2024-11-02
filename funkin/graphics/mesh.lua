local Mesh = Basic:extend("Mesh")
if love._version_major > 11 then
	Mesh.vertexFormat = {
		{format = "floatvec3", name = "VertexPosition"},
		{format = "floatvec2", name = "VertexTexCoord"},
		{format = "floatvec3", name = "VertexNormal"},
	}
else
	Mesh.vertexFormat = {
		{"VertexPosition", "float", 3},
		{"VertexTexCoord", "float", 2},
		{"VertexNormal", "float", 3},
	}
end

function Mesh:new()
	
end

function Mesh:fromOBJ(data)
	
end

return Mesh