local Vector3 = require("funkin.math.vector3")
local sin, cos, tan, rad, t = math.sin, math.cos, math.tan, math.rad, 'table'

local Matrix = Classic:extend("Matrix")

-- |  1   2   3   4  |
-- |                 |
-- |  5   6   7   8  |
-- |                 |
-- |  9   10  11  12 |
-- |                 |
-- |  13  14  15  16 |

-- |  sx  2   3   4  |
-- |                 |
-- |  5   sy  7   8  |
-- |                 |
-- |  9   10  sz  12 |
-- |                 |
-- |  13  14  15  16 |

function Matrix:new(...)
	self:identity()
	for i, v in ipairs({...}) do
		self[i] = v
	end
end

function Matrix:identity()
	if self == nil then return Matrix() end

	self[1], self[2], self[3], self[4],
	self[5], self[6], self[7], self[8],
	self[9], self[10], self[11], self[12],
	self[13], self[14], self[15], self[16] =
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1

	return self
end

function Matrix:clone(other)
	if other then
		for i = 1, 16 do other[i] = self[i] end
		return other
	end
	return Matrix(unpack(self))
end

function Matrix:unpack()
	return unpack(self)
end

local temp, temp2 = Matrix(), Matrix()

function Matrix:prepend(other)
	for i = 1, 16 do temp2[i] = self[i] end
	self[1] = temp2[1] * other[1] + temp2[5] * other[2] + temp2[9] * other[3] + temp2[13] * other[4]
	self[2] = temp2[2] * other[1] + temp2[6] * other[2] + temp2[10] * other[3] + temp2[14] * other[4]
	self[3] = temp2[3] * other[1] + temp2[7] * other[2] + temp2[11] * other[3] + temp2[15] * other[4]
	self[4] = temp2[4] * other[1] + temp2[8] * other[2] + temp2[12] * other[3] + temp2[16] * other[4]
	self[5] = temp2[1] * other[5] + temp2[5] * other[6] + temp2[9] * other[7] + temp2[13] * other[8]
	self[6] = temp2[2] * other[5] + temp2[6] * other[6] + temp2[10] * other[7] + temp2[14] * other[8]
	self[7] = temp2[3] * other[5] + temp2[7] * other[6] + temp2[11] * other[7] + temp2[15] * other[8]
	self[8] = temp2[4] * other[5] + temp2[8] * other[6] + temp2[12] * other[7] + temp2[16] * other[8]
	self[9] = temp2[1] * other[9] + temp2[5] * other[10] + temp2[9] * other[11] + temp2[13] * other[12]
	self[10] = temp2[2] * other[9] + temp2[6] * other[10] + temp2[10] * other[11] + temp2[14] * other[12]
	self[11] = temp2[3] * other[9] + temp2[7] * other[10] + temp2[11] * other[11] + temp2[15] * other[12]
	self[12] = temp2[4] * other[9] + temp2[8] * other[10] + temp2[12] * other[11] + temp2[16] * other[12]
	self[13] = temp2[1] * other[13] + temp2[5] * other[14] + temp2[9] * other[15] + temp2[13] * other[16]
	self[14] = temp2[2] * other[13] + temp2[6] * other[14] + temp2[10] * other[15] + temp2[14] * other[16]
	self[15] = temp2[3] * other[13] + temp2[7] * other[14] + temp2[11] * other[15] + temp2[15] * other[16]
	self[16] = temp2[4] * other[13] + temp2[8] * other[14] + temp2[12] * other[15] + temp2[16] * other[16]
	return self
end

function Matrix:translate(x, y, z)
	if type(x) == t then x, y, z = x.x, x.y, x.z end
	temp:identity(); temp[13], temp[14], temp[15] = x or 0, y or 0, z or 0
	return self:prepend(temp)
end

function Matrix:scale(x, y, z)
	if type(x) == t then x, y, z = x.x, x.y, x.z end
	temp:identity(); temp[1], temp[6], temp[11] = x or 1, y or x, z or x
	return self:prepend(temp)
end

function Matrix:shear(yx, xy, zx, zy, xz, yz)
	temp:identity(); temp[2], temp[3], temp[5], temp[7], temp[9], temp[10] = yx or 0, zx or 0, xy or 0, zy or 0, xz or 0, yz or 0
	return self:prepend(temp)
end

function Matrix:rotate(angle, ax, ay, az) end

