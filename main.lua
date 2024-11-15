io.stdout:setvbuf("no"); io.stdout:write('\n')

require("run")
require("lib.override")
require("lib.prettyprint")

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

	love.window.setTitle(sourceMode and conf.title .. " (SOURCE)" or conf.title)
	love.window.setMode(conf.width, conf.height, {
		fullscreen = isMobile,
		resizable = not isMobile,
		vsync = 0,
		depth = true,
		usedpiscale = false
	})
	native.setDarkMode(true)
	if sourceMode then
		if love.system.getOS() == "Windows" then
			native.setIcon("icon.ico")
		else
			love.window.setIcon(love.image.newImageData('art/icons/iconOG.png'))
		end
	end

	funkin.init()
end

function love.keypressed(t, b, s, r)
	if love.keyboard.isDown("lctrl", "rctrl") then
		if b == "f4" then error("force crash") end
		if b == "`" then return "restart" end
	end
end

love.update = funkin.update
love.draw = funkin.draw
love.focus = funkin.focus
love.keyreleased = funkin.keyreleased
love.touchpressed = funkin.touchpressed
love.touchmoved = funkin.touchmoved
love.touchreleased = funkin.touchreleased
love.joystickpressed = funkin.joystickpressed
love.joystickreleased = funkin.joystickreleased
love.gamepadpressed = funkin.gamepadpressed
love.gamepadreleased = funkin.gamepadreleased

function love.quit()
	funkin.quit()
end