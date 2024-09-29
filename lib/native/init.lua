--
-- native
--
-- i made this w co fellyn yukira -- ralty
--

local OS, native = love.system.getOS()
if OS == "Windows" then
	native = require((...) .. ".windows")
end

-- Default Implementation
local function defaultImplementation(name, func) if not native[name] then native[name] = func or function() end end end
defaultImplementation("setCursor")
defaultImplementation("setDarkMode")
defaultImplementation("setIcon")
defaultImplementation("getIcon")
defaultImplementation("loadIcon")
defaultImplementation("showNotification")


return native