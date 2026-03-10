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
local _, ns = ...

-- Font cache that spawns new objects on-the-fly.
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
			local new = CreateFont(string.format("AzeriteUnitFrameFont%d", count))
			new:SetJustifyH("LEFT") -- new fonts appear to be centered after 9.1.5
			rawset(t,k,new)
			return new
		end
	end
}
local Fonts = setmetatable({}, font_mt)

-- Put our global fontobjects into our table.
-- These are defined in our FontStyles.xml and support all locales.
for _,fontType in next,{ "Normal", "Chat", "Number" } do
	for _,fontStyle in next,{ "None", "Outline" } do
		for fontSize = 1,34 do -- iterate all commonly used sizes
			local namedType = fontType == "Normal" and "" or fontType
			local namedStyle = fontStyle == "None" and "" or fontStyle
			local fontObject = _G["AzeriteUI6Font"..namedType..fontSize..namedStyle]
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
