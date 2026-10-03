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

local MinimapModule = ns:NewModule("Minimap", nil, "LibMoreEvents-1.0", "LibFadingFrames-1.0")

-- Declare module defaults
local defaults = { profile = {
	fadeClutter = true
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
	MinimapCluster.BorderTop:SetParent(hider)
	MinimapCluster.DielFrame:SetParent(hider) -- contains day/night indicator
	MinimapCluster.Tracking:SetParent(hider)
	MinimapCluster.ZoneTextButton:SetParent(hider)
	Minimap.ZoomIn:SetParent(hider)
	Minimap.ZoomOut:SetParent(hider)
	MinimapCompassTexture:SetParent(hider)
	MinimapCompassTextureUnderlay:SetParent(hider)
	AddonCompartmentFrame:SetParent(hider)
	GameTimeFrame:SetParent(hider)
	TimeManagerClockButton:SetParent(hider)

	-- hide various banners and retail buttons too? figure out what they are!
	-- hide new retail coords, or move them inside the map

	-- Readjust stock coordinate text to match classic azerite position and size
	MinimapCluster.MinimapContainer.PlayerCoords:ClearAllPoints()
	MinimapCluster.MinimapContainer.PlayerCoords:SetPoint("BOTTOM", Minimap, "BOTTOM", 3, 23)
	MinimapCluster.MinimapContainer.PlayerCoords.CoordText:SetFontObject(GetFont(12, true))
	MinimapCluster.MinimapContainer.PlayerCoords.CoordText:SetTextColor(oUF.colors.offwhite:GetRGB())
	MinimapCluster.MinimapContainer.PlayerCoords.CoordText:SetAlpha(.75)

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
	
	--local north = MinimapBackdrop:CreateFontString(nil, "ARTWORK", nil, 1)
	--north:SetFontObject(GetFont(16,true))
	--north:SetTextColor(oUF.colors.normal:GetRGB())
	--north:SetAlpha(.75)
	--north:SetText("N")
	--north:SetPoint("TOP", MinimapCompassTexture, "TOP", 0, 0) -- ?

	--compass.north = north

	--self.compass = compass

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
	C_AddOns.LoadAddOn("Blizzard_TimeManager")

	self.db = ns.db:RegisterNamespace("Minimap", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end
