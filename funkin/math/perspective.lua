local cos, sin, rad = math.cos, math.sin, math.rad

local Perspective = Classic:extend("Perspective")
-- automatically adjusted in funkin/init
Perspective.aspect = 1
Perspective.scale = 1

function Perspective:new(fov, aspect, position, rotation)
	self.fov = fov or 45
	self.aspect = aspect or nil
	self.near = 0
	self.far = 2048

	self.position, self.rotation = position or Vector3.ZERO, rotation or Vector3.ZERO
	--self.look = nil
	self.up = Vector3.Y
	self.scale = nil

	self._projection, self._dirtyProjection = Matrix(), true
	self._view, self._dirtyView = Matrix(), true
	self:get_projection()
	self:get_view()
end

function Perspective:get_projection()
	if self._dirtyProjection or self.aspect ~= self._lastAspect then
		self._lastAspect = self.aspect
		self._projection:identity():perspective(self.fov, self.aspect, self.near, self.far)
	end
	return self._projection
end

function Perspective:get_view()
	if self._dirtyView or self.scale ~= self._lastScale then
		self._lastScale = self.scale
		if self.look and self.up then
			self._view:identity():lookAt(self.position * self.scale, self.look, self.up)
		else
			self._view:identity():compose(-self.position * self.scale, -self.rotation)
		end
		if self.scale ~= 1 then self._view:scale(self.scale) end
	end
	return self._view
end

local projectionProps, _dirtyProjection = {'fov', 'aspect', 'near', 'far'}, '_dirtyProjection'
local viewProps, _dirtyView = {'position', 'rotation', 'target', 'up', 'scale'}, '_dirtyView'
for _, prop in ipairs(projectionProps) do Perspective['set_' .. prop] = function(self, v) rawset(self, prop, v); self[_dirtyProjection] = true end end
for _, prop in ipairs(viewProps) do Perspective['set_' .. prop] = function(self, v) rawset(self, prop, v); self[_dirtyView] = true end end

return Perspective