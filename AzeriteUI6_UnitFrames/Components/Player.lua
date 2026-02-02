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

-- Custom locals
local GetMedia = ns.GetMedia

-- Setup the unitframe
local style = function(self, unit)

	-- General frame settings
	self:SetSize(560, 180)
	self:SetHitRectInsets(0, 0, 30, -2)

	-- Health bar
	local health = CreateFrame("StatusBar", nil, self)
	health:SetSize(385, 40)
	health:SetPoint("BOTTOMLEFT", 148, 27)
	health:SetStatusBarTexture(GetMedia("hp_cap_bar"))
	health:SetStatusBarColor(245/255, 0/255, 45/255)
	health:SetReverseFill(false)

	-- Health backdrop
	local healthBg = health:CreateTexture(nil, "BORDER", nil, 0)
	healthBg:SetSize(716, 188)
	healthBg:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", -17, -48)
	healthBg:SetTexture(GetMedia("hp_cap_case"))
	healthBg:SetVertexColor(192/255, 192/255, 192/255)

	-- Options
	health.colorTapping = false
	health.colorDisconnected = false
	health.colorClass = false
	health.colorReaction = false
	health.colorHealth = false

	-- Register it with oUF
	self.Health = health

	-- Overlayed castbar
	local cast


	-- Power crystal
	local power = CreateFrame("StatusBar", nil, self)
	power:SetSize(120,140)
	power:SetPoint("BOTTOMLEFT", 20, 38)
	power:SetStatusBarTexture(GetMedia("blank"))
	--power:SetAlpha(0)

	-- Power crystal backdrop
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
