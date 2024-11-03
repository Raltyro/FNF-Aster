local TitleScene = Scene:extend("TitleScene")

function TitleScene:enter()
	Assets.clearUnused()

	TitleScene.super.enter(self)

	self.sprite = Sprite(Assets.getImage(Paths.image('logoBumpin')))
	self:add(self.sprite)

	SoundManager.playMusic(Assets.getMusic(Paths.music('freakyMenu')))
	self.conductor:setBPM(102)
end

function TitleScene:metronomeHit(measureHit)
	local beat, measure, pos = Conductor.instance.currentBeat, Conductor.instance.currentMeasure
	if measureHit then
		SoundManager.play(Paths.sound('clav1'))
		pos = Conductor.instance:getMeasuresInTime(measure, Conductor.instance.currentTimeChangeIdx)
		beat = Conductor.instance:getTimeInBeats(pos, Conductor.instance.currentTimeChangeIdx)
	else
		SoundManager.play(Paths.sound('clav2'))
		pos = Conductor.instance:getBeatsInTime(beat, Conductor.instance.currentTimeChangeIdx)
		measure = Conductor.instance:getTimeInMeasures(pos, Conductor.instance.currentTimeChangeIdx)
	end

	print(beat, measure, pos, Conductor.instance:getTimeInBPM(pos, Conductor.instance.currentTimeChangeIdx))
end

function TitleScene:update(dt)
	TitleScene.super.update(self, dt)

	--[[self.timer = (self.timer or 0) + dt
	--self.sprite.position:set(math.cos(self.timer) * 500, math.sin(self.timer) * 500, math.cos(self.timer * 500))
	self.sprite.rotation:set(0, 0, self.timer * 130)
	self.sprite.position:set(0, 0, 5000)]]
end

return TitleScene