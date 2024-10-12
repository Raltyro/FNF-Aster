local srcfgcolor, srcbgcolor = 96, 0
local warnfgcolor, warnbgcolor = 33, 0
local timefgcolor, timebgcolor = 35, 0
local maxdepth = 16

local iswindows, ffi = love.system.getOS() == "Windows"
if iswindows then
	ffi = require("ffi")
	ffi.cdef [[typedef unsigned int DWORD; typedef unsigned short WORD;
	void* GetStdHandle(DWORD nStdHandle); int SetConsoleTextAttribute(void* HANDLE, WORD wAttributes);]]
end

local __table__, __string__, indent, comma, space, newline = 'table', 'string', '\t', ', ', ' ', '\n'
local function checkstringtable(v)
	if type(v) == __table__ then
		v = getmetatable(v)
		return not v or not v.__tostring
	end
	return false
end

local stringifytable
local function indentation(space, depth) return depth == 0 and '' or (space and ' ' or indent:rep(depth)) end
local function stringifyvalue(v, space, depth)
	return checkstringtable(v) and stringifytable(v, space, depth) or
		type(v) == __string__ and ('"' .. v .. '"') or
		tostring(v)
end

function stringifytable(t, usespace, depth)
	depth = (depth or 0) + 1
	if depth > maxdepth then return "Limited" end

	local iter, newline, str = 0, usespace and '' or newline
	for i, v in pairs(t) do
		iter = iter + 1
		str = (iter > 1 and str .. comma or '{') .. newline .. indentation(usespace, depth)

		if i ~= iter then str = str .. '[' .. stringifyvalue(i, usespace, depth) .. '] = ' end
		str = str .. stringifyvalue(v, usespace, depth)
	end

	return tostring(t) .. space .. (iter == 0 and '{}' or (str .. newline .. indentation(usespace, depth - 1) .. '}'))
end

local out, hash, time, bracketl, bracketr = io.stdout, '#', '%X', '[', ']'
local os_date, os_time, setc = os.date, os.time
if iswindows then
	local colors = {
		[30] = 0,
		[34] = 1,
		[32] = 2,
		[36] = 3,
		[31] = 4,
		[35] = 5,
		[33] = 6,
		[37] = 7,
		[90] = 8,
		[94] = 9,
		[92] = 10,
		[96] = 11,
		[91] = 12,
		[95] = 13,
		[93] = 14,
		[97] = 15
	}
	function setc(bg, fg)
		if bg == 0 or fg == 0 then return setc((bg == 0 or bg == nil) and 30 or bg, (fg == 0 or fg == nil) and 37 or fg) end
		ffi.C.SetConsoleTextAttribute(ffi.C.GetStdHandle(4294967285), (colors[bg] * 16) + colors[fg])
	end
else
	local c, m = '\x1b[', 'm'
	function setc(bg, fg, bold)
		bg = c .. (bg == 0 and bg or bg + 10) .. m
		if fg ~= nil then bg = bg .. c .. fg .. m end
		if bold then bg = bg .. c .. 1 .. m end
		out:write(bg)
	end
end
local function prettyvalues(...)
	local str, v = ''
	for i = 1, select(hash, ...) do
		v = select(i, ...)
		if i > 1 then str = str .. comma end
		str = str .. (checkstringtable(v) and stringifytable(v) or tostring(v))
	end
	return str
end
if debug and debug.getinfo then
	local getinfo, l, Sl = debug.getinfo, ':', "Sl"
	function print(...)
		setc(timebgcolor, timefgcolor, true); out:write(bracketl .. os_date(time, os_time()) .. bracketr)
		setc(0); out:write(space)

		local info = getinfo(2, Sl)
		setc(srcbgcolor, srcfgcolor); out:write(info.short_src .. l .. info.currentline .. l)

		setc(0); out:write(space .. prettyvalues(...) .. newline)
	end

	function warn(...)
		setc(timebgcolor, timefgcolor, 1); out:write(bracketl .. os_date(time, os_time()) .. bracketr)
		setc(0); out:write(space)

		local info = getinfo(2, Sl)
		setc(warnbgcolor, warnfgcolor); out:write(info.short_src .. l .. info.currentline .. l)
		setc(0); out:write(space)

		setc(warnbgcolor, warnfgcolor); out:write(prettyvalues(...) .. newline)
		setc(0)
	end
else
	function print(...)
		setc(timebgcolor, timefgcolor, 1); out:write(bracketl .. os_date(time, os_time()) .. bracketr)
		setc(0); out:write(space .. prettyvalues(...) .. newline)
	end

	function warn(...)
		setc(timebgcolor, timefgcolor, 1); out:write(bracketl .. os_date(time, os_time()) .. bracketr)
		setc(0); out:write(space)

		setc(warnbgcolor, warnfgcolor); out:write(prettyvalues(...) .. newline)
		setc(0)
	end
end