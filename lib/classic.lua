--
-- https://github.com/rxi/classic
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

local __class, get_, set_, _, recursiveget = "__class", "get_", "set_", "_"
function recursiveget(class, k)
	local v = rawget(class, k)
	if v == nil and class.super then return recursiveget(class.super, k)
	else return v end
end

function Classic:__index(k)
	local cls = getmetatable(self)
	local getter = recursiveget(rawget(self, __class) == nil and cls or self, get_ .. k)
	if getter == nil then
		local v = rawget(self, k, _ .. k)
		if v ~= nil then return v end
		return cls[k]
	else return getter(self) end
end

function Classic:__newindex(k, v)
	local isObj = rawget(self, __class) == nil
	local setter = recursiveget(isObj and getmetatable(self) or self, set_ .. k)
	if setter == nil then return rawset(self, k, v)
	elseif isObj then return setter(self, v)
	else return setter(v) end
end

function Classic:extend(type)
	local cls = {}

	for k, v in pairs(self) do
		if k:sub(1, 2) == "__" then cls[k] = v end
	end

	cls.__class = type or "Unknown(" .. self.__class .. ")"
	cls.super = self
	setmetatable(cls, self)

	if debug then
		cls.__path = debug.getinfo(2, "S").short_src:gsub('/', '.')
		cls.__path = cls.__path:match("(.+)%..+$") or cls.__path
		if cls.__path:sub(-#type) == type:lower() then cls.__path = cls.__path:sub(1, -#type - 2) end
	end

	return cls
end

function Classic:implement(...)
	for i = 1, select("#", ...) do
		for k, v in pairs(select(i, ...)) do
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
	if type(T) == 'string' then return self.__class == T end
	local mt = self
	repeat
		mt = getmetatable(mt)
		if mt == T then return true end
	until mt == nil
	return false
end

function Classic:__tostring() return self.__class end

function Classic:__call(...)
	local obj = setmetatable({}, self)
	obj:new(...)
	return obj
end

return Classic