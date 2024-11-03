local sqrt = math.sqrt

local Vector3 = Classic:extend("Vector3")

local status, ffi
if type(jit) == "table" and jit.status() then
	status, ffi = pcall(require, "ffi")
	if status then
		ffi.cdef "typedef struct { double x, y, z;} ffi_vec3;"
		Vector3.__call = ffi.typeof("ffi_vec3")
	end
end

local number = 'number'
function Vector3:new(x, y, z) self.x, self.y, self.z = x or 0, y or 0, z or 0 end
function Vector3:clone(other)
	if other then
		other.x, other.y, other.z = self.x, self.y, self.z
		return other
	end
	return Vector3(self.x, self.y, self.z)
end
function Vector3:set(x, y, z) self.x, self.y, self.z = x or self.x, y or self.y, z or self.z end
function Vector3:unpack() return self.x, self.y, self.z end
function Vector3:add(other) self.x, self.y, self.z = self.x + other.x, self.y + other.y, self.z + other.z; return self end
function Vector3:subtract(other) self.x, self.y, self.z = self.x - other.x, self.y - other.y, self.z - other.z; return self end
function Vector3:multiply(other)
	if type(other) == number then
		self.x, self.y, self.z = self.x * other, self.y * other, self.z * other
	else
		self.x, self.y, self.z = self.x * other.x, self.y * other.y, self.z * other.z
	end
	return self
end
function Vector3:divide(other)
	if type(other) == number then
		self.x, self.y, self.z = self.x / other, self.y / other, self.z / other
	else
		self.x, self.y, self.z = self.x / other.x, self.y / other.y, self.z / other.z
	end
	return self
end

function Vector3:lerp(other, t)
	return Vector3(
		self.x + (other.x - self.x) * t,
		self.y + (other.y - self.y) * t,
		self.z + (other.z - self.z) * t
	)
end

function Vector3:dot(other) return self.x * other.x + self.y * other.y + self.z * other.z end
function Vector3:cross(other)
	return Vector3(
		self.y * other.z - self.z * other.y,
		self.z * other.x - self.x * other.z,
		self.x * other.y - self.y * other.x
	)
end

function Vector3:get_magnitude() return sqrt(self.x ^ 2 + self.y ^ 2 + self.z ^ 2) end

function Vector3:get_unit()
	local magnitude = sqrt(self.x ^ 2 + self.y ^ 2 + self.z ^ 2)
	if magnitude > 0 then
		return Vector3(self.x / magnitude, self.y / magnitude, self.z / magnitude)
	else
		return Vector3(0, 0, 0)
	end
end

function Vector3:__add(other) return Vector3(self.x + other.x, self.y + other.y, self.z + other.z) end
function Vector3:__sub(other) return Vector3(self.x - other.x, self.y - other.y, self.z - other.z) end
function Vector3:__mul(other)
	if type(other) == number then
		return Vector3(self.x * other, self.y * other, self.z * other)
	else
		return Vector3(self.x * other.x, self.y * other.y, self.z * other.z)
	end
end
function Vector3:__div(other)
	if type(other) == number then
		return Vector3(self.x / other, self.y / other, self.z / other)
	else
		return Vector3(self.x / other.x, self.y / other.y, self.z / other.z)
	end
end
function Vector3:__eq(other) return self.x == other.x and self.y == other.y and self.z == other.z end
function Vector3:__unm() return Vector3(-self.x, -self.y, -self.z) end
function Vector3:__tostring() return 'Vector3 (' .. table.concat({self:unpack()}, ', ') .. ')'  end

function Vector3.get_ZERO() return Vector3(0, 0, 0) end
function Vector3.get_ONE() return Vector3(1, 1, 1) end
function Vector3.get_X() return Vector3(1, 0, 0) end
function Vector3.get_Y() return Vector3(0, 1, 0) end
function Vector3.get_Z() return Vector3(0, 0, 1) end

if status then
	xpcall(function()
		ffi.metatype(Vector3.__call, Vector3)
	end, function() end)
end

return Vector3