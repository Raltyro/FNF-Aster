local SoundManager, _ = {muted = false, volume = 1, pitch = 1}, '_'
local properties = {}; for i, v in pairs(SoundManager) do properties[i], SoundManager[_ .. i], SoundManager[i] = true, v, nil end
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
	for i, member in ipairs(SoundManager.sounds) do
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
end

function SoundManager.playMusic(asset, volume, looped, ...)
	if looped == nil then looped = true end
	return SoundManager.loadMusic(asset):play(volume, looped, ...)
end

function SoundManager.pause()
	for _, sound in ipairs(SoundManager.sounds) do
		if sound.playing then
			table.insert(SoundManager._pausedSources, sound._source)
		end
	end
	love.audio.pause(SoundManager._pausedSources)
end

function SoundManager.resume()
	love.audio.play(SoundManager._pausedSources)
	table.clear(SoundManager._pausedSources)
end

function SoundManager.update()
	for _, sound in ipairs(SoundManager.sounds) do
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

return setmetatable(SoundManager, {
	__newindex = function(t, i, v)
		if properties[i] then
			rawset(t, _ .. i, v)
			if t.sounds then
				for _, sound in ipairs(t.sounds) do sound:adjust() end
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