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
local oUF = ns.oUF

local ToT = ns:NewModule("ToT", nil, "LibMoreEvents-1.0", "LibMovableFrames-1.0")

-- Declare module defaults
local defaults = { 
	profile = {
		hideWhenTargetingPlayer = true,
		hideWhenTargetingSelf = true
	}
}

-- Custom API locals
local AbbreviateNumber = ns.AbbreviateNumber
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia

-- Safely compare units
local AreUnitsSame = function(u1, u2)
	local g1 = UnitGUID(u1)
	local g2 = UnitGUID(u2)

	-- Bail if different secrecy levels (can't be equal, avoids mixed == error)
	if (issecretvalue(g1) ~= issecretvalue(g2)) then
		return false
	end

	-- Now safe: both non-secret or both secret
	return g1 == g2
end

-- Update targeting highlight outline
local TargetHighlight_PostUpdate = function(self, event, unit, ...)
	if (unit and unit ~= self.unit) then return end

	local element = self.TargetHighlight
	unit = unit or self.unit

	if (AreUnitsSame(unit, "focus")) then
		element:Show()
	else
		element:Hide()
	end

end

-- Hide the ToT frame under certain conditions using alpha
local Unitframe_PostUpdateAlpha = function(self, event, unit, ...)
	if (unit and unit ~= self.unit) then return end

	unit = unit or self.unit

	if (ToT.db.profile.hideWhenTargetingPlayer and AreUnitsSame(unit, "player"))
	or (ToT.db.profile.hideWhenTargetingSelf and AreUnitsSame(unit, unit.."target")) then
		self:SetAlpha(0)
	else
		self:SetAlpha(1)
	end
end

local UnitFrame_OnEvent = function(self, event, unit, ...)
	if (unit and unit ~= self.unit) then return end

	Unitframe_PostUpdateAlpha(self, event, unit, ...)
	TargetHighlight_PostUpdate(self, event, unit, ...)
end

local style = function(self, unit)

		-- General frame settings
	self:SetSize(136, 47)
	self:SetFrameLevel(self:GetFrameLevel() + 10)

	ns.ApplyUnitFrameScriptsTo(self)

	-- Frame for font Overlays
	local overlay = CreateFrame("Frame", nil, self)
	overlay:SetFrameLevel(self:GetFrameLevel() + 7)
	overlay:SetAllPoints()

	self.Overlay = overlay

	-- Health bar
	--------------------------------------------
	local health = CreateFrame("StatusBar", nil, self)
	health:SetFrameLevel(health:GetFrameLevel() + 2)
	health:SetPoint("CENTER", 0, 0)
	health:SetSize(113, 14)
	health:SetStatusBarTexture(GetMedia("cast_bar"))

	-- Options
	health.colorDisconnected = true
	health.colorTapping = true
	health.colorThreat = true
	health.colorClass = true
	health.colorReaction = true

	local healthBackdrop = health:CreateTexture(nil, "BACKGROUND", nil, -1)
	healthBackdrop:SetPoint("CENTER", 2, -1)
	healthBackdrop:SetSize(193, 93)
	healthBackdrop:SetTexture(GetMedia("cast_back"))
	healthBackdrop:SetVertexColor(self.colors.ui:GetRGB())

	-- Health Value
	local healthValue = health:CreateFontString(nil, "OVERLAY", nil, 1)
	healthValue:SetPoint("CENTER", 0, 0)
	healthValue:SetFontObject(GetFont(14, true))
	healthValue:SetTextColor(self.colors.offwhite:GetRGB())
	healthValue:SetAlpha(.75)
	healthValue:SetJustifyH("CENTER")
	healthValue:SetJustifyV("MIDDLE")

	self:Tag(healthValue, "[azui:shorthealth]")

	self.Health = health
	self.Health.Value = healthValue
	self.Health.Backdrop = healthBackdrop

	-- Cast bar
	--------------------------------------------
	local castbar = CreateFrame("StatusBar", nil, self)
	castbar:SetAllPoints(health)
	castbar:SetSize(113, 14)
	castbar:SetFrameLevel(health:GetFrameLevel() + 1)
	castbar:SetStatusBarTexture(GetMedia("cast_bar"))
	castbar:SetStatusBarColor(1, 1, 1, .5)
	castbar:Hide() -- does this bar even work for ToT anymore?

	self.Castbar = castbar

	-- Unit Name
	--------------------------------------------
	local name = self:CreateFontString(nil, "OVERLAY", nil, 1)
	name:SetPoint("BOTTOM", 0, 46)
	name:SetFontObject(GetFont(13, true))
	name:SetTextColor(self.colors.highlight:GetRGB())
	name:SetAlpha(.75)
	name:SetJustifyH("RIGHT")
	name:SetJustifyV("TOP")

	self:Tag(name, "[azui:name(24)]")

	self.Name = name

	-- RaidTarget Indicator
	--------------------------------------------
	local raidTargetIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, 2)
	raidTargetIndicator:SetSize(24, 24)
	raidTargetIndicator:SetPoint("RIGHT", self.Name, "LEFT", 0, 0)
	raidTargetIndicator:SetTexture(GetMedia("raid_target_icons_small"))

	self.RaidTargetIndicator = raidTargetIndicator

	-- Target highlight
	--------------------------------------------
	local targetHighlight = overlay:CreateTexture(nil, "BACKGROUND", nil, -2)
	targetHighlight:SetPoint("CENTER", 1, -2)
	targetHighlight:SetSize(193,93)
	targetHighlight:SetTexture(GetMedia("cast_back_outline"))
	targetHighlight:SetVertexColor(144/255, 195/255, 255/255) -- only focus highlighting

	self.TargetHighlight = targetHighlight

	-- Midnight-compatible ToT watcher
	local ToTWatcher = CreateFrame("Frame")
	ToTWatcher.unit = unit
	ToTWatcher.frame = self
	-- None of these appears to be passed to unittarget unitframes,
	-- so we need a regular frame to monitor them. 
	-- No idea why oUFs methods don't work for this anymore.
	ToTWatcher:RegisterEvent("PLAYER_TARGET_CHANGED")
	ToTWatcher:RegisterEvent("PLAYER_FOCUS_CHANGED")
	ToTWatcher:RegisterUnitEvent("UNIT_TARGET", "target")
	ToTWatcher:SetScript("OnEvent", function(self, event, unit, ...)
		UnitFrame_OnEvent(self.frame, event, self.unit, ...)
	end)

end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling and combat end.
ToT.UpdateSettings = function(self)
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
ToT.RefreshConfig = function(self)
	self:UpdateSettings()
end

ToT.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("ToT", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

ToT.OnEnable = function(self)
	oUF:RegisterStyle("AzeriteUnitFrameTargetTarget", style)	
	oUF:Factory(function(self) 
		self:SetActiveStyle("AzeriteUnitFrameTargetTarget")

		local frame = self:Spawn("targettarget")
		frame:SetScale(.9)
		frame:SetPoint("TOPRIGHT", -446/.9, -66/.9)

		ToT:RegisterMovableFrameAnchor(frame, string.lower(SHOW_TARGET_OF_TARGET_TEXT), "unitframes", AzeriteUI6_Positions_DB):SetAbove(true)
	end)
end
