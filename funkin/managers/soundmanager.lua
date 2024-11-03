local SoundManager = {muted = false, volume = 1, pitch = 1}
local properties = {'muted', 'volume', 'pitch'}
SoundManager.paused = false
SoundManager.groups = {}
SoundManager.sounds = {}
SoundManager._pausedSources = {}

function SoundManager.add(sound)
	if sound:is("SoundGroup") then
		table.insert(SoundManager.groups, sound)
	else
		table.insert(SoundManager.sounds, sound)
		sound:adjust()
	end
end

function SoundManager.load(asset, autoDestroy, ...)
	local sound
	for i, member in pairs(SoundManager.sounds) do
		if member.destroyed then
			sound = member
			table.remove(SoundManager.sounds, i)
			sound:revive()
			break
		end
	end
	if not sound then sound = require("funkin.audio.sound")() end

	if autoDestroy == nil then autoDestroy = true end
	return sound:load(asset, autoDestroy, ...)
end

function SoundManager.play(asset, volume, looped, autoDestroy, onComplete, ...)
	return SoundManager.load(asset, autoDestroy, onComplete):play(volume, looped, ...)
end

function SoundManager.loadMusic(asset, onComplete)
	if SoundManager.music then
		SoundManager.music:load(asset, false, onComplete)
	else
		SoundManager.music = SoundManager.load(asset, false, onComplete)
		SoundManager.music.persist = true
	end
	return SoundManager.music
end

function SoundManager.playMusic(asset, volume, looped, ...)
	if looped == nil then looped = true end
	return SoundManager.loadMusic(asset):play(volume, looped, ...)
end

function SoundManager.pause()
	for _, sound in pairs(SoundManager.sounds) do
		if sound.playing and type(sound._source) == 'userdata' then
			table.insert(SoundManager._pausedSources, sound._source)
		end
	end
	if #SoundManager._pausedSources > 0 and not pcall(love.audio.pause, SoundManager._pausedSources) then
		for i = #SoundManager._pausedSources, 1, -1 do
			local source = SoundManager._pausedSources[i]
			if not pcall(source.pause, source) then table.remove(SoundManager._pausedSources, i) end
		end
	end

	SoundManager.paused = true
end

function SoundManager.resume()
	SoundManager.paused = false

	for i = 1, #SoundManager._pausedSources do SoundManager._pausedSources[i]:seek(SoundManager._pausedSources[i]:tell()) end

	if #SoundManager._pausedSources > 0 and not pcall(love.audio.play, SoundManager._pausedSources) then  -- creepy! dont use ipairs here...
		for i = 1, #SoundManager._pausedSources do pcall(SoundManager._pausedSources[i].play, SoundManager._pausedSources[i]) end
	end
	table.clear(SoundManager._pausedSources)
end

function SoundManager.update()
	for _, sound in pairs(SoundManager.sounds) do
		if sound.active then
			sound:update()
		end
	end
end

function SoundManager.reset(force)
	table.remove(SoundManager.sounds, function(t, i)
		local sound = t[i]
		if force or not sound.persist then
			sound:destroy()
			return true
		end
	end)
end

function SoundManager.getActualX() return 0 end
function SoundManager.getActualY() return 0 end
function SoundManager.getActualPitch() return SoundManager.pitch end
function SoundManager.getActualVolume()
	if SoundManager.muted then return 0
	else return SoundManager.volume end
end

local _ = '_'
for i, v in ipairs(properties) do properties[v], SoundManager[_ .. v], SoundManager[v] = true, SoundManager[v], nil end
for i = 1, #properties do properties[i] = nil end
return setmetatable(SoundManager, {
	__newindex = function(t, i, v)
		if properties[i] then
			rawset(t, _ .. i, v)
			if t.sounds then
				for _, sound in pairs(t.sounds) do sound:adjust() end
			end
			return
		end
		return rawset(t, i, v)
	end,
	__index = function(t, i)
		if properties[i] then return rawget(t, _ .. i) end
		return rawget(t, i)
	end
})