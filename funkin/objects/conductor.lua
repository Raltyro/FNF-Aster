local Signal = require("funkin.utils.signal")

local Conductor = Basic:extend("Conductor")
Conductor.DEFAULT_BPM = 100

function Conductor.sortByTime(a, b)
	if a.beatTime or b.beatTime then return (a.beatTime or -math.huge) < (b.beatTime or -math.huge)
	elseif a.time or b.time then return (a.time or -math.huge) < (b.time or -math.huge) end
	return false
end

--[[ timeChange {
	time = songPosition,
	bpm = bpm or Conductor.DEFAULT_BPM,
	numerator = 4,
	denominator = 4,

	endTime = nil, -- if theres endTime, it'll be automatically assigned as linear change

	beatTime = ?, -- automatically calculated
	measureTime = ?, -- automatically calculated
	resetSignature = true -- ceils beatTime, ceils measureTime,
		if resetSignature is false and numerator/denominator is set, it wont reset the beatTimes, measureTimes, stepTimes
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
	self.onMetronomeHit = Signal()

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
	if self.currentTimeChangeIdx > 1 then
		return self:rawgetTimeInBPM(self.songPosition, self.currentTimeChangeIdx)
	else
		return Conductor.DEFAULT_BPM
	end
end

---Beats per minute of the current song at the start time.
function Conductor:get_startingBPM()
	local timeChange = self.timeChanges[0]
	return timeChange and timeChange.bpm or Conductor.DEFAULT_BPM
end

---Duration of a measure in seconds. Calculated based on bpm.
function Conductor:get_measureLength(timeChange)
	return self:get_beatLength(timeChange) / self:get_beatsPerMeasure(timeChange)
end

---Duration of a beat (quarter note) in seconds. Calculated based on bpm.
function Conductor:get_beatLength(timeChange)
	return 60 / (timeChange and timeChange.bpm or self.bpm)
end

---Duration of a step (sixtennth note) in seconds. Calculated based on bpm.
function Conductor:get_stepLength(timeChange)
	return self:get_beatLength(timeChange) / self:get_numerator(timeChange)
end

---The numerator for the current time signature (the `3` in `3/4`).
function Conductor:get_numerator(timeChange)
	timeChange = timeChange or self:get_currentTimeChange()
	return timeChange and timeChange.numerator or 4
end

---The denominator for the current time signature (the `4` in `3/4`).
function Conductor:get_denominator(timeChange)
	timeChange = timeChange or self:get_currentTimeChange()
	return timeChange and timeChange.denominator or 4
end

---The number of beats in a measure. May be fractional depending on the time signature.
function Conductor:get_beatsPerMeasure(timeChange)
	return self:get_numerator(timeChange) / self:get_denominator(timeChange) * 4
end

---The number of steps in a measure.
function Conductor:get_stepsPerMeasure(timeChange)
	return (self:get_numerator(timeChange) ^ 2 * 4) / self:get_denominator(timeChange)
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
			self.onMetronomeHit:dispatch(false)
		end
		return
	end

	self.songPosition, self.oldMeasure, self.oldBeat, self.oldStep = songPosition, self.currentMeasure, self.currentBeat, self.currentStep

	self.currentTimeChangeIdx = self:getTimeInChangeIdx(songPosition, self.currentTimeChangeIdx)
	if self.currentTimeChangeIdx > 1 then
		self.currentBeatTime, self.currentMeasureTime = self:rawgetTimeInBeats(songPosition, self.currentTimeChangeIdx,
			self:rawgetTimeInBPM(songPosition, self.currentTimeChangeIdx))
	else
		self.currentBeatTime = songPosition / self:get_beatLength()
		self.currentMeasureTime = self.currentBeatTime / self:get_beatsPerMeasure()
	end
	self.currentStepTime = self.currentBeatTime * self:get_numerator()

	self.currentBeat, self.currentStep, self.currentMeasure = math.floor(self.currentBeatTime), math.floor(self.currentStepTime), math.floor(self.currentMeasureTime)
	
	local beatTicked, measureTicked = self.currentBeat ~= self.oldBeat, self.currentMeasure ~= self.oldMeasure
	if self.currentStep ~= self.oldStep or forceDispatch then self.onStepHit:dispatch() end
	if beatTicked or forceDispatch then self.onBeatHit:dispatch() end
	if measureTicked or forceDispatch then self.onMeasureHit:dispatch() end
	if beatTicked or measureTicked or forceDispatch then self.onMetronomeHit:dispatch(measureTicked) end
end

function Conductor:getTimeInChangeIdx(time, from)
	local c = #self.timeChanges; if c < 2 then return c end

	from = from and math.clamp(from, 1, c) or 1
	if self.timeChanges[from].time > time then
		for i = from - 1, 2, -1 do if time > self.timeChanges[i].time then return i end end; return 1
	else
		for i = from + 1, c do if self.timeChanges[i].time > time then return i - 1 end end; return c
	end
end

function Conductor:getBeatsInChangeIdx(beatTime, from)
	local c = #self.timeChanges; if c < 2 then return c end

	from = from and math.clamp(from, 1, c) or 1
	if self.timeChanges[from].beatTime > beatTime then
		for i = from - 1, 2, -1 do if beatTime > self.timeChanges[i].beatTime then return i end end; return 1
	else
		for i = from + 1, c do if self.timeChanges[i].beatTime > beatTime then return i - 1 end end; return c
	end
end

function Conductor:getMeasuresInChangeIdx(measureTime, from)
	local c = #self.timeChanges; if c < 2 then return c end

	from = from and math.clamp(from, 1, c) or 1
	if self.timeChanges[from].measureTime > measureTime then
		for i = from - 1, 2, -1 do if measureTime > self.timeChanges[i].measureTime then return i end end; return 1
	else
		for i = from + 1, c do if self.timeChanges[i].measureTime > measureTime then return i - 1 end end; return c
	end
end

function Conductor:rawgetTimeInBPM(time, idx)
	local timeChange = self.timeChanges[idx]
	if timeChange.endTime and time < timeChange.endTime then
		local prev = self.timeChanges[idx - 1]
		if not prev then return timeChange.bpm elseif time <= timeChange.time then return prev.bpm end

		-- BPM isn't so linear afterall, formula is pbpm * exp((1 / duration * ln(bpm / pbpm)) * elapsed), simplified
		local ratio = math.invlerp(timeChange.time, timeChange.endTime, time)
		return prev.bpm ^ (1 - ratio) * timeChange.bpm ^ ratio
	else
		return timeChange.bpm
	end
end

function Conductor:getTimeInBPM(time, from)
	local idx = self:getTimeInChangeIdx(time, from)
	if idx < 2 then return Conductor.DEFAULT_BPM else return self:rawgetTimeInBPM(time, idx) end
end

function Conductor:rawgetTimeInBeats(time, idx, bpm)
	local timeChange = self.timeChanges[idx]
	local startBeatTime, resetSignature = timeChange.beatTime or 0,
		timeChange.resetSignature or (timeChange.resetSignature ~= false and (timeChange.numerator or timeChange.denominator))

	startBeatTime = (resetSignature and math.ceil(math.truncate(startBeatTime, 6)) or startBeatTime)

	local beatTime, measureTime
	if timeChange.endTime and time > timeChange.time and idx > 1 then
		local prevBPM = self.timeChanges[idx - 1].bpm
		if time > timeChange.endTime then
			if timeChange.endBeatTime then
				beatTime = timeChange.endBeatTime + (time - timeChange.endTime) / self:get_beatLength(timeChange)
			else
				beatTime = startBeatTime + (timeChange.endTime - timeChange.time) * (bpm - prevBPM) / math.log(bpm / prevBPM) / 60 +
					(time - timeChange.endTime) / self:get_beatLength(timeChange)
			end
		else
			beatTime = startBeatTime + (time - timeChange.time) * (bpm - prevBPM) / math.log(bpm / prevBPM) / 60
		end
	else
		beatTime = startBeatTime + (time - timeChange.time) / self:get_beatLength(timeChange)
	end

	if timeChange.measureTime then
		measureTime = (resetSignature and math.ceil(math.truncate(timeChange.measureTime, 6)) or timeChange.measureTime) + (beatTime - startBeatTime) / self:get_beatsPerMeasure(timeChange)
	--elseif resetSignature then
	--	measureTime = math.ceil(startBeatTime / self:get_beatsPerMeasure(self.timeChanges[idx - 1])) + (beatTime - startBeatTime) / self:get_beatsPerMeasure(timeChange)
	else
		measureTime = beatTime / self:get_beatsPerMeasure(timeChange)
	end

	return beatTime, measureTime
end

function Conductor:getTimeInBeats(time, from)
	local idx = self:getTimeInChangeIdx(time, from)
	if idx < 2 then return time / self.beatLength else return self:rawgetTimeInBeats(time, idx, self:rawgetTimeInBPM(time, idx)) end
end

function Conductor:getTimeInMeasures(time, from)
	local idx = self:getTimeInChangeIdx(time, from)
	if idx < 2 then return time / self.get_measureLength else return select(2, self:rawgetTimeInBeats(time, idx, self:rawgetTimeInBPM(time, idx))) end
end

function Conductor:mapTimeChanges(timeChanges)
	if self.destroyed then return end
	table.sort(timeChanges, Conductor.sortByTime)

	local prev, prev2
	for i, timeChange in pairs(timeChanges) do
		timeChange.resetSignature = timeChange.resetSignature or (timeChange.resetSignature ~= false and (timeChange.numerator or timeChange.denominator))

		if i == 1 then
			timeChange.time = math.max(timeChange.time or 0, 0)
			timeChange.beatTime = timeChange.time / (60 / timeChange.bpm)
		elseif (timeChange.time and timeChange.time <= 0) or (timeChange.beatTime and timeChange.beatTime <= 0) then
			timeChange.time, timeChange.beatTime = 0, 0
		elseif timeChange.beatTime and not timeChange.time then
			timeChange.beatTime = timeChange.resetSignature and math.ceil(math.truncate(timeChange.beatTime, 6)) or timeChange.beatTime

			if prev.endTime and prev2 then--(prev.endTime - prev.time) * (prev.bpm - prev2.bpm) / math.log(prev.bpm / prev2.bpm) / 60
				timeChange.time = prev.endTime + timeChange.beatTime * (60 / prev.bpm)-- - (prev.beatTime)
				if prev.endBeatTime then
					timeChange.time = prev.endTime + (timeChange.beatTime - prev.endBeatTime) * (60 / prev.bpm)
				else
					timeChange.time = prev.endTime + timeChange.beatTime * (60 / prev.bpm)
				end
			else
				timeChange.time = prev.time + (timeChange.beatTime - prev.beatTime) * (60 / prev.bpm)
			end
			if timeChange.endBeatTime then
				timeChange.endTime = timeChange.time + (timeChange.endBeatTime - timeChange.beatTime) / (timeChange.bpm - prev.bpm) * math.log(timeChange.bpm / prev.bpm) * 60
			end
		else
			if prev.endTime and prev2 then
				timeChange.beatTime = prev.beatTime + (prev.endTime - prev.time) * (prev.bpm - prev2.bpm) / math.log(prev.bpm / prev2.bpm) / 60 +
					(timeChange.time - prev.endTime) / (60 / prev.bpm)
			else
				timeChange.beatTime = prev.beatTime + (timeChange.time - prev.time) / (60 / prev.bpm)
			end

			timeChange.beatTime = timeChange.resetSignature and math.ceil(math.truncate(timeChange.beatTime, 6)) or timeChange.beatTime
		end

		if prev then
			timeChange.measureTime = prev.measureTime + (timeChange.beatTime - prev.beatTime) / self:get_beatsPerMeasure(prev)
		else
			timeChange.measureTime = timeChange.beatTime / self:get_beatsPerMeasure(prev)
		end
		timeChange.measureTime = timeChange.resetSignature and math.ceil(math.truncate(timeChange.measureTime, 6)) or timeChange.measureTime

		prev2 = prev
		prev = timeChange
	end

	self.timeChanges = timeChanges
end

function Conductor:destroy()
	Conductor.super.destroy(self)

	self.timeChanges = nil
	self.onMeasureHit:destroy()
	self.onBeatHit:destroy()
	self.onStepHit:destroy()
end

return Conductor