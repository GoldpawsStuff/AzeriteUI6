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
local LibOrb = LibStub("LibOrb-1.0")

-- Declare module defaults
local defaults = { profile = {
	alwaysUseCrystal = false,
	useIceCrystal = false
}}

local db -- will be assigned a utility function returning the profile settings/defaults during initialization

-- Custom API locals
local AbbreviateNumber = ns.AbbreviateNumber
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia

-- We'll update this when entering world or changing specs
local playerIsRetribution = UnitClassBase("player") == "PALADIN" and (GetSpecialization() == SPEC_PALADIN_RETRIBUTION)

-- Function to create an alpha curve based on min/max values.
local createAlphaCurve = function(min, max)
	local alphaCurve = C_CurveUtil.CreateColorCurve()  -- Returns ColorCurveObject
	alphaCurve:SetType(Enum.LuaCurveType.Step) -- Step: instant jump at points
	alphaCurve:AddPoint(0, CreateColor(1, 1, 1, min or 0)) -- At 0%: alpha=<min> (hide)
	alphaCurve:AddPoint(.01, CreateColor(1, 1, 1, max or 1)) -- At 1%+: alpha=<max> (show)
	return alphaCurve
end

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
		element.Text:SetTextColor(self.colors.normal:GetRGB())
		element.Text:SetAlpha(.75)
	else
		element.Text:SetTextColor(self.colors.highlight:GetRGB())
		element.Text:SetAlpha(.5)
	end
end

-- Trigger PvPIndicator post update when combat status is toggled.
local CombatIndicator_PostUpdate = function(element, inCombat)
	element.__owner.PvPIndicator:ForceUpdate()
end

-- Only show Horde/Alliance badges, and hide them in combat.
local PvPIndicator_Override = function(self, event, unit)
	if (unit and unit ~= self.unit) then return end

	local element = self.PvPIndicator
	unit = unit or self.unit

	local status
	local factionGroup = UnitFactionGroup(unit) or "Neutral"

	if (factionGroup ~= "Neutral") then
		if (UnitIsPVPFreeForAll(unit)) then
		elseif (UnitIsPVP(unit)) then
			-- Mercenaries fight for the opposite team, 
			-- happens all the time in battlegrounds.
			if (unit == "player" and UnitIsMercenary(unit)) then
				if (factionGroup == "Horde") then
					factionGroup = "Alliance"
				elseif (factionGroup == "Alliance") then
					factionGroup = "Horde"
				end
			end
			status = factionGroup
		end
	end

	if (status and not self.CombatIndicator:IsShown()) then
		element:SetTexture(element[status])
		element:Show()
	else
		element:Hide()
	end

end

-- We need to override this update
local Mana_Override = function(self, event, unit)
	if(self.unit ~= unit) then return end
	local element = self.AdditionalPower

	--[[ Callback: Power:PreUpdate(unit)
	Called before the element has been updated.

	* self - the Power element
	* unit - the unit for which the update has been triggered (string)
	--]]
	if (element.PreUpdate) then
		element:PreUpdate(unit)
	end

	-- Different GUID means a different player or NPC,
	-- so we want updates to be instant, not smoothed.
	local guid = UnitGUID(unit)
	local forced = (guid ~= element.guid) or (UnitIsDeadOrGhost(unit))
	element.guid = guid

	local displayType, min
	if (element.displayAltPower and oUF.isRetail) then
		displayType, min = element:GetDisplayPower()
	end

	local cur, max = UnitPower(unit, displayType), UnitPowerMax(unit, displayType)
	element:SetMinMaxValues(min or 0, max)

	if (UnitIsConnected(unit)) then
		element:SetValue(cur, forced)
	else
		element:SetValue(max, forced)
	end

	element.cur = cur
	element.min = min
	element.max = max
	element.displayType = displayType

	--[[ Callback: Power:PostUpdate(unit, cur, min, max)
	Called after the element has been updated.

	* self - the Power element
	* unit - the unit for which the update has been triggered (string)
	* cur  - the unit's current power value (number)
	* min  - the unit's minimum possible power value (number)
	* max  - the unit's maximum possible power value (number)
	--]]
	if (element.PostUpdate) then
		element:PostUpdate(unit, cur, min, max)
	end
end

