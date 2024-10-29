local TitleScene = Scene:extend("TitleScene")

function TitleScene:enter()
	TitleScene.super.enter(self)

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

return TitleScene