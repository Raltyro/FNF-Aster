require("funkin.loadmodules")

funkin = {}

local Discord = require("funkin.api.discord")
local SoundManager = require("funkin.managers.soundmanager")
local Conductor = require("funkin.objects.conductor")

local beepData

function funkin.init(initialScene)
	Discord.init()


	local function test(bpm1, bpm2, B) return B/(bpm2 - bpm1) * math.log(bpm2 / bpm1) * 60 end
	local function test2(bpm1, bpm2, time, endTime)
		return (endTime - time)*(bpm2 - bpm1) / math.log(bpm2 / bpm1) / 60
		--(() * duration)/(bpm - prevBPM) * math.log(bpm / prevBPM) * 60
	end
	--print(test(132, 140, 48), test2(114, 124, 0, test(114, 124, 16)))

	local song, suffix, player, opponent = "alert", "", "bf", "trolljak"
	local timeChanges = {
		{bpm = 158, beatTime = 0},
		{bpm = 168, beatTime = 34 * 4},
		{bpm = 178, beatTime = 140 * 4},
		{bpm = 168, beatTime = 207 * 4},
		{bpm = 158, beatTime = 215 * 4}
	}
	--[[local song, suffix, player, opponent = "linear-bpm", "", "", ""
	local timeChanges = {
		{bpm = 100, beatTime = 0, denominator = 4},
		{bpm = 140, beatTime = 8, endBeatTime = 24},
		{bpm = 60, beatTime = 24, endBeatTime = 32},
		{bpm = 100, beatTime = 32, endBeatTime = 36},
		{bpm = 500, beatTime = 44, endBeatTime = 100},
	}]]
	--[[local song, suffix, player, opponent = "taco-tirade", "", "", ""--"darnell", "-bf", "bf", "darnell"
	local timeChanges = {
		{bpm = 114, time = 0.03, resetSignature = true, numerator = 2.75},
		{bpm = 116, time = 7.2, resetSignature = true, numerator = 2.75},
		{bpm = 114, time = 12.742, resetSignature = true, numerator = 4},
		{bpm = 86, time = 27.47884210526316, endTime = 29.209},
		{bpm = 114, time = 29.938, resetSignature = true},
		{bpm = 124, time = 57.30642105263158, endTime = 65.37840030484358},
		{bpm = 132, time = 65.37840030484358, endTime = 72.88084314260368},
		{bpm = 140, time = 72.88084314260368, endTime = 94.06342315085968},
		{bpm = 114, time = 94.06342315085968, endTime = 97.85623498251768},
		{bpm = 114, time = 97.85623498251768, resetSignature = true},
		{bpm = 124, time = 123.11939287725451, endTime = 131.19137212946652},
		{bpm = 134, time = 131.19137212946652, endTime = 138.63696262667042},
		{bpm = 140, time = 138.63696262667042, endTime = 159.66222150269942},
		{bpm = 114, time = 159.66222150269942, endTime = 163.45503333435744},
		{bpm = 114, time = 163.45503333435744, resetSignature = true},
		{bpm = 172, time = 184.5076649133048, endTime = 194.65622933298582},
	}
	--[[local song, suffix, player, opponent, timeChanges = 'fuck', '', '', '', {
		{bpm = 178, beatTime = 0, numerator = 4, denominator = 4},
		{bpm = 178, beatTime = 224, numerator = 6, denominator = 8, tuplet = 2},
		{bpm = 178, beatTime = 242, numerator = 10, denominator = 4},
		{bpm = 178, beatTime = 247, numerator = 7, denominator = 8, tuplet = 2},
	}
	local beat = 8
	for i = 2, 17 do
		table.insert(timeChanges, {bpm = 178, beatTime = beat, numerator = 4, denominator = 4, tuplet = 4})
		table.insert(timeChanges, {bpm = 178, beatTime = beat + 4, numerator = i, denominator = 8, tuplet = 2})
		beat = beat + 4 + i
	end

	beat = 394
	bpm = 178
	for i = 2, 7 do
		table.insert(timeChanges, {bpm = bpm, beatTime = beat, numerator = 4, denominator = 4, tuplet = 4})
		table.insert(timeChanges, {bpm = bpm, beatTime = beat + 4, numerator = i, denominator = 8, tuplet = 2})
		beat = beat + 4 + i
		bpm = bpm + 10
	end
	local shit = 20
	for i = 8, 17 do
		table.insert(timeChanges, {bpm = bpm, beatTime = beat, numerator = 4, denominator = 4, tuplet = 4})
		table.insert(timeChanges, {bpm = bpm, beatTime = beat + 4, numerator = i, denominator = 8, tuplet = 2})
		beat = beat + 4 + i
		bpm = bpm + shit
		shit = shit + 40 * (2.718281828459045/1.3)^(i - 9)
	end]]
	Conductor.instance:mapTimeChanges(timeChanges)
	for _, timeChange in ipairs(Conductor.instance.timeChanges) do
		timeChange.resetSignature = nil
	end
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
	--SoundManager.music.time = 26.952526315789473443373935879208147525787353515625
	--SoundManager.music.volume = 0.5
	play()

	local clav1Data, clav2Data = love.sound.newSoundData("assets/sounds/clav1.ogg"), love.sound.newSoundData("assets/sounds/clav2.ogg")
	Conductor.instance.onMetronomeHit:add(function(measureHit)
		local beat, measure, pos = Conductor.instance.currentBeat, Conductor.instance.currentMeasure
		if measureHit then
			SoundManager.play(clav1Data)
			pos = Conductor.instance:getMeasuresInTime(measure, Conductor.instance.currentTimeChangeIdx)
			beat = Conductor.instance:getTimeInBeats(pos, Conductor.instance.currentTimeChangeIdx)
		else
			SoundManager.play(clav2Data)
			pos = Conductor.instance:getBeatsInTime(beat, Conductor.instance.currentTimeChangeIdx)
			measure = Conductor.instance:getTimeInMeasures(pos, Conductor.instance.currentTimeChangeIdx)
		end

		print(beat, measure, pos, Conductor.instance:getTimeInBPM(pos, Conductor.instance.currentTimeChangeIdx))
	end)
	Conductor.instance.onStepHit:add(function()
		SoundManager.play(clav1Data, .5)
	end)

	beepData = love.sound.newSoundData("assets/sounds/beep.ogg")

	--love.autoPause = true
end

local infos, infotimer = {}, 0

function funkin.update(dt)
	funkin.deltatime = dt

	Discord.update()
	if love.window.hasFocus() or not love.autoPause then
		SoundManager.update()
	end

	local prev = Conductor.instance.currentTimeChangeIdx
	Conductor.instance:update(nil)
	if Conductor.instance.currentTimeChangeIdx ~= prev then
		print(Conductor.instance.currentTimeChange)
		SoundManager.play(beepData)
	end

	infotimer = infotimer + dt
	if infotimer > 0.04 then
		table.insert(infos, Conductor.instance.bpm)
		infotimer = 0
	end
	while #infos > 300 do
		table.remove(infos, 1)
	end
end

function funkin.draw()
	love.graphics.print(math.truncate(Conductor.instance.currentBeatTime))
	love.graphics.print(math.truncate(Conductor.instance.currentMeasureTime), 0, 12)
	love.graphics.print(math.truncate(Conductor.instance.bpm, 4), 0, 24)
	love.graphics.print(math.truncate(Conductor.instance:rawgetBeatsInBPM(Conductor.instance.currentBeatTime, Conductor.instance.currentTimeChangeIdx), 4), 0, 36)
	love.graphics.print(math.truncate(Conductor.instance.currentStepTime), 0, 48)


	if #infos > 1 then
		local positions = {}

		for i = 1, #infos do
			table.insert(positions, 20 + (i * 3.5));
			table.insert(positions, 1000 - (infos[i] * 4))
		end
		love.graphics.setLineWidth(5)
		love.graphics.line(positions)
	end
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