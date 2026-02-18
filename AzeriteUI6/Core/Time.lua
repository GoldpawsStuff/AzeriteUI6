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
