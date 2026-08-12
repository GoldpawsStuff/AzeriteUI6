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

-- Custom API locals
local AbbreviateNumber = ns.AbbreviateNumber
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia

-- Auras
-----------------------------------------
--ns.AuraButton_PostCreate = function(element, options, button)
ns.AuraButton_PostCreate = function(element, button, options)

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

	--button.Overlay:SetTexture(GetMedia("blank")) -- gone?

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

-- Hover Scripts
-----------------------------------------
local OnEnter = function(self)
	if (GameTooltip:IsForbidden()) then
		self.UpdateTooltip = nil
	else
	end
end

local OnLeave = function(self)
	self.UpdateTooltip = nil
	if (not GameTooltip:IsForbidden()) then
		UnitFrame_OnLeave(self)
	end
end

ns.ApplyUnitFrameScriptsTo = function(frame)
	-- Enable clicks (required for both targeting and menus)
	frame:RegisterForClicks("AnyUp")

	-- Standard Blizzard tooltip handling (shows unit name, health, buffs, etc.)
	frame:SetScript("OnEnter", OnEnter)
	frame:SetScript("OnLeave", OnLeave)
end

ns.AreUnitsSame = function(u1, u2)
	local g1 = UnitGUID(u1)
	local g2 = UnitGUID(u2)

	-- Bail if different secrecy levels (can't be equal, avoids mixed == error)
	if (issecretvalue(g1) ~= issecretvalue(g2)) then
		return false
	end

	-- Now appears to create problems if both are secret too?
	-- *"attempt to compare local 'g1' (a secret string value tainted by..."
	if (issecretvalue(g1) and issecretvalue(g2)) then
		return false
	end

	-- Now safe: both non-secret or both secret
	return g1 == g2 
end

ns.UpdateHealthColor = function(self, event, unit)
	if(not unit or self.__unit ~= unit) then return end
	local element = self.Health

	local color
	if(element.colorDisconnected and not UnitIsConnected(unit)) then
		color = self.colors.disconnected
	elseif(element.colorTapping and not UnitPlayerControlled(unit) and UnitIsTapDenied(unit)) then
		color = self.colors.tapped
	elseif(element.colorThreat and not UnitPlayerControlled(unit) and UnitThreatSituation('player', unit) and not issecretvalue(UnitThreatSituation('player', unit))) then
		color = self.colors.threat[UnitThreatSituation('player', unit)]
	elseif(element.colorClass and (UnitIsPlayer(unit) or UnitInPartyIsAI(unit)))
		or (element.colorClassNPC and not (UnitIsPlayer(unit) or UnitInPartyIsAI(unit)))
		or (element.colorClassPet and UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
		local _, class = UnitClass(unit)
		if(issecretvalue(class)) then
			-- BUG: we can't use custom colors if the class is secret
			-- https://github.com/oUF-wow/oUF/issues/873
			color = C_ClassColor.GetClassColor(class)
		else
			color = self.colors.class[class]
		end
	elseif(element.colorSelection and unitSelectionType(unit, element.considerSelectionInCombatHostile)) then
		color = self.colors.selection[unitSelectionType(unit, element.considerSelectionInCombatHostile)]
	elseif(element.colorReaction and UnitReaction(unit, 'player')) then
		color = self.colors.reaction[UnitReaction(unit, 'player')]
	elseif(element.colorSmooth and self.colors.health:GetCurve()) then
		color = element.values:EvaluateCurrentHealthPercent(self.colors.health:GetCurve())
	elseif(element.colorHealth) then
		color = self.colors.health
	end

	if(color) then
		element:SetStatusBarColor(color:GetRGB())
	end

	--[[ Callback: Health:PostUpdateColor(unit, color)
	Called after the element color has been updated.

	* self  - the Health element
	* unit  - the unit for which the update has been triggered (string)
	* color - the used ColorMixin-based object (table?)
	--]]
	if(element.PostUpdateColor) then
		element:PostUpdateColor(unit, color)
	end
end
