local Signal = require("funkin.utils.signal")

local Conductor = Basic:extend("Conductor")
Conductor.DEFAULT_BPM = 100

--[[ timeChange {
	time = songPosition,
	bpm = bpm or Conductor.DEFAULT_BPM,
	numerator = 4,
	denominator = 4,

	beatTime = ? -- automatically calculated
}]]

Conductor._instance = nil
function Conductor.get_instance()
	if Conductor._instance == nil then Conductor.reset() end
	return Conductor._instance
end

function Conductor.set_instance(instance)
	local oldConductor = Conductor._instance

	Conductor._instance = instance

	if oldConductor ~= nil then oldConductor:destroy() end
end

function Conductor.reset() Conductor.instance = Conductor() end

function Conductor:new()
	Conductor.super.new(self)

	self.onMeasureHit = Signal()
	self.onBeatHit = Signal()
	self.onStepHit = Signal()

	self.songPosition = 0
	self.offset = 0

	self.oldMeasure = 0
	self.oldBeat = 0
	self.oldStep = 0

	self.currentMeasure = 0
	self.currentBeat = 0
	self.currentStep = 0

	self.currentMeasureTime = 0
	self.currentBeatTime = 0
	self.currentStepTime = 0

	self.timeChanges = {}
	self.currentTimeChangeIdx = 0
end

function Conductor:setBPM(bpm)
	self.timeChanges = {{bpm = bpm, time = 0}}
end

---The time change that current song position are in.
function Conductor:get_currentTimeChange()
	return self.timeChanges[self.currentTimeChangeIdx]
end

---Beats per minute of the current song at the current time.
function Conductor:get_bpm()
	local timeChange = self:get_currentTimeChange()
	return timeChange and timeChange.bpm or Conductor.DEFAULT_BPM
end

---Beats per minute of the current song at the start time.
function Conductor:get_startingBPM()
	local timeChange = self.timeChanges[0]
	return timeChange and timeChange.bpm or Conductor.DEFAULT_BPM
end

---Duration of a measure in seconds. Calculated based on bpm.
function Conductor:get_measureLengthM()
	return self.beatLength * self.numerator
end

---Duration of a beat (quarter note) in seconds. Calculated based on bpm.
function Conductor:get_beatLength()
	return 60 / self.bpm
end

---Duration of a step (sixtennth note) in seconds. Calculated based on bpm.
function Conductor:get_stepLength()
	return self.beatLength / self.numerator
end

---The numerator for the current time signature (the `3` in `3/4`).
function Conductor:get_numerator()
	local timeChange = self:get_currentTimeChange()
	return timeChange and timeChange.numerator or 4
end

---The denominator for the current time signature (the `4` in `3/4`).
function Conductor:get_denominator()
	local timeChange = self:get_currentTimeChange()
	return timeChange and timeChange.denominator or 4
end

---The number of beats in a measure. May be fractional depending on the time signature.
function Conductor:get_beatsPerMeasure()
	return self.numerator / self.denominator * 4
end

---The number of steps in a measure.
function Conductor:get_stepsPerMeasure()
	return self.numerator / self.denominator * 16
end

function Conductor:update(sound, forceDispatch, applyOffsets)
	if not self.active or self.destroyed then return end
	if sound == nil then sound = SoundManager.music end
	if applyOffsets == nil then applyOffsets = true end

	local songPosition = sound == nil and SoundManager.music or (type(sound) == 'number' and sound or sound.time) - (applyOffsets and self.offset or 0)
	if songPosition == self.songPosition then
		if forceDispatch then
			self.onStepHit:dispatch()
			self.onBeatHit:dispatch()
			self.onMeasureHit:dispatch()
		end
		return
	end

	self.songPosition, self.oldMeasure, self.oldBeat, self.oldStep = songPosition, self.currentMeasure, self.currentBeat, self.currentStep

	self.currentTimeChangeIdx = self:getTimeInChangeIdx(songPosition, self.currentTimeChangeIdx)
	local timeChange = self.currentTimeChange
	if timeChange == nil then
		self.currentBeatTime = songPosition / self:get_beatLength()
	else
		self.currentBeatTime = (timeChange.beatTime or 0) + (songPosition - timeChange.time) / self:get_beatLength()
	end
	self.currentStepTime = self.currentBeatTime * self:get_numerator()
	self.currentMeasureTime = self.currentBeatTime / self:get_beatsPerMeasure() -- fix this
	self.currentBeat, self.currentStep, self.currentMeasure = math.floor(self.currentBeatTime), math.floor(self.currentStepTime), math.floor(self.currentMeasureTime)

	if self.currentStep ~= self.oldStep or forceDispatch then self.onStepHit:dispatch() end
	if self.currentBeat ~= self.oldBeat or forceDispatch then self.onBeatHit:dispatch() end
	if self.currentMeasure ~= self.oldMeasure or forceDispatch then self.onMeasureHit:dispatch() end
end

function Conductor:getTimeInChangeIdx()
	return 1
end

function Conductor:mapTimeChanges(timeChanges)
	if self.destroyed then return end
	-- sorting here

	--[[
		this.timeChanges = SongUtil.sortTimeChanges(timeChanges);

		// Re-assure the beatTimes just incase if any of it are in wrong beats
		var idx = 0;
		for (timeChange in this.timeChanges) {
			if (timeChange.timeStamp <= 0) timeChange.timeStamp = timeChange.beatTime = 0;
			else if (idx == 0) timeChange.beatTime = timeChange.timeStamp * timeChange.bpm / 60000;
			else {
				var prev:SongTimeChange = this.timeChanges[idx - 1];
				timeChange.beatTime = prev.beatTime + ((timeChange.timeStamp - prev.timeStamp) * timeChange.bpm / 60000);
			}

			idx++;
		}

		update(songPosition, true);
	}
	]]
end

function Conductor:destroy()
	Conductor.super.destroy(self)

	self.timeChanges = nil
	self.onMeasureHit:destroy()
	self.onBeatHit:destroy()
	self.onStepHit:destroy()
end

return Conductor