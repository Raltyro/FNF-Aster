require("funkin.loadmodules")

funkin = {}

local Discord = require("funkin.api.discord")

function funkin.init(initialScene)
	if initialScene == nil then initialScene = require("funkin.menus.titlescene") end

	SceneManager.switch(initialScene)
	Discord.init()

	love.autoPause = true
end

function funkin.update(deltaTime)
	funkin.deltaTime = deltaTime

	SceneManager.update(deltaTime)
	if love.window.hasFocus() or not love.autoPause then
		SoundManager.update()
	end
	Discord.update()
end

function funkin.draw()
	SceneManager.render()
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