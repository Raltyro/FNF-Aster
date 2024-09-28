local SoundManager = require("funkin.managers.soundmanager")

local Sound = Basic:extend("Sound", ...)

function Sound:new(x, y)
	Sound.super.new(self)
	self:revive(x, y)
end

function Sound:setPosition(x, y)
	self.x, self.y = x or 0, y or 0
end

function Sound:proximity(x, y, target, radius)
	self:setPosition(x, y)
	self.target = target
	self.radius = radius

	return self
end

function Sound:revive(x, y)
	self:reset(true, x, y)

	self._volume = 1
	self._pitch = 1
	self._duration = 0
	self._wasPlaying = nil
	Sound.super.revive(self)
end

function Sound:reset(cleanup, x, y)
	if cleanup then
		self:cleanup()
	elseif self.loaded then
		self:stop()
	end
	self:setPosition(x or self.x, y or self.y)

	self.looped = false
	self.autoDestroy = false
	self.radius = 0
end

function Sound:cleanup()
	self.active = false
	self.target = nil
	self.group = nil
	self.onComplete = nil
	self.isSource = false

	if self.loaded then
		self:stop()
		if not self.isSource and self._source.release then
			self._source:release()
		end
	end

	self._muted = false
	self._paused = true
	self._wasFinished = false
	self._source = nil
end

function Sound:destroy()
	Sound.super.destroy(self)
	self:cleanup()
end

function Sound:kill()
	Sound.super.kill(self)
	self:reset(self.autoDestroy)
end

function Sound:load(asset, autoDestroy, onComplete)
	if self.destroyed or asset == nil then return end
	self:cleanup()

	self.isSource = asset:typeOf("Source")
	self._source = self.isSource and asset or love.audio.newSource(asset)
	return self:init(autoDestroy, onComplete)
end

function Sound:init(autoDestroy, onComplete)
	if autoDestroy ~= nil then self.autoDestroy = autoDestroy end
	if onComplete ~= nil then self.onComplete = onComplete end

	self.active = true

	if self.loaded then self._duration = self._source:getDuration() end

	return self
end

function Sound:play(volume, looped, pitch, restart)
	if not self.active or not self.loaded then return self end

	self.volume = volume or self.volume
	self.looped = looped or self.looped
	self.pitch = pitch or self.pitch

	if restart then
		pcall(self._source.stop, self._source)
	elseif self.playing then
		return self
	end

	self._paused = false
	self._wasFinished = false
	pcall(self._source.play, self._source)
	return self
end

function Sound:pause()
	self._paused = true
	if self.loaded then pcall(self._source.pause, self._source) end
	return self
end

function Sound:stop()
	self._paused = true
	if self._source then pcall(self._source.stop, self._source) end
	return self
end

function Sound:update(dt)
	local isFinished = self.finished
	if isFinished and not self._wasFinished then
		local onComplete = self.onComplete
		if self.autoDestroy then
			self:kill()
		else
			self:stop()
		end

		if onComplete then onComplete() end
	end

	self._wasFinished = isFinished
end

function Sound:onFocus(focus)
	if love.autoPause and self.active and not self.finished then
		if focus then
			if self._wasPlaying ~= nil and self._wasPlaying then
				self._wasPlaying = nil
				self:play()
			end
		else
			self._wasPlaying = self.playing
			if self._wasPlaying then
				self:pause()
			end
		end
	end
end

function Sound:getActualGroup()
	return self.group or SoundManager
end

function Sound:getActualX()
	return self.x + self:getActualGroup():getActualX()
end

function Sound:getActualY()
	return self.y + self:getActualGroup():getActualY()
end

function Sound:getActualVolume()
	if self.muted then return 0 end
	return self._volume * self:getActualGroup():getActualVolume()
end

function Sound:getActualPitch()
	return self._pitch * self:getActualGroup():getActualPitch()
end

function Sound:get_loaded()
	return self._source ~= nil
end

function Sound:get_duration()
	return self.loaded and self._duration or -1
end

function Sound:get_paused()
	return self._paused
end

function Sound:get_playing()
	if not self.loaded then return false end

	local success, playing = pcall(self._source.isPlaying, self._source)
	return success and playing
end

function Sound:get_finished()
	return self.active and not self.paused and not self.looped and not self.playing
end

function Sound:get_time()
	if not self.loaded then return 0 end

	local success, position = pcall(self._source.tell, self._source)
	return success and position or 0
end

function Sound:set_time(position)
	if not self.loaded then return false end
	return pcall(self._source.seek, self._source, position)
end

function Sound:get_volume()
	return self._volume
end

function Sound:set_volume(volume)
	self._volume = volume or self._volume
	if not self.loaded then return false end
	return pcall(self._source.setVolume, self._source, self:getActualVolume())
end

function Sound:get_pitch()
	return self._pitch
end

function Sound:set_pitch(pitch)
	self._pitch = pitch or self._pitch
	if not self.loaded then return false end
	return pcall(self._source.setPitch, self._source, self:getActualPitch())
end

function Sound:get_looped()
	if not self.loaded then return end

	local success, loop = pcall(self._source.isLooping, self._source)
	if success then return loop end
end

function Sound:set_looped(looped)
	if not self.loaded then return false end
	return pcall(self._source.setLooping, self._source, looped)
end

function Sound:get_muted()
	return self._muted
end

function Sound:set_muted(muted)
	self._muted = muted
	return self:set_volume()
end

return Sound