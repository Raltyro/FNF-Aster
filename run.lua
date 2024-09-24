-- NOTE, no matter how precision is, in windows 10 as of now (<=love 11)
-- will be always 12ms, unless its using SDL3 or CREATE_WAITABLE_TIMER_HIGH_RESOLUTION flag
require "love.window"

local step, quit = 'step', 'quit'
local dt, fps = 0, 0
local ch_ev, ch_ev_active, ch_ev_tick = love.thread.getChannel'run_event', love.thread.getChannel'run_event_active', love.thread.getChannel'run_event_tick'
local thread_event_code, thread_event = [[require"love.event"; require"love.timer"
local pump, poll, getChannel = love.event.pump, love.event.poll(), love.thread.getChannel
local channel, active, tick = getChannel"event", getChannel"event_active", getChannel"event_tick"
local getTime, sleep, step = love.timer.getTime, love.timer.sleep, "step"

local t, s, clock, prev, v, push = {}, 0, getTime()
function push(i, a, ...) if a then t[i] = a; return push(i + 1, ...) end return i - 1 end
repeat v = active:pop(); if v == 0 then break elseif v == 1 then s = 0 end
	pcall(pump); prev, clock = clock, getTime()
	for name, a, b, c, d, e, f in poll do
		v = push(1, a, b, c, d, e, f); channel:push(name); channel:push(clock); channel:push(v);
		for i = 1, v do channel:push(t[i]) end
	end

	v = clock - prev; s = s + v; tick:clear(); tick:push(v)
	sleep(v < 0.001 and 0.001 or 0)
	collectgarbage(step)
until s > 1]]

--[[local eventhandlers = {
	keypressed = function(t, b, s, r) return love.keypressed(b, s, r, t) end,
	keyreleased = function(t, b, s) return love.keyreleased(b, s, t) end,
	touchpressed = function(t, id, x, y, dx, dy, p) return love.touchpressed(id, x, y, dx, dy, p, t) end,
	touchmoved = function(t, id, x, y, dx, dy, p) return love.touchmoved(id, x, y, dx, dy, p, t) end,
	touchreleased = function(t, id, x, y, dx, dy, p) return love.touchreleased(id, x, y, dx, dy, p, t) end,
	joystickpressed = function(t, j, b) if love.joystickpressed then return love.joystickpressed(j, b, t) end end,
	joystickreleased = function(t, j, b) if love.joystickreleased then return love.joystickreleased(j, b, t) end end,
	gamepadpressed = function(t, j, b) if love.gamepadpressed then return love.gamepadpressed(j, b, t) end end,
	gamepadreleased = function(t, j, b) if love.gamepadreleased then return love.gamepadreleased(j, b, t) end end,
}]]
function love.run()
	love.framerate, love.unfocusedFramerate = math.max(select(3, love.window.getMode()).refreshrate, 60), 16
	love.asyncInput, thread_event = false, love.thread.newThread(thread_event_code)
	love.autoPause, love.parallelUpdate = false, false

	if love.math then love.math.setRandomSeed(os.time()) end
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	love.timer.step(); collectgarbage()

	local origin, clear, present, pump, poll = love.graphics.origin, love.graphics.clear, love.graphics.present, love.event.pump, love.event.poll()
	local hasFocus, sleep, focused, clock, nextdraw, cap, t, n, a, b = love.window.hasFocus, love.timer.sleep, true, 0, 0, 0, {}, 0
	local prevFpsUpdate, sinceLastFps, frames = 0, 0, 0

	local function event(name, a, ...)
		if name == quit and not love.quit() then ch_ev:clear(); ch_ev_active:clear(); ch_ev_active:push(0) return a or 0, ... end
		--[[if name:sub(1,5) == "mouse" and name ~= "mousefocus" and (name ~= "mousemoved" or love.mouse.isDown(1, 2)) then
			love.handlers["touch"..name:sub(6)](0, a, ...)
		end]]
		--if eventhandlers[name] then return eventhandlers[name](clock, a, ...) end
		return love.handlers[name](a, ...)
	end

	return function()
		a = love.asyncInput and focused
		if thread_event:isRunning() then
			ch_ev_active:clear()
			ch_ev_active:push(a and 1 or 0)
			a = ch_ev:pop()
			while a do
				clock, b = ch_ev:demand(), ch_ev:demand()
				for i = 1, b do t[i] = ch_ev:demand() end
				n, a, b = b, event(a, unpack(t, 1, b))
				if a then pump(); return a, b end
				a = ch_ev:pop()
			end
		elseif a then thread_event:start(); ch_ev:clear(); ch_ev_active:clear() end
		pump(); for name, a, b, c, d, e, f in poll do a, b = event(name, a, b, c, d, e, f); if a then return a, b end end

		cap, a = 1 / (focused and love.framerate or love.unfocusedFramerate), not love.parallelUpdate
		dt, clock = love.timer.step(), love.timer.getTime()
		if focused or not love.autoPause then
			love.update(dt)
			if love.graphics.isActive() and (a or clock > nextdraw - dt) then
				origin(); clear(love.graphics.getBackgroundColor()); love.draw(); present()
				nextdraw, sinceLastFps, frames = cap + clock, clock - prevFpsUpdate, frames + 1
				if sinceLastFps > 0.5 then
					fps, prevFpsUpdate, frames = math.round(frames / sinceLastFps), clock, 0
				end
			end
		end

		if hasFocus() then
			if a then sleep(cap - dt) else sleep(dt < 0.001 and 0.001 or 0) end
			focused = true
		else
			if focused then collectgarbage(); collectgarbage() end
			focused = sleep(cap)
		end
		collectgarbage(step)
	end
end

function love.handlers.fullscreen(f, t)
	love.fullscreen(f, t)
end

local _ogGetFPS = love.timer.getFPS

---@return number -- Returns the current ticks per second.
love.timer.getTPS = _ogGetFPS

---@return number -- Returns the current frames per second.
function love.timer.getFPS() return fps end

---@return number -- Returns the current inputs in second.
function love.timer.getInputs()
	if not love.asyncInput then return dt end
	local ips = ch_ev_tick:peek()
	return ips and ips > dt and ips or dt
end

-- fix a bug where love.window.hasFocus doesnt return the actual focus in Mobiles
local _ogSetFullscreen = love.window.setFullscreen
if love._os == "Android" or love._os == "iOS" then
	local _f = true
	function love.window.hasFocus()
		return _f
	end

	function love.handlers.focus(f)
		_f = f
		if love.focus then return love.focus(f) end
	end

	function love.window.setFullscreen()
		return false
	end
else
	function love.window.setFullscreen(f, t)
		if _ogSetFullscreen(f, t) then
			love.handlers.fullscreen(f, t)
			return true
		end
		return false
	end
end