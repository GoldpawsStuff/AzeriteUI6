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

local L = LibStub("AceLocale-3.0"):GetLocale((...))

local Target = ns:NewModule("Target", nil, "LibMoreEvents-1.0", "LibMovableFrames-1.0")

-- Declare module defaults
local defaults = { profile = {
	enabled = true
}}

-- Custom API locals
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia
local UnitIsUnit = ns.UnitIsUnit

-- Function to create an alpha curve based on min/max values.
-- Useful to hide elements when at (almost) zero.
local createAlphaCurve = function(min, max)
	local alphaCurve = C_CurveUtil.CreateColorCurve()  -- Returns ColorCurveObject
	alphaCurve:SetType(Enum.LuaCurveType.Step) -- Step: instant jump at points
	alphaCurve:AddPoint(0, CreateColor(1, 1, 1, min or 0)) -- At 0%: alpha=<min> (hide)
	alphaCurve:AddPoint(.01, CreateColor(1, 1, 1, max or 1)) -- At 1%+: alpha=<max> (show)
	return alphaCurve
end

-- Add an aura filter group and apply styling
local Auras_AddGroup = function(element, filter, data)
	if (string.find(filter, "HARM")) then
		data.initializeFrame = ns.AuraButton_InitializeBigDebuff
	else
		data.initializeFrame = ns.AuraButton_InitializeBigBuff
	end 
	return element:AddGroup(filter, data)
end

-- Set the index of an aura group.
local Auras_SetGroupIndex = function(element, groupKey, index)
	element:SetAuraGroupLayout(groupKey, {
		layoutIndex = index, -- the only actual change
		elementSpacing = element.elementSpacing,
		forceNewLine = element.forceNewLine,
		groupLineSpacing = element.groupLineSpacing,
		groupSpacing = element.groupSpacing,
		lineSpacing = element.lineSpacing
	})
end

