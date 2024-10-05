local SoundGroup = Basic:extend("SoundGroup", ...)

function SoundGroup:new(volume, pitch, x, y)
	SoundGroup.super.new(self)
end

return SoundGroup