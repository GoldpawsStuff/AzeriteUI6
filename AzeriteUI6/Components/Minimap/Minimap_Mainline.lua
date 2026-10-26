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
local oUF = ns.oUF or oUF

local L = LibStub("AceLocale-3.0"):GetLocale((...))
local LibSpinBar = LibStub("LibSpinBar-1.0")
local MinimapModule = ns:NewModule("Minimap", nil, "LibMoreEvents-1.0", "LibFadingFrames-1.0")

-- Declare module defaults
local defaults = { profile = {
	fadeClutter = true,
	showXP = true
}}

-- Custom API locals
local AbbreviateNumber = ns.AbbreviateNumber
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia

local safecall = function(obj, method, ...)
    local f = obj and obj[method]
    if (type(f) == "function") then
        pcall(f, obj, ...)
    end
end

local Badge_FadeIn = function(self) 
	-- continue the fade
	if (self:IsMouseOver() or self.Ring:IsMouseOver()) then
		local oldAlpha = self.Ring:GetAlpha()
		local newAlpha = oldAlpha + 1/(self.fadeInDuration/self.fadeFreq)
		if (newAlpha < 1) then
			self.Ring:SetAlpha(newAlpha)
		else
			-- goal reached, set the final alpha and cancel timer
			self.Ring:SetAlpha(1)
			self.ringFadeDirection = nil
		end
	else
		-- kill this timer and change fade direction
		self:StartFadeOut()
	end
end

local Badge_FadeOut = function(self)
	-- kill this timer and change fade direction
	if (self:IsMouseOver() or self.Ring:IsMouseOver()) then
		self:StartFadeIn()
	else
		-- continue the fade
		local oldAlpha = self.Ring:GetAlpha()
		local newAlpha = oldAlpha - 1/(self.fadeOutDuration/self.fadeFreq)
		if (newAlpha > 0) then
			self.Ring:SetAlpha(newAlpha)
		else
			-- goal reached, set the final alpha and cancel timer
			self.Ring:SetAlpha(0)
			self.Ring:Hide() -- fully hide the frame
			self.ringFadeDirection = nil
		end
	end
end

local Badge_StartFadeIn = function(self)
	-- check for existing timers
	if (self.ringTimer) then 
		-- bail out if we already have the correct timer running
		if (self.ringFadeDirection == "IN") then
			return 
		end
		-- cancel the existing wrong timer
		self.ringTimer:Cancel()
	end
	-- start a new timer
	self.ringFadeDirection = "IN"
	self.ringTimer = C_Timer.NewTicker(1/30, function() self:FadeIn() end)
end

local Badge_StartFadeOut = function(self)
	-- check for existing timers
	if (self.ringTimer) then 
		-- bail out if we already have the correct timer running
		if (self.ringFadeDirection == "OUT") then
			return 
		end
		-- cancel the existing wrong timer
		self.ringTimer:Cancel()
	end
	-- start a new timer
	self.ringFadeDirection = "OUT"
	self.ringTimer = C_Timer.NewTicker(1/30, function() self:FadeOut() end)
end

local Badge_OnEnter = function(self)
	-- check if ring is visible
	if (not self.Ring:IsShown()) then
		self.Ring:SetAlpha(0)
		self.Ring:Show()
	end
	self:StartFadeIn()
end

local Badge_OnLeave = function(self)
	if (not self:IsMouseOver() and not self.Ring:IsMouseOver()) then
		self:StartFadeOut()
	end
end

-- Will this taint or create other problems now?
local Minimap_OnMouseUp = function(self, button)
	if (button == "MiddleButton") then
		MenuUtil.CreateContextMenu(self, MinimapCluster.Tracking.Button.menuGenerator)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "SFX")
	end
end

