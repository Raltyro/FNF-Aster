local discordRPC = require("lib.discordRPC")
local Signal = require("funkin.utils.signal")

local Discord = {}
Discord.CLIENT_ID = "1289598322767691776"

-- since the callbacks are unsafe, not protected, we have to wrap it
local pendingDispatches, table_insert = {}, table.insert
local CALLBACKS = {
	READY = 0,
	DISCONNECTED = 1,
	ERROR = 2
}
local function dispatchSafe(callback, ...)
	table_insert(pendingDispatches, {callback, ...})
end

function Discord.init(CLIENT_ID)
	discordRPC.ready = function(...) dispatchSafe(CALLBACKS.READY, ...) end
	discordRPC.disconnected = function(...) dispatchSafe(CALLBACKS.DISCONNECTED, ...) end
	discordRPC.errored = function(...) dispatchSafe(CALLBACKS.ERROR, ...) end

	Discord.onReady = Signal()
	Discord.onDisconnected = Signal()
	Discord.onError = Signal()

	discordRPC.initialize(CLIENT_ID or Discord.CLIENT_ID, true)
end

local nextUpdate = 0
function Discord.update()
	local time = os.time()
	if time > nextUpdate then
		nextUpdate = time + 2

		if discordRPC.DISCORD_DISABLE_IO_THREAD then
			discordRPC.updateConnection()
		end
		discordRPC.runCallbacks()

		local i = #pendingDispatches
		while i ~= 0 do
			local callback = table.remove(pendingDispatches[i], 1)
			if callback == CALLBACKS.READY then callback = Discord.readyCallback
			elseif callback == CALLBACKS.DISCONNECTED then callback = Discord.disconnectedCallback
			elseif callback == CALLBACKS.ERROR then callback = Discord.errorCallback end

			callback(unpack(pendingDispatches[i]))
			pendingDispatches[i] = nil
			i = #pendingDispatches
		end
	end
end

function Discord.readyCallback(userId, username, discriminator, avatar, globalName)
	discriminator = tonumber(discriminator)
	Discord.user = {
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
end

function Discord.disconnectedCallback(errorCode, message)
	print('[DISCORD] Client has disconnected! (' .. errorCode .. ') "' .. message .. '"')

	Discord.onDisconnected:dispatch()
end

function Discord.errorCallback(errorCode, message)
	print('[DISCORD] Client has received an error! (' .. errorCode .. ') "' .. message .. '"')

	Discord.onError:dispatch()
end

return Discord