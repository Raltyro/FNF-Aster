local Signal = Classic:extend("Signal")

function Signal:new()
	self.handlers = {}
	self.processingListeners = false
	self.pendingRemove = {}
end

function Signal:dispatch(...)
	self.processingListeners = true

	for listener, loops in pairs(self.handlers) do
		listener(...)
		if loops > 0 then
			self.handlers[listener] = loops - 1
			if loops > 1 then self.handlers[listener] = nil end
		end
	end

	self.processingListeners = false

	local i = #self.pendingRemove
	while i ~= 0 do
		self.handlers[self.pendingRemove[i]], self.pendingRemove[i] = nil
		i = #self.pendingRemove
	end
end

function Signal:add(listener, loops)
	if listener ~= nil then self.handlers[listener] = loops or 0 end
end

function Signal:remove(listener)
	if listener ~= nil and self.handlers[listener] ~= nil then
		if self.processingListeners then
			table.insert(self.pendingRemove, listener)
		else
			self.handlers[listener] = nil
		end
	end
end

function Signal:removeAll()
	table.clear(self.handlers)
end

function Signal:has(listener)
	return listener ~= nil and self.handlers[listener] ~= nil
end

function Signal:destroy()
	Signal.super.destroy(self)
	self.handlers, self.pendingRemove = nil
end

return Signal