-- Only show mana orb when mana is the primary resource.
local Mana_UpdateVisibility = function(self, event, unit)
	local element = self.AdditionalPower

	-- There is a short period when entering vehicles where the player unit does not exist.
	-- We don't want the mana orb accidentially popping up during this period.
	local shouldEnable = not playerIsRetribution and not db.alwaysUseCrystal and UnitExists("player") and not UnitHasVehicleUI("player") and UnitPowerType(unit) == Enum.PowerType.Mana
	local isEnabled = element.__isEnabled

	if (shouldEnable and not isEnabled) then

		if (element.frequentUpdates) then
			self:RegisterEvent("UNIT_POWER_FREQUENT", element.Override)
		else
			self:RegisterEvent("UNIT_POWER_UPDATE", element.Override)
		end

		self:RegisterEvent("UNIT_MAXPOWER", element.Override)

		element:Show()

		element.__isEnabled = true
		element.Override(self, "ElementEnable", "player", "MANA")

		--[[ Callback: AdditionalPower:PostVisibility(isVisible)
		Called after the element's visibility has been changed.

		* self      - the AdditionalPower element
		* isVisible - the current visibility state of the element (boolean)
		--]]
		if (element.PostVisibility) then
			element:PostVisibility(true)
		end

	elseif (not shouldEnable and (isEnabled or isEnabled == nil)) then

		self:UnregisterEvent("UNIT_MAXPOWER", element.Override)
		self:UnregisterEvent("UNIT_POWER_FREQUENT", element.Override)
		self:UnregisterEvent("UNIT_POWER_UPDATE", element.Override)

		element:Hide()

		element.__isEnabled = false
		element.Override(self, "ElementDisable", "player", "MANA")

		if (element.PostVisibility) then
			element:PostVisibility(false)
		end

	elseif (shouldEnable and isEnabled) then
		element.Override(self, event, unit, "MANA")
	end
end

-- Hide power crystal when mana is the primary resource,
-- also hide power value on systems that go to zero while out of combat. 
local Power_UpdateVisibility = function(element, unit, cur, min, max)

	-- power crystal visibility
	local powerType = UnitPowerType(unit)
	if (playerIsRetribution or db.alwaysUseCrystal) then
		element:Show()
	else
		if (powerType == Enum.PowerType.Mana and not UnitHasVehicleUI("player")) then
			element:Hide()
		else
			element:Show()
		end
	end

	-- power value visibility
	if (element.Value.alphaCurve) then
		local ptype = UnitPowerType(unit)  -- Safe (non-secret)
		local color = UnitPowerPercent(unit, ptype, true, element.Value.alphaCurve)  -- Secret-safe!
		local _, _, _, a = color:GetRGBA()  -- Safe number!
		element.Value:SetAlpha(a)
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

