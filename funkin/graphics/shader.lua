local Shader = Classic:extend("Shader")
Shader.pragmas = {
	fragment = {
		default = [[
			vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
				return Texel(tex, texture_coords) * color;
			}
		]]
	},
	vertex = {
		header = [[
			uniform mat4 projectionMatrix;
			uniform mat4 viewMatrix;
			uniform mat4 modelMatrix;

			varying vec4 worldPosition;
			varying vec4 viewPosition;
			varying vec4 screenPosition;

			vec4 project(vec4 vertex) {
				return screenPosition = projectionMatrix * (viewPosition = viewMatrix * (worldPosition = modelMatrix * vertex));
			}
		]],
		default = [[
			#pragma header
			vec4 position(mat4 transform_projection, vec4 vertex_position) {
				return project(vertex_position);
			}
		]]
	}
}

local function include_pragmas(code, pragmas)
	local lines = {}
	for line in string.gmatch(code .. "\n", "(.-)\n") do
		local new = line:gsub("#pragma (%w+)", function(pragma)
			return pragmas[pragma] or ''
		end)
		table.insert(lines, new)
	end
	return table.concat(lines, '\n')
end

function Shader:new(fragmentSource, vertexSource)
	fragmentSource, vertexSource = include_pragmas(fragmentSource or Shader.pragmas.fragment.default, Shader.pragmas.fragment),
		include_pragmas(vertexSource or Shader.pragmas.vertex.default, Shader.pragmas.vertex)

	local s, w = love.graphics.validateShader(false, fragmentSource, vertexSource)
	if not s then
		warn("Unable to Validate Shader", w, fragmentSource, vertexSource)
		fragmentSource, vertexSource = include_pragmas(Shader.pragmas.fragment.default, Shader.pragmas.fragment),
			include_pragmas(Shader.pragmas.vertex.default, Shader.pragmas.vertex)
	end

	local shader = love.graphics.newShader(fragmentSource, vertexSource)
	return shader
end

local column, modelMatrix, viewMatrix, projectionMatrix = 'column', 'modelMatrix', 'viewMatrix', 'projectionMatrix'
function Shader.model(shader, data) shader:send(modelMatrix, column, data) end
function Shader.view(shader, data) shader:send(viewMatrix, column, data) end
function Shader.projection(shader, data) shader:send(projectionMatrix, column, data) end

function Shader.get_DEFAULT() Shader.DEFAULT = Shader() return Shader.DEFAULT end
return Shader