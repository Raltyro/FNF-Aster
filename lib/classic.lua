--
-- classic
--
-- Copyright (c) 2014, rxi
--
-- This module is free software; you can redistribute it and/or modify it under
-- the terms of the MIT license. See LICENSE for details.
--
-- Modified for FNF-Aster purposes, ralty
--

local Classic = {__class = "Classic"}

function Classic:new() end

function Classic:__index(k)
	local cls = getmetatable(self)
	local getter = rawget(rawget(self, '__class') == nil and cls or self, 'get_' .. k)
	if getter == nil then return cls[k]
	else return getter(self) end
end

function Classic:__newindex(k, v)
	local isObj = rawget(self, '__class') == nil
	local setter = rawget(isObj and getmetatable(self) or self, 'set_' .. k)
	if setter == nil then return rawset(self, k, v)
	elseif isObj then return setter(self, v)
	else return setter(v) end
end

function Classic:extend(type, path)
	local cls = {}

	for k, v in pairs(self) do
		if k:sub(1, 2) == "__" then cls[k] = v end
	end

	cls.__class = type or "Unknown(" .. self.__class .. ")"
	cls.__path = path
	cls.super = self
	setmetatable(cls, self)

	return cls
end

function Classic:implement(...)
	for _, cls in pairs({...}) do
		for k, v in pairs(cls) do
			if self[k] == nil and type(v) == "function" and k ~= "new" and k:sub(1, 2) ~= "__" then
				self[k] = v
			end
		end
	end
end

function Classic:exclude(...)
	for i = 1, select("#", ...) do
		self[select(i, ...)] = nil
	end
end

function Classic:is(T)
	local mt = self
	repeat
		mt = getmetatable(mt)
		if mt == T then return true end
	until mt == nil
	return false
end

function Classic:__tostring() return (path and path .. "." or '') .. self.__class end

function Classic:__call(...)
	local obj = setmetatable({}, self)
	obj:new(...)
	return obj
end

return Classic