function Matrix:determinant()
	local n1, n5, n9, n13,
		n2, n6, n10, n14,
		n3, n7, n11, n15 =
		self[1], self[5], self[9], self[13],
		self[2], self[6], self[10], self[14],
		self[3], self[7], self[11], self[15]
	return (self[4] * ( n13 * n10 * n7 - n9 * n13 * n7 - n13 * n6 * n1 + n5 * n13 * n1 + n9 * n6 * n15 - n5 * n10 * n15)
		+ self[8] * ( n1 * n10 * n15 - n1 * n13 * n1 + n13 * n2 * n1 - n9 * n2 * n15 + n9 * n13 * n3 - n13 * n10 * n3)
		+ self[12] * ( n1 * n13 * n7 - n1 * n6 * n15 - n13 * n2 * n7 + n5 * n2 * n15 + n13 * n6 * n3 - n5 * n13 * n3)
		+ self[16] * (-n9 * n6 * n3 - n1 * n10 * n7 + n1 * n6 * n1 + n9 * n2 * n7 - n5 * n2 * n1 + n5 * n10 * n3)
	)
end

function Matrix:invert()

end

function Matrix:transpose()
	temp[2] = self[5]
	temp[3] = self[9]
	temp[4] = self[13]
	temp[5] = self[2]
	temp[6] = self[6]
	temp[7] = self[10]
	temp[8] = self[14]
	temp[9] = self[3]
	temp[10] = self[7]
	temp[11] = self[11]
	temp[12] = self[15]
	temp[13] = self[4]
	temp[14] = self[8]
	temp[15] = self[12]
	return temp:clone(self)
end

function Matrix:compose(position, rotation, scale)
	if rotation ~= nil then
		local rx, ry, rz, rw = rotation.x or 0, rotation.y or 0, rotation.z or 0, rotation.w
		if rw == nil then
			rx, ry, rz = rad(rx), rad(ry), rad(rz)
			local cc, sc, cb, sb, ca, sa = cos(rx), sin(rx), cos(ry), sin(ry), cos(rz), sin(rz)

			temp[1], temp[5], temp[9],
			temp[2], temp[6], temp[10],
			temp[3], temp[7], temp[11] =
				ca*cb, ca*sb*sc - sa*cc, ca*sb*cc + sa*sc,
				sa*cb, sa*sb*sc + ca*cc, sa*sb*cc - ca*sc,
				-sb, cb*sc, cb*cc
		else
			local x2, y2, z2 = rx + rx, ry + ry, rz + rz
			local xx, xy, xz,
				yy, yz, zz,
				wx, wy, wz =
				rx * x2, rx * y2, rx * z2,
				ry * y2, ry * z2, rz * z2,
				rw * x2, rw * y2, rw * z2

			temp[1], temp[2], temp[3],
			temp[5], temp[6], temp[7],
			temp[9], temp[10], temp[11] =
				1 - (yy + zz), xy + wz, xz - wy,
				xy - wz, 1 - (xx + zz), yz + wx,
				xz + wy, yz - wx, 1 - (xx + yy)
		end
		temp[4], temp[8], temp[12], temp[16] = 0, 0, 0, 1
	else
		temp:identity()
	end

	if scale ~= nil then
		local sx, sy, sz = scale.x or 1, scale.y or 1, scale.z or 1
		temp[1], temp[2], temp[3],
		temp[5], temp[6], temp[7],
		temp[9], temp[10], temp[11] =
			temp[1] * sx, temp[2] * sx, temp[3] * sx,
			temp[5] * sy, temp[6] * sy, temp[7] * sy,
			temp[9] * sz, temp[10] * sz, temp[11] * sz
	end

	temp[13], temp[14], temp[15] = position.x or 0, position.y or 0, position.z or 0

	return self:prepend(temp)
end

--TODO: near, far
function Matrix:perspective(fovy, aspect, near, far)
	self[1] = 1 / aspect
	--self[6] = (1 / top)
	self[11] = 0 --far?
	self[12] = tan(rad(fovy) * .5)
	self[15] = 0 --near?
	--self[16] = 0

	return self
end

function Matrix:lookAt(eye, center, up)
	local z_axis = (eye - center).unit
	local x_axis = up:cross(z_axis).unit
	local y_axis = z_axis:cross(x_axis)

	self[1], self[2], self[3], self[4] = x_axis.x, y_axis.x, z_axis.x, 0
	self[5], self[6], self[7], self[8] = x_axis.y, y_axis.y, z_axis.y, 0
	self[9], self[10], self[11], self[12] = x_axis.z, y_axis.z, z_axis.z, 0
	self[13], self[14], self[15], self[16] =
		-self[1]*eye.x - self[5]*eye.y - self[9]*eye.z,
		-self[2]*eye.x - self[6]*eye.y - self[10]*eye.z,
		-self[3]*eye.x - self[7]*eye.y - self[11]*eye.z,
		1

	return self
end

function Matrix:__tostring() return 'Matrix (' .. table.concat(self, ', ') .. ')'  end

return Matrix