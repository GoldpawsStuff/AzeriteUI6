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

local Pet = ns:NewModule("Pet", nil, "LibMoreEvents-1.0")

-- Declare module defaults
local defaults = { profile = {}}
local db -- will be assigned a utility function returning the profile settings/defaults during initialization

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
		element:SetVertexColor(144/255, 195/255, 255/255)
		element:Show()
	elseif (AreUnitsSame(unit, "target")) then
		element:SetVertexColor(255/255, 239/255, 169/255)
		element:Show()
	else
		element:Hide()
	end

end

local UnitFrame_OnEvent = function(self, event, unit, ...)
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
	health:SetStatusBarColor(self.colors.healthdark:GetRGB())
	health.colorHealth = false -- true

	local healthBackdrop = health:CreateTexture(nil, "BACKGROUND", nil, -1)
	healthBackdrop:SetPoint("CENTER", 2, -1)
	healthBackdrop:SetSize(193, 93)
	healthBackdrop:SetTexture(GetMedia("cast_back"))
	healthBackdrop:SetVertexColor(self.colors.uidark:GetRGB())

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
	castbar:SetFrameLevel(self:GetFrameLevel() + 5)
	castbar:SetStatusBarTexture(GetMedia("cast_bar"))
	castbar:SetStatusBarColor(1, 1, 1, .5)

	self.Castbar = castbar

	-- Target highlight
	--------------------------------------------
	local targetHighlight = overlay:CreateTexture(nil, "BACKGROUND", nil, -2)
	targetHighlight:SetPoint("CENTER", 1, -2)
	targetHighlight:SetSize(193,93)
	targetHighlight:SetTexture(GetMedia("cast_back_outline"))

	self.TargetHighlight = targetHighlight

	-- Textures need an update when frame is displayed.
	self.PostUpdate = TargetHighlight_PostUpdate

	-- Register events to handle additional texture updates.
	self:RegisterEvent("PLAYER_ENTERING_WORLD", UnitFrame_OnEvent, true)
	self:RegisterEvent("PLAYER_TARGET_CHANGED", UnitFrame_OnEvent, true)
	self:RegisterEvent("PLAYER_FOCUS_CHANGED", UnitFrame_OnEvent, true)

end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling and combat end.
Pet.UpdateSettings = function(self)
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
Pet.RefreshConfig = function(self)
	self:UpdateSettings()
end

Pet.OnInitialize = function(self)
	-- Let's not do these until the addon is more stable
	--self.db = ns.db:RegisterNamespace("Pet", defaults)
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

Pet.OnEnable = function(self)
	oUF:RegisterStyle("AzeriteUnitFramePet", style)
	oUF:Factory(function(self) 
		self:SetActiveStyle("AzeriteUnitFramePet") -- Set the current oUF style

		-- Note that this is the default position,
		-- it will be overwritten by saved positions.
		local frame = self:Spawn("pet")
		frame:SetPoint("BOTTOMLEFT", 362, 102)

		--frame.Enable = function(self)
		--	RegisterAttributeDriver(self, "unit", "[vehicleui]player; pet")
		--	RegisterAttributeDriver(self, "state-visibility", "[@pet,exists]show;hide")
		--end

		--frame.Disable = function(self)
		--	UnregisterAttributeDriver(self, "unit")
		--	UnregisterAttributeDriver(self, "state-visibility")
		--	self:Hide()
		--end

		-- Disable WoWs own handling
		--UnregisterUnitWatch(frame)
		--frame:SetAttribute("toggleForVehicle", false)

	end)
end
