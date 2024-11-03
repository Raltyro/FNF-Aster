local sqrt = math.sqrt

local Vector4 = Classic:extend("Vector4")

local status, ffi
if type(jit) == "table" and jit.status() then
	status, ffi = pcall(require, "ffi")
	if status then
		ffi.cdef "typedef struct { double x, y, z, w;} ffi_vec4;"
		Vector4.__call = ffi.typeof("ffi_vec4")
	end
end

local number = 'number'
function Vector4:new(x, y, z, w) self.x, self.y, self.z, self.w = x or 0, y or 0, z or 0, w or 0 end
function Vector4:clone(other)
	if other then
		other.x, other.y, other.z, other.w = self.x, self.y, self.z, self.w
		return other
	end
	return Vector4(self.x, self.y, self.z, self.w)
end
function Vector4:set(x, y, z, w) self.x, self.y, self.z, self.w = x or self.x, y or self.y, z or self.z, w or self.w end
function Vector4:unpack() return self.x, self.y, self.z, self.w end
function Vector4:add(other) self.x, self.y, self.z, self.w = self.x + other.x, self.y + other.y, self.z + other.z, self.w + other.w; return self end
function Vector4:subtract(other) self.x, self.y, self.z, self.w = self.x - other.x, self.y - other.y, self.z - other.z, self.w - other.w; return self end
function Vector4:multiply(other)
	if type(other) == number then
		self.x, self.y, self.z, self.w = self.x * other, self.y * other, self.z * other, self.w * other
	else
		self.x, self.y, self.z, self.w = self.x * other.x, self.y * other.y, self.z * other.z, self.w * other.w
	end
	return self
end
function Vector4:divide(other)
	if type(other) == number then
		self.x, self.y, self.z, self.w = self.x / other, self.y / other, self.z / other, self.w / other
	else
		self.x, self.y, self.z, self.w = self.x / other.x, self.y / other.y, self.z / other.z, self.w / other.w
	end
	return self
end

function Vector4:lerp(other, t)
	return Vector4(
		self.x + (other.x - self.x) * t,
		self.y + (other.y - self.y) * t,
		self.z + (other.z - self.z) * t,
		self.w + (other.w - self.w) * t
	)
end

function Vector4:dot(other) return self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w end

function Vector4:get_magnitude() return sqrt(self.x ^ 2 + self.y ^ 2 + self.z ^ 2 + self.w ^ 2) end

function Vector4:get_unit()
	local magnitude = sqrt(self.x ^ 2 + self.y ^ 2 + self.z ^ 2 + self.w ^ 2)
	if magnitude > 0 then
		return Vector4(self.x / magnitude, self.y / magnitude, self.z / magnitude, self.w / magnitude)
	else
		return Vector4(0, 0, 0)
	end
end

function Vector4:__add(other) return Vector4(self.x + other.x, self.y + other.y, self.z + other.z, self.w + other.w) end
function Vector4:__sub(other) return Vector4(self.x - other.x, self.y - other.y, self.z - other.z, self.w - other.w) end
function Vector4:__mul(other)
	if type(other) == number then
		return Vector4(self.x * other, self.y * other, self.z * other, self.w * other)
	else
		return Vector4(self.x * other.x, self.y * other.y, self.z * other.z, self.w * other.w)
	end
end
function Vector4:__div(other)
	if type(other) == number then
		return Vector4(self.x / other, self.y / other, self.z / other, self.w / other)
	else
		return Vector4(self.x / other.x, self.y / other.y, self.z / other.z, self.w / other.w)
	end
end
function Vector4:__eq(other) return self.x == other.x and self.y == other.y and self.z == other.z and self.w == other.w end
function Vector4:__unm() return Vector4(-self.x, -self.y, -self.z, -self.w) end
function Vector4:__tostring() return 'Vector4 (' .. table.concat({self:unpack()}, ', ') .. ')'  end

function Vector4.get_ZERO() return Vector4(0, 0, 0, 0) end
function Vector4.get_ONE() return Vector4(1, 1, 1, 1) end
function Vector4.get_X() return Vector4(1, 0, 0, 0) end
function Vector4.get_Y() return Vector4(0, 1, 0, 0) end
function Vector4.get_Z() return Vector4(0, 0, 1, 0) end
function Vector4.get_W() return Vector4(0, 0, 0, 1) end

if status then
	xpcall(function()
		ffi.metatype(Vector4.__call, Vector4)
	end, function() end)
end

return Vector4