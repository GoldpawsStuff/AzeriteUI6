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
local oUF = ns.oUF or oUF

-- Utility function to turn 'true','false' and 'nil' as text into actual booleans.
local getargs = function(...)
	local args = {}
	for i = 1, select("#", ...) do
		local arg = select(i, ...)
		local num = tonumber(arg)
		if (num) then
			args[i] = num
		elseif (arg == "true" or arg == true) then
			args[i] = true
		elseif (arg == "nil" or arg == "false" or not arg) then
			args[i] = false
		else
			args[i] = arg
		end
	end
	return unpack(args)
end

-- Unit difficulty coloring.
local GetDifficultyColorForUnit = function(unit)
	-- 0 = Trivial 	
	-- 1 = Easy 	
	-- 2 = Fair 	
	-- 3 = Difficult 	
	-- 4 = Impossible 	
	local difficulty = C_PlayerInfo.GetContentDifficultyCreatureForPlayer(unit)
	if (difficulty == Enum.RelativeContentDifficulty.Trivial) then
		return oUF.colors.quest.gray
	elseif (difficulty == Enum.RelativeContentDifficulty.Easy) then
		return oUF.colors.quest.green
	elseif (difficulty == Enum.RelativeContentDifficulty.Fair) then
		return oUF.colors.quest.yellow
	elseif (difficulty == Enum.RelativeContentDifficulty.Difficult) then
		return oUF.colors.quest.orange
	elseif (difficulty == Enum.RelativeContentDifficulty.Impossible) then
		return oUF.colors.quest.red
	else
		return oUF.colors.quest.yellow
	end
end

oUF.Tags.Events["azui:shorthealth"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION"
oUF.Tags.Methods["azui:shorthealth"] = function(unit, realUnit)
	if (not UnitIsConnected(unit)) then
		return PLAYER_OFFLINE
	elseif (UnitIsGhost(unit)) then
		return GHOST
	elseif (UnitIsDead(unit)) then
		return DEAD
	else
		return AbbreviateNumbers(UnitHealth(unit))
	end
end

oUF.Tags.Events["azui:healthpercent"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION"
oUF.Tags.Methods["azui:healthpercent"] = function(unit, realUnit)
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then
		return ""
	else
		return oUF.Tags.Methods["perhp"](unit, realUnit)
	end
end

-- Need the extra events for it to register on things like druid form changes
oUF.Tags.Events["azui:shortpower"] = "UNIT_MAXPOWER UNIT_POWER_FREQUENT UNIT_POWER_UPDATE UNIT_DISPLAYPOWER UNIT_CONNECTION"
oUF.Tags.Methods["azui:shortpower"] = function(unit, realUnit)
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then
		return ""
	else
		local val = UnitPower(unit)
		if (val) then
			return AbbreviateNumbers(val)
		else
			return ""
		end
	end
end

-- Need the extra events for it to register on things like druid form changes
oUF.Tags.Events["azui:shortmana"] = "UNIT_MAXPOWER UNIT_POWER_FREQUENT UNIT_POWER_UPDATE UNIT_DISPLAYPOWER UNIT_CONNECTION"
oUF.Tags.Methods["azui:shortmana"] = function(unit, realUnit)
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then
		return ""
	else
		local val = UnitPower(unit, Enum.PowerType.Mana)
		if (val) then
			return AbbreviateNumbers(val)
		else
			return ""
		end
	end
end

-- Name function that accepts max length
-- self:Tag(fontString, "[azui:name(maxLength)]")
oUF.Tags.Events["azui:name"] = "UNIT_NAME_UPDATE GROUP_ROSTER_UPDATE"
oUF.Tags.Methods["azui:name"] = function(unit, realUnit, ...)
	local name = oUF.Tags.Methods["name"](unit, realUnit)
	local length = tonumber(getargs(...))
	if (length) then
		return name:utf8sub(1, length)
	else
		return name
	end
end

-- Show level when appropriate
-- self:Tag(fontString, "[azui:level(reversed)]")
oUF.Tags.Events["azui:level"] = "UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED"
oUF.Tags.Methods["azui:level"] = function(unit, realUnit, ...)
	local level = UnitEffectiveLevel(realUnit or unit)
	if (level and level > 0) then
		local color = GetDifficultyColorForUnit(unit)
		local levelText = color:GenerateHexColorMarkup() .. level .. "|r"

		local showLast = getargs(...)
		if (showLast) then
			return " |cff888888:|r" .. levelText
		else
			return levelText .. "|cff888888:|r "
		end
	end
end
