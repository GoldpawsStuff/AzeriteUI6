--[[

	The MIT License (MIT)

	Copyright (c) 2026 Lars Norberg

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

--]]
local addonName, ns = ...

ns = LibStub("AceAddon-3.0"):NewAddon(ns, addonName, "LibMoreEvents-1.0")
ns.callbacks = LibStub("CallbackHandler-1.0"):New(ns, nil, nil, false)

-- Saved variables global
local AzeriteUI6_UnitFrames_Positions_DB = {}

-- Addon defaults
local defaults = { profile = {} }

-- Fonts & Media
-----------------------------------------------
-- Add some aliases for blizzard artwork.
local alias = {
	["plain"] = [[Interface\ChatFrame\ChatFrameBackground]]
}

-- Full cache that spawns new objects on-the-fly.
local count, font_mt = 0, nil
font_mt = {
	__index = function(t,k)
		-- Create a new category and subtable
		if (type(k) == "string") then
			local new = setmetatable({}, font_mt)
			rawset(t,k,new)
			return new
		-- Create a new font object
		elseif (type(k) == "number") then
			count = count + 1
			local new = CreateFont(string_format("AzeriteUnitFrameFont%d", count))
			new:SetJustifyH("LEFT") -- new fonts appear to be centered after 9.1.5
			rawset(t,k,new)
			return new
		end
	end
}

local Fonts = setmetatable({}, font_mt)

-- Put our global fontobjects into our table.
for _,fontType in next,{ "Normal", "Chat", "Number" } do
	for _,fontStyle in next,{ "None", "Outline" } do
		for fontSize = 1,34 do -- iterate all commonly used sizes
			local namedType = fontType == "Normal" and "" or fontType
			local namedStyle = fontStyle == "None" and "" or fontStyle
			local fontObject = _G["AzeriteUnitFrameFont"..namedType..fontSize..namedStyle]
			if (fontObject) then -- only put actual fontobjects into the table
				Fonts[fontType][fontStyle][fontSize] = fontObject
			end
		end
	end
end

-- Return a font object, re-use existing ones that match.
ns.GetFont = function(size, outline, type)
	return Fonts[type or "Normal"][outline and "Outline" or "None"][size]
end

-- Retrieve an asset from the media asset folder.
ns.GetMedia = function(name, type)
	return alias[name] or string.format([[Interface\AddOns\%s\Assets\%s.%s]], addonName, name, type or "tga")
end

-- Number Abbreviations
-----------------------------------------------
-- Shorten as much as possible.
ns.AbbreviateNumber = function(value)
	value = tonumber(value)
	if (not value) then return "" end
	if (value >= 1e9) then
		return ("%.1fb"):format(value / 1e9):gsub("%.?0+([kmb])$", "%1")
	elseif (value >= 1e6) then
		return ("%.1fm"):format(value / 1e6):gsub("%.?0+([kmb])$", "%1")
	elseif (value >= 1e3) or (value <= -1e3) then
		return ("%.1fk"):format(value / 1e3):gsub("%.?0+([kmb])$", "%1")
	elseif (value > 0) then
		return ""..math.floor(value)
	else
		return ""
	end
end

-- Aim at filling 3-5 digits or letters.
ns.AbbreviateNumberBalanced = function(value)
	value = tonumber(value)
	if (not value) then return "" end
	if (value >= 1e8) then
		return string_format("%.0fm", value/1e6) -- 100m, 1000m, 2300m, etc
	elseif (value >= 1e6) then
		return string_format("%.1fm", value/1e6) -- 1.0m - 99.9m
	elseif (value >= 1e5) then
		return string_format("%.0fk", value/1e3) -- 100k - 999k
	elseif (value >= 1e3) then
		return string_format("%.1fk", value/1e3) -- 1.0k - 99.9k
	elseif (value > 0) then
		return ""..math.floor(value) -- 1 - 999
	else
		return ""
	end
end

-- Time Abbreviations
-----------------------------------------------
-- Returns a format string and input values
local DAY, HOUR, MINUTE = 86400, 3600, 60
ns.AbbreviateTime = function(secs)
	if (secs > DAY) then -- more than a day
		return "%.0f%s", math.ceil(secs / DAY), "d"
	elseif (secs > HOUR) then -- more than an hour
		return "%.0f%s", math.ceil(secs / HOUR), "h"
	elseif (secs > MINUTE) then -- more than a minute
		return "%.0f%s", math.ceil(secs / MINUTE), "m"
	elseif (secs > 5) then
		return "%.0f", math.ceil(secs)
	elseif (secs > .9) then
		return "|cffff8800%.0f|r", math.ceil(secs)
	elseif (secs > .05) then
		return "|cffff0000%.0f|r", secs*10 - secs*10%1
	else
		return ""
	end
end

-- zhCN Exceptions
-----------------------------------------------
if (GetLocale() == "zhCN") then
	ns.AbbreviateNumber = function(value)
		value = tonumber(value)
		if (not value) then return "" end
		if (value >= 1e8) then
			return ("%.2f亿"):format(value / 1e8):gsub("%.?0+([km])$", "%1")
		elseif (value >= 1e4) or (value <= -1e3) then
			return ("%.2f万"):format(value / 1e4):gsub("%.?0+([km])$", "%1")
		elseif (value > 0) then
			return ""..math.floor(value)
		else
			return ""
		end
	end

	ns.AbbreviateNumberBalanced = function(value)
		value = tonumber(value)
		if (not value) then return "" end
		if (value >= 1e8) then
			return string.format("%.2f亿", value/1e8)
		elseif (value >= 1e4) then
			return string.format("%.2f万", value/1e4)
		elseif (value > 0) then
			return ""..math.floor(value)
		else
			return ""
		end
	end
end

ns.RefreshConfig = function(self, event, ...)
	if (event == "OnNewProfile") then
		--local db, profileKey = ...

	elseif (event == "OnProfileChanged") then
		local db, newProfileKey = ...

		db.char.profile = newProfileKey

	elseif (event == "OnProfileCopied") then
		--local db, sourceProfileKey = ...

	elseif (event == "OnProfileReset") then
		--local db = ...

	end
end

ns.OnEnable = function(self)
	--self.db:SetProfile(self.db.char.profile)
end

ns.OnInitialize = function(self)
	--self.db = LibStub("AceDB-3.0"):New("AzeriteUI6_UnitFrames_DB", defaults, true)
	--self.db.RegisterCallback(self, "OnNewProfile", "RefreshConfig")
	--self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	--self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	--self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end
