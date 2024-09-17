local Object = Basic:extend("Object", ...)
Object.defaultAntialiasing = false

function Object.getAngleTowards(x, y, x2, y2)
	return math.deg(math.atan((x2 - x) / (y2 - y))) + (y > y2 and 180 or 0)
end

function Object:new(x, y)
	Object.super.new(self)

	self:setPosition(x, y)
	self.width, self.height = 0, 0

	self.offset = {x = 0, y = 0}
	self.origin = {x = 0, y = 0}
	self.scale = {x = 1, y = 1}
	self.scrollFactor = {x = 1, y = 1}
	self.flipX = false
	self.flipY = false
	self.angle = 0

	self.shader = nil
	self.antialiasing = Object.defaultAntialiasing or false
	self.color = 0xFFFFFFFF
	self.alpha = 1

	self.moves = false
	self.velocity = {x = 0, y = 0}
	self.acceleration = {x = 0, y = 0}
end

function Object:get_frameWidth() return self.width end
function Object:get_frameHeight() return self.height end

function Object:destroy()
	Object.super.destroy(self)

	self.offset.x, self.offset.y = 0, 0
	self.scale.x, self.scale.y = 1, 1

	self.shader = nil
end

function Object:setPosition(x, y)
	self.x, self.y = x or 0, y or 0
end

function Object:setScrollFactor(x, y)
	self.scrollFactor.x, self.scrollFactor.y = x or 0, y or x or 0
end

function Object:getMidpoint()
	return self.x + self.width / 2, self.y + self.height / 2
end

function Object:screenCenter(axes)
	if axes == nil then axes = "xy" end
	if axes:find("x") then self.x = (game.width - self.width) / 2 end
	if axes:find("y") then self.y = (game.height - self.height) / 2 end
	return self
end

function Object:updateHitbox()
	local width, height = self.width, self.height
	self:fixOffsets(width, height)
	self:centerOrigin(width, height)
end

function Object:centerOffsets(__width, __height)
	self.offset.x = (__width or self.width) / 2
	self.offset.y = (__height or self.height) / 2
end

function Object:fixOffsets(__width, __height)
	self.offset.x = ((__width or self.frameWidth) - self.width) / 2
	self.offset.y = ((__height or self.frameHeight) - self.height) / 2
end

function Object:centerOrigin(__width, __height)
	self.origin.x = (__width or self.width) / 2
	self.origin.y = (__height or self.height) / 2
end

function Object:update(dt)
	if self.moves then
		self.velocity.x = self.velocity.x + self.acceleration.x * dt
		self.velocity.y = self.velocity.y + self.acceleration.y * dt

		self.x = self.x + self.velocity.x * dt
		self.y = self.y + self.velocity.y * dt
	end
end

return Object