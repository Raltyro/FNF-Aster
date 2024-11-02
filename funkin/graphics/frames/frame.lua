local Shader = require("funkin.graphics.shader")
local lovg = love.graphics

local Frame = Classic:extend("Frame")

function Frame:new(texture, angle, flipX, flipY)
	self.texture = texture
	self.angle = angle or 0
	self.flipX = flipX or false
	self.flipY = flipY or false

	local w, h = 0, 0; if texture then w, h = texture:getDimensions() end
	self.rect = {x = 0, y = 0, width = w, height = h}
	self.size = {x = w, y = h}
	self.offset = {x = 0, y = 0}
end

function Frame:sortFrames(frames, prefix, suffix, warn)
	self:sortHelpers(frames, #prefix, suffix == nil and 0 or #suffix, warn)
end

function Frame:sort(frames, prefixLength, suffixLength, warn)
	self:sortHelpers(frames, prefixLength, suffixLength, warn)
end

function Frame:sortHelpers(frames, prefixLength, suffixLength, warn)
	if warn == nil or warn then
		for i, frame in pairs(frames) do
			self:checkValidName(frame.name, prefixLength, suffixLength)
		end
	end

	table.sort(frames, function(frame1, frame2)
		return self:sortByName(frame1, frame2, prefixLength, suffixLength)
	end)
end

function Frame:checkValidName(name, prefixLength, suffixLength)
	local nameSub = name:sub(prefixLength + 1, #name - suffixLength)
	local num = tonumber(nameSub)

	if num == nil then
		warn(string.format('Could not parse frame number of "%s" in frame named "%s"', nameSub, name))
	elseif num < 0 then
		warn(string.format('Found negative frame number "%s" in frame named "%s"', nameSub, name))
	end
end

function Frame:sortByName(frame1, frame2, prefixLength, suffixLength)
	local function getNameOrder(name)
		local num = tonumber(name:sub(prefixLength + 1, #name - suffixLength))
		return num == nil and 0 or math.floor(math.abs(num))
	end
	return getNameOrder(frame1.name) < getNameOrder(frame2.name)
end

local mesh
function Frame:render(sprite)
	if self.texture == nil or not pcall(self.texture.isReadable, self.texture) then
		self.texture = nil
		return
	end

	lovg.pushall()

	if mesh == nil then
		mesh = lovg.newMesh(require("funkin.graphics.Mesh").vertexFormat, {
			{0, 0, 0, 0, 0},
			{1, 0, 0, 1, 0},
			{1, 1, 0, 1, 1},
			{0, 1, 0, 0, 1}
		}, 'fan', 'static')
	end
	local shader = sprite:applyStack(self.texture, mesh)
	local mat = Matrix.temp:identity()
	Shader.model(shader, sprite:applyMatrix(mat):scale(self.size))
	lovg.draw(mesh)

	lovg.pop()

	lovg.draw(mesh)
end

return Frame