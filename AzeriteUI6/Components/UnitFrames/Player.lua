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

local Player = ns:NewModule("Player", nil, "LibMoreEvents-1.0")

-- Declare module defaults
local defaults = { profile = {
	useIceCrystal --= true
}}

local db -- will be assigned a utility function returning the profile settings/defaults during initialization

-- Custom API locals
local AbbreviateNumber = ns.AbbreviateNumber
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia


-- Toggle cast info and health info when castbar is visible.
local Castbar_PostUpdateTexts = function(element)
	if (element:IsShown()) then
		element.Text:Show()
		element.Time:Show()
		element.__owner.Health.Value:Hide()
	else
		element.Text:Hide()
		element.Time:Hide()
		element.__owner.Health.Value:Show()
	end
end

-- Toggle cast text color on protected casts.
local Castbar_PostCastInterruptible = function(element, unit)
	if (element.notInterruptible) then
		element.Text:SetTextColor(229/255, 178/255, 38/255, .75)
	else
		element.Text:SetTextColor(250/255, 250/255, 250/255, .5)
	end
end

-- Partly sourced from oUF's power element's coloring function
local Power_UpdateColor = function(self, event, unit)
	if (self.unit ~= unit) then return end
	local element = self.Power

	if (db.useIceCrystal) then
		--element.Texture:SetVertexColor(1, 1, 1) 
		element:SetStatusBarColor(1, 1, 1) 
	else
		local r, g, b, color
		if (element.colorPower) then
			if (not color) then
				local pType, pToken, altR, altG, altB = UnitPowerType(unit)
				color = self.colors.power[pToken]

				if (not color and altR) then
					r, g, b = altR, altG, altB
					if (r > 1 or g > 1 or b > 1) then
						-- BUG: As of 7.0.3, altR, altG, altB may be in 0-1 or 0-255 range.
						r, g, b = r / 255, g / 255, b / 255
					end
				else
					color = self.colors.power[pToken.."_CRYSTAL"] or self.colors.power[pType] or self.colors.power.MANA
				end
			end
		end

		-- it's done this way so that only non-standard powers have r, g, b values
		if (b) then
			--element.Texture:SetVertexColor(r, g, b)
			element:SetStatusBarColor(r, g, b)
		elseif(color) then
			--element.Texture:SetVertexColor(color:GetRGB())
			element:SetStatusBarColor(color:GetRGB())
		end
	end

	--[[ Callback: Power:PostUpdateColor(unit, color, altR, altG, altB)
	Called after the element color has been updated.

	* self  - the Power element
	* unit  - the unit for which the update has been triggered (string)
	* color - the used ColorMixin-based object (table?)
	* altR  - the red component of the used alternative color (number?)[0-1]
	* altG  - the green component of the used alternative color (number?)[0-1]
	* altB  - the blue component of the used alternative color (number?)[0-1]
	--]]
	if (element.PostUpdateColor) then
		element:PostUpdateColor(unit, color, r, g, b)
	end
end

