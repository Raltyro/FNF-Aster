local Assets = {}

function Assets.exists(path, isDir)
	local v = love.filesystem.getInfo(path)
	return v and (v.type == 'folder') == (isDir or false)
end

Assets.cachedSounds = {}

function Assets.getMusic(path) return Assets.getSound(path, true) end
function Assets.getSound(path, stream)
	if stream then
		return love.audio.newSource(path, 'stream')
	else
		local snd = Assets.cachedSounds[path]
		if snd ~= nil and pcall(snd.getPointer, snd) then return snd
		elseif Assets.exists(path) then
			local s, v = pcall(love.sound.newSoundData, path)
			if s then
				Assets.cachedSounds[path] = v
				return v
			end
		end
	end

	warn("Unable to get Sound '" .. path .. "'" .. (stream and ' with Stream' or ''))
end

function Assets.regetSound(path)
	Assets.decacheSound(path)
	return Assets.getSound(path)
end

function Assets.decacheSound(path)
	local snd = Assets.cachedSounds[path]
	if snd ~= nil then pcall(snd.release, snd) Assets.cachedSounds[path] = nil end
end

function Assets.soundCached(path) return Assets.cachedSounds[path] ~= nil end

Assets.cachedImages = {}

function Assets.getImage(path)
	local img = Assets.cachedImages[path]
	if img ~= nil and pcall(img.getPointer, img) then return img
	elseif Assets.exists(path) then
		local s, v = pcall(love.graphics.newImage, path)
		if s then
			Assets.cachedImages[path] = v
			return v
		end
	end

	warn("Unable to get Image '" .. path .. "'")
end

function Assets.regetImage(path)
	Assets.decacheImage(path)
	return Assets.getImage(path)
end

function Assets.decacheImage(path)
	local img = Assets.cachedImages[path]
	if img ~= nil then pcall(img.release, img) Assets.cachedImages[path] = nil end
end

function Assets.imageCached(path) return Assets.cachedImages[path] ~= nil end

Assets.cachedTexts = {}

function Assets.getText(path)
	local txt = Assets.cachedTexts[path]
	if txt ~= nil then return txt
	elseif Assets.exists(path) then
		local s, v = pcall(love.filesystem.newFileData, path)
		if s then
			Assets.cachedTexts[path] = v:getString()
			return Assets.cachedTexts[path]
		end
	end

	warn("Unable to get Text '" .. path .. "'")
end

function Assets.regetText(path)
	Assets.decacheText(path)
	return Assets.getText(path)
end

function Assets.decacheText(path) Assets.cachedTexts[path] = nil end

function Assets.textCached(path) return Assets.cachedTexts[path] ~= nil end

Assets.pathExclusions = {}

function Assets.excludePath(path)
	path = path:lower()
	if not table.find(Assets.pathExclusions, path) then table.insert(Assets.pathExclusions, path) end
end

function Assets.unexcludePath(path)
	path = path:lower()
	for i = #Assets.pathExclusions, 1, -1 do if path:endsWith(Assets.pathExclusions[i]) then table.remove(Assets.pathExclusions, i) end end
end

function Assets.pathExcluded(path)
	path = path:lower()
	for i = #Assets.pathExclusions, 1, -1 do if path:endsWith(Assets.pathExclusions[i]) then return true end end
	return false
end

return Assets