-- Update aura filters based on unit alignment and combat state
local Auras_PostUpdate = function(element, event)
	local unit = element.__owner.__unit
	if (not unit) then return end

	local inCombat
	if (event == "PLAYER_REGEN_DISABLED") then
		inCombat = true
	elseif (event ~= "PLAYER_REGEN_ENABLED") then
		inCombat = UnitAffectingCombat(unit)
	end

	local canAttack = UnitCanAttack("player", unit)

	-- Hostile unit
	if (canAttack) then 
		-- Prioritize your harmful running auras
		if (inCombat) then
			element:SetGroupIndex(element.Groups.HarmfulBoss, 1)
			element:SetGroupIndex(element.Groups.HelpfulBoss, 1)
			element:SetGroupIndex(element.Groups.HelpfulAllWhitelist, 1)
			element:SetGroupIndex(element.Groups.HelpfulPlayerWhitelist, 1)
			element:SetGroupIndex(element.Groups.HelpfulPlayer, 1)
			element:SetGroupIndex(element.Groups.HelpfulPlayerLong, 1000)
			element:SetGroupIndex(element.Groups.HelpfulNotPlayerLong, 1000)
			element:SetGroupIndex(element.Groups.HarmfulPlayer, 1)
			element:SetGroupIndex(element.Groups.HarmfulAllNotPlayer, 1)
			element:SetGroupIndex(element.Groups.HarmfulAllWhitelist, 1)
			element:SetGroupIndex(element.Groups.HarmfulAllDurationless, 1000)

			element:SetAuraGroupEnabled(element.Groups.HarmfulBoss, true)
			element:SetAuraGroupEnabled(element.Groups.HelpfulBoss, true)
			element:SetAuraGroupEnabled(element.Groups.HelpfulAllWhitelist, true)
			element:SetAuraGroupEnabled(element.Groups.HarmfulPlayer, true)
			element:SetAuraGroupEnabled(element.Groups.HarmfulAllWhitelist, true)

			element:SetAuraGroupEnabled(element.Groups.HelpfulPlayerWhitelist, false)
			element:SetAuraGroupEnabled(element.Groups.HelpfulPlayer, false)
			element:SetAuraGroupEnabled(element.Groups.HelpfulPlayerLong, false)
			element:SetAuraGroupEnabled(element.Groups.HelpfulNotPlayerLong, false)
			element:SetAuraGroupEnabled(element.Groups.HarmfulAllNotPlayer, false)
			element:SetAuraGroupEnabled(element.Groups.HarmfulAllDurationless, false)

		-- Any difference at all?
		else
			element:SetGroupIndex(element.Groups.HarmfulBoss, 1)
			element:SetGroupIndex(element.Groups.HelpfulBoss, 1)
			element:SetGroupIndex(element.Groups.HelpfulAllWhitelist, 1)
			element:SetGroupIndex(element.Groups.HelpfulPlayerWhitelist, 1)
			element:SetGroupIndex(element.Groups.HelpfulPlayer, 1)
			element:SetGroupIndex(element.Groups.HelpfulPlayerLong, 1)
			element:SetGroupIndex(element.Groups.HelpfulNotPlayerLong, 1)
			element:SetGroupIndex(element.Groups.HarmfulPlayer, 1)
			element:SetGroupIndex(element.Groups.HarmfulAllNotPlayer, 1)
			element:SetGroupIndex(element.Groups.HarmfulAllWhitelist, 1)
			element:SetGroupIndex(element.Groups.HarmfulAllDurationless, 1)

			element:SetAuraGroupEnabled(element.Groups.HarmfulBoss, true)
			element:SetAuraGroupEnabled(element.Groups.HelpfulBoss, true)
			element:SetAuraGroupEnabled(element.Groups.HelpfulAllWhitelist, true)
			element:SetAuraGroupEnabled(element.Groups.HelpfulNotPlayerLong, true)
			element:SetAuraGroupEnabled(element.Groups.HarmfulPlayer, true)
			element:SetAuraGroupEnabled(element.Groups.HarmfulAllWhitelist, true)

			element:SetAuraGroupEnabled(element.Groups.HelpfulPlayerWhitelist, false)
			element:SetAuraGroupEnabled(element.Groups.HelpfulPlayer, false)
			element:SetAuraGroupEnabled(element.Groups.HelpfulPlayerLong, false)
			element:SetAuraGroupEnabled(element.Groups.HarmfulAllNotPlayer, false)
			element:SetAuraGroupEnabled(element.Groups.HarmfulAllDurationless, false)
		end

	-- Friendly unit
	else
		-- Prioritize your helpful running auras
		-- Show harmful running DoTs
		if (inCombat) then
			element:SetGroupIndex(element.Groups.HarmfulBoss, 1)
			element:SetGroupIndex(element.Groups.HelpfulBoss, 1)
			element:SetGroupIndex(element.Groups.HelpfulAllWhitelist, 1)
			element:SetGroupIndex(element.Groups.HelpfulPlayerWhitelist, 1)
			element:SetGroupIndex(element.Groups.HelpfulPlayer, 1)
			element:SetGroupIndex(element.Groups.HelpfulPlayerLong, 1)
			element:SetGroupIndex(element.Groups.HelpfulNotPlayerLong, 1)
			element:SetGroupIndex(element.Groups.HarmfulPlayer, 1)
			element:SetGroupIndex(element.Groups.HarmfulAllNotPlayer, 1)
			element:SetGroupIndex(element.Groups.HarmfulAllWhitelist, 1)
			element:SetGroupIndex(element.Groups.HarmfulAllDurationless, 1)

			element:SetAuraGroupEnabled(element.Groups.HarmfulBoss, true)
			element:SetAuraGroupEnabled(element.Groups.HelpfulBoss, true)
			element:SetAuraGroupEnabled(element.Groups.HelpfulAllWhitelist, true)
			element:SetAuraGroupEnabled(element.Groups.HelpfulPlayerWhitelist, true)
			element:SetAuraGroupEnabled(element.Groups.HelpfulPlayer, true)
			element:SetAuraGroupEnabled(element.Groups.HarmfulAllNotPlayer, true)
			element:SetAuraGroupEnabled(element.Groups.HarmfulAllWhitelist, true)

			element:SetAuraGroupEnabled(element.Groups.HelpfulPlayerLong, false)
			element:SetAuraGroupEnabled(element.Groups.HelpfulNotPlayerLong, false)
			element:SetAuraGroupEnabled(element.Groups.HarmfulPlayer, false)
			element:SetAuraGroupEnabled(element.Groups.HarmfulAllDurationless, false)

		else
			element:SetGroupIndex(element.Groups.HarmfulBoss, 1)
			element:SetGroupIndex(element.Groups.HelpfulBoss, 1)
			element:SetGroupIndex(element.Groups.HelpfulAllWhitelist, 1)
			element:SetGroupIndex(element.Groups.HelpfulPlayerWhitelist, 1)
			element:SetGroupIndex(element.Groups.HelpfulPlayer, 1)
			element:SetGroupIndex(element.Groups.HelpfulNotPlayerLong, 1)
			element:SetGroupIndex(element.Groups.HelpfulPlayerLong, 1)
			element:SetGroupIndex(element.Groups.HarmfulPlayer, 1)
			element:SetGroupIndex(element.Groups.HarmfulAllNotPlayer, 1)
			element:SetGroupIndex(element.Groups.HarmfulAllWhitelist, 1)
			element:SetGroupIndex(element.Groups.HarmfulAllDurationless, 1)

			element:SetAuraGroupEnabled(element.Groups.HarmfulBoss, true)
			element:SetAuraGroupEnabled(element.Groups.HelpfulBoss, true)
			element:SetAuraGroupEnabled(element.Groups.HelpfulAllWhitelist, true)
			element:SetAuraGroupEnabled(element.Groups.HelpfulPlayerWhitelist, true)
			element:SetAuraGroupEnabled(element.Groups.HelpfulPlayerLong, true)
			element:SetAuraGroupEnabled(element.Groups.HelpfulNotPlayerLong, true)
			element:SetAuraGroupEnabled(element.Groups.HarmfulAllNotPlayer, true)

			element:SetAuraGroupEnabled(element.Groups.HelpfulPlayer, false)
			element:SetAuraGroupEnabled(element.Groups.HarmfulPlayer, false)
			element:SetAuraGroupEnabled(element.Groups.HarmfulAllWhitelist, false)
			element:SetAuraGroupEnabled(element.Groups.HarmfulAllDurationless, false)
		end
	end