-- Primarily needed to update orb/crystal visibilities
local UnitFrame_OnEvent = function(self, event, unit, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		playerIsRetribution = playerClass == "PALADIN" and GetSpecialization() == SPEC_PALADIN_RETRIBUTION
	elseif (event == "PLAYER_SPECIALIZATION_CHANGED") then
		playerIsRetribution = playerClass == "PALADIN" and GetSpecialization() == SPEC_PALADIN_RETRIBUTION
	end

	self.Power:ForceUpdate()
	self.AdditionalPower:ForceUpdate()
end

local style = function(self, unit)

	-- General frame settings
	self:SetSize(560, 180)
	self:SetHitRectInsets(0, 0, 30, -2)

	ns.ApplyUnitFrameScriptsTo(self)

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
	health:SetStatusBarColor(self.colors.health:GetRGB())

	-- Health backdrop
	local healthBg = health:CreateTexture(nil, "BORDER", nil, 0)
	healthBg:SetSize(716, 188)
	healthBg:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", -15, -47)
	healthBg:SetTexture(GetMedia("hp_cap_case"))
	healthBg:SetVertexColor(self.colors.ui:GetRGB())

	-- Health overlay for fonts and icons
	local healthOverlay = CreateFrame("Frame", nil, overlay)
	healthOverlay:SetAllPoints(health)

	local healthValue = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	healthValue:SetPoint("LEFT", 27, 4)
	healthValue:SetFontObject(GetFont(18, true))
	healthValue:SetTextColor(self.colors.highlight:GetRGB())
	healthValue:SetAlpha(.5)
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
	castbarText:SetTextColor(self.colors.highlight:GetRGB())
	castbarText:SetAlpha(.5)
	castbarText:SetJustifyH("LEFT")
	castbarText:SetJustifyV("MIDDLE")
	castbarText:Hide()

	-- Cast Time
	local castbarTime = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	castbarTime:SetPoint("RIGHT", -27, 4)
	castbarTime:SetFontObject(GetFont(18, true))
	castbarTime:SetTextColor(self.colors.highlight:GetRGB())
	castbarTime:SetAlpha(.5)
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
	power:SetPoint("BOTTOMLEFT", 8, 32) -- 20,38
	power:SetStatusBarTexture(GetMedia("power_crystal_front_cropped"))
	power:SetOrientation("VERTICAL")
	power:GetStatusBarTexture():SetDrawLayer("BACKGROUND", -6)

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
	powerValue:SetPoint("CENTER", power, "CENTER", 0, -16)
	powerValue:SetFontObject(GetFont(18, true))
	powerValue:SetTextColor(self.colors.highlight:GetRGB())
	powerValue:SetJustifyH("CENTER")
	powerValue:SetJustifyV("MIDDLE")
	powerValue:SetAlpha(.75)
	powerValue.alphaCurve = createAlphaCurve(0, .75)

	self:Tag(powerValue, "[azui:shortpower]")

	-- Power foreground. The "case" of the power crystal.
	local powerFg = power:CreateTexture(nil, "BACKGROUND", nil, -5)
	powerFg:SetSize(198,98)
	powerFg:SetPoint("BOTTOM", 7, -44) -- 7, -51
	powerFg:SetTexture(GetMedia("pw_crystal_case"))
	powerFg:SetVertexColor(self.colors.ui:GetRGB())

	-- Options
	power.colorPower = true -- false -- true to follow default coloring, false to never/manually modify
	power.displayAltPower = true -- allow this to be used for altpower from quests and various
	power.frequentUpdates = true -- update often

	-- Register it with oUF
	self.Power = power
	self.Power.Value = powerValue
	self.Power.UpdateColor = Power_UpdateColor
	self.Power.PostUpdate = Power_UpdateVisibility

	--[[-- 

	-- Energy systems which regenerate OOC
	Enum.PowerType.Energy
	Enum.PowerType.Focus

	-- ComboPoint systems
	Enum.PowerType.ArcaneCharges
	Enum.PowerType.Chi
	Enum.PowerType.ComboPoints
	Enum.PowerType.Essence
	Enum.PowerType.HolyPower
	Enum.PowerType.Runes
	Enum.PowerType.SoulShards

	-- Aura based ComboPoint systems
	--Enum.PowerType.SOUL_FRAGMENTS
	--Enum.PowerType.STAGGER
	--]]--

	-- Mana Orb
	--------------------------------------------
	local mana = LibOrb:CreateOrb(nil, self)
	mana:SetFrameLevel(self:GetFrameLevel() - 2) -- get it below health
	mana:SetPoint("BOTTOMLEFT", 29, 29) -- 29, 27
	mana:SetSize(103, 103)
	mana:SetStatusBarTexture(GetMedia("orb2"), GetMedia("orb2"))
	mana:SetStatusBarColor(self.colors.power.MANA_ORB:GetRGB())

	mana.displayPairs = {} -- disable oUFs own enabling
	mana.frequentUpdates = true

	-- orb backdrop
	local manaBackdrop = mana:CreateTexture(nil, "BACKGROUND", nil, -2)
	manaBackdrop:SetPoint("CENTER", 0, 0)
	manaBackdrop:SetSize(180, 180)
	manaBackdrop:SetTexture(GetMedia("orb-backdrop2"))

	-- content holder for overlays
	local manaCaseFrame = CreateFrame("Frame", nil, mana)
	manaCaseFrame:SetFrameLevel(mana:GetFrameLevel() + 1)
	manaCaseFrame:SetAllPoints()

	-- a little shading to give more depth
	local manaShade = manaCaseFrame:CreateTexture(nil, "ARTWORK", nil, 1)
	manaShade:SetPoint("CENTER", 0, 0)
	manaShade:SetSize(127, 127)
	manaShade:SetTexture(GetMedia("shade-circle"))
	manaShade:SetVertexColor(0, 0, 0, 1)

	-- orb case in the foreground
	local manaCase = manaCaseFrame:CreateTexture(nil, "ARTWORK", nil, 2)
	manaCase:SetPoint("CENTER", 0, 0)
	manaCase:SetSize(188, 188)
	manaCase:SetTexture(GetMedia("orb_case_hi"))
	manaCase:SetVertexColor(self.colors.ui:GetRGB())

	-- mana Orb Value
	local manaValue = manaCaseFrame:CreateFontString(nil, "OVERLAY", nil, 1)
	manaValue:SetPoint("CENTER", 3, 0)
	manaValue:SetFontObject(GetFont(18, true))
	manaValue:SetTextColor(self.colors.highlight:GetRGB())
	manaValue:SetAlpha(.4)
	manaValue:SetJustifyH("CENTER")
	manaValue:SetJustifyV("MIDDLE")

	self:Tag(manaValue, "[azui:shortmana]")

	self.AdditionalPower = mana
	self.AdditionalPower.Backdrop = manaBackdrop
	self.AdditionalPower.Shade = manaShade
	self.AdditionalPower.Case = manaCase
	self.AdditionalPower.Value = manaValue
	self.AdditionalPower.Override = Mana_Override
	self.AdditionalPower.OverrideVisibility = Mana_UpdateVisibility

	-- Combat Indicator
	--------------------------------------------
	local combatIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, -2)
	combatIndicator:SetSize(80,80)
	combatIndicator:SetPoint("BOTTOMLEFT", 42, -16) -- 40,-18
	combatIndicator:SetTexture(GetMedia("icon-combat"))
	combatIndicator:SetVertexColor(self.colors.uidark:GetRGB())

	self.CombatIndicator = combatIndicator
	self.CombatIndicator.PostUpdate = CombatIndicator_PostUpdate

	-- PvP Indicator
	--------------------------------------------
	local PvPIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, -2)
	PvPIndicator:SetSize(84, 84)
	PvPIndicator:SetPoint("BOTTOMLEFT", 42, -16) -- 40,-18
	PvPIndicator.Alliance = GetMedia("icon_badges_alliance")
	PvPIndicator.Horde = GetMedia("icon_badges_horde")

	self.PvPIndicator = PvPIndicator
	self.PvPIndicator.Override = PvPIndicator_Override

	-- Auras
	--------------------------------------------
	local auras = CreateFrame("Frame", nil, self)
	auras:SetSize(40*8 - 4, 40*2 - 4)
	auras:SetPoint("BOTTOMLEFT", 158, 91)

	auras.size = 36
	auras.spacing = 4
	auras.numTotal = 16
	auras.disableMouse = false
	auras.disableCooldown = false
	auras.initialAnchor = "BOTTOMLEFT"
	auras.spacingX = 4
	auras.spacingY = 4
	auras.growthX = "RIGHT"
	auras.growthY = "UP"
	auras.tooltipAnchor = "ANCHOR_TOPLEFT"
	auras.sortMethod = "TIME_REMAINING"
	auras.sortDirection = "DESCENDING"
	auras.reanchorIfVisibleChanged = true
	auras.buffFilter = "HELPFUL|INCLUDE_NAME_PLATE_ONLY|RAID_IN_COMBAT"
	auras.debuffFilter = "HARMFUL|INCLUDE_NAME_PLATE_ONLY|RAID_PLAYER_DISPELLABLE"

	self.Auras = auras
	self.Auras.PostCreateButton = ns.AuraButton_PostCreate
	self.Auras.PostUpdateButton = ns.AuraButton_PostUpdatePlayer

	-- Register events to handle custom element changes
	self:RegisterEvent("PLAYER_ALIVE", UnitFrame_OnEvent, true)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", UnitFrame_OnEvent, true)
	--self:RegisterEvent("PLAYER_REGEN_DISABLED", UnitFrame_OnEvent, true)
	--self:RegisterEvent("PLAYER_REGEN_ENABLED", UnitFrame_OnEvent, true)
	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", UnitFrame_OnEvent) -- needed for paladin crystal changes
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", UnitFrame_OnEvent, true) -- needed for power updates when switching directly between forms

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
		local frame = self:Spawn("player")
		frame:SetPoint("BOTTOMLEFT", 46, 100)

		frame.Enable = function(self)
			RegisterAttributeDriver(self, "unit", "[vehicleui]vehicle; player")
			self:Show()
		end

		frame.Disable = function(self)
			UnregisterAttributeDriver(self, "unit")
			self:Hide()
		end

		-- Disable WoWs own handling
		UnregisterUnitWatch(self.frame)
		frame:SetAttribute("toggleForVehicle", false)

	end)
end