local style = function(self, unit)

	-- General frame settings
	self:SetSize(560, 180)
	self:SetHitRectInsets(0, 0, 30, -2)

	-- Frame for font Overlays
	local overlay = CreateFrame("Frame", nil, self)
	overlay:SetFrameLevel(self:GetFrameLevel() + 7)
	overlay:SetAllPoints()


	-- Health bar
	--------------------------------------------
	local health = CreateFrame("StatusBar", nil, self)
	health:SetSize(386, 40)
	health:SetPoint("BOTTOMLEFT", 148, 27)
	health:SetStatusBarTexture(GetMedia("hp_cap_bar"))
	health:SetStatusBarColor(245/255, 0/255, 45/255)

	-- Health backdrop
	local healthBg = health:CreateTexture(nil, "BORDER", nil, 0)
	healthBg:SetSize(716, 188)
	healthBg:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", -15, -47)
	healthBg:SetTexture(GetMedia("hp_cap_case"))
	healthBg:SetVertexColor(192/255, 192/255, 192/255)

	-- Health overlay for fonts and icons
	local healthOverlay = CreateFrame("Frame", nil, overlay)
	healthOverlay:SetAllPoints(health)

	local healthValue = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	healthValue:SetPoint("LEFT", 27, 4)
	healthValue:SetFontObject(GetFont(18, true))
	healthValue:SetTextColor(250/255, 250/255, 250/255, .5)
	healthValue:SetJustifyH("LEFT")
	healthValue:SetJustifyV("MIDDLE")

	self:Tag(healthValue, "[azui:shorthealth]")

	-- Options
	health.colorTapping = false
	health.colorDisconnected = false
	health.colorClass = false
	health.colorReaction = false
	health.colorHealth = false

	-- Make the bar move smoothly 
	-- *Note that this fails for reversed bars
	--  do to how blizzard handles texcoords.
	health.smoothing = Enum.StatusBarInterpolation.ExponentialEaseOut 

	-- Register it with oUF
	self.Health = health
	self.Health.Value = healthValue


	-- CombatFeedback
	--------------------------------------------
	local combatFeedback = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 7)
	combatFeedback:SetPoint("CENTER", 0, 4)
	combatFeedback:SetJustifyH("CENTER")
	combatFeedback:SetJustifyV("MIDDLE")

	-- Options
	combatFeedback.feedbackFont = GetFont(20, true)
	combatFeedback.feedbackFontLarge = GetFont(24, true)
	combatFeedback.feedbackFontSmall = GetFont(18, true)
	combatFeedback.maxAlpha = .9
	combatFeedback.colors = oUF.colors.combatfeedback 

	self.CombatFeedback = combatFeedback


	-- Health Prediction
	--------------------------------------------
	-- This looks really bad in retail now.
	-- The problems is how WoW statusbars textures are rendered, 
	-- where they always start from the left and crop the right, 
	-- even when the bars grow from the right. 
	-- It is also fully impossible to adjust the health prediction 
	-- with the new secure values, as you cannot know both the health value 
	-- and absorb value at the same time, let alone do math on these numbers.
	--local healingAll = CreateFrame("StatusBar", nil, self.Health)
	--healingAll:SetFrameLevel(self.Health:GetFrameLevel() + 3)
	--healingAll:SetStatusBarTexture(GetMedia("plain"))
	--healingAll:SetStatusBarColor(1, 1, 1, .25)
	--healingAll:SetPoint("TOP", 0, -.95)
	--healingAll:SetPoint("BOTTOM",0, 8.25)
	-- We can't read health values from within the healpredict element,
	-- so we cannot adjust the texcoords of the healpredict properly.
	--healingAll:SetPoint("LEFT", self.Health:GetStatusBarTexture(), "RIGHT")
	--healingAll:SetWidth(385)

	-- This frame needs to be reversed, 
	-- so we need to apply some trickery to make it work.
	--local damageAbsorb = CreateFrame("StatusBar", nil, self.Health)
	--damageAbsorb:SetFrameLevel(self.Health:GetFrameLevel() + 3)
	--damageAbsorb:SetSize(386, 40)
	--damageAbsorb:SetPoint("TOP")
	--damageAbsorb:SetPoint("BOTTOM")
	--damageAbsorb:SetPoint("RIGHT")
	--damageAbsorb:SetStatusBarTexture(GetMedia("blank")) -- in theory enough
	--damageAbsorb:GetStatusBarTexture():SetAlpha(0) -- hide the bar tex, not the bar
	--damageAbsorb:SetReverseFill(true)

	-- Fake absorb texture, needed for reversed bars
	--local damageAbsorbTex = damageAbsorb:CreateTexture(nil, "ARTWORK", nil, 0)
	--damageAbsorbTex:SetPoint("BOTTOM", 0, 0)
	--damageAbsorbTex:SetPoint("RIGHT", 0, 0)
	--damageAbsorbTex:SetPoint("TOP", 0, 0)
	--damageAbsorbTex:SetTexture(GetMedia("hp_cap_bar"))
	--damageAbsorbTex:SetVertexColor(1, 1, 1, .35)

	--local aMin, aMax
	--damageAbsorb:SetScript("OnMinMaxChanged", function(self, min, max) 
	--	aMin, aMax = min, max
	--end)

	-- This will be called when the value changes, 
	-- and it's allowed access and do math to min/max/cur values of the bar.
	-- This script handler is one of the only ones that are allowed to do that in WoW12.
	--damageAbsorb:SetScript("OnValueChanged", function(element, val) 
	--	if (val and aMin and aMax and aMax > 0) then
	--		-- This can bug out if we don't specifically check. 
	--		-- Experienced this with some mini-games that have 
	--		-- their own set of actionbars, but lacks the "player" unitframe. 
	--		--if (UnitExists("player") or UnitExists("vehicle")) then
	--			--absorbValue:SetText(AbbreviateNumber(val))
	--			damageAbsorbTex:SetPoint("LEFT", ((aMax - aMin)-val)/(aMax - aMin) * 386, 0)
	--			damageAbsorbTex:SetTexCoord((val - aMin)/(aMax - aMin), 0, 0, 1) -- flip the textures
	--		--end
	--	else
	--		--absorbValue:SetText("")
	--	end
	--end)

	-- Register with oUF
	self.HealthPrediction = {
		--healingAll = healingAll, 
		--damageAbsorb = damageAbsorb,
		damageAbsorbClampMode = 0,
		incomingHealClampMode = 0,
		incomingHealOverflow = 1
	}


	-- Overlayed Castbar
	--------------------------------------------
	local castbar = CreateFrame("StatusBar", nil, self)
	castbar:SetFrameLevel(self:GetFrameLevel() + 5)
	castbar:SetStatusBarTexture(GetMedia("hp_cap_bar_highlight"))
	castbar:SetStatusBarColor(1, 1, 1, .35)
	castbar:GetStatusBarTexture():SetBlendMode("ADD")
	castbar:SetAllPoints(self.Health)

	-- Cast Name
	local castbarText = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	castbarText:SetPoint("LEFT", 27, 4)
	castbarText:SetFontObject(GetFont(16, true))
	castbarText:SetTextColor(250/255, 250/255, 250/255, .5)
	castbarText:SetJustifyH("LEFT")
	castbarText:SetJustifyV("MIDDLE")
	castbarText:Hide()

	-- Cast Time
	local castbarTime = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	castbarTime:SetPoint("RIGHT", -27, 4)
	castbarTime:SetFontObject(GetFont(18, true))
	castbarTime:SetTextColor(250/255, 250/255, 250/255, .5)
	castbarTime:SetJustifyH("CENTER")
	castbarTime:SetJustifyV("MIDDLE")
	castbarTime:Hide()

	-- Attach scripts
	castbar:HookScript("OnShow", Castbar_PostUpdateTexts)
	castbar:HookScript("OnHide", Castbar_PostUpdateTexts)

	-- Register it with oUF
	self.Castbar = castbar
	self.Castbar.Text = castbarText
	self.Castbar.Time = castbarTime
	self.Castbar.PostCastInterruptible = Castbar_PostCastInterruptible


	-- Power Crystal
	--------------------------------------------
	local power = CreateFrame("StatusBar", nil, self)
	power:SetSize(144,144) -- 120,140
	power:SetPoint("BOTTOMLEFT", 18, 32) -- 20,38
	power:SetStatusBarTexture(GetMedia("power_crystal_front_cropped"))
	power:SetOrientation("VERTICAL")
	power:GetStatusBarTexture():SetDrawLayer("BACKGROUND", -6)
	--power:GetStatusBarTexture():SetAlpha(.5)

	-- Power Crystal backdrop
	local powerBg = power:CreateTexture(nil, "BACKGROUND", nil, -7)
	powerBg:SetSize(196, 196)
	powerBg:SetPoint("CENTER", 0, 0)
	powerBg:SetTexture(db.useIceCrystal and GetMedia("power-crystal-ice-back") or GetMedia("power_crystal_back"))

	if (db.useIceCrystal) then
		power:SetStatusBarTexture(GetMedia("power-crystal-ice-front-cropped"))
		power:GetStatusBarTexture():SetDrawLayer("BACKGROUND", -6)
		power:SetStatusBarColor(1, 1, 1) 
	else
		power:SetStatusBarTexture(GetMedia("power_crystal_front_cropped"))
		power:GetStatusBarTexture():SetDrawLayer("BACKGROUND", -6)
	end

	-- Power Value
	local powerValue = power:CreateFontString(nil, "OVERLAY", nil, 1)
	powerValue:SetPoint("CENTER", 0, -16)
	powerValue:SetFontObject(GetFont(18, true))
	powerValue:SetTextColor(250/255, 250/255, 250/255, .75)
	powerValue:SetJustifyH("CENTER")
	powerValue:SetJustifyV("MIDDLE")

	self:Tag(powerValue, "[azui:shortpower]")

	-- Power foreground. The "case" of the power crystal.
	local powerFg = power:CreateTexture(nil, "BACKGROUND", nil, -5)
	powerFg:SetSize(198,98)
	powerFg:SetPoint("BOTTOM", 7, -51)
	powerFg:SetTexture(GetMedia("pw_crystal_case"))
	powerFg:SetVertexColor(192/255, 192/255, 192/255)

	-- Options
	power.colorPower = true -- false -- true to follow default coloring, false to never/manually modify
	power.displayAltPower = true -- allow this to be used for altpower from quests and various
	power.frequentUpdates = true -- update often

	-- Register it with oUF
	self.Power = power
	self.Power.Value = powerValue
	self.Power.UpdateColor = Power_UpdateColor

end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling and combat end.
Player.UpdateSettings = function(self)
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
Player.RefreshConfig = function(self)
	self:UpdateSettings()
end

Player.OnInitialize = function(self)
	-- Let's not do these until the addon is more stable
	--self.db = ns.db:RegisterNamespace("Player", defaults)
	--self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	--self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	--self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	-- Utility to get saved settings or defaults
	-- *Will default to defaults if the saved settings above don't exist (during development)
	db = (function(forceDefaults)
		if (forceDefaults) then return defaults.profile end
		return self.db and self.db.profile or defaults.profile
	end)(false)
end

Player.OnEnable = function(self)
	oUF:RegisterStyle("AzeriteUnitFramePlayer", style)
	oUF:Factory(function(self) 
		self:SetActiveStyle("AzeriteUnitFramePlayer") -- Set the current oUF style
		-- Note that this is the default position,
		-- it will be overwritten by saved positions.
		self:Spawn("player"):SetPoint("BOTTOMLEFT", 46, 100)
	end)
end
