require("funkin.loadmodules")

local funkin = {}

local Discord = require("funkin.api.discord")

function funkin.init()
	Discord.init()

end

function funkin.update(dt)
	Discord.update()
end

function funkin.draw()

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