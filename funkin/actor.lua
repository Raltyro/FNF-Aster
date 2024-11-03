local Shader = require("funkin.graphics.shader")
local lovg = love.graphics

local Actor = Basic:extend("Actor")

function Actor:new(x, y, z)
	Actor.super.new(self)

	self.position, self.rotation, self.scale = Vector3(x, y, z), Vector3(0, 0, 0), Vector3.ONE
	self.visible = true
	self.layer = 0

	self.offset = Vector3()
	self.origin = Vector3()
	self.size = Vector3()
	self.flip = {x = false, y = false, z = false}

	self.smoothing = true
	self.wrap = {x = 'clamp', y = 'clamp', z = 'clamp'}

	self.diffuse = Color.WHITE
	self.shader = nil
	self.depth = 'less'
	self.cull = 'none'
	self.blend = 'alpha'
	self.alphamode = 'alphamultiply'
	self.wireframe = false
end

local none, alpha, clamp, linear, nearest = 'none', 'alpha', 'clamp', 'linear', 'nearest'
function Actor:applyStack(texture, mesh, view, projection)
	if texture then
		texture:setFilter(self.smoothing and linear or nearest)
		texture:setWrap(self.wrap.x or clamp, self.wrap.y, self.wrap.z)
		if mesh then mesh:setTexture(texture) end
	end

	local shader = self.shader or Shader.DEFAULT
	Shader.view(shader, Matrix():lookAt(Vector3.ZERO, -Vector3.Z, Vector3.Y))
	Shader.projection(shader, Matrix())

	lovg.setShader(shader)
	lovg.setColor(self.diffuse.r, self.diffuse.g, self.diffuse.b, self.diffuse.a)
	lovg.setBlendMode(self.blend or alpha, self.alphamode)
	lovg.setWireframe(self.wireframe == true)
	lovg.setMeshCullMode(self.cull or none)
	if self.depth then lovg.setDepthMode(self.depth, true) else lovg.setDepthMode() end

	return shader
end

function Actor:applyMatrix(matrix)
	return matrix:translate(self.position):compose(self.origin, self.rotation, self.scale):translate(self.offset)
end

function Actor:setPosition(x, y, z)
	self.position.x, self.position.y, self.position.z = x or self.position.x, y or self.position.y, z or self.position.z
end

function Actor:setRotation(x, y, z)
	self.rotation.x, self.rotation.y, self.rotation.z = x or self.rotation.x, y or self.rotation.y, z or self.rotation.z
end

function Actor:destroy()
	Actor.super.destroy(self)
	self.shader = nil
end

function Actor:getMidpoint()
	return self.position.x + self.size.x * 0.5, self.position.y + self.size.y * 0.5, self.position.z + self.size.z * 0.5
end

function Actor:get_x() return self.position.x end; function Actor:set_x(v) self.position.x = v end
function Actor:get_y() return self.position.y end; function Actor:set_y(v) self.position.y = v end
function Actor:get_z() return self.position.z end; function Actor:set_z(v) self.position.z = v end
function Actor:get_rotX() return self.rotation.x end; function Actor:set_rotX(v) self.rotation.x = v end
function Actor:get_rotY() return self.rotation.y end; function Actor:set_rotY(v) self.rotation.y = v end
function Actor:get_rotZ() return self.rotation.z end; function Actor:set_rotZ(v) self.rotation.z = v end
function Actor:get_width() return self.size.x end; function Actor:set_width(v) self.size.x = v end
function Actor:get_height() return self.size.y end; function Actor:set_height(v) self.size.y = v end
function Actor:get_alpha() return self.diffuse.a end; function Actor:set_alpha(v) self.diffuse.a = v end

return Actor