--[[
	tinyfiledialogs.openFileDialog{
		title = "Open File",
		default_path_and_file = "directory" or "directory/file",
		filter_patterns = "*.txt" or {"*.txt", "*.md"}, -- may also be a single string or an array
		filter_description = "Text" -- name that can substitute for patterns
		allow_multiple_selects = false -- may able to open multiple files, if true, it'll return as an array of path to files
	}

	tinyfiledialogs.saveFileDialog{
		title = "Save File",
		default_path_and_file = "directory" or "directory/file",
		filter_patterns = { "*.png", "*.jpg" }, -- may also be a single string
		filter_description = "Images" -- name that can substitute for patterns
	}

	tinyfiledialogs.selectFolderDialog{
		title = "Select folder",
		default_path = "directory" -- n.b. path seems to not work yet on Windows?
	}

	tinyfiledialogs.colorChooser{
		title = "Choose color",
		rgb = {1.0, 1.0, 1.0}, -- ranges from 0.0 to 1.0
		out_rgb = result -- assume result is a table {}
	}

	tinyfiledialogs.inputBox{
		title = "Enter some text",
		message = "Huzzah",
		default_input = "TEXT" or false,
	}

	tinyfiledialogs.messagebox{
		title = "Enter some text",
		message = "Huzzah",
		dialog_type = "ok" or "okcancel" or "yesno",
		icon_type = "question",
		default_okyes = true
	}
]]

local OS = love.system.getOS()

local tryload
function tryload(dir, file, ...)
	local s, module = pcall(package.loadlib, dir:replace('.', '/') .. '/' .. file, "luaopen_tinyfiledialogs")
	if not s then s, module = pcall(package.loadlib, file, "luaopen_tinyfiledialogs") end
	if s then
		if type(module) == "function" then return module() end
		return module
	else
		if ... then return tryload(dir, ...) end
		print("Failed to load " .. file .. ", returning nulled module")
		local __NULL__ = function() end
		return setmetatable({}, {__index = function() return __NULL__ end})
	end
end

if OS == "Windows" then
	return tryload(..., "lua-tinyfiledialogs-x64", "lua-tinyfiledialogs-win32")
elseif OS == "Linux" then
	return tryload(..., "lua-tinyfiledialogs-linux")
elseif OS == "OS X" then
	return tryload(..., "lua-tinyfiledialogs-mac")
end

local __NULL__ = function() end
return setmetatable({}, {__index = function() return __NULL__ end})