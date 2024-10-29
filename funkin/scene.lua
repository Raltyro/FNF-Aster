local Scene = Group:extend("Scene")

function Scene:new()
	Scene.super.new(self)

	self.updateConductor = true
end

function Scene:enter()
	local conductor = Conductor.instance

	if self.beatHit ~= nil then
		if self._beatHit then conductor.onBeatHit:remove(self._beatHit) end
		self._beatHit = bind(self, self.beatHit); conductor.onBeatHit:add(self._beatHit)
	end
	if self.stepHit ~= nil then
		if self._stepHit then conductor.onStepHit:remove(self._stepHit) end
		self._stepHit = bind(self, self.stepHit); conductor.onStepHit:add(self._stepHit)
	end
	if self.measureHit ~= nil then
		if self._measureHit then conductor.onMeasureHit:remove(self._measureHit) end
		self._measureHit = bind(self, self.measureHit); conductor.onMeasureHit:add(self._measureHit)
	end
	if self.metronomeHit ~= nil then
		if self._metronomeHit then conductor.onMetronomeHit:remove(self._metronomeHit) end
		self._metronomeHit = bind(self, self.metronomeHit); conductor.onMetronomeHit:add(self._metronomeHit)
	end

	self.conductor = conductor
end

function Scene:update(dt)
	if self.updateConductor then Conductor.instance:update() end
end

function Scene:leave()
	local conductor = self.conductor
	if conductor then
		if self._beatHit then conductor.onBeatHit:remove(self._beatHit) end
		if self._stepHit then conductor.onStepHit:remove(self._stepHit) end
		if self._measureHit then conductor.onMeasureHit:remove(self._measureHit) end
		if self._metronomeHit then conductor.onMetronomeHit:remove(self._metronomeHit) end
	end
end

return Scene