local textcolor = 92
local maxdepth = 16

local __table__, __string__, indent, comma, s = 'table', 'string', '  ', ', ', ' '
local function checkstringtable(v)
	if type(v) == __table__ then
		local meta = getmetatable(v)
		return not meta or not meta.__tostring
	end
	return false
end

local function indentation(space, depth) return depth == 0 and '' or (space and ' ' or indent:rep(depth)) end

local stringifytable
function stringifytable(t, space, depth)
	depth = (depth or 0) + 1
	if depth > maxdepth then return "Limited" end

	local newline = space and '' or '\n'
	local str, iter = '{', 0

	for i, v in pairs(t) do
		iter = iter + 1

		if iter > 1 then str = str .. comma end
		str = str .. newline .. indentation(space, depth)

		if i ~= iter then
			str = str .. '[' .. (
				checkstringtable(i) and stringifytable(i, space, depth) or
				type(i) == __string__ and ('"' .. i .. '"') or
				tostring(i)
			) .. '] = '
		end

		str = str .. (
			checkstringtable(v) and stringifytable(v, space, depth) or
			type(v) == __string__ and ('"' .. v .. '"') or
			tostring(v)
		)
	end

	return tostring(t) .. s .. (iter == 0 and '{}' or str .. newline .. indentation(space, depth - 1) .. '}')
end

local out, hash = io.stdout, '#'
if debug and debug.getinfo then
	local l, c, m, zero, Sl = ':', '\x1b[', 'm', '0', "Sl"
	function print(...)
		local info = debug.getinfo(2, Sl)
		out:write(c .. tostring(textcolor) .. m)
		out:write(info.short_src .. l .. info.currentline .. l .. s)
		out:write(c .. zero .. m)

		local str, v = ''
		for i = 1, select(hash, ...) do
			v = select(i, ...)

			if i > 1 then str = str .. comma end
			if checkstringtable(v) then str = str .. stringifytable(v)
			else str = str .. tostring(v) end
		end

		out:write(str .. '\n')
	end
else
	function print(...)
		local str, v = ''
		for i = 1, select(hash, ...) do
			v = select(i, ...)

			if i > 1 then str = str .. comma end
			if checkstringtable(v) then str = str .. stringifytable(v)
			else str = str .. tostring(v) end
		end

		out:write(str .. '\n')
	end
end