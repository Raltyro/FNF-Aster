local Actor = Basic:extend("Actor")

function Actor:new(x, y, z)
	Actor.super.new(self)

	self.position, self.rotation = {x = x or 0, y = y or 0, z = z or 0}, {x = 0, y = 0, z = 0}
	self.angle = 0 -- Rotates this Actor by Perspective

	self.offset = {x = 0, y = 0, z = 0}
	self.origin = {x = 0, y = 0, z = 0}
	self.size = {x = 0, y = 0, z = 0}
	self.scale = {x = 1, y = 1, z = 1}
	self.scrollFactor = {x = 1, y = 1, z = 1} -- How much it scrolls with the Camera Scroll Position
	self.flip = {x = false, y = false, z = false}

	--self.shader = nil
	self.diffuse = {r = 1, g = 1, b = 1, a = 1}
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

function Actor:setScrollFactor(x, y, z)
	x = x or self.scrollFactor.x
	self.scrollFactor.x, self.scrollFactor.y, self.scrollFactor.z = x, y or x, z or x
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