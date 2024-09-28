require("funkin.loadmodules")

local funkin = {}
local tinyfiledialogs = require("lib.tinyfiledialogs")
local discordRPC = require("lib.discordRPC")

function funkin.init()
	--[=[local file = native.askOpenFile('Open the fucking fnf song music something shit like damn', {{'Ogg Vorbis Files', '*.ogg*'}})
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
	end]=]

	discordRPC.initialize("1289598322767691776", true)
	local input = tinyfiledialogs.inputBox{
		title = "Enter song ID",
		message = "Song ID?",
		default_input = "hatena"
	}
	print(input)

	local song, suffix, player, opponent = input, "", "", ""

	discordRPC.updatePresence({
		state = song:capitalize(),
		details = "Listening to Song",
		largeImageKey = "icon",
		largeImageText = "Funkin' Aster",
		smallImageKey = "iconsmall"
	})

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

	local inst, player, opponent = Sound(), playerData and Sound():load(playerData), opponentData and Sound():load(opponentData)
	local function play()
		inst:play()
		if player then player:play(nil, nil, nil, true) end
		if opponent then opponent:play(nil, nil, nil, true) end
	end
	inst:load(instData, false, play)
	play()
end

function funkin.update(dt)
	discordRPC.runCallbacks()
end

return funkin