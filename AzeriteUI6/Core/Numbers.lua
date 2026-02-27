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

-- Shorten as much as possible.
ns.AbbreviateNumber = function(value) do return end
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
		return string.format("%.0fm", value/1e6) -- 100m, 1000m, 2300m, etc
	elseif (value >= 1e6) then
		return string.format("%.1fm", value/1e6) -- 1.0m - 99.9m
	elseif (value >= 1e5) then
		return string.format("%.0fk", value/1e3) -- 100k - 999k
	elseif (value >= 1e3) then
		return string.format("%.1fk", value/1e3) -- 1.0k - 99.9k
	elseif (value > 0) then
		return ""..math.floor(value) -- 1 - 999
	else
		return ""
	end
end

-- zhCN Exceptions
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
