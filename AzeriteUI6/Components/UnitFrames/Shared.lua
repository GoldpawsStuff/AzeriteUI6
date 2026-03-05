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

-- Custom API locals
local AbbreviateNumber = ns.AbbreviateNumber
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia

local OnEnter = function(self)
	if (GameTooltip:IsForbidden()) then
		self.UpdateTooltip = nil
	else
		UnitFrame_OnEnter(self)
	end
end

local OnLeave = function(self)
	self.UpdateTooltip = nil
	if (not GameTooltip:IsForbidden()) then
		UnitFrame_OnLeave(self)
	end
end

-- Auras
-----------------------------------------
ns.AuraButton_PostCreate = function(element, button)

	-- adjust the stack count
	button.Count:SetFontObject(GetFont(12,true))
	button.Count:SetTextColor(oUF.colors.offwhite:GetRGB())
	button.Count:ClearAllPoints()
	button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 3)

	-- drop the border embedded in the icon file
	button.Icon:SetMask(GetMedia("actionbutton-mask-square"))
	button.Icon:ClearAllPoints()
	button.Icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	button.Icon:SetPoint("TOPLEFT", 2, -2)
	button.Icon:SetPoint("BOTTOMRIGHT", -2, 2)

	-- add our own border
	local border = CreateFrame("Frame", nil, button, "BackdropTemplate")
	border:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 12 })
	border:SetBackdropBorderColor(oUF.colors.verydarkgray:GetRGB())
	border:SetPoint("TOPLEFT", -6, 6)
	border:SetPoint("BOTTOMRIGHT", 6, -6)
	border:SetFrameLevel(button:GetFrameLevel() + 2)
	button.Border = border -- we need access for coloring

	button.Overlay:SetTexture(GetMedia("blank"))

	-- adjust the countdown/timer fontstring
	local countdownString = button.Cooldown:GetCountdownFontString()
	countdownString:SetFontObject(GetFont(14,true))
	countdownString:SetTextColor(oUF.colors.offwhite:GetRGB())
	countdownString:ClearAllPoints()
	countdownString:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 4)
	countdownString:SetParent(button.Border) -- taint? secrets?

end

ns.AuraButton_PostUpdatePlayer = function(element, button, unit, data, position)

	-- Harmful auras on the player
	if (data.isHarmfulAura) then
		local color = C_UnitAuras.GetAuraDispelTypeColor(unit, data.auraInstanceID, element.dispelColorCurve)
		if (color == nil) then
			-- BUG: this shouldn't happen but color can be nil, so default to None color
			color = element.dispelColorCurve:Evaluate(0)
		end
		button.Border:SetBackdropBorderColor(color:GetRGBA())
	else
		-- Beneficial auras on the player
		button.Border:SetBackdropBorderColor(oUF.colors.verydarkgray:GetRGB())
	end

	-- Icon Coloring
	--if (button.isHarmfulAura) or (not data.isHarmfulAura and data.isPlayerAura and data.canApplyAura) then
	--	button.Icon:SetDesaturated(false)
	--	button.Icon:SetVertexColor(1, 1, 1)
	--
	--elseif (data.isPlayerAura) then
	--	button.Icon:SetDesaturated(false)
	--	button.Icon:SetVertexColor(.3, .3, .3)
	--
	--else
	--	button.Icon:SetDesaturated(true)
	--	button.Icon:SetVertexColor(.6, .6, .6)
	--end

end

ns.AuraButton_PostUpdateTarget = function(element, button, unit, data, position)

	if (UnitCanAttack("player", unit)) then

		-- Beneficial auras on hostile target
		if (not data.isHarmfulAura) then
			local color = C_UnitAuras.GetAuraDispelTypeColor(unit, data.auraInstanceID, element.dispelColorCurve)
			if (color == nil) then
				-- BUG: this shouldn't happen but color can be nil, so default to None color
				color = element.dispelColorCurve:Evaluate(0)
			end
			button.Border:SetBackdropBorderColor(color:GetRGBA())

		else
			-- Harmful auras on hostile targets
			button.Border:SetBackdropBorderColor(oUF.colors.debuff.none:GetRGB())
		end
	else

		-- Harmful auras or friendly targets
		if (data.isHarmfulAura) then
			local color = C_UnitAuras.GetAuraDispelTypeColor(unit, data.auraInstanceID, element.dispelColorCurve)
			if (color == nil) then
				-- BUG: this shouldn't happen but color can be nil, so default to None color
				color = element.dispelColorCurve:Evaluate(0)
			end
			button.Border:SetBackdropBorderColor(color:GetRGBA())

		else
			-- Beneficial auras on friendly targets 
			button.Border:SetBackdropBorderColor(oUF.colors.verydarkgray:GetRGB())
		end

	end


	-- Icon Coloring
	--if (not data.isHarmful and data.isPlayerAura and data.canApplyAura) then
	--	button.Icon:SetDesaturated(false)
	--	button.Icon:SetVertexColor(1, 1, 1)
	--
	--elseif (data.isPlayerAura) then
	--	button.Icon:SetDesaturated(false)
	--	button.Icon:SetVertexColor(.3, .3, .3)
	--
	--else
	--	button.Icon:SetDesaturated(true)
	--	button.Icon:SetVertexColor(.6, .6, .6)
	--end

