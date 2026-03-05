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
local oUF = ns.oUF


oUF.Tags.Events["azui:shorthealth"] = "UNIT_HEALTH UNIT_MAXHEALTH"
oUF.Tags.Methods["azui:shorthealth"] = function(unit, realUnit)
	if (not UnitIsConnected(unit)) then
		return PLAYER_OFFLINE
	elseif (UnitIsGhost(unit)) then
		return GHOST
	elseif (UnitIsDead(unit)) then
		return DEAD
	else
		local secretFuckingNumber = AbbreviateNumbers(UnitHealth(unit))
		if (secretFuckingNumber == 0) then 
			return ""
		else
			return secretFuckingNumber
		end
	end
end

oUF.Tags.Events["azui:shortpower"] = "UNIT_MAXPOWER UNIT_POWER_UPDATE"
oUF.Tags.Methods["azui:shortpower"] = function(unit, realUnit)
	local val = UnitPower(unit)
	if (val) then
		if (not UnitIsDeadOrGhost(unit)) then
			local secretFuckingNumber = AbbreviateNumbers(val)
			if (secretFuckingNumber == 0) then 
				return ""
			else
				return secretFuckingNumber
			end
			return secretFuckingNumber
		end
	end
end
