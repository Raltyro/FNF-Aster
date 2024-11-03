local Vector2 = require("funkin.math.Vector2")

local Bound2 = Classic:extend("Bound2")

local status, ffi
if type(jit) == "table" and jit.status() then
	status, ffi = pcall(require, "ffi")
	if status then
		ffi.cdef "typedef struct { ffi_vec2 min, max;} ffi_bound2;"
		Bound2.__call = ffi.typeof("ffi_bound2")
	end
end

local number = 'number'
function Bound2:new(min, max) self.min, self.max = min or Vector2.ZERO, max or Vector2.ZERO end
function Bound2:clone(other)
	if other then
		other.min, other.max = self.min, self.max
		return other
	end
	return Bound2(self.min, self.max)
end
function Bound2:unpack() return self.min, self.max end

function Bound2:contains(v)
	return self.min.x <= v.x and self.min.y <= v.y and self.max.x >= v.x and self.max.y >= v.y
end

function Bound2:get_left() return self.min.x end; function Bound2:set_left(v) self.min.x = v end
function Bound2:get_top() return self.min.y end; function Bound2:set_top(v) self.min.y = v end
function Bound2:get_right() return self.max.x end; function Bound2:set_right(v) self.max.x = v end
function Bound2:get_bottom() return self.max.y end; function Bound2:set_bottom(v) self.min.y = v end
Bound2.get_x = Bound2.get_left; Bound2.set_x = Bound2.set_left
Bound2.get_y = Bound2.get_top; Bound2.set_y = Bound2.set_top
function Bound2:get_width() return self.max.x - self.min.x end; function Bound2:set_width(v) self.max.x = v + self.min.x end
function Bound2:get_height() return self.max.y - self.min.y end; function Bound2:set_height(v) self.max.y = v + self.min.y end
function Bound2:get_size() return self.max - self.min end; function Bound2:set_size(v) self.max = v + self.min end

function Bound2:__tostring() return 'Bound2 (min: ' .. table.concat(tostring(self.min), ', ') .. ', max: ' .. table.concat(tostring(self.max), ', ') .. ')'  end

function Bound2.get_ZERO() return Bound2(Vector2.ZERO, Vector2.ZERO) end

if status then
	xpcall(function()
		ffi.metatype(Bound2.__call, Bound2)
	end, function() end)
end

return Bound2