--[[
do -- tinyfiledialogs.openFileDialog
	local files = tinyfiledialogs.openFileDialog{
		title = "Open File",
		--default_path_and_file = "directory" or "directory/file",
		--filter_patterns = "*.txt" or {"*.txt", "*.md"}, -- may also be a single string or an array
		--filter_description = "Text", -- name that can substitute for patterns, defaults to nil
		allow_multiple_selects = true -- may able to open multiple files, if true, it'll return as an array of path to files
	}

	print(files)
end

do -- tinyfiledialogs.saveFileDialog
	-- this isnt much of saving, it's more of just a prompt to where the path should be located in
	tinyfiledialogs.saveFileDialog{
		title = "Save File",
		--default_path_and_file = "directory" or "directory/file",
		--filter_patterns = { "*.png", "*.jpg" }, -- may also be a single string
		--filter_description = "Images" -- name that can substitute for patterns, defaults to nil
	}
end

do -- tinyfiledialogs.selectFolderDialog
	tinyfiledialogs.selectFolderDialog{
		title = "Select folder",
		--default_path = "directory" -- n.b. path seems to not work yet on Windows?
	}
end

do -- tinyfiledialogs.colorChooser
	local result = {}
	tinyfiledialogs.colorChooser{
		title = "Choose color",
		rgb = {1.0, 1.0, 1.0}, -- ranges from 0.0 to 1.0
		out_rgb = result -- assume result is a table {}
	}

	print(result)
end

do -- tinyfiledialogs.inputBox
	local result = tinyfiledialogs.inputBox{
		title = "Enter some text",
		message = "Huzzah",
		default_input = "TEXT" or false -- if false, it'll be hidden like a password, defaults to nil
	}

	print(result)
end

do -- tinyfiledialogs.messageBox
	local result_bool = tinyfiledialogs.messagebox{
		title = "Enter some text",
		message = "Huzzah",
		dialog_type = "ok", -- ok|okcancel|yesno|yesnocancel, defaults to ok
		icon_type = "info", -- info|warning|error|question, defaults to info
		default_okyes = true
	}

	print(result_bool)
end

do -- tinyfiledialogs.notifyPopup
	local result_bool = tinyfiledialogs.notifyPopup{
		title = "Title",
		message = "Message",
		icon_type = "info" -- info|warning|error, defaults to info
	}

	print(result_bool)
end
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
else
	return tryload(..., "lua-tinyfiledialogs")
end