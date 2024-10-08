require("funkin.loadmodules")

funkin = {}

local Discord = require("funkin.api.discord")
local SoundManager = require("funkin.managers.soundmanager")
local Conductor = require("funkin.objects.conductor")

function funkin.init(initialScene)
	Discord.init()

	local song, suffix, player, opponent = "darnell", "-bf", "bf", "darnell"
	Conductor.instance:setBPM(155)
	print(song)

	Discord.setPresence{
		state = song:title(),
		smallImageKey = "iconsmall"
	}

	local instData = love.sound.newSoundData("assets/songs/" .. song .. "/Inst" .. suffix .. ".ogg")
	local playerData, opponentData
	if player == "" then
		local s, data = pcall(love.sound.newSoundData, "assets/songs/" .. song .. "/Voices" .. suffix .. ".ogg")
		if s then playerData = data end
	else
		playerData, opponentData =
			love.sound.newSoundData("assets/songs/" .. song .. "/Voices" .. "-" .. player  .. suffix .. ".ogg"),
			love.sound.newSoundData("assets/songs/" .. song .. "/Voices" .. "-" .. opponent .. suffix .. ".ogg")
	end

	local player, opponent = playerData and SoundManager.load(playerData, false), opponentData and SoundManager.load(opponentData, false)
	local function play()
		SoundManager.music:play()
		if player then player:restart() end
		if opponent then opponent:restart() end
	end
	SoundManager.loadMusic(instData, play)
	play()

	local clav1Data, clav2Data = love.sound.newSoundData("assets/sounds/clav1.ogg"), love.sound.newSoundData("assets/sounds/clav2.ogg")
	Conductor.instance.onBeatHit:add(function()
		print(Conductor.instance.currentBeat, Conductor.instance.currentMeasure)
		if Conductor.instance.currentMeasure ~= Conductor.instance.oldMeasure then
			SoundManager.play(clav1Data)
		else
			SoundManager.play(clav2Data)
		end
	end)

	--love.autoPause = true
end

function funkin.update(dt)
	funkin.deltatime = dt

	Discord.update()
	if love.window.hasFocus() or not love.autoPause then
		SoundManager.update()
	end

	Conductor.instance:update()
end

function funkin.draw()

end

function funkin.focus(f)
	if not love.autoPause then return end
	if f then
		SoundManager.resume()
	else
		SoundManager.pause()
	end
end

function funkin.keypressed(t, b, s, r)
	
end

function funkin.keyreleased(t, b, s)
	
end

function funkin.touchpressed(t, id, x, y, dx, dy, p)
	
end

function funkin.touchmoved(t, id, x, y, dx, dy, p)
	
end

function funkin.touchreleased(t, id, x, y, dx, dy, p)
	
end

function funkin.joystickpressed(t, j, b)
	
end

function funkin.joystickreleased(t, j, b)
	
end

function funkin.gamepadpressed(t, j, b)
	
end

function funkin.gamepadreleased(t, j, b)
	
end

function funkin.quit()
	
end

return funkin