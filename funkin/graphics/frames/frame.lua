local Shader = require("funkin.graphics.shader")
local Matrix = require("funkin.math.matrix")
local lovg = love.graphics

local Frame = Classic:extend("Frame")
local matrix = Matrix()

function Frame:new(texture, angle, flipX, flipY, offsetX, offsetY)
	self.texture = texture
	self.angle = angle
	self.flip = {x = flipX or false, y = flipY or false}
	self.offset = Vector2(offsetX, offsetY)

	local w, h = 0, 0; if texture then w, h = texture:getDimensions() end
	self.rect = Bound2(Vector2.ZERO, Vector2(w, h))
	self.size = Vector3(w, h, 1)
end

function Frame:render(sprite)
	if self.texture == nil or not pcall(self.texture.isReadable, self.texture) then
		self.texture = nil
		return
	end

	lovg.pushall()

	local mesh = Frame.sharedMesh
	if mesh == nil then
		mesh = lovg.newMesh(require("funkin.graphics.Mesh").vertexFormat, {
			{-.5, -.5, 0, 0, 0},
			{.5, -.5, 0, 1, 0},
			{.5, .5, 0, 1, 1},
			{-.5, .5, 0, 0, 1}
		}, 'fan', 'static')
		Frame.sharedMesh = mesh
	end

	matrix:identity()
	local shader = sprite:applyStack(self.texture, mesh)
	Shader.model(shader, sprite:applyMatrix(matrix))
	lovg.draw(mesh)

	lovg.pop()
end

return Frame