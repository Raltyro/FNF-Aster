local Paths = {
	ASSET_EXT = {
		IMAGES = {'png', 'jpg', 'jpeg', 'bmp'},
		SOUNDS = {'ogg', 'oga', 'wav', 'mp3'},
		VIDEOS = {'ogv', 'ogg'},
		FRAGS = {'frag', 'glsl'},
		VERTS = {'vert'},
		FONTS = {'otf', 'ttf'}
	}
}

Paths.currentLevel = nil
Paths._cachedPaths = {}

local function getPrefix(...) local v = {...} table.reverse(v) return table.concat(v, '/') end
local function getSuffix(...) return table.concat({...}, '-') end
function Paths.getPath(file, prefix, assetType)
	file = getPrefix(prefix, 'assets') .. '/' .. file
	if love.system.getOS() == "Windows" then file = file:lower() end
	if Paths._cachedPaths[file] == false or file:hasExt() then return file
	elseif assetType ~= nil then assetType = assetType:upper() .. "S" end

	local cache = Paths._cachedPaths[file]
	if cache and cache ~= true then
		local v = love.filesystem.getInfo(file .. '.' .. cache)
		if v and (v.type == 'file' or v.type == 'symlink') then return file .. '.' .. cache end
		Paths._cachedPaths[file] = nil
	end

	if Paths.ASSET_EXT[assetType] then
		for _, ext in ipairs(Paths.ASSET_EXT[assetType]) do
			if not cache or ext ~= cache then
				local v = love.filesystem.getInfo(file .. '.' .. ext)
				if v and (v.type == 'file' or v.type == 'symlink') then
					Paths._cachedPaths[file] = ext
					return file .. '.' .. ext
				end
			end
		end
	elseif not cache or assetType ~= cache then
		local v = love.filesystem.getInfo(file .. '.' .. assetType)
		if v and (v.type == 'file' or v.type == 'symlink') then
			Paths._cachedPaths[file] = assetType
			return file .. '.' .. assetType
		end
	end

	if cache == nil then
		local v = love.filesystem.getInfo(file)
		Paths._cachedPaths[file] = not v or v.type == 'symlink'
	end

	return file
end

function Paths.txt(key, ...) return Paths.getPath(key, getPrefix('data', ...), 'txt') end
function Paths.json(key, ...) return Paths.getPath(key, getPrefix('data', ...), 'json') end
function Paths.xml(key, ...) return Paths.getPath(key, getPrefix('data', ...), 'xml') end
function Paths.frag(key, ...) return Paths.getPath(key, getPrefix('shaders', ...), 'FRAG') end
function Paths.vert(key, ...) return Paths.getPath(key, getPrefix('shaders', ...), 'VERT') end

function Paths.image(key, ...) return Paths.getPath(key, getPrefix('images', ...), 'IMAGE') end
function Paths.sound(key, ...) return Paths.getPath(key, getPrefix('sounds', ...), 'SOUND') end
function Paths.soundRandom(key, min, max, ...) return Paths.getPath(key, getPrefix('sounds', ...) + love.math.random(min or 0, max or 1), 'SOUND') end
function Paths.music(key, ...) return Paths.getPath(key, getPrefix('music', ...), 'SOUND') end
function Paths.video(key, ...) return Paths.getPath(key, getPrefix('videos', ...), 'VIDEO') end
function Paths.font(key, ...) return Paths.getPath(key, getPrefix('fonts', ...), 'FONT') end

local invalidChars, hideChars = '[ ~&\\;:<>#]', '[.,\'"%?!]'
function Paths.formatSongKey(key) return key:gsub(invalidChars, '-'):gsub(hideChars, ''):lower() end
function Paths.voices(song, ...) return Paths.getPath(song .. '/' .. Paths.songSuffix('Voices', ...), 'songs', 'SOUND') end
function Paths.inst(song, ...) return Paths.getPath(song .. '/' .. Paths.songSuffix('Inst', ...), 'songs', 'SOUND') end

return Paths