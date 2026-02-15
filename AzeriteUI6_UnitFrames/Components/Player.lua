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
local defaults = { profile = {} }

-- Custom API locals
local AbbreviateNumber = ns.AbbreviateNumber
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia

-- Setup the unitframe
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

	-- Health Value
	local healthValue = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	healthValue:SetPoint("LEFT", 27, 4)
	healthValue:SetFontObject(GetFont(18, true))
	healthValue:SetTextColor(250/255, 250/255, 250/255, .5)
	healthValue:SetJustifyH("LEFT")
	healthValue:SetJustifyV("MIDDLE")

	local hMin, hMax
	health:SetScript("OnMinMaxChanged", function(self, min, max) 
		hMin, hMax = min, max
		-- Do we actually need to do anything more here? 
	end)

	-- This will be called when the value changes, 
	-- and it's allowed access to min/max/cur values of the bar.
	-- This script handler is one of the only ones that are allowed to do that in WoW12.
	health:SetScript("OnValueChanged", function(self, val) 
		if (val and hMax) then
			healthValue:SetText(hMax > 0 and AbbreviateNumber(val) or "")
		else
			healthValue:SetText("")
		end
	end)

	-- Options
	health.colorTapping = false
	health.colorDisconnected = false
	health.colorClass = false
	health.colorReaction = false
	health.colorHealth = false

	-- Register it with oUF
	self.Health = health
	self.Health.Value = healthValue


	-- Health Prediction
	--------------------------------------------
	-- This looks really bad in retail now.
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

	local damageAbsorb = CreateFrame("StatusBar", nil, self.Health)
	damageAbsorb:SetFrameLevel(self.Health:GetFrameLevel() + 3)
	damageAbsorb:SetStatusBarTexture(GetMedia("blank"))
	--damageAbsorb:SetStatusBarTexture(GetMedia("hp_cap_bar"))
	--damageAbsorb:SetStatusBarColor(1, 1, 1, .35)
	damageAbsorb:SetSize(386, 40)
	--damageAbsorb:SetPoint("TOP", self.Health, "TOP")
	--damageAbsorb:SetPoint("BOTTOM", self.Health, "BOTTOM")
	--damageAbsorb:SetPoint("RIGHT", self.Health, "RIGHT")
	damageAbsorb:SetAllPoints(self.Health)
	damageAbsorb:SetReverseFill(true)

	-- Fake absorb texture, needed for reversed bars
	local damageAbsorbTex = damageAbsorb:CreateTexture(nil, "ARTWORK", nil, 0)
	damageAbsorbTex:SetPoint("BOTTOM", 0, 0)
	damageAbsorbTex:SetPoint("RIGHT", 0, 0)
	damageAbsorbTex:SetPoint("TOP", 0, 0)
	damageAbsorbTex:SetTexture(GetMedia("hp_cap_bar"))
	damageAbsorbTex:SetVertexColor(1, 1, 1, .35)

	local aMin, aMax
	damageAbsorb:SetScript("OnMinMaxChanged", function(self, min, max) 
		aMin, aMax = min, max
		-- Do we actually need to do anything more here? 
	end)

	-- This will be called when the value changes, 
	-- and it's allowed access to min/max/cur values of the bar.
	-- This script handler is one of the only ones that are allowed to do that in WoW12.
	damageAbsorb:SetScript("OnValueChanged", function(self, val) 
		if (val and aMax) then
			--absorbValue:SetText(aMax > 0 and AbbreviateNumber(val) or "")
			damageAbsorbTex:SetTexCoord((aMax-val)/aMax, 1, 0, 1)
			damageAbsorbTex:SetPoint("LEFT", (aMax-val)/aMax * 386, 0)
		else
			--absorbValue:SetText("")
		end
	end)

	-- Register with oUF
	self.HealthPrediction = {
		--healingAll = healingAll, 
		damageAbsorb = damageAbsorb,
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

	-- Register it with oUF
	self.Castbar = castbar


	-- Power Crystal
	--------------------------------------------
	local power = CreateFrame("StatusBar", nil, self)
	power:SetSize(120,140)
	power:SetPoint("BOTTOMLEFT", 20, 38)
	power:SetStatusBarTexture(GetMedia("blank"))
	power:GetStatusBarTexture():SetVertexColor(0, 0, 0, 0) -- hide statusbar tex, not the bar

	-- Power Crystal backdrop
	local powerBg = power:CreateTexture(nil, "BACKGROUND", nil, -7)
	powerBg:SetSize(196, 196)
	powerBg:SetPoint("CENTER", 0, 0)
	powerBg:SetTexture(GetMedia("power-crystal-ice-back"))
	--powerBg:SetTexture(GetMedia("power_crystal_back"))
	--powerBg:SetIgnoreParentAlpha(true)

	-- Fake powerbar texture, needed for our vertical bars
	local powerTex = power:CreateTexture(nil, "BACKGROUND", nil, -6)
	powerTex:SetPoint("BOTTOM", 0, 0)
	powerTex:SetPoint("LEFT", 0, 0)
	powerTex:SetPoint("RIGHT", 0, 0)
	powerTex:SetPoint("TOP", 0, 0)
	powerTex:SetTexture(GetMedia("power-crystal-ice-front")) 
	--powerTex:SetTexture(GetMedia("power_crystal_front"))
	--powerTex:SetVertexColor(0/255, 208/255, 176/255) 
	--powerTex:SetIgnoreParentAlpha(true)
	powerTex:SetTexCoord(50/255, 206/255, 37/255, 219/255)

	local pMin, pMax
	power:SetScript("OnMinMaxChanged", function(self, min, max) 
		pMin, pMax = min, max
		-- Do we actually need to do anything more here? 
	end)

	-- This will be called when the value changes, 
	-- and it's allowed access to min/max/cur values of the bar.
	-- This script handler is one of the only ones that are allowed to do that in WoW12.
	power:SetScript("OnValueChanged", function(self, val) 
		if (val and pMax) then
			powerTex:SetTexCoord(50/255, 206/255, 37/255 + (1 - val/pMax)*((219-37)/255), 219/255)
			powerTex:SetPoint("TOP", 0, (- (pMax-val)/pMax * 140))
		end
	end)

	-- Power foreground. The "case" of the power crystal.
	local powerFg = power:CreateTexture(nil, "BACKGROUND", nil, -5)
	powerFg:SetSize(198,98)
	powerFg:SetPoint("BOTTOM", 7, -51)
	powerFg:SetTexture(GetMedia("pw_crystal_case"))
	powerFg:SetVertexColor(192/255, 192/255, 192/255)
	--powerFg:SetIgnoreParentAlpha(true)

	-- Options
	power.colorPower = false -- true to follow default coloring, false to never modify
	power.displayAltPower = true -- allow this to be used for altpower from quests and various
	power.frequentUpdates = true -- update often

	-- Register it with oUF
	self.Power = power


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
