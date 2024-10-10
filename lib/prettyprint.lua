local srcfgcolor, srcbgcolor = 92, 0
local warnfgcolor, warnbgcolor = 93, 0
local timefgcolor, timebgcolor = 95, 0
local maxdepth = 16

local iswindows, ffi = love.system.getOS() == "Windows"
if iswindows then
	ffi = require("ffi")
	ffi.cdef [[typedef unsigned int DWORD; typedef unsigned short WORD;
	void* GetStdHandle(DWORD nStdHandle); int SetConsoleTextAttribute(void* HANDLE, WORD wAttributes);]]
end

local __table__, __string__, indent, comma, space, newline = 'table', 'string', '  ', ', ', ' ', '\n'
local function checkstringtable(v)
	if type(v) == __table__ then
		local meta = getmetatable(v)
		return not meta or not meta.__tostring
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

	local newline = usespace and '' or newline
	local str, iter = '{', 0

	for i, v in pairs(t) do
		iter = iter + 1

		if iter > 1 then str = str .. comma end
		str = str .. newline .. indentation(usespace, depth)

		if i ~= iter then
			str = str .. '[' .. stringifyvalue(v, usespace, depth) .. '] = '
		end

		str = str .. stringifyvalue(v, usespace, depth)
	end

	return tostring(t) .. space .. (iter == 0 and '{}' or (str .. newline .. indentation(usespace, depth - 1) .. '}'))
end

local out, hash, time, bracketl, bracketr = io.stdout, '#', '%X', '[', ']'
local setcolor, bgc
local ogprint = print
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
	function setcolor(bg, fg) if bg == 0 or fg == 0 then return setcolor((bg == 0 or bg == nil) and 30 or bg, (fg == 0 or fg == nil) and 37 or fg) end ffi.C.SetConsoleTextAttribute(ffi.C.GetStdHandle(4294967285), (colors[bg] * 16) + colors[fg]) end
	function bgc(v) return v end
else
	local c, m = '\x1b[', 'm'
	function setcolor(...) for i = 1, select(hash, ...) do out:write(c .. select(i, ...) .. m) end end
	function bgc(v) return v == 0 and 0 or v + 10 end
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
if debug then
	local l, Sl = ':', "Sl"
	function print(...)
		setcolor(bgc(timebgcolor), timefgcolor, 1); out:write(bracketl .. os.date(time, os.time()) .. bracketr)
		setcolor(0); out:write(space)

		local info = debug.getinfo(2, Sl)
		setcolor(bgc(srcbgcolor), srcfgcolor); out:write(info.short_src .. l .. info.currentline .. l)

		setcolor(0); out:write(space .. prettyvalues(...) .. newline)
	end

	function warn(...)
		setcolor(bgc(timebgcolor), timefgcolor, 1); out:write(bracketl .. os.date(time, os.time()) .. bracketr)
		setcolor(0); out:write(space)

		local info = debug.getinfo(2, Sl)
		setcolor(bgc(warnbgcolor), warnfgcolor); out:write(info.short_src .. l .. info.currentline .. l)
		setcolor(0); out:write(space)

		setcolor(bgc(warnbgcolor), warnfgcolor); out:write(prettyvalues(...) .. newline)
		setcolor(0)
	end
else
	function print(...)
		setcolor(bgc(timebgcolor), timefgcolor, 1); out:write(bracketl .. os.date(time, os.time()) .. bracketr)
		setcolor(0); out:write(space .. prettyvalues(...) .. newline)
	end

	function warn(...)
		setcolor(bgc(timebgcolor), timefgcolor, 1); out:write(bracketl .. os.date(time, os.time()) .. bracketr)
		setcolor(0); out:write(space)

		setcolor(bgc(warnbgcolor), warnfgcolor); out:write(prettyvalues(...) .. newline)
		setcolor(0)
	end
end