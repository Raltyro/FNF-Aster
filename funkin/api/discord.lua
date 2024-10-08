local discordRPC = require("lib.discordRPC")
local Signal = require("funkin.utils.signal")

local Discord = {}
Discord.DEFAULT_ID = "1289598322767691776"
Discord.CLIENT_ID = Discord.DEFAULT_ID

Discord.active = false
Discord.connected = false
Discord.defaultPresence = {
	details = "Initial",
	state = nil,
	largeImageKey = "icon",
	largeImageText = "Funkin' Aster",
	smallImageKey = "",
	smallImageText = "",
	startTimestamp = 0,
	timestamp = 0
}

-- since the callbacks are unsafe, not protected, we have to wrap it
local pendingDispatches, table_insert = {}, table.insert
local function wrappedDispatchSafe(callback) return function(...) table_insert(pendingDispatches, {callback, ...}) end end

function Discord.init(CLIENT_ID)
	discordRPC.ready = wrappedDispatchSafe("ready")
	discordRPC.disconnected = wrappedDispatchSafe("disconnected")
	discordRPC.errored = wrappedDispatchSafe("error")

	Discord.onReady = Signal()
	Discord.onDisconnected = Signal()
	Discord.onError = Signal()
	Discord.presence = table.clone(Discord.defaultPresence)

	if CLIENT_ID then Discord.CLIENT_ID = CLIENT_ID end
	discordRPC.initialize(Discord.CLIENT_ID, true)

	Discord.active = true
end

function Discord.shutdown()
	Discord.active = false
	Discord.connected = false
	discordRPC.shutdown()
end

function Discord.restart()
	Discord.shutdown()
	Discord.init()
end

local nextUpdate = 0
function Discord.update()
	if not Discord.active then return end

	local time = love.timer.getTime()
	if time > nextUpdate then
		nextUpdate = time + 2

		if discordRPC.DISCORD_DISABLE_IO_THREAD then
			discordRPC.updateConnection()
		end
		discordRPC.runCallbacks()

		local i = #pendingDispatches
		while i ~= 0 do
			pendingDispatches[i] = Discord[table.remove(pendingDispatches[i], 1) .. "Callback"](unpack(pendingDispatches[i]))
			i = #pendingDispatches
		end
	end
end

function Discord.setPresence(presence)
	if presence then table.merge(Discord.presence, presence) end
	discordRPC.updatePresence(Discord.presence)
end

function Discord.resetPresence()
	Discord.presence = table.clone(Discord.defaultPresence)
	discordRPC.updatePresence(Discord.presence)
end

function Discord.clearPresence()
	Discord.presence = {
		details = ""
	}
	discordRPC.clearPresence()
end

function Discord.readyCallback(userId, username, discriminator, avatar, globalName)
	discriminator = tonumber(discriminator)
	Discord.connected, Discord.user = true, {
		userId = userId,
		username = username,
		discriminator = discriminator,
		avatar = avatar,
		globalName = globalName,
		legacy = discriminator ~= 0
	}

	if Discord.user.legacy then
		print('[DISCORD] User: ' .. globalName .. ' ' .. username .. '#' .. discriminator .. ' | Avatar: ' .. avatar)
	else
		print('[DISCORD] User: ' .. globalName .. ' @' .. username .. ' | Avatar: ' .. avatar)
	end

	Discord.onReady:dispatch()

	Discord.setPresence()
end

function Discord.disconnectedCallback(errorCode, message)
	print('[DISCORD] Client has disconnected! (' .. errorCode .. ') "' .. message .. '"')

	Discord.connected = false
	Discord.onDisconnected:dispatch()
end

function Discord.errorCallback(errorCode, message)
	print('[DISCORD] Client has received an error! (' .. errorCode .. ') "' .. message .. '"')

	Discord.active = false
	Discord.connected = false
	Discord.onError:dispatch()

	discordRPC.restart()
end

return Discord