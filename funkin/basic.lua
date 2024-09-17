local Basic = Classic:extend("Basic", ...)

function Basic:new()
	self.active = true
end

function Basic:revive()
	self.destroyed = false
end

function Basic:destroy()
	self.destroyed = true
end

return Basic