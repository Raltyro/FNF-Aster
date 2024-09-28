local Signal = require("funkin.utils.signal")

local Conductor = Basic:extend("Conductor", ...)
Conductor.DEFAULT_BPM = 100

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
	self.onMeasureHit = Signal()
	self.onBeatHit = Signal()
	self.onStepHit = Signal()

	self.songPosition = 0

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

---Duration of a measure in milliseconds. Calculated based on bpm.
function Conductor:get_measureLengthMs()
	return self.beatLengthMs * self.timeSignatureNumerator
end

---Duration of a beat (quarter note) in milliseconds. Calculated based on bpm.
function Conductor:get_beatLengthMs()
	return 60 / self.bpm
end

---Duration of a step (sixtennth note) in milliseconds. Calculated based on bpm.
function Conductor:get_stepLengthMs()
	return self.beatLengthMs / self.timeSignatureNumerator
end

---The numerator for the current time signature (the `3` in `3/4`).
function Conductor:get_timeSignatureNumerator()
	local timeChange = self:get_currentTimeChange()
	return timeChange and timeChange.timeSignatureNumerator or 4
end

---The denominator for the current time signature (the `4` in `3/4`).
function Conductor:get_timeSignatureDenominator()
	local timeChange = self:get_currentTimeChange()
	return timeChange and timeChange.timeSignatureDenominator or 4
end

---The number of beats in a measure. May be fractional depending on the time signature.
function Conductor:get_beatsPerMeasure()
	return self.timeSignatureNumerator / self.timeSignatureDenominator * 4
end

---The number of steps in a measure.
function Conductor:get_stepsPerMeasure()
	return self.timeSignatureNumerator / self.timeSignatureDenominator * 16
end

function Conductor:update(songPosition, forceDispatch)
	if not self.active or self.destroyed then return end
	if songPosition == nil then songPosition = SoundManager.music.time end
	if songPosition == self.songPosition then return end
	
	self.songPosition = songPosition
	self.oldMeasure = self.currentMeasure
	self.oldBeat = self.currentBeat
	self.oldStep = self.currentStep
	
	self.currentTimeChangeIdx = self:getTimeInChangeIdx(songPosition, self.currentTimeChangeIdx)
	local timeChange = self.timeChanges[self.currentTimeChangeIdx]
	if timeChange == nil then
		self.currentBeatTime = songPosition / self:get_beatLengthMs()
	else
		self.currentBeatTime = timeChange.beatTime + (songPosition - timeChange.timeStamp) / self:get_beatLengthMs()
	end

	self.currentStepTime = self.currentBeatTime * self.get_timeSignatureNumerator()
	self.currentStep = math.floor(self.currentStepTime)
	self.currentMeasureTime = self.currentBeatTime / self:get_beatsPerMeasure() -- fix this
	self.currentMeasure = math.floor(self.currentMeasureTime)

	if self.currentStep ~= self.oldStep or forceDispatch then onStepHit:dispatch() end
	if self.currentBeat ~= self.oldBeat or forceDispatch then onBeatHit:dispatch() end
	if self.currentMeasure ~= self.oldMeasure or forceDispatch then onMeasureHit:dispatch() end
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