io.stdout:setvbuf("no")

require("run")
require("lib.override")

conf = require("conf")

-- If it's fused, and there no assets folder in the package, assume it's outside and mount outside the executable to the default directory
if (love.filesystem.isFused() or not love.filesystem.getInfo("assets")) and love.filesystem.mountFullPath then
	love.filesystem.mountFullPath(love.filesystem.getSourceBaseDirectory(), "")
end

function love.load()
	local isMobile = love.system.getDevice() == "Mobile"

	if not love.filesystem.isFused() then love.window.setIcon(love.image.newImageData('art/icon.png')) end
	love.window.setTitle(conf.title)
	love.window.setMode(conf.width, conf.height, {
		fullscreen = isMobile,
		resizable = not isMobile,
		vsync = 0,
		usedpiscale = false
	})

	require("funkin")
end

function love.update(dt)
	if yeah then yeah:update(dt) end
end

function love.draw()

end

function love.quit()

end