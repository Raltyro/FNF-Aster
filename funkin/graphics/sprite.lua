local Frame = require("funkin.graphics.frames.Frame")

local Sprite = Actor:extend("Sprite")

function Sprite:new(frames, x, y, z)
	Sprite.super.new(self, x, y, z)
	self.size = nil

	if type(frames) == 'userdata' and frames.typeOf then
		if frames:typeOf('Texture') then self.frame = Frame(frames) end
	else

	end
end

function Sprite:render()
	local frame = self.frame
	if not frame or not self.visible then return end

	frame:render(self)
end

function Sprite:get_size()
	return self.frame and self.frame.size
end

--[[
function Sprite:get_frame()
	return nil
end]]

return Sprite