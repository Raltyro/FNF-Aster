require("funkin.loadmodules")

local file = native.askOpenFile('Open the fucking fnf song music something shit like damn', {{'Ogg Vorbis Files', '*.ogg*'}})
if file then
	local dir, file = file:sub(1, #file - #file:fileName()), file:fileName()
	print(love.filesystem.mountFullPath(dir, ""))

	local musicData, musicIntroData
	if file:endsWith("-intro.ogg") then
		musicIntroData = love.sound.newSoundData(file)
		musicData = love.sound.newSoundData(file:sub(1, #file - 10) .. ".ogg")
	else
		musicData = love.sound.newSoundData(file)
	end

	local music = Sound()
	if musicIntroData then
		love.framerate = 280
		music:load(musicIntroData, false, function()
			love.framerate = 60
			music:load(musicData)
			music:play(1, true)
			yeah = nil
		end)
		music:play(1)
		yeah = music
	else
		music:load(musicData)
		music:play(1, true)
	end

	--[[local music = Sound():load(love.sound.newSoundData(file:fileName()))
	local bf = Sound():load(love.sound.newSoundData("Voices-bf-bf.ogg"))
	local dad = Sound():load(love.sound.newSoundData("Voices-darnell-bf.ogg"))

	music:play()
	bf:play()
	dad:play()]]
else
	love.event.quit()
end