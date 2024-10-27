local Signal = require("funkin.utils.signal")

local Conductor = Basic:extend("Conductor")
local DEFAULT_TIMECHANGES = {bpm = 100, numerator = 4, denominator = 4, tuplet = 4}

function Conductor.sortByTime(a, b)
	if a.beatTime or b.beatTime then return (a.beatTime or -math.huge) < (b.beatTime or -math.huge)
	elseif a.time or b.time then return (a.time or -math.huge) < (b.time or -math.huge) end
	return false
end

--[[ timeChange {
	time = songPosition,
	bpm = bpm,
	numerator = 4,
	denominator = 4,
	tuplet = 4,

	endTime = nil, -- if theres endTime, it'll be automatically assigned as linear change

	stepTime = ?, -- automatically calculated
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
	self.currentTimeChangeIdx = 1
end

---Force Set the BPM and overriding the timeChanges
function Conductor:setBPM(bpm) self.timeChanges = {{bpm = bpm, time = 0, beatTime = 0, measureTime = 0}} end

---The time change that current song position are in.
function Conductor:get_currentTimeChange() return self.timeChanges[self.currentTimeChangeIdx] end

---Beats per minute of the current song at the current time.
function Conductor:get_bpm()
	if self.currentTimeChangeIdx > 1 then
		return self:rawgetTimeInBPM(self.songPosition, self.currentTimeChangeIdx)
	else
		return self:get_startingBPM()
	end
end

---Beats per minute of the current song at the start time.
function Conductor:get_startingBPM()
	return (self.timeChanges[1] or DEFAULT_TIMECHANGES).bpm
end

---Duration of a beat (quarter note) by current denominator in seconds. Calculated based on bpm.
function Conductor:get_beatLength(timeChange)
	return 240 / (timeChange or self).bpm / self:get_denominator(timeChange)
end

---Duration of a step (sixtennth note) by current tuplet in seconds. Calculated based on bpm.
function Conductor:get_stepLength(timeChange)
	return self:get_beatLength(timeChange) / self:get_tuplet(timeChange)
end

---Duration of a measure in seconds. Calculated based on bpm.
function Conductor:get_measureLength(timeChange)
	return self:get_beatLength(timeChange) * self:get_numerator(timeChange)
end

---The numerator for the current time signature (the `3` in `3/4`).
function Conductor:get_numerator(timeChange)
	return (timeChange or self:get_currentTimeChange() or DEFAULT_TIMECHANGES).numerator
end

---The denominator for the current time signature (the `4` in `3/4`).
function Conductor:get_denominator(timeChange)
	return (timeChange or self:get_currentTimeChange() or DEFAULT_TIMECHANGES).denominator
end

---The tuplet for the current time change
function Conductor:get_tuplet(timeChange)
	return (timeChange or self:get_currentTimeChange() or DEFAULT_TIMECHANGES).tuplet
end

---The number of steps in a measure.
function Conductor:get_stepsPerMeasure(timeChange)
	return self:get_numerator(timeChange) * self:get_tuplet(timeChange)
end

function Conductor:update(sound, forceDispatch, applyOffsets)
	if not self.active or self.destroyed then return end
	if sound == nil then sound = SoundManager.music end
	if applyOffsets == nil then applyOffsets = true end

	local songPosition = sound == nil and SoundManager.music or (type(sound) == 'number' and sound or sound.time) - (applyOffsets and self.offset or 0)
	if songPosition == self.songPosition then
		if forceDispatch ~= false and forceDispatch then
			self.onStepHit:dispatch()
			self.onBeatHit:dispatch()
			self.onMeasureHit:dispatch()
			self.onMetronomeHit:dispatch(false)
		end
		return
	end

	self.songPosition, self.oldBeat, self.oldStep, self.oldMeasure = songPosition, self.currentBeat, self.currentStep, self.currentMeasure

	self.currentTimeChangeIdx = self:getTimeInChangeIdx(songPosition, self.currentTimeChangeIdx)
	if self.currentTimeChangeIdx > 1 then
		local timeChange = self:get_currentTimeChange()
		self.currentBeatTime = self:rawgetTimeInBeats(songPosition, self.currentTimeChangeIdx, self:rawgetTimeInBPM(songPosition, self.currentTimeChangeIdx))
		self.currentStepTime = timeChange.stepTime + (self.currentBeatTime - timeChange.beatTime) * self:get_tuplet(timeChange)
		self.currentMeasureTime = timeChange.measureTime + (self.currentBeatTime - timeChange.beatTime) / self:get_numerator(timeChange)
	else
		self.currentBeatTime = songPosition / self:get_beatLength()
		self.currentStepTime = self.currentBeatTime * self:get_tuplet()
		self.currentMeasureTime = self.currentBeatTime / self:get_numerator()
	end

	self.currentBeat, self.currentStep, self.currentMeasure = math.floor(self.currentBeatTime),
		math.floor(self.currentStepTime),
		math.floor(self.currentMeasureTime)
	
	if forceDispatch ~= false then
		local beatTicked, measureTicked = self.currentBeat ~= self.oldBeat, self.currentMeasure ~= self.oldMeasure
		if self.currentStep ~= self.oldStep or forceDispatch then self.onStepHit:dispatch() end
		if beatTicked or forceDispatch then self.onBeatHit:dispatch() end
		if measureTicked or forceDispatch then self.onMeasureHit:dispatch() end
		if beatTicked or measureTicked or forceDispatch then self.onMetronomeHit:dispatch(measureTicked) end
	end
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

function Conductor:getStepsInChangeIdx(stepTime, from)
	local c = #self.timeChanges; if c < 2 then return c end

	from = from and math.clamp(from, 1, c) or 1
	if self.timeChanges[from].stepTime > stepTime then
		for i = from - 1, 2, -1 do if stepTime > self.timeChanges[i].stepTime then return i end end; return 1
	else
		for i = from + 1, c do if self.timeChanges[i].stepTime > stepTime then return i - 1 end end; return c
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
	if timeChange.endTime and time < timeChange.endTime and idx > 1 then
		local prevBPM = self.timeChanges[idx - 1].bpm
		if time <= timeChange.time then return prevBPM end

		-- BPM isn't so linear afterall, formula is pbpm * exp((1 / duration * ln(bpm / pbpm)) * elapsed), simplified
		local ratio = math.invlerp(timeChange.time, timeChange.endTime, time)
		return prevBPM ^ (1 - ratio) * timeChange.bpm ^ ratio
	else
		return timeChange.bpm
	end
end

function Conductor:rawgetBeatsInBPM(beatTime, idx)
	local timeChange = self.timeChanges[idx]
	if timeChange.endTime and idx > 1 then
		local prevBPM = self.timeChanges[idx - 1].bpm
		if beatTime <= timeChange.beatTime then return prevBPM end

		-- Okay so this one is linear, but that's because it's in beatTimes
		local endBeatTime = timeChange.beatTime + (timeChange.endTime - timeChange.time) * (timeChange.bpm - prevBPM)
			/ math.log(timeChange.bpm / prevBPM) / 240 * self:get_denominator(timeChange)

		if beatTime < endBeatTime then return math.remap(beatTime, timeChange.beatTime, endBeatTime, prevBPM, timeChange.bpm) end
	end
	return timeChange.bpm
end

function Conductor:getTimeInBPM(time, from)
	local idx = self:getTimeInChangeIdx(time, from)
	if idx == 0 then return DEFAULT_TIMECHANGES.bpm else return self:rawgetTimeInBPM(time, idx) end
end

function Conductor:getBeatsInBPM(beatTime, from)
	local idx = self:getBeatsInChangeIdx(beatTime, from)
	if idx == 0 then return DEFAULT_TIMECHANGES.bpm else return self:rawgetBeatsInBPM(beatTime, idx) end
end

function Conductor:getStepsInBPM(stepTime, from)
	local idx = self:getStepsInChangeIdx(stepTime, from)
	if idx == 0 then return DEFAULT_TIMECHANGES.bpm else
		local timeChange = self.timeChanges[idx]
		return self:rawgetBeatsInBPM(timeChange.stepTime + (stepTime - timeChange.stepTime) / self:get_tuplet(timeChange), idx)
	end
end

function Conductor:getMeasuresInBPM(measureTime, from)
	local idx = self:getMeasuresInChangeIdx(measureTime, from)
	if idx == 0 then return DEFAULT_TIMECHANGES.bpm else
		local timeChange = self.timeChanges[idx]
		return self:rawgetMeasuresInBPM(timeChange.measureTime + (measureTime - timeChange.measureTime) * timeChange.numerator, idx)
	end
end

function Conductor:rawgetTimeInBeats(time, idx, bpm)
	local timeChange = self.timeChanges[idx]
	if timeChange.endTime and time > timeChange.time and idx > 1 then
		local prevBPM = self.timeChanges[idx - 1].bpm
		if time > timeChange.endTime then
			return timeChange.beatTime + (((timeChange.endTime - timeChange.time) * (timeChange.bpm - prevBPM))
				/ math.log(timeChange.bpm / prevBPM) + (time - timeChange.endTime) * bpm) / 240 * self:get_denominator(timeChange)
		else
			return timeChange.beatTime + (time - timeChange.time) * (bpm - prevBPM) / math.log(bpm / prevBPM) / 240 * self:get_denominator(timeChange)
		end
	else
		return timeChange.beatTime + (time - timeChange.time) / self:get_beatLength(timeChange)
	end
end

function Conductor:getTimeInBeats(time, from)
	local idx = self:getTimeInChangeIdx(time, from)
	if idx < 2 then return time / self.beatLength else return self:rawgetTimeInBeats(time, idx, self:rawgetTimeInBPM(time, idx)) end
end

function Conductor:getTimeInSteps(time, from)
	local idx = self:getTimeInChangeIdx(time, from)
	if idx < 2 then return time / self.stepLength else
		local timeChange = self.timeChanges[idx]
		return timeChange.stepTime + (self:rawgetTimeInBeats(time, idx, self:rawgetTimeInBPM(time, idx)) - timeChange.beatTime) * self:get_tuplet(timeChange)
	end
end

function Conductor:getTimeInMeasures(time, from)
	local idx = self:getTimeInChangeIdx(time, from)
	if idx < 2 then return time / self.measureLength else
		local timeChange = self.timeChanges[idx]
		return timeChange.measureTime + (self:rawgetTimeInBeats(time, idx, self:rawgetTimeInBPM(time, idx)) - timeChange.beatTime) / self:get_numerator(timeChange)
	end
end

function Conductor:rawgetBeatsInTime(beatTime, idx, bpm)
	local timeChange = self.timeChanges[idx]
	if timeChange.endTime and beatTime > timeChange.beatTime and idx > 1 then
		local prevBPM = self.timeChanges[idx - 1].bpm
		local time = timeChange.time + (beatTime - timeChange.beatTime) / (bpm - prevBPM) * math.log(bpm / prevBPM) * 240 / self:get_denominator(timeChange)
		if time > timeChange.endTime then
			return (240 / self:get_denominator(timeChange) * (beatTime - timeChange.beatTime) - ((timeChange.endTime - timeChange.time)
				* (timeChange.bpm - prevBPM)) / math.log(timeChange.bpm / prevBPM)) / bpm + timeChange.endTime
		else
			return time
		end
	else
		return timeChange.time + (beatTime - timeChange.beatTime) * self:get_beatLength(timeChange)
	end
end

function Conductor:getBeatsInTime(beatTime, from)
	local idx = self:getBeatsInChangeIdx(beatTime, from)
	if idx < 2 then return beatTime * self.beatLength else return self:rawgetBeatsInTime(beatTime, idx, self:rawgetBeatsInBPM(beatTime, idx)) end
end

function Conductor:getStepsInTime(stepTime, from)
	local idx = self:getStepsInChangeIdx(stepTime, from)
	if idx < 2 then return stepTime * self.stepLength else
		local timeChange = self.timeChanges[idx]
		local beatTime = timeChange.beatTime + (stepTime - timeChange.stepTime) / self:get_tuplet(timeChange)
		return self:rawgetBeatsInTime(beatTime, idx, self:rawgetBeatsInBPM(beatTime, idx))
	end
end

function Conductor:getMeasuresInTime(measureTime, from)
	local idx = self:getMeasuresInChangeIdx(measureTime, from)
	if idx < 2 then return measureTime * self.measureLength else
		local timeChange = self.timeChanges[idx]
		local beatTime = timeChange.beatTime + (measureTime - timeChange.measureTime) * self:get_numerator(timeChange)
		return self:rawgetBeatsInTime(beatTime, idx, self:rawgetBeatsInBPM(beatTime, idx))
	end
end

function Conductor:updateTimeChanges(timeChanges, from)
	if self.destroyed then return end

	if self.timeChanges ~= nil then
		for i = #timeChanges, #self.timeChanges do table.remove(self.timeChanges) end
	else
		self.timeChanges = {}
	end

	local change, new, current, prev
	for i = from, #timeChanges do
		change, new, current, prev = timeChanges[i], self.timeChanges[i], new or self.timeChanges[i - 1], current or self.timeChanges[i - 2]
		if not new then new = {}; table.insert(self.timeChanges, new) end

		new.resetSignature, new.time, new.endTime, new.bpm, new.tuplet, new.numerator, new.denominator =
			change.resetSignature or (change.resetSignature ~= false and (change.numerator ~= nil or change.denominator ~= nil)),
			change.time or 0,
			change.endTime,
			change.bpm or current and current.bpm or DEFAULT_TIMECHANGES.bpm,
			change.tuplet or current and current.tuplet or DEFAULT_TIMECHANGES.tuplet,
			change.numerator or current and current.numerator or DEFAULT_TIMECHANGES.numerator,
			change.denominator or current and current.denominator or DEFAULT_TIMECHANGES.denominator

		if (new.time and new.time <= 0) or (new.beatTime and new.beatTime <= 0) then
			new.time, new.beatTime = 0, 0
		elseif current == nil then
			new.beatTime = new.time / 240 * new.bpm * new.denominator
		elseif change.beatTime and not new.time then
			if current.endTime and prev2 then
				new.time = current.endTime + new.beatTime * 240 / current.bpm / current.denominator
				if current.endBeatTime then
					new.time = current.endTime + (new.beatTime - current.endBeatTime) * 240 / current.bpm / current.denominator
				else
					new.time = current.endTime + new.beatTime * 240 / current.bpm / current.denominator
				end
			else
				new.time = current.time + (new.beatTime - current.beatTime) * 240 / current.bpm / current.denominator
			end
			if change.endBeatTime then
				new.endTime = new.time + (change.endBeatTime - new.beatTime) / (new.bpm - current.bpm)
					* math.log(new.bpm / current.bpm) * 240 / current.denominator
			end
		else
			if current.endTime and prev then
				new.beatTime = current.beatTime + (((current.endTime - current.time) * (current.bpm - prev.bpm))
					/ math.log(current.bpm / prev.bpm) + (new.time - current.endTime) * new.bpm) / 240 * self:get_denominator(current)
			else
				new.beatTime = current.beatTime + (new.time - current.time) / 240 * current.bpm * current.denominator
			end
		end

		if current then
			new.stepTime = current.stepTime + (new.beatTime - current.beatTime) * current.tuplet
			new.measureTime = current.measureTime + (new.beatTime - current.beatTime) / current.numerator
		else
			new.stepTime, new.measureTime = new.beatTime * new.tuplet, new.beatTime / new.numerator
		end

		if new.resetSignature then
			new.beatTime, new.stepTime, new.measureTime = math.ceil(new.beatTime - .000001), math.ceil(new.stepTime - .000001), math.ceil(new.measureTime - .000001)
		end
	end
end

function Conductor:mapTimeChanges(timeChanges)
	if not self.destroyed then
		timeChanges = table.clone(timeChanges)
		table.sort(timeChanges, Conductor.sortByTime)
		self:updateTimeChanges(timeChanges, 1)
	end
end

function Conductor:destroy()
	Conductor.super.destroy(self)

	self.timeChanges = nil
	self.onMeasureHit:destroy()
	self.onBeatHit:destroy()
	self.onStepHit:destroy()
end

return Conductor