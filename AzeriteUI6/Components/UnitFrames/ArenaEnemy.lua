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

local Arena = ns:NewModule("Arena", nil, "LibMoreEvents-1.0", "LibMovableFrames-1.0")

-- In-code testing switch.
-- Set to true to force all arena frames onto the player unit for layout work.
-- Must be false (or removed) before shipping.
local USE_DUMMY_FRAMES = true

-- Declare module defaults
local defaults = { profile = {
	enabled = true,
}}

-- Custom API locals
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia

-- Apply or clear dummy unit override
local ApplyDummyState = function(frame, enable)
	if (InCombatLockdown()) then return end

	if (enable) then
		if (not frame.__realunit) then
			frame.__realunit = frame:GetAttribute("unit") or frame.unit
		end
		frame:SetAttribute("unit", "player")
		frame.unit = "player"
		frame:Show()
		frame:UpdateAllElements("Dummy")
	else
		if (frame.__realunit) then
			frame:SetAttribute("unit", frame.__realunit)
			frame.unit = frame.__realunit
			frame.__realunit = nil
		end
		-- Let oUF visibility handle the rest
		frame:Hide()
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

-- Style function
-- Styling is intentionally minimal here — I'll expand this later.
local style = function(self, unit)

	-- Basic secure frame setup
	self:SetSize(210, 86)
	self:SetFrameLevel(self:GetFrameLevel() + 10)
	self:SetAllParentPoints()
	self:RegisterMouseScripts()

	-- Frame for font Overlays
	local overlay = CreateFrame("Frame", nil, self)
	overlay:SetFrameLevel(self:GetFrameLevel() + 7)
	overlay:SetAllPoints()

	-- Health
	--------------------------------------------
	local health = CreateFrame("StatusBar", nil, self)
	health:SetSize(113, 14)
	health:SetPoint("LEFT", 26, -13)
	health:SetStatusBarTexture(GetMedia("cast_bar"))
	health:GetStatusBarTexture():SetAlpha(0) -- hide the bar tex, not the bar
	health:SetStatusBarColor(.2, .8, .2)
	health:SetReverseFill(true)

	health.colorDisconnected = true
	health.colorClass = true
	health.colorReaction = true
	health.colorHealth = true
	health.frequentUpdates = true

	local healthBg = health:CreateTexture(nil, "BACKGROUND", nil, -1)
	healthBg:SetPoint("CENTER", 1, -2)
	healthBg:SetSize(193,93)
	healthBg:SetTexture(GetMedia("cast_back"))
	healthBg:SetVertexColor(self.colors.ui:GetRGB())

	local healthTex = health:CreateTexture(nil, "ARTWORK", nil, 0)
	healthTex:SetSize(113, 14)
	healthTex:SetAllPoints(health:GetStatusBarTexture())
	healthTex:SetTexture(GetMedia("cast_bar"))
	healthTex:SetTexCoord(1, 0, 0, 1)

	self.Health = health
	self.Health.Backdrop = healthBg
	self.Health.Texture = healthTex
	self.Health.UpdateColor = ns.Health_UpdateColor
	self.Health.PostUpdateColor = Health_PostUpdateColor

	-- Apply scripts that update our reversed bar texture.
	self.Health:SetScript("OnValueChanged", Health_OnValueChanged)

	-- Power
	--------------------------------------------
	local power = CreateFrame("StatusBar", nil, self)
	power:SetSize(98, .75)
	power:SetPoint("LEFT", 34, -22)
	power:SetStatusBarTexture([[Interface\ChatFrame\ChatFrameBackground]])
	power:SetAlpha(.65)
	power.colorPower = true
	power.frequentUpdates = true

	local powerBg = power:CreateTexture(nil, "BACKGROUND", nil, -1)
	powerBg:SetPoint("CENTER", 0, 0)
	powerBg:SetSize(102.4, 2.4)
	powerBg:SetTexture([[Interface\ChatFrame\ChatFrameBackground]])
	powerBg:SetVertexColor(0, 0, 0, 1)
	
	self.Power = power
	self.Power.Backdrop = powerBg

	-- Name
	--------------------------------------------
	local name = overlay:CreateFontString(nil, "OVERLAY")
	name:SetPoint("RIGHT", -82, 13)
	name:SetFontObject(GetFont(11, true))
	name:SetJustifyH("RIGHT")
	name:SetJustifyV("BOTTOM")
	name:SetTextColor(self.colors.highlight:GetRGB())
	name:SetAlpha(.75)
	
	self:Tag(name, "[name]")
	
	self.Name = name

	-- Portrait
	--------------------------------------------
	local portraitFrame = CreateFrame("Frame", nil, self)
	portraitFrame:SetFrameLevel(self:GetFrameLevel() - 2)
	portraitFrame:SetAllPoints()

	local portrait = portraitFrame:CreateTexture(nil, "ARTWORK", nil, 1)
	portrait:SetPoint("LEFT", 146, 0)
	portrait:SetSize(46, 47)
	portrait:SetAlpha(.85)
	portrait.showClass = true -- class icons instead of portraits

	local portraitBg = portraitFrame:CreateTexture(nil, "BACKGROUND", nil, 0)
	portraitBg:SetPoint("LEFT", 128, 0)
	portraitBg:SetSize(87, 87)
	portraitBg:SetTexture(GetMedia("party_portrait_back"))
	portraitBg:SetVertexColor(.5, .5, .5, .75)

	local portraitOverlayFrame = nil -- ?
	portraitOverlayFrame = CreateFrame("Frame", nil, self, "PingReceiverAttributeTemplate")

	if (ns.WoWMainline or ns.WoWCamelot) then
		Mixin(portraitOverlayFrame, PingableTypeMixin)
	end

	portraitOverlayFrame.GetContextualPingType = function(self) return PingUtil:GetContextualPingTypeForUnit(self:GetTargetPingGUID()) end
	portraitOverlayFrame.GetTargetPingGUID = function(self) return UnitGUID(unit) end
	portraitOverlayFrame:SetFrameLevel(self:GetFrameLevel() - 1)
	portraitOverlayFrame:SetAllPoints()

	local portraitShade = portraitOverlayFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
	portraitShade:SetPoint("LEFT", 142, 0)
	portraitShade:SetSize(58, 58)
	portraitShade:SetTexture(GetMedia("shade-circle"))

	local portraitBorder = portraitOverlayFrame:CreateTexture(nil, "BACKGROUND", nil, 0)
	portraitBorder:SetPoint("LEFT", 106, 0)
	portraitBorder:SetSize(130, 130)
	portraitBorder:SetTexture(GetMedia("party_portrait_border"))
	portraitBorder:SetVertexColor(self.colors.ui:GetRGB())

	self.Portrait = portrait
	self.Portrait.Bg = portraitBg
	self.Portrait.Shade = portraitShade
	self.Portrait.Border = portraitBorder

	-- CombatFeedback
	--------------------------------------------
	local combatFeedback = overlay:CreateFontString(nil, "OVERLAY", nil, 7)
	combatFeedback:SetPoint("CENTER", portrait, "CENTER", 0, 0)
	combatFeedback:SetJustifyH("CENTER")
	combatFeedback:SetJustifyV("MIDDLE")

	-- Options
	combatFeedback.feedbackFont = GetFont(20, true)
	combatFeedback.feedbackFontLarge = GetFont(24, true)
	combatFeedback.feedbackFontSmall = GetFont(18, true)
	combatFeedback.colors = oUF.colors.combatfeedback 
	combatFeedback.maxAlpha = .9

	self.CombatFeedback = combatFeedback

	-- Optional: keep a reference so dummy mode can force updates
	self.__arenaIndex = tonumber(unit:match("%d+"))
end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling and combat end.
Arena.UpdateSettings = function(self)
	if (not self.frames) then return end

end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
Arena.RefreshConfig = function(self)
	self:UpdateSettings()
end

Arena.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("Arena", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	-- Clean obsolete keys
	for key in next, self.db.profile do
		if (defaults.profile[key] == nil) then
			self.db.profile[key] = nil
		end
	end
end

Arena.OnEnable = function(self)
	oUF:RegisterStyle("AzeriteUnitFrameArena", style)

	oUF:Factory(function(oUF)
		oUF:SetActiveStyle("AzeriteUnitFrameArena")

		local anchor = CreateFrame("Frame", nil, UIParent)
		anchor:SetSize(210, 86*5 + 12*4)
		anchor:SetPoint("RIGHT", -60/.9, 0/.9)

		local frames = {}
		local previous

		for i = 1, 5 do
			local unit = "arena" .. i
			local frame = oUF:Spawn(unit, "AzeriteUnitFrameArena" .. i)

			if (i == 1) then
				frame:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", 0, 0)
			else
				frame:SetPoint("TOP", previous, "BOTTOM", 0, -12)
			end

			frames[i] = frame
			previous = frame

			-- Apply dummy override immediately if requested
			--if (USE_DUMMY_FRAMES) then
			--	ApplyDummyState(frame, true)
			--end
		end

		local SetScale = anchor.SetScale
		anchor.SetScale = function(self, scale)
			if (InCombatLockdown()) then return end
			SetScale(self, scale)
			for i,frame in next,frames do
				frame:SetScale(scale)
			end
		end
		anchor:SetScale(.9)

		Arena.frames = frames

		Arena:RegisterMovableFrameAnchor(anchor, "arena", "unitframes", AzeriteUI6_Positions_DB)
		Arena:UpdateSettings()
	end)

	-- Optional slash command for runtime toggle while testing
	-- Remove or comment out before shipping if you don't want it.
	if (USE_DUMMY_FRAMES) then
		SLASH_AZARENATEST1 = "/azarenatest"
		SlashCmdList.AZARENATEST = function()
			local enable = not Arena.frames[1].__realunit
			for i = 1, 5 do
				ApplyDummyState(Arena.frames[i], enable)
			end
			print("|cffffcc00AzeriteUI:|r Arena dummy frames " .. (enable and "enabled" or "disabled"))
		end
	end
end

