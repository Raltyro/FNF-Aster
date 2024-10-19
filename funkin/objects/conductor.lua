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
	local timeChange = self:get_currentTimeChange()
	if timeChange then
		if timeChange.endTime then
			if self.songPosition >= timeChange.endTime then return timeChange.bpm end

			local prev = self.timeChanges[self.currentTimeChangeIdx - 1]
			if not prev then return timeChange.bpm
			elseif self.songPosition < timeChange.time then return prev.bpm end

			-- BPM isn't so linear afterall
			return prev.bpm * math.exp((1 / (timeChange.endTime - timeChange.time) * math.log(timeChange.bpm / prev.bpm)) * (self.songPosition - timeChange.time))
		end
		return timeChange.bpm
	end
	return Conductor.DEFAULT_BPM
end

---Beats per minute of the current song at the start time.
function Conductor:get_startingBPM()
	local timeChange = self.timeChanges[0]
	return timeChange and timeChange.bpm or Conductor.DEFAULT_BPM
end

---Duration of a measure in seconds. Calculated based on bpm.
function Conductor:get_measureLengthM(timeChange)
	return self:get_beatLength(timeChange) * self:get_numerator(timeChange)
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
-- TODO: fix this?
function Conductor:get_beatsPerMeasure(timeChange)
	return self:get_numerator(timeChange) / self:get_denominator(timeChange) * 4
end

---The number of steps in a measure.
function Conductor:get_stepsPerMeasure(timeChange)
	return self:get_numerator(timeChange) / self:get_denominator(timeChange) * 16
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
			self.onMetronomeHit:dispatch(0)
		end
		return
	end

	self.songPosition, self.oldMeasure, self.oldBeat, self.oldStep = songPosition, self.currentMeasure, self.currentBeat, self.currentStep

	self.currentTimeChangeIdx = self:getTimeInChangeIdx(songPosition, self.currentTimeChangeIdx)
	local timeChange = self.currentTimeChange
	if timeChange == nil then
		self.currentBeatTime = songPosition / self:get_beatLength()
		self.currentMeasureTime = self.currentBeatTime / self:get_beatsPerMeasure()
	else
		local startBeatTime, resetSignature = timeChange.beatTime or 0, timeChange.resetSignature or (timeChange.resetSignature ~= false and (timeChange.numerator or timeChange.denominator))
		startBeatTime = (resetSignature and math.ceil(math.truncate(startBeatTime, 6)) or startBeatTime)

		if timeChange.endTime and self.currentTimeChangeIdx > 1 then
			local prevBPM, bpm = self.timeChanges[self.currentTimeChangeIdx - 1].bpm, self:get_bpm()
			if songPosition > timeChange.endTime then
				self.currentBeatTime = startBeatTime + (timeChange.endTime - timeChange.time) * (bpm - prevBPM) / math.log(bpm / prevBPM) / 60 +
					(songPosition - timeChange.endTime) / self:get_beatLength()
			else
				self.currentBeatTime = startBeatTime + (songPosition - timeChange.time) * (bpm - prevBPM) / math.log(bpm / prevBPM) / 60
			end
		else
			self.currentBeatTime = startBeatTime + (songPosition - timeChange.time) / self:get_beatLength()
		end

		if timeChange.measureTime then
			self.currentMeasureTime = (resetSignature and math.ceil(math.truncate(timeChange.measureTime, 6)) or timeChange.measureTime) + (self.currentBeatTime - startBeatTime) / self:get_beatsPerMeasure()
		--elseif resetSignature then
		--	self.currentMeasureTime = math.ceil(startBeatTime / self:get_beatsPerMeasure(self.timeChanges[self.currentTimeChangeIdx - 1])) + (songPosition - timeChange.time) / self:get_beatLength(timeChange) / self:get_beatsPerMeasure(timeChange)
		else
			self.currentMeasureTime = self.currentBeatTime / self:get_beatsPerMeasure()
		end
	end
	self.currentStepTime = self.currentBeatTime * self:get_numerator()

	self.currentBeat, self.currentStep, self.currentMeasure = math.floor(self.currentBeatTime), math.floor(self.currentStepTime), math.floor(self.currentMeasureTime)
	
	local beatTicked, measureTicked = self.currentBeat ~= self.oldBeat, self.currentMeasure ~= self.oldMeasure
	if self.currentStep ~= self.oldStep or forceDispatch then self.onStepHit:dispatch() end
	if beatTicked or forceDispatch then self.onBeatHit:dispatch() end
	if measureTicked or forceDispatch then self.onMeasureHit:dispatch() end

	if beatTicked or measureTicked or forceDispatch then
		self.onMetronomeHit:dispatch(measureTicked)
	end
end

function Conductor:getTimeInChangeIdx(time, from)
	if #self.timeChanges < 2 then return 1 end
	from = math.clamp(from or 1, 1, #self.timeChanges)

	if self.timeChanges[from].time > time then
		while from > 1 do from = from - 1; if time > self.timeChanges[from].time then return from end end
	else
		local c = #self.timeChanges
		for from = from, c do if self.timeChanges[from].time > time then return from - 1 end end
		return c
	end

	return from
end

function Conductor:getBeatTimeInChangeIdx(beatTime, from)
	if #self.timeChanges < 2 then return 1 end
	from = math.clamp(from or 1, 1, #self.timeChanges)

	if self.timeChanges[from].beatTime > beatTime then
		while from > 1 do from = from - 1; if beatTime > self.timeChanges[from].beatTime then return from end end
	else
		local c = #self.timeChanges
		for from = from, c do if self.timeChanges[from].beatTime > beatTime then return from - 1 end end
		return c
	end

	return from
end

function Conductor:getMeasureTimeInChangeIdx(measureTime, from)
	if #self.timeChanges < 2 then return 1 end
	from = math.clamp(from or 1, 1, #self.timeChanges)

	if self.timeChanges[from].measureTime > measureTime then
		while from > 1 do from = from - 1; if measureTime > self.timeChanges[from].measureTime then return from end end
	else
		local c = #self.timeChanges
		for from = from, c do if self.timeChanges[from].measureTime > measureTime then return from - 1 end end
		return c
	end

	return from
end

function Conductor:mapTimeChanges(timeChanges)
	if self.destroyed then return end
	table.sort(timeChanges, Conductor.sortByTime)

	local prev, prev2
	for i, timeChange in pairs(timeChanges) do
		if i == 1 then
			timeChange.time = math.max(timeChange.time or 0, 0)
			timeChange.beatTime = timeChange.time / (60 / timeChange.bpm)
		elseif (timeChange.time and timeChange.time <= 0) or (timeChange.beatTime and timeChange.beatTime <= 0) then
			timeChange.time, timeChange.beatTime = 0, 0
		elseif timeChange.beatTime and not timeChange.time then
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
		end
		local resetSignature = timeChange.resetSignature or (timeChange.resetSignature ~= false and (timeChange.numerator or timeChange.denominator))
		timeChange.beatTime = timeChange.resetSignature and math.ceil(math.truncate(timeChange.beatTime, 6)) or timeChange.beatTime

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