end

-- Toggle cast text color on protected casts.
local Castbar_PostCastInterruptible = function(element, unit)
	if (element.notInterruptible) then
		element.Text:SetTextColor(element.__owner.colors.normal:GetRGB())
		element.Text:SetAlpha(.75)
	else
		element.Text:SetTextColor(element.__owner.colors.highlight:GetRGB())
		element.Text:SetAlpha(.5)
	end
end

-- Toggle cast info and health info when castbar is visible.
local Castbar_PostUpdateTexts = function(element)
	if (element:IsShown()) then
		element.Text:Show()
		element.Time:Show()
		element.__owner.Health.Value:Hide()
		element.__owner.Health.ValuePercent:Hide()
	else
		element.Text:Hide()
		element.Time:Hide()
		element.__owner.Health.Value:Show()
		element.__owner.Health.ValuePercent:Show()
	end
end

-- Custom castbar update to get our flipped textures
local Castbar_OnUpdate = function(element, elapsed)
	if (not element.__owner:IsEnabled()) then return end

	local name = UnitCastingInfo(element.__owner.__unit)
	if (name) then
		local durationObject = element:GetTimerDuration()
		local perc = durationObject:GetElapsedPercent(0)

		element.Texture:SetTexCoord(perc, 0, 0, 1)
		element.Texture:Show()
	else
		name = UnitChannelInfo(element.__owner.__unit)
		if (name) then
			local durationObject = element:GetTimerDuration()
			local perc = durationObject:GetRemainingPercent(0)

			element.Texture:SetTexCoord(perc, 0, 0, 1) 
			element.Texture:Show()
		else
			return element.Texture:Hide()
		end
	end
end

if (not ns.WoWCamelot and not ns.WoWMainline) then 
	Castbar_OnUpdate = function(self, elapsed)

		local duration
		if(self.casting or self.channeling or self.empowering) then

			local isCasting = self.casting or self.empowering
			if(isCasting) then

				duration = self.duration + elapsed

				self.duration = duration

				if(duration >= self.max) then
					local spellID = self.spellID

					self.castID = nil
					self.casting = nil
					self.channeling = nil
					self.empowering = nil
					self.isTradeSkill = nil
					self.notInterruptible = nil
					self.spellID = nil
					self.spellName = nil
					self.tradeSkillCastID = nil

					for _, pip in next, self.Pips do
						pip:Hide()
					end

					self:Hide()

					if(self.PostCastStop) then
						self:PostCastStop(self.__owner.__unit, spellID)
					end

					return
				end

				local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(self.__owner.__unit, spellID)
				if (ns.WoWVanilla) then
					notInterruptible = false
				end

				endTime = endTime * 0.001
				startTime = startTime * 0.001

				local delta
				if(self.channeling) then
					delta = self.startTime - startTime

					self.duration = endTime - GetTime()
				else
					delta = startTime - self.startTime

					self.duration = GetTime() - startTime
				end

				if(delta < 0) then
					delta = 0
				end	

				local perc = self.duration / (endTime - startTime) -- cast

				self.Texture:SetTexCoord(perc, 0, 0, 1)
			else

				duration = self.duration - elapsed

				self.duration = duration

				if(duration <= 0) then
					local spellID = self.spellID

					self.castID = nil
					self.casting = nil
					self.channeling = nil
					self.empowering = nil
					self.isTradeSkill = nil
					self.notInterruptible = nil
					self.spellID = nil
					self.spellName = nil
					self.tradeSkillCastID = nil

					for _, pip in next, self.Pips do
						pip:Hide()
					end

					self:Hide()

					if(self.PostCastStop) then
						self:PostCastStop(self.__owner.__unit, spellID)
					end

					return
				end

				local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = UnitChannelInfo(self.__owner.__unit, spellID)
				if (ns.WoWVanilla) then
					notInterruptible = false
				end

				endTime = endTime * 0.001
				startTime = startTime * 0.001

				local delta
				if(self.channeling) then
					delta = self.startTime - startTime

					self.duration = endTime - GetTime()
				else
					delta = startTime - self.startTime

					self.duration = GetTime() - startTime
				end

				if(delta < 0) then
					delta = 0
				end	

				local perc = self.duration / (endTime - startTime) 

				self.Texture:SetTexCoord(perc, 0, 0, 1)
			end

		elseif(self.holdTime > 0) then
			self.holdTime = self.holdTime - elapsed

			self:SetMinMaxValues(0, 1)
			self:SetValue(1)

			if(self.Time) then
				self.Time:SetText('')
			end
		else
			self.castID = nil
			self.casting = nil
			self.channeling = nil
			self.empowering = nil
			self.isTradeSkill = nil
			self.notInterruptible = nil
			self.spellID = nil
			self.spellName = nil
			self.tradeSkillCastID = nil

			for _, pip in next, self.Pips do
				pip:Hide()
			end

			self:Hide()
		end
	end
end

