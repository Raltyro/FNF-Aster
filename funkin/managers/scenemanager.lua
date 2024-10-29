local SceneManager = {stack = {}, dirty = false, deltaTime = 0}

local initialized_scenes = setmetatable({}, {__mode = 'k'})
local function enter_scene(offset, to, ...)
	local pre = SceneManager.stack[#SceneManager.stack]
	to = type(to) == 'string' and pcall(require, to)() or (to.isObject and to:isObject()) and to or to()

	; (initialized_scenes[to] or to.init or __NULL__)(to)
	initialized_scenes[to] = true

	SceneManager.dirty = true
	SceneManager.stack[math.max(#SceneManager.stack + offset, 1)] = to
	return (to.enter or __NULL__)(to, pre, ...)
end

function SceneManager.switch(scene, ...)
	local pre = SceneManager.stack[#SceneManager.stack]
	; (pre and pre.leave or __NULL__)(pre)
	return enter_scene(0, scene, ...)
end

function SceneManager.push(scene, ...)
	return enter_scene(1, scene, ...)
end

function SceneManager.pop(index, ...)
	if #SceneManager.stack == 0 or index > #SceneManager.stack then return
	elseif index == nil then index = #SceneManager.stack end

	local pre, to = SceneManager.stack[index], SceneManager.stack[index - 1]
	SceneManager.stack[index] = nil
	; (pre.leave or __NULL__)(pre)
	return (to.resume or __NULL__)(to, pre, ...)
end

function SceneManager.clear(...)
	for i = 1, #SceneManager.stack do SceneManager.pop(nil, ...) end
end

function SceneManager.update(deltaTime)
	if SceneManager.dirty then
		deltaTime = 0
		SceneManager.dirty = false
	else
		local fakedt = SceneManager.deltaTime
		local low = math.min(math.log(1.101 + fakedt), 0.1)
		deltaTime = deltaTime - fakedt > low and fakedt + low or deltaTime
	end
	SceneManager.deltaTime = deltaTime

	local n = #SceneManager.stack
	for i = n, 1, -1 do
		if i == n or SceneManager.stack[i].persistentUpdate then
			(SceneManager.stack[i].update or __NULL__)(SceneManager.stack[i], deltaTime)
		else
			break
		end
	end
end

function SceneManager.render()
	local n = #SceneManager.stack
	for i = n, 1, -1 do
		if i == n or SceneManager.stack[i].persistentRender then
			(SceneManager.stack[i].render or __NULL__)(SceneManager.stack[i], deltaTime)
		else
			break
		end
	end
end

local current = 'current'
return setmetatable(SceneManager, {
	__index = function(t, i)
		if i == current then return t.stack[#t.stack] else rawget(t, i) end
	end
})