io.stdout:setvbuf("no")

require("run")
require("lib.override")

native = require("lib.native")

conf = require("conf")

-- If it's fused, and there no assets folder in the package, assume it's outside and mount outside the executable to the default directory
if (love.filesystem.isFused() or not love.filesystem.getInfo("assets")) and love.filesystem.mountFullPath then
	love.filesystem.mountFullPath(love.filesystem.getSourceBaseDirectory(), "")
else
	sourceMode = true
end

local funkin = require("funkin")

function love.load()
	local isMobile = love.system.getDevice() == "Mobile"

	if sourceMode then
		love.window.setTitle(conf.title .. " (SOURCE)")
	else
		love.window.setTitle(conf.title)
	end
	love.window.setMode(conf.width, conf.height, {
		fullscreen = isMobile,
		resizable = not isMobile,
		vsync = 0,
		usedpiscale = false
	})
	if sourceMode then
		if love.system.getOS() == "Windows" then
			native.setIcon("icon.ico")
		else
			love.window.setIcon(love.image.newImageData('art/icons/iconOG.png'))
		end
	end
	native.setDarkMode(true)

	funkin.init()
end

function love.update(dt)
	funkin.update(dt)
end

function love.draw()

end

function love.keypressed(t, b, s, r)

end

function love.keyreleased(t, b, s)

end

function love.touchpressed(t, id, x, y, dx, dy, p)

end

function love.touchmoved(t, id, x, y, dx, dy, p)

end

function love.touchreleased(t, id, x, y, dx, dy, p)

end

function love.joystickpressed(t, j, b)

end

function love.joystickreleased(t, j, b)

end

function love.gamepadpressed(t, j, b)

end

function love.gamepadreleased(t, j, b)

end

function love.quit()

end