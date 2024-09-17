local os, native = love.system.getOS()
if os == "Windows" then
	native = require((...) .. ".windows")
end

-- Default Implementation
local function defaultImplementation(name, func) if not native[name] then native[name] = func or function() end end end
defaultImplementation("askOpenFile")
defaultImplementation("askSaveAsFile")
defaultImplementation("setCursor")
defaultImplementation("setDarkMode")

return native