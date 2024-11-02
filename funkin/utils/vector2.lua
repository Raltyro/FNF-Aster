local sqrt = math.sqrt

local Vector2 = Classic:extend("Vector2")

local status, ffi
if type(jit) == "table" and jit.status() then
	status, ffi = pcall(require, "ffi")
	if status then
		ffi.cdef "typedef struct { double x, y;} ffi_vec2;"
		Vector2.__call = ffi.typeof("ffi_vec2")
	end
end

local number = 'number'
function Vector2:new(x, y) self.x, self.y = x or 0, y or 0 end
function Vector2:clone(other)
	if other then
		other.x, other.y = self.x, self.y
		return other
	end
	return Vector2(self.x, self.y)
end
function Vector2:unpack() return self.x, self.y end
function Vector2:add(other) self.x, self.y = self.x + other.x, self.y + other.y; return self end
function Vector2:subtract(other) self.x, self.y = self.x - other.x, self.y - other.y; return self end
function Vector2:multiply(other)
	if type(other) == number then
		self.x, self.y = self.x * other, self.y * other
	else
		self.x, self.y = self.x * other.x, self.y * other.y
	end
	return self
end
function Vector2:divide(other)
	if type(other) == number then
		self.x, self.y = self.x / other, self.y / other
	else
		self.x, self.y = self.x / other.x, self.y / other.y
	end
	return self
end

function Vector2:lerp(other, t)
	return Vector2(
		self.x + (other.x - self.x) * t,
		self.y + (other.y - self.y) * t
	)
end

function Vector2:dot(other) return self.x * other.x + self.y * other.y end

function Vector2:get_magnitude() return sqrt(self.x ^ 2 + self.y ^ 2) end

function Vector2:get_unit()
	local magnitude = sqrt(self.x ^ 2 + self.y ^ 2)
	if magnitude > 0 then
		return Vector2(self.x / magnitude, self.y / magnitude)
	else
		return Vector2(0, 0, 0)
	end
end

function Vector2:__add(other) return Vector2(self.x + other.x, self.y + other.y) end
function Vector2:__sub(other) return Vector2(self.x - other.x, self.y - other.y) end
function Vector2:__mul(other)
	if type(other) == number then
		return Vector2(self.x * other, self.y * other)
	else
		return Vector2(self.x * other.x, self.y * other.y)
	end
end
function Vector2:__div(other)
	if type(other) == number then
		return Vector2(self.x / other, self.y / other)
	else
		return Vector2(self.x / other.x, self.y / other.y)
	end
end
function Vector2:__eq(other) return self.x == other.x and self.y == other.y end
function Vector2:__unm() return Vector2(-self.x, -self.y) end
function Vector2:__tostring() return 'Vector2 (' .. table.concat({self:unpack()}, ', ') .. ')'  end

Vector2.ZERO = Vector2(0, 0)
Vector2.ONE = Vector2(1, 1)
Vector2.X = Vector2(1, 0)
Vector2.Y = Vector2(0, 1)

if status then
	xpcall(function()
		ffi.metatype(Vector2.__call, Vector2)
	end, function() end)
end

return Vector2