local Vector3 = require("funkin.utils.vector3")
local tan, rad, t = math.tan, math.rad, 'table'

local Matrix = Classic:extend("Matrix")
local temp

function Matrix:new(...)
	self:identity()
	for i, v in ipairs({...}) do
		self[i] = v
	end
end

function Matrix:clone(other)
	if other then
		for i, v in ipairs(self) do
			other[i] = v
		end
		return other
	end
	return Matrix(unpack(self))
end

function Matrix:unpack()
	return unpack(self)
end

function Matrix:multiply(other)
	self[1] = self[1] * other[1] + self[5] * other[2] + self[9] * other[3] + self[13] * other[4]
	self[2] = self[2] * other[1] + self[6] * other[2] + self[10] * other[3] + self[14] * other[4]
	self[3] = self[3] * other[1] + self[7] * other[2] + self[11] * other[3] + self[15] * other[4]
	self[4] = self[4] * other[1] + self[8] * other[2] + self[12] * other[3] + self[16] * other[4]
	self[5] = self[1] * other[5] + self[5] * other[6] + self[9] * other[7] + self[13] * other[8]
	self[6] = self[2] * other[5] + self[6] * other[6] + self[10] * other[7] + self[14] * other[8]
	self[7] = self[3] * other[5] + self[7] * other[6] + self[11] * other[7] + self[15] * other[8]
	self[8] = self[4] * other[5] + self[8] * other[6] + self[12] * other[7] + self[16] * other[8]
	self[9] = self[1] * other[9] + self[5] * other[10] + self[9] * other[11] + self[13] * other[12]
	self[10] = self[2] * other[9] + self[6] * other[10] + self[10] * other[11] + self[14] * other[12]
	self[11] = self[3] * other[9] + self[7] * other[10] + self[11] * other[11] + self[15] * other[12]
	self[12] = self[4] * other[9] + self[8] * other[10] + self[12] * other[11] + self[16] * other[12]
	self[13] = self[1] * other[13] + self[5] * other[14] + self[9] * other[15] + self[13] * other[16]
	self[14] = self[2] * other[13] + self[6] * other[14] + self[10] * other[15] + self[14] * other[16]
	self[15] = self[3] * other[13] + self[7] * other[14] + self[11] * other[15] + self[15] * other[16]
	self[16] = self[4] * other[13] + self[8] * other[14] + self[12] * other[15] + self[16] * other[16]

	return self
end

function Matrix:identity()
	if self == nil then return Matrix() end

	self[1],  self[2],  self[3],  self[4]  = 1, 0, 0, 0
	self[5],  self[6],  self[7],  self[8]  = 0, 1, 0, 0
	self[9],  self[10], self[11], self[12] = 0, 0, 1, 0
	self[13], self[14], self[15], self[16] = 0, 0, 0, 1

	return self
end

function Matrix:translate(x, y, z)
	if type(x) == t then x, y, z = x.x, x.y, x.z end
	temp:identity(); temp[13], temp[14], temp[15] = x or 0, y or 0, z or 0
	return self:multiply(temp)
end

function Matrix:scale(x, y, z)
	if type(x) == t then x, y, z = x.x, x.y, x.z end
	temp:identity(); temp[1], temp[6], temp[11] = x or 1, y or 1, z or 1
	return self:multiply(temp)
end

function Matrix:shear(yx, xy, zx, zy, xz, yz)
	temp:identity(); temp[2], temp[3], temp[5], temp[7], temp[9], temp[10] = yx or 0, zx or 0, xy or 0, zy or 0, xz or 0, yz or 0
	return self:multiply(temp)
end

function Matrix:rotate(angle, ax, ay, az) end

function Matrix:compose(position, rotation, scale)
	local x, y, z, w = rotation.x or 0, rotation.y or 0, rotation.z or 0, rotation.w or 0
	local x2, y2, z2 = x + x, y + y, z + z

	local xx, xy, xz = x * x2, x * y2, x * z2
	local yy, yz, zz = y * y2, y * z2, z * z2
	local wx, wy, wz = w * x2, w * y2, w * z2

	local sx, sy, sz = scale.x or 1, scale.y or 1, scale.z or 1

	self[1]  = (1 - (yy + zz)) * sx
	self[2]  = (xy + wz) * sx
	self[3]  = (xz - wy) * sx
	self[4]  = 0
	self[5]  = (xy - wz) * sy
	self[6]  = (1 - (xx + zz)) * sy
	self[7]  = (yz + wx) * sy
	self[8]  = 0
	self[9]  = (xz + wy) * sz
	self[10] = (yz - wx) * sz
	self[11] = (1 - (xx + yy)) * sz
	self[12] = 0
	self[13] = position.x
	self[14] = position.y
	self[15] = position.z
	self[16] = 1
	return self
end

function Matrix:perspective(fovy, aspect, near, far)
	local t = tan(rad(fovy) / 2)
	self[1] = 1 / (t * aspect)
	self[6] = 1 / t
	self[11] = -(far + near) / (far - near)
	self[12] = -1
	self[15] = -(2 * far * near) / (far - near)
	self[16] = 0

	return self
end

function Matrix:lookAt(eye, center, up)
	local z_axis = (eye - center).unit
	local x_axis = up:cross(z_axis).unit
	local y_axis = z_axis:cross(x_axis)

	self[1], self[2], self[3], self[4] = x_axis.x, y_axis.x, z_axis.x, 0
	self[5], self[6], self[7], self[8] = x_axis.y, y_axis.y, z_axis.y, 0
	self[9], self[10], self[11], self[9] = x_axis.z, y_axis.z, z_axis.z, 0
	self[13] = -self[1]*eye.x - self[5]*eye.y - self[9]*eye.z
	self[14] = -self[2]*eye.x - self[6]*eye.y - self[10]*eye.z
	self[15] = -self[3]*eye.x - self[7]*eye.y - self[11]*eye.z
	self[16] = 1

	return self
end

function Matrix:__tostring() return 'Matrix (' .. table.concat(self, ', ') .. ')'  end

temp = Matrix()
Matrix.temp = temp

print(Matrix():translate(1, 1, 1), Matrix():scale(2, 2, 2):translate(2, 1, 1), Matrix())

return Matrix