-- Update NPC classification badge for rares, elites and bosses.
local Classification_Update = function(self, event, unit, ...)
	if (unit and unit ~= self.__unit) then return end

	local element = self.Classification
	unit = unit or self.__unit

	if (UnitIsPlayer(unit)) then
		return element:Hide()
	end
	local l = UnitEffectiveLevel(unit)
	local c = (l and l < 1) and "worldboss" or UnitClassification(unit)
	if (c == "boss" or c == "worldboss") then
		element:SetTexture(element.bossTexture)
		element:Show()

	elseif (c == "elite") then
		element:SetTexture(element.eliteTexture)
		element:Show()

	elseif (c == "rare" or c == "rareelite") then
		element:SetTexture(element.rareTexture)
		element:Show()
	else
		element:Hide()
	end
end

-- API magic to reverse the bar texture.
local Health_OnValueChanged = function(element, val) 
	if (val) then
		-- This returns the health as a value from 0 to 1. 
		local perc = UnitHealthPercent(element.__owner.__unit, true, CurveConstants.ZeroToOne)
		element.Texture:SetTexCoord(perc, 0, 0, 1)
	else
		element.Texture:SetTexCoord(1, 0, 0, 1)
	end
end

-- Forward color updates to our flipped health bar texture
local Health_PostUpdateColor = function(element, unit, color)
	if (color) then
		element.Texture:SetVertexColor(color:GetRGB())
	end
end

-- Make the portrait look better for offline or invisible units.
local Portrait_PostUpdate = function(element, unit, hasStateChanged)
	if (not element.state) then
		element:ClearModel()
		if (not element.fallback2DTexture) then
			element.fallback2DTexture = element:CreateTexture()
			element.fallback2DTexture:SetDrawLayer("ARTWORK")
			element.fallback2DTexture:SetAllPoints()
			element.fallback2DTexture:SetTexCoord(.1, .9, .1, .9)
		end
		SetPortraitTexture(element.fallback2DTexture, unit)
		element.fallback2DTexture:Show()
	else
		if (element.fallback2DTexture) then
			element.fallback2DTexture:Hide()
		end
		element:SetCamDistanceScale(element.distanceScale or 1)
		element:SetPortraitZoom(1)
		element:SetPosition(element.positionX or 0, element.positionY or 0, element.positionZ or 0)
		element:SetRotation(element.rotation and element.rotation*degToRad or 0)
		element:ClearModel()
		element:SetUnit(unit)
		element.guid = guid
	end
end

-- Hide power crystal when no power exists.
local Power_UpdateVisibility = function(element, unit, cur, min, max)
	if (UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit)) then
		element:Hide()
		element.Backdrop:Hide()
		element.Value:Hide()
	else
		element:Show()
		element.Backdrop:Show()
		element.Value:Show()
		if (element.alphaCurve) then
			local ptype = UnitPowerType(unit)  -- Safe (non-secret)
			local color = UnitPowerPercent(unit, ptype, true, element.alphaCurve)  -- Secret-safe!
			local _, _, _, a = color:GetRGBA()  -- Safe number!
			element:SetAlpha(a)
		end
	end
end

-- Only show Horde/Alliance badges,
-- keep this hidding for rare-, elite- and boss NPCs.
local PvPIndicator_Override = function(self, event, unit)
	if (unit and unit ~= self.__unit) then return end

	local element = self.PvPIndicator
	unit = unit or self.__unit

	local l = UnitEffectiveLevel(unit)
	local c = (l and l < 1) and "worldboss" or UnitClassification(unit)
	if (c == "boss" or c == "worldboss" or c == "elite" or c == "rare") then
		return element:Hide()
	end

	local status
	local factionGroup = UnitFactionGroup(unit) or "Neutral"
	if (factionGroup ~= "Neutral") then
		if (UnitIsPVPFreeForAll(unit)) then
		else
			local isPvP = UnitIsPVP(unit)
			if (not issecretvalue(isPvP) and isPvP) then
				if (ns.IsRetail and UnitIsMercenary(unit)) then
					if (factionGroup == "Horde") then
						factionGroup = "Alliance"
					elseif (factionGroup == "Alliance") then
						factionGroup = "Horde"
					end
				end
				status = factionGroup
			end
		end
	end

	if (status) then
		element:SetTexture(element[status])
		element:Show()
	else
		element:Hide()
	end
end

-- Update target indicator texture.
local TargetIndicator_Update = function(self, event, unit, ...)
	if (unit and unit ~= self.__unit) then return end

	local element = self.TargetIndicator
	unit = unit or self.__unit

	-- if we are targeting ourselves, hide the targeting eye
	if (UnitIsUnit(unit, "player")) then
		return element:Hide()
	end

	-- get the ToT unit
	local tot = unit .. "target" 

	-- if our target is hostile
	if (UnitExists(tot) and UnitCanAttack("player", unit)) then

		-- if our hostile target is targeting us
		if (UnitIsUnit(tot, "player")) then
			element:SetTexture(element.enemyTexture)

		-- if our hostile target is targeting our pet 
		elseif (UnitIsUnit(tot, "pet")) then
			element:SetTexture(element.petTexture)
		else
			return element:Hide()
		end

	-- if our target is friendly and targeting us
	elseif (UnitIsUnit(tot, "player")) then
		element:SetTexture(element.friendTexture)
	else
		return element:Hide()
	end

	element:Show()
end

local TargetIndicator_Start = function(self)
	local targetIndicator = self.TargetIndicator
	if (not targetIndicator.Ticker) then
		targetIndicator.Ticker = C_Timer.NewTicker(.1, function() TargetIndicator_Update(self) end)
	end
end

local TargetIndicator_Stop = function(self)
	local targetIndicator = self.TargetIndicator
	if (targetIndicator.Ticker) then
		targetIndicator.Ticker:Cancel()
		targetIndicator.Ticker = nil
		targetIndicator:Hide()
	end
end

local UnitFrame_PostUpdate = function(self, event, unit, ...)
	Classification_Update(self, event, unit, ...)
	TargetIndicator_Update(self, event, unit, ...)
	TargetIndicator_Start(self)
end

-- Primarily needed to update orb/crystal visibilities
local UnitFrame_OnEvent = function(self, event, unit, ...)
	self.Power:ForceUpdate()
	UnitFrame_PostUpdate(self, event, unit, ...)
end

-- Setup the unitframe
local style = function(self, unit)

	-- General frame settings
	self:SetSize(550, 160) -- 550, 210
	self:SetHitRectInsets(0, 0, 0, 60)
	self:SetFrameLevel(self:GetFrameLevel() + 10)
	self:SetAllParentPoints()
	self:RegisterMouseScripts()

	-- Frame for font Overlays
	local overlay = CreateFrame("Frame", nil, self)
	overlay:SetFrameLevel(self:GetFrameLevel() + 7)
	overlay:SetAllPoints()

	-- Health bar
	--------------------------------------------
	local health = CreateFrame("StatusBar", nil, self)
	health:SetSize(385, 40) -- 385, 37
	health:SetPoint("TOPRIGHT", -140, -66)
	health:SetStatusBarTexture(GetMedia("hp_cap_bar")) 
	health:GetStatusBarTexture():SetAlpha(0) -- hide the bar tex, not the bar
	health:SetReverseFill(true)

	local healthTex = health:CreateTexture(nil, "ARTWORK", nil, 0)
	healthTex:SetSize(385, 40)
	healthTex:SetAllPoints(health:GetStatusBarTexture())
	healthTex:SetTexture(GetMedia("hp_cap_bar"))
	healthTex:SetTexCoord(1, 0, 0, 1)

	-- Health backdrop
	local healthBg = health:CreateTexture(nil, "BORDER", nil, 0)
	healthBg:SetSize(716, 188)
	healthBg:SetPoint("TOPRIGHT", self, "TOPRIGHT", 23, 8)
	healthBg:SetTexture(GetMedia("hp_cap_case"))
	healthBg:SetTexCoord(1, 0, 0, 1) -- Horizontally flip the texture
	healthBg:SetVertexColor(self.colors.ui:GetRGB())

	-- Health overlay for fonts and icons
	local healthOverlay = CreateFrame("Frame", nil, overlay)
	healthOverlay:SetAllPoints(health)

	-- Health Value
	local healthValue = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	healthValue:SetPoint("RIGHT", -27, 4)
	healthValue:SetFontObject(GetFont(18, true))
	healthValue:SetTextColor(self.colors.highlight:GetRGB())
	healthValue:SetAlpha(.5)
	healthValue:SetJustifyH("RIGHT")
	healthValue:SetJustifyV("MIDDLE")

	self:Tag(healthValue, "[azui:shorthealth]")

	local healthPerc = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	healthPerc:SetPoint("LEFT", 27, 4)
	healthPerc:SetFontObject(GetFont(18, true))
	healthPerc:SetTextColor(self.colors.highlight:GetRGB())
	healthPerc:SetAlpha(.4)
	healthPerc:SetJustifyH("LEFT")
	healthPerc:SetJustifyV("MIDDLE")

	self:Tag(healthPerc, "[azui:healthpercent]")

	-- Options
	health.colorDisconnected = true
	health.colorTapping = true
	health.colorThreat = true
	health.colorClass = true
	health.colorReaction = true

	-- This does not work with our reversed bars yet. 
	--health.smoothing = Enum.StatusBarInterpolation.ExponentialEaseOut -- Make the bar move smoothly 

	-- Register it with oUF
	self.Health = health
	self.Health.Value = healthValue
	self.Health.ValuePercent = healthPerc
	self.Health.Texture = healthTex
	self.Health.UpdateColor = ns.Health_UpdateColor
	self.Health.PostUpdateColor = Health_PostUpdateColor

	-- Apply scripts that update our reversed bar texture.
	self.Health:SetScript("OnValueChanged", Health_OnValueChanged)
	
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
	combatFeedback.colors = oUF.colors.combatfeedback 
	combatFeedback.maxAlpha = .9

	self.CombatFeedback = combatFeedback

	-- Overlayed Castbar
	--------------------------------------------
	local castbar = CreateFrame("StatusBar", nil, self)
	castbar:SetFrameLevel(self:GetFrameLevel() + 5)
	castbar:SetStatusBarTexture(GetMedia("blank"))
	castbar:GetStatusBarTexture():SetVertexColor(0, 0, 0, 0)
	castbar:SetReverseFill(true)
	castbar:SetAllPoints(self.Health)
	castbar:SetSize(self.Health:GetSize())

	local castbarTex = castbar:CreateTexture(nil, "ARTWORK", nil, 0)
	castbarTex:SetTexture(GetMedia("hp_cap_bar_highlight"))
	castbarTex:SetVertexColor(1, 1, 1, .35)  
	castbarTex:SetTexCoord(1, 0, 0, 1)
	castbarTex:SetBlendMode("ADD")
	castbarTex:SetAllPoints(castbar:GetStatusBarTexture()) -- this is the trick to avoiding math on secret values

	-- Cast Name
	local castName = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	castName:SetPoint("RIGHT", -27, 4)
	castName:SetSize(250, 40)
	castName:SetFontObject(GetFont(16, true))
	castName:SetTextColor(self.colors.highlight:GetRGB())
	castName:SetAlpha(.5)
	castName:SetJustifyH("RIGHT")
	castName:SetJustifyV("MIDDLE")
	castName:Hide()

	-- Cast Time
	-- *Not showing for anybody but the player unit in Midnight?
	local castbarTime = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	castbarTime:SetPoint("LEFT", 27, 4)
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
	self.Castbar.Texture = castbarTex
	self.Castbar.Text = castName
	self.Castbar.Time = castbarTime
	--self.Castbar.OnUpdate = (not ns.WoWCamelot and not ns.WoWMainline) and onUpdate
	self.Castbar.PostCastInterruptible = Castbar_PostCastInterruptible

	-- Power Crystal
	--------------------------------------------
	-- *why did I create so many frames and layers here? 

	local power = CreateFrame("StatusBar", nil, self)
	power:SetFrameLevel(self:GetFrameLevel() + 5)
	--power:GetStatusBarTexture():SetDrawLayer("BACKGROUND", -6)
	power:SetPoint("TOPRIGHT", 8, -58)
	power:SetSize(80, 80)
	power:SetOrientation("VERTICAL")
	power:SetStatusBarTexture(GetMedia("power_crystal_small_front"))
	power:SetAlpha(.75)
	power.alphaCurve = createAlphaCurve(0,1)
	power.frequentUpdates = true
	power.displayAltPower = true
	power.colorPower = true

	local powerBackdrop = power:CreateTexture(nil, "BACKGROUND", nil, 0)
	powerBackdrop:SetPoint("CENTER", 0, 0)
	powerBackdrop:SetSize(80, 80)
	powerBackdrop:SetTexture(GetMedia("power_crystal_small_back"))
	powerBackdrop:SetVertexColor(1, 1, 1, .85)

	local powerValue = power:CreateFontString(nil, "OVERLAY", nil, 0)
	powerValue:SetPoint("CENTER", 0, -5)
	powerValue:SetJustifyH("CENTER")
	powerValue:SetJustifyV("MIDDLE")
	powerValue:SetFontObject(GetFont(14, true))
	powerValue:SetTextColor(self.colors.highlight:GetRGB())
	powerValue:SetAlpha(.5)

	self:Tag(powerValue, "[azui:shortpower]")

	self.Power = power
	self.Power.Value = powerValue
	self.Power.Backdrop = powerBackdrop
	self.Power.PostUpdate = Power_UpdateVisibility

	-- Portrait
	--------------------------------------------
	local portraitFrame = CreateFrame("Frame", nil, self)
	portraitFrame:SetFrameLevel(self:GetFrameLevel() - 2)
	portraitFrame:SetAllPoints()

	local portrait = CreateFrame("PlayerModel", nil, portraitFrame)
	portrait:SetFrameLevel(portraitFrame:GetFrameLevel())
	portrait:SetPoint("TOPRIGHT", -40, -31)
	portrait:SetSize(85, 85)
	portrait:SetAlpha(.85)

	local portraitBg = portraitFrame:CreateTexture(nil, "BACKGROUND", nil, 0)
	portraitBg:SetPoint("TOPRIGHT", 3, 16)
	portraitBg:SetSize(173, 173)
	portraitBg:SetTexture(GetMedia("party_portrait_back"))
	portraitBg:SetVertexColor(.5, .5, .5)

	local portraitOverlayFrame = nil
	portraitOverlayFrame = CreateFrame("Frame", nil, self, "PingReceiverAttributeTemplate")

	if (ns.WoWMainline or ns.WoWCamelot) then
		Mixin(portraitOverlayFrame, PingableTypeMixin)
	end

	portraitOverlayFrame.GetContextualPingType = function(self) return PingUtil:GetContextualPingTypeForUnit(self:GetTargetPingGUID()) end
	portraitOverlayFrame.GetTargetPingGUID = function(self) return UnitGUID(unit) end
	portraitOverlayFrame:SetFrameLevel(self:GetFrameLevel() - 1)
	portraitOverlayFrame:SetAllPoints()

	local portraitShade = portraitOverlayFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
	portraitShade:SetPoint("TOPRIGHT", -30, -18)
	portraitShade:SetSize(107, 107)
	portraitShade:SetTexture(GetMedia("shade-circle"))

	local portraitBorder = portraitOverlayFrame:CreateTexture(nil, "BACKGROUND", nil, 0)
	portraitBorder:SetPoint("TOPRIGHT", 10, 22)
	portraitBorder:SetSize(187, 187)
	portraitBorder:SetTexture(GetMedia("portrait_frame_hi"))
	portraitBorder:SetVertexColor(self.colors.ui:GetRGB())

	self.Portrait = portrait
	self.Portrait.Bg = portraitBg
	self.Portrait.Shade = portraitShade
	self.Portrait.Border = portraitBorder
	self.Portrait.PostUpdate = Portrait_PostUpdate

	-- PvP Indicator Badge
	--------------------------------------------
	local PvPIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, -2)
	PvPIndicator:SetSize(84, 84)
	PvPIndicator:SetPoint("TOPRIGHT", -41, -91)
	PvPIndicator.Alliance = GetMedia("icon_badges_alliance")
	PvPIndicator.Horde = GetMedia("icon_badges_horde")

	self.PvPIndicator = PvPIndicator
	self.PvPIndicator.Override = PvPIndicator_Override

	-- Classification Badge
	--------------------------------------------
	local classification = overlay:CreateTexture(nil, "OVERLAY", nil, -2)
	classification:SetSize(84, 84)
	classification:SetPoint("TOPRIGHT", -41, -91)
	classification.bossTexture = GetMedia("icon_badges_boss")
	classification.eliteTexture = GetMedia("icon_classification_elite")
	classification.rareTexture = GetMedia("icon_classification_rare")

	self.Classification = classification

	-- Target Indicator
	--------------------------------------------
	local targetIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, -2)
	targetIndicator:SetPoint("TOPRIGHT", -75, -3)
	targetIndicator:SetSize(96, 48)
	targetIndicator:SetVertexColor(self.colors.ui:GetRGB())
	targetIndicator.petTexture = GetMedia("icon_target_blue")
	targetIndicator.enemyTexture = GetMedia("icon_target_red")
	targetIndicator.friendTexture = GetMedia("icon_target_green")

	self.TargetIndicator = targetIndicator

	-- Unit Name
	--------------------------------------------
	local name = self:CreateFontString(nil, "OVERLAY", nil, 1)
	name:SetPoint("TOPRIGHT", -153, -21)
	name:SetFontObject(GetFont(16, true))
	name:SetTextColor(self.colors.highlight:GetRGB())
	name:SetAlpha(.75)
	name:SetJustifyH("RIGHT")
	name:SetJustifyV("TOP")

	self:Tag(name, "[azui:name(32)][azui:level(false,true)]")

	self.Name = name

	-- RaidTarget Indicator
	--------------------------------------------
	local raidTargetIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, 2)
	raidTargetIndicator:SetSize(32, 32)
	raidTargetIndicator:SetPoint("RIGHT", self.Name, "LEFT", -2, 2)
	raidTargetIndicator:SetTexture(GetMedia("raid_target_icons"))

	self.RaidTargetIndicator = raidTargetIndicator

	-- Auras
	--------------------------------------------
	if (ns.WoWMainline or ns.WoWCamelot) then

		-- Little hack to avoid "stuck" numbers on auras with no duration
		local binding = C_DurationUtil.CreateDurationTextBinding()
		binding:SetZeroDurationText("") -- clears the stuck number
		binding:SetExpiredText("") -- optional, for fully expired
		--binding:SetFormatter(...) -- if you want custom formatting
		--binding:SetUpdateInterval(0.1) -- optional

		local auras = self:CreateAurasElement()
		auras:SetSize(316, 76)
		auras:SetPoint("TOPRIGHT", -150, -126)

		-- Enable some sub-widgets
		auras.durationBinding = binding
		auras.showCount = true
		auras.showDuration = true
		auras.showBuffBorder = false

		-- Group options
		auras.size = 36
		auras.elementSpacing = 4 -- Spacing between each button (number) 
		auras.forceNewLine = false -- Whether to force a new row or column between each group (boolean)
		auras.groupSpacing = 4 -- Spacing between each group (number) 
		auras.groupLineSpacing = 4 -- Spacing between each group row or column 
		auras.lineSpacing = 4 -- Spacing between each button row or column (number) 
		auras.maxFrameCount = 8 -- Number of buttons to display. Defaults to an infinite number (number)
		auras.sortDirection = AuraContainerSortDirection.Reverse
		auras.sortMethod = AuraContainerSortMethod.ExpirationOnly 

		-- Aura Groups
		-- *named and referenced for easy enabling/disabling
		auras.Groups = {

			-- Out of Combat Buff display

			-- Boss Auras, always top priority
			HarmfulBoss = Auras_AddGroup(auras, "HARMFUL", { layoutIndex = 1, candidateFilters = { isBossAura = true } }),
			HelpfulBoss = Auras_AddGroup(auras, "HELPFUL", { layoutIndex = 2, candidateFilters = { isBossAura = true } }),

			-- Whitelisted buffs from anybody
			HelpfulAllWhitelist = Auras_AddGroup(auras, "HELPFUL", { layoutIndex = 10, candidateFilters = { includeSpellIDs = { 

			}}}),

			-- Whitelisted player selfbuffs
			HelpfulPlayerWhitelist = Auras_AddGroup(auras, "HELPFUL|PLAYER", { layoutIndex = 11, candidateFilters = { includeSpellIDs = {
				-- limited to auras marked NotSecretEnum.SecrecyLevel.NeverSecret
			}}}),

			-- Regular player selfbuffs, with spammy stuff blacklisted
			HelpfulPlayer = Auras_AddGroup(auras, "HELPFUL|PLAYER", { layoutIndex = 12, candidateFilters = { maxDuration = 60, excludeSpellIDs = {

			}}}),

			-- Helpful buffs, long duration
			HelpfulPlayerLong = Auras_AddGroup(auras, "HELPFUL|PLAYER", { layoutIndex = 12, candidateFilters = { maxDuration = 3600, excludeSpellIDs = {

			}}}),

			-- Non-player buffs, with spammy stuff blacklisted
			HelpfulNotPlayerLong = Auras_AddGroup(auras, "HELPFUL|!PLAYER", { layoutIndex = 14, candidateFilters = { maxDuration = 3600, excludeSpellIDs = {

			}}}),

			-- Whitelisted harmful auras
			HarmfulAllWhitelist = Auras_AddGroup(auras, "HARMFUL", { layoutIndex = 100, candidateFilters = { includeSpellIDs = {
				-- limited to auras marked NotSecretEnum.SecrecyLevel.NeverSecret
			}}}),

			-- No duration harmful auras (lava on the floor, etc)
			HarmfulAllDurationless = Auras_AddGroup(auras, "HARMFUL", { layoutIndex = 101, candidateFilters = { maxDuration = 0, excludeSpellIDs = {

			}}}),

			HarmfulPlayer = Auras_AddGroup(auras, "HARMFUL|PLAYER", { layoutIndex = 12, candidateFilters = { maxDuration = 60, excludeSpellIDs = {

			}}}),

			-- Non-player harmful auras
			HarmfulAllNotPlayer = Auras_AddGroup(auras, "HARMFUL|!PLAYER", { layoutIndex = 102, candidateFilters = { maxDuration = 60, excludeSpellIDs = {

			}}})
		}

		self.Auras = auras
		self.Auras.PostUpdate = Auras_PostUpdate
		self.Auras.SetGroupIndex = Auras_SetGroupIndex
	end

	-- General post update
	self.PostUpdate = UnitFrame_PostUpdate

	-- Callbacks
	--------------------------------------------
	self:RegisterEvent("PLAYER_ENTERING_WORLD", UnitFrame_OnEvent, true)
	self:RegisterEvent("PLAYER_TARGET_CHANGED", UnitFrame_OnEvent, true)
	self:RegisterEvent("PLAYER_FOCUS_CHANGED", UnitFrame_OnEvent, true)

end

Target.GetDefaults = function(self)
	return defaults
end

Target.GetOptions = function(self)
	return {
		type = "group",
		name = L["Target Unit Frame"],
		arg = { menuName = L["Target"] },
		order = 220,
		args = {
			enable = {
				type = "toggle", width = "full",
				name = L["Enable"],
				desc = L["Toggle the usage of this Unit Frame. Note that disabling this does not re-enable the game's default Unit Frames."],
				disabled = function() return InCombatLockdown() end,
				get = function(info) return self.db.profile.enabled end,
				set = function(info, val) 
					if InCombatLockdown() then return end
					self.db.profile.enabled = val 
					self:UpdateSettings()
				end,
				order = 2
			},
		}
	}
end

-- Return the unitframe
Target.GetFrame = function(self)
	return self.frame
end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling and combat end.
Target.UpdateSettings = function(self)
	if (InCombatLockdown()) then return end

	local frame = self:GetFrame()
	if (not frame) then return end

	if (self.db.profile.enabled) then
		if (not frame:IsEnabled()) then
			frame:Enable() -- watch this, maybe I need to rehook the castbar script. doesn't look like it so far.
		end
	else
		if (frame:IsEnabled()) then
			frame:Disable()
		end
	end
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
Target.RefreshConfig = function(self)
	self:UpdateSettings()
end

Target.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("Target", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	-- Every now and then we need a spring cleaning
	for i in next,self.db.profile do
		if (defaults.profile[i] == nil) then
			self.db.profile[i] = nil
		end
	end
end

Target.OnEnable = function(self)
	oUF:RegisterStyle("AzeriteUnitFrameTarget", style)	
	oUF:Factory(function(self) 
		self:SetActiveStyle("AzeriteUnitFrameTarget")

		local frame = self:Spawn("target", "AzeriteUnitFrameTarget")
		frame:SetScale(.9)
		frame:SetPoint("TOPRIGHT", -40/.9, -40/.9)

		Target.frame = frame

		Target:RegisterMovableFrameAnchor(frame, string.lower(TARGET), "unitframes", AzeriteUI6_Positions_DB)
		Target:UpdateSettings()

		-- It's gotten increasingly hard to track a cast or update a castbar, 
		-- and oUF have restricted external access to a lot of information. 
		Target.frame.Castbar:HookScript("OnUpdate", Castbar_OnUpdate) -- hook it after creation
	end)
end