end

-- https://warcraft.wiki.gg/wiki/Struct_AuraData
ns.AuraButton_FilterPlayer = function(button, unit, data)
	-- Every fucking thing fails here. What is the fucking point.
	--return C_UnitAuras.DoesAuraHaveExpirationTime(unit, data.auraInstanceID)
end

ns.AuraButton_FilterTarget = function(button, unit, data)
end

-- https://wowpedia.fandom.com/wiki/API_C_UnitAuras.GetAuraDataByAuraInstanceID
local Aura_Sort = function(a, b)

	-- Debuffs first
	local aHarm = a.isHarmful
	local bHarm = b.isHarmful
	if (aHarm ~= bHarm) then
		return aHarm
	end

	-- Show priority auras first
	--local aPrio = a.spellId and Priority[a.spellId]
	--local bPrio = b.spellId and Priority[b.spellId]
	--if (aPrio ~= bPrio) then
	--	return aPrio
	--end

	-- Player applied HoTs that we would display on nameplates
	local aHoT = not a.isHarmful and a.isPlayerAura and a.canApplyAura
	local bHoT = not b.isHarmful and b.isPlayerAura and b.canApplyAura
	if (aHoT ~= bHoT) then
		return aHoT
	end

	-- Playered applied debuffs that would display by default on nameplates
	local aPlate = a.nameplateShowAll or (a.nameplateShowPersonal and a.isPlayerAura)
	local bPlate = b.nameplateShowAll or (b.nameplateShowPersonal and b.isPlayerAura)
	if (aPlate ~= bPlate) then
		return aPlate
	end

	-- Player first, includes procs and zone buffs.
	if (a.isPlayerAura ~= b.isPlayerAura) then
		return a.isPlayerAura
	end

	-- No duration last, short times first.
	local aTime = (not a.duration or a.duration == 0) and math_huge or a.expirationTime or -1
	local bTime = (not b.duration or b.duration == 0) and math_huge or b.expirationTime or -1

	if (aTime ~= bTime) then
		return aTime < bTime
	end

	return a.auraInstanceID < b.auraInstanceID
end

-- The alternate function is meant to mimic Blizzard sorting.
local Aura_Sort_Alternate = function(a, b)

	-- Player applied HoTs that we would display on nameplates
	local aHoT = not a.isHarmful and a.isPlayerAura and a.canApplyAura
	local bHoT = not b.isHarmful and b.isPlayerAura and b.canApplyAura
	if (aHoT ~= bHoT) then
		return aHoT
	end

	-- Playered applied debuffs that would display by default on nameplates
	local aPlate = a.nameplateShowAll or (a.nameplateShowPersonal and a.isPlayerAura)
	local bPlate = b.nameplateShowAll or (b.nameplateShowPersonal and b.isPlayerAura)
	if (aPlate ~= bPlate) then
		return aPlate
	end

	-- Player first, includes procs and zone buffs.
	if (a.isPlayerAura ~= b.isPlayerAura) then
		return a.isPlayerAura
	end

	-- No duration last, short times first.
	--local aTime = (not a.duration or a.duration == 0) and math_huge or a.expirationTime or -1
	--local bTime = (not b.duration or b.duration == 0) and math_huge or b.expirationTime or -1

	--if (aTime ~= bTime) then
	--	return aTime < bTime
	--end

	return a.auraInstanceID < b.auraInstanceID
end

ns.AuraSorts_AlternateFuncton = Aura_Sort_Alternate
ns.AuraSorts_Alternate = function(element, max)
	table.sort(element, ns.AuraSorts_AlternateFuncton)
	return 1, #element
end

ns.AuraSorts_DefaultFunction = Aura_Sort
ns.AuraSorts_Default = function(element, max)
	table.sort(element, ns.AuraSorts_DefaultFunction)
	return 1, #element
end

-- Hover Scripts
-----------------------------------------
ns.ApplyUnitFrameScriptsTo = function(frame)
	-- Enable clicks (required for both targeting and menus)
	frame:RegisterForClicks("AnyUp")

	-- Standard Blizzard tooltip handling (shows unit name, health, buffs, etc.)
	frame:SetScript("OnEnter", OnEnter)
	frame:SetScript("OnLeave", OnLeave)
end
