local Shader = Classic:extend("Shader")
local pragmas = {
	fragment = {
		header = [[
			uniform Image MainTex;
		]],
		body = [[
			love_PixelColor = Texel(MainTex, love_PixelCoord) * VaryingColor;
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
		]],
		body = [[
			worldPosition = modelMatrix * VertexPosition;
			viewPosition = viewMatrix * worldPosition;
			screenPosition = projectionMatrix * viewPosition;
		]]
	}
}
pragmas.fragment.default = love.filesystem.read('funkin/graphics/shader/default.fsh')
pragmas.vertex.default = love.filesystem.read('funkin/graphics/shader/default.vsh')

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
	fragmentSource, vertexSource = include_pragmas(fragmentSource or pragmas.fragment.default, pragmas.fragment),
		include_pragmas(vertexSource or pragmas.vertex.default, pragmas.vertex)

	local s, w = love.graphics.validateShader(false, fragmentSource, vertexSource)
	if not s then
		warn("Unable to Validate Shader", w, fragmentSource, vertexSource)
		fragmentSource, vertexSource = include_pragmas(pragmas.fragment.default, pragmas.fragment), include_pragmas(pragmas.vertex.default, pragmas.vertex)
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