local Group = Basic:extend("Group")

function Group:new()
	Group.super.new(self)
	self.members = {}
end

function Group:add(obj)
	return self:insert(obj)
end

function Group:insert(idx, obj)
	table.insert(self.members, idx, obj)
	if obj.enter then obj:enter(self) end
	return obj
end

function Group:indexOf(obj)
	return table.find(self.members, obj)
end

function Group:remove(obj)
	return self:removeIdx(self:indexOf(obj))
end

function Group:pop()
	return self:removeIdx(#self.members)
end

function Group:removeIdx(idx)
	local obj, last = table.remove(self.members, idx), idx ~= 1 and self.members[idx - 1]
	if obj.leave then obj:leave(self) end
	if last and last.resume then last:resume(self) end
	return obj, last
end

function Group:clear()
	for _, member in pairs(self.members) do member:leave(self) end
	table.clear(self.members)
end

function Group:reverse() table.reverse(self.members) end

function Group:sort(func) table.sort(self.members, func) end

function Group:recycle(class, factory, revive)
	if factory == nil then factory = class end
	if revive == nil then revive = true end

	local obj
	for _, member in ipairs(self.members) do
		if member.destroyed and (not class or (member.is and member:is(class))) then
			obj = member
			break
		end
	end
	if obj then
		self:remove(obj)
		if revive and obj.revive then obj:revive() end
	elseif factory then
		obj = factory()
	else
		return nil
	end

	self:add(obj)
	return obj
end

function Group:update(dt)
	if not self.destroyed and self.active then
		for _, member in ipairs(self.members) do
			if not member.destroyed and member.active then
				local f = member.update
				if f then f(member, dt) end
			end
		end
	end
end

function Group:render()
	if not self.destroyed and self.active then
		for _, member in ipairs(self.members) do
			if not member.destroyed and member.active then
				local f = member.render
				if f then f(member, dt) end
			end
		end
	end
end

function Group:revive()
	for _, member in ipairs(self.members) do
		local f = member.revive
		if f then f(member) end
	end

	Group.super.revive(self)
end

function Group:destroy()
	Group.super.destroy(self)

	for _, member in ipairs(self.members) do
		local f = member.destroy
		if f then f(member) end
	end
end

return Group