MinimapModule.StyleMinimap = function(self)

	-- create our custom border
	local borderFrame = CreateFrame("Frame", nil, Minimap)
	borderFrame:SetFrameLevel(Minimap:GetFrameLevel() + 10)
	borderFrame:SetAllPoints(Minimap)

	local borderTexture = borderFrame:CreateTexture(nil, "BORDER", nil, 5)
	borderTexture:SetTexture(GetMedia("minimap-border"))
	borderTexture:SetVertexColor(192/255, 192/255, 192/255)
	borderTexture:SetPoint("CENTER", -2, -2)
	borderTexture:SetSize(360,360)

	local hider = CreateFrame("Frame")
	hider:Hide()

	-- hide the clutter
	for _,element in next, {
		MinimapCluster.BorderTop, -- Retail
		MinimapCluster.DielFrame, -- Forever (contains day/night indicator)
		MinimapCluster.IndicatorFrame, -- Retail (MailFrame)
		MinimapCluster.Tracking,
		MinimapCluster.ZoneTextButton,
		Minimap.ZoomIn,
		Minimap.ZoomOut,
		MinimapCompassTexture,
		MinimapCompassTextureUnderlay, -- Forever
		AddonCompartmentFrame,
		GameTimeFrame,
		TimeManagerClockButton
	} do
		if (element) then 
			element:SetParent(hider)
		end
	end

	-- hide various banners and retail buttons too? figure out what they are!
	-- hide new retail coords, or move them inside the map

	-- Readjust stock coordinate text to match classic azerite position and size
	local coords = MinimapCluster.MinimapContainer.PlayerCoords -- Only in Forever (+Retail now)
	coords:ClearAllPoints()
	coords:SetPoint("BOTTOM", Minimap, "BOTTOM", 1, 24)

	local msg = coords.CoordText
	msg:SetFontObject(GetFont(11, true))
	msg:SetTextColor(oUF.colors.offwhite:GetRGB())
	msg:SetAlpha(.66)

	local holder = msg:GetParent()
	holder:SetParent(Minimap)

	-- get this out of the way
	MinimapCluster:EnableMouse(false)
	MinimapCluster:SetFrameLevel(1)

	-- Make the scalar rings slightly less horrible
	-- Also attempt to fix the outer blob ring appearing outside
	-- of the map bounds when having a rotating minimap.
	-- *this still doesn't work?
	safecall(Minimap, "SetQuestBlobRingScalar", 0) -- quests 
	safecall(Minimap, "SetQuestBlobRingAlpha", 0)
	safecall(Minimap, "SetArchBlobRingScalar", 0) -- archeology
	safecall(Minimap, "SetArchBlobRingAlpha", 0)
	safecall(Minimap, "SetTaskBlobRingScalar", 0) -- tasks / world quests
	safecall(Minimap, "SetTaskBlobRingAlpha", 0)

	-- these show outside the map when having a rotating map.
	-- this is a blizzard bug, and not something we currently can fix.
	if (GetCVarBool("rotateMinimap")) then 
		safecall(Minimap, "SetQuestBlobOutsideAlpha", 0) 
		safecall(Minimap, "SetArchBlobOutsideAlpha", 0) 
		safecall(Minimap, "SetTaskBlobOutsideAlpha", 0) 
	end

	-- add the tracking menu on middle-click
	-- *does this taint? seems dodgy
	Minimap:HookScript("OnMouseUp", Minimap_OnMouseUp)
	
	-- Mail
--	local mailFrame = CreateFrame("Button", nil, frame)
--	mailFrame:SetFrameLevel(mailFrame:GetFrameLevel() + 5)
--	mailFrame:SetScript("OnEnter", Mail_OnEnter)
--	mailFrame:SetScript("OnLeave", Mail_OnLeave)
--
--	local mail = frame:CreateFontString(nil, "OVERLAY", nil, 1)
--	mail.frame = mailFrame
--	mail:SetFontObject(GetFont(15, true))
--	mail:SetTextColor(oUF.colors.offwhite:GetRGB())
--	mail:SetAlpha(.85)
--	mail:SetJustifyH("CENTER")
--	mail:SetJustifyV("BOTTOM")
--	mail:SetFormattedText("%s", MAIL_LABEL)
--	mail:SetPoint("BOTTOM", 0, 30)
--	mailFrame:SetAllPoints(mail)
--
--	self.mail = mail
--
--	self:RegisterEvent("CVAR_UPDATE", "UpdateTimers")
--	self:RegisterEvent("UPDATE_PENDING_MAIL", "UpdateMail")
--	self:RegisterEvent("VARIABLES_LOADED", "OnEvent")

	-- XP bar
	------------------------------------------
	-- badge showing xp percent with hover functionality to show bars
	local badge = CreateFrame("Frame", nil, Minimap)
	badge:SetFrameStrata("HIGH")
	badge:SetFrameLevel(Minimap:GetFrameLevel() + 50)
	badge:SetSize(50, 50)
	badge:SetPoint("CENTER", Minimap, "BOTTOM", ns.WoWMainline and 2 or 0, -6*.9)
	badge.fadeInDuration = .3
	badge.fadeOutDuration = .1
	badge.fadeFreq = 1/30
	badge.ringTimer = nil
	badge.ringFadeDirection = nil

	-- badge backdrop
	local badgeBackdrop = badge:CreateTexture(nil, "BACKGROUND", nil, 1)
	badgeBackdrop:SetSize(90, 90)
	badgeBackdrop:SetPoint("CENTER", 0, 4)
	badgeBackdrop:SetTexture(GetMedia("point_plate"))
	badgeBackdrop:SetVertexColor(oUF.colors.ui:GetRGB())

	-- badge value showing percentage towards next level
	local badgeValue = badge:CreateFontString(nil, "OVERLAY", nil, 1)
	badgeValue:SetFontObject(GetFont(12, true)) -- 15
	badgeValue:SetPoint("CENTER", 1, 4)
	badgeValue:SetJustifyH("CENTER")
	badgeValue:SetJustifyV("MIDDLE")
	badgeValue:SetTextColor(oUF.colors.ui:GetRGB())
	badgeValue:SetAlpha(.75)

	-- ringframe containing backdrops and bars
	local ring = CreateFrame("Frame", nil, badge)
	ring:SetFrameStrata("MEDIUM")
	ring:SetSize(182, 182)
	ring:SetPoint("CENTER", Minimap, "CENTER", 0, -2)
	ring:SetAlpha(0)
	ring:Hide()

	-- ringframe backdrop
	local ringBackdrop = ring:CreateTexture(nil, "BACKGROUND", nil, 1)
	ringBackdrop:SetSize(352, 352)
	ringBackdrop:SetPoint("CENTER", -1, 0)
	ringBackdrop:SetTexture(GetMedia("minimap-onebar-backdrop"))
	ringBackdrop:SetVertexColor(oUF.colors.ui:GetRGB())

	-- xp bar
	local xp = LibSpinBar:CreateSpinBar(addonName.."XPBar", ring)
	xp:SetFrameLevel(ring:GetFrameLevel() + 5)
	xp:SetPoint("CENTER", -1, 1)
	xp:SetSize(182,182)
	xp:SetStatusBarTexture(GetMedia("minimap-bars-single"))
	xp:SetSparkOffset(-1/10) -- offset in degrees from the end of the bar to the spark
	xp:SetSparkInset(17) -- distance from outer diameter to start of spark
	xp:SetSparkSize(24,34) -- width = thickness along ring bar, height = length across
	xp:SetSparkFlash(nil, nil, 1, 1)
	xp:SetSparkBlendMode("ADD")
	xp:SetClockwise(true)
	xp:SetDegreeOffset(256) -- offset from top center in degrees to the start of the ring bar
	xp:SetDegreeSpan(332) -- degrees of the circle covered by the bar

	-- xp rested bonus bar
	local rested = LibSpinBar:CreateSpinBar(addonName.."XPBar", ring)
	rested:SetFrameLevel(ring:GetFrameLevel() + 2)
	rested:SetPoint("CENTER", -1, 1)
	rested:SetSize(182,182)
	rested:SetStatusBarTexture(GetMedia("minimap-bars-single"))
	rested:SetStatusBarColor(oUF.colors.restedBonus:GetRGB())
	rested:SetSparkOffset(-1/10) -- offset in degrees from the end of the bar to the spark
	rested:SetSparkInset(17) -- distance from outer diameter to start of spark
	rested:SetSparkSize(24,34) -- width = thickness along ring bar, height = length across
	rested:SetSparkFlash(nil, nil, 1, 1)
	rested:SetSparkBlendMode("ADD")
	rested:SetClockwise(true)
	rested:SetDegreeOffset(256) -- offset from top center in degrees to the start of the ring bar
	rested:SetDegreeSpan(332) -- degrees of the circle covered by the bar
	
	-- xp value text
	local ringValue = ring:CreateFontString(nil, "OVERLAY", nil, 1)
	ringValue:SetFontObject(GetFont(24, true))
	ringValue:SetPoint("CENTER", 0, 1)
	ringValue:SetJustifyH("CENTER")
	ringValue:SetJustifyV("MIDDLE")
	ringValue:SetTextColor(oUF.colors.ui:GetRGB())
	
	-- xp description text
	local ringDescription = ring:CreateFontString(nil, "OVERLAY", nil, 1)
	ringDescription:SetFontObject(GetFont(12, true))
	ringDescription:SetPoint("CENTER", 0, -16)
	ringDescription:SetWidth(90) -- uh
	ringDescription:SetJustifyH("CENTER")
	ringDescription:SetJustifyV("MIDDLE")
	ringDescription:SetTextColor(oUF.colors.quest.gray:GetRGB())

	self.XP = xp
	self.XP.Rested = rested
	self.XP.Description = ringDescription
	self.XP.Value = ringValue

	self.Badge = badge
	self.Badge.Backdrop = badgeBackdrop
	self.Badge.Value = badgeValue

	self.Badge.Ring = ring
	self.Badge.Ring.Backdrop = ringBackdrop

	self.Badge.FadeIn = Badge_FadeIn
	self.Badge.FadeOut = Badge_FadeOut
	self.Badge.StartFadeIn = Badge_StartFadeIn
	self.Badge.StartFadeOut = Badge_StartFadeOut

	self.Badge:SetScript("OnEnter", Badge_OnEnter)
	self.Badge:SetScript("OnLeave", Badge_OnLeave)

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateXP")
	self:RegisterEvent("PLAYER_XP_UPDATE", "UpdateXP")
	self:RegisterEvent("PLAYER_LEVEL_UP", "UpdateXP")
	self:RegisterEvent("UPDATE_EXHAUSTION", "UpdateXP")

	-- Only exists in Retail
	if (ns.WoWMainline) then
		self:RegisterEvent("ENABLE_XP_GAIN", "UpdateXP")
		self:RegisterEvent("DISABLE_XP_GAIN", "UpdateXP")
	end
end

MinimapModule.UpdateXP = function(self, event, ...)
	if (event == "PLAYER_LEVEL_UP") then
		self.playerLevel = ...
	end
	if (not self.playerLevel) then
		self.playerLevel = UnitLevel("player")
	end

	-- At max level, just completely disable the widget
	if (self.playerLevel >= GetMaxPlayerLevel()) then 
		self.Badge:Hide() -- all other frames are parented to this

		-- kill off events, we don't need them anymore
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", "UpdateXP")
		self:UnregisterEvent("PLAYER_XP_UPDATE", "UpdateXP")
		self:UnregisterEvent("PLAYER_LEVEL_UP", "UpdateXP")
		self:UnregisterEvent("UPDATE_EXHAUSTION", "UpdateXP")

		-- Only exists in Retail
		if (ns.WoWMainline) then
			self:UnregisterEvent("ENABLE_XP_GAIN", "UpdateXP")
			self:UnregisterEvent("DISABLE_XP_GAIN", "UpdateXP")
		end

		return 
	end

	-- xp gains are disabled by the user
	if (event == "DISABLE_XP_GAIN" or IsXPUserDisabled()) then
		self.userDisabledXP = true
		self.Badge:Hide() 

		-- kill off xp tracking events
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", "UpdateXP")
		self:UnregisterEvent("PLAYER_XP_UPDATE", "UpdateXP")
		self:UnregisterEvent("PLAYER_LEVEL_UP", "UpdateXP")
		self:UnregisterEvent("UPDATE_EXHAUSTION", "UpdateXP")

		return
	end

	-- xp gains are enabled by the user
	if (event == "ENABLE_XP_GAIN" and self.userDisabledXP) then
		self.userDisabledXP = nil

		-- register tracking events
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateXP")
		self:RegisterEvent("PLAYER_XP_UPDATE", "UpdateXP")
		self:RegisterEvent("PLAYER_LEVEL_UP", "UpdateXP")
		self:RegisterEvent("UPDATE_EXHAUSTION", "UpdateXP")

		-- enable the badge
		self.Badge:Show()
	end

	local current = UnitXP("player")
    local max = UnitXPMax("player")
    local rested = GetXPExhaustion() or 0
    local percent = current / max * 100
	local r, g, b 

	if (rested > 0) then
		r, g, b = oUF.colors.rested:GetRGB()
	else
		r, g, b = oUF.colors.xp:GetRGB()
	end

	self.XP:SetMinMaxValues(0, max)
	self.XP:SetValue(current)
	self.XP:SetStatusBarColor(r, g, b)

	local restedShown = self.XP.Rested:IsShown()
	if (rested) then
		self.XP.Rested:SetMinMaxValues(0, max, not restedShown)
		self.XP.Rested:SetValue(math.min(max, current + rested), not restedShown)
		if (not restedShown) then
			self.XP.Rested:Show()
		end
	elseif (restedShown) then
		self.XP.Rested:Hide()
		self.XP.Rested:SetValue(0, true)
		self.XP.Rested:SetMinMaxValues(0, 1, true)
	end
	
	self.XP.Value:SetFormattedText("%s", AbbreviateNumber(max-current))
	self.XP.Description:SetFormattedText(L["to level %s"], self.playerLevel + 1)
	self.XP.Value:SetTextColor(r, g, b)
	self.Badge.Value:SetTextColor(r, g, b)

	local perc = math.floor(current/max*100)
	if (perc > 0) then
		self.Badge.Value:SetFormattedText("%.0f", perc)
	else
		self.Badge.Value:SetText(XP)
	end

end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling.
MinimapModule.UpdateSettings = function(self)
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
MinimapModule.RefreshConfig = function(self)
	self:UpdateSettings()
end

MinimapModule.OnEnable = function(self)
	self:StyleMinimap()
end

MinimapModule.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("Minimap", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end
