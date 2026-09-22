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

--LoadAddOn("Blizzard_TimeManager") -- still needed?

local MinimapModule = ns:NewModule("Minimap", nil, "LibMoreEvents-1.0", "LibMovableFrames-1.0", "LibFadingFrames-1.0", "AceTimer-3.0")

-- Declare module defaults
local defaults = { profile = {
	fadeClutter = true
}}

-- Custom API locals
local AbbreviateNumber = ns.AbbreviateNumber
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia

-- Constants
--local TORGHAST_ZONE_ID = 2162
--local IN_TORGHAST = (not IsResting()) and (GetRealZoneText() == GetRealZoneText(TORGHAST_ZONE_ID))

--local Minimap_OnMouseUp = function(self, button)
--	if (button == "MiddleButton") then
--		MenuUtil.CreateContextMenu(self, MinimapCluster.Tracking.Button.menuGenerator)
--		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "SFX")
--	end
--end

local Minimap_OnMouseUp = function(self, button)
	if (button == "RightButton") then
		if (ns.IsClassic or ns.IsTBC) then
			if (MinimapModule.ShowMinimapTrackingMenu) then
				MinimapModule:ShowMinimapTrackingMenu()
			end
		--elseif (ns.WoW11) then
		--	MenuUtil.CreateContextMenu(self, MinimapCluster.Tracking.Button.menuGenerator)
		else
			ToggleDropDownMenu(1, nil, _G[ns.Prefix.."MiniMapTrackingDropDown"], "cursor")
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "SFX")
		end

	elseif (button == "MiddleButton") then
		MenuUtil.CreateContextMenu(self, MinimapCluster.Tracking.Button.menuGenerator)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "SFX")

	--elseif (button == "MiddleButton" and ns.IsRetail) then
	--	local GLP = GarrisonLandingPageMinimapButton or ExpansionLandingPageMinimapButton
	--	if (GLP and GLP:IsShown()) and (not InCombatLockdown()) then
	--		if (GLP.ToggleLandingPage) then
	--			GLP:ToggleLandingPage()
	--		else
	--			GarrisonLandingPage_Toggle()
	--		end
	--	end
	else
		local func = Minimap.OnClick or Minimap_OnClick
		if (func) then
			func(self)
		end
	end
end

local Minimap_OnMouseWheel = function(self, delta)
	if (delta > 0) then
		(Minimap.ZoomIn or MinimapZoomIn):Click()
	elseif (delta < 0) then
		(Minimap.ZoomOut or MinimapZoomOut):Click()
	end
end

local Mail_OnEnter = function(self)
	if (GameTooltip:IsForbidden()) then return end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)

	-- Add unread mail notifier.
	local sender1, sender2, sender3 = GetLatestThreeSenders()
	if (sender1 or sender2 or sender3) then
		GameTooltip:AddLine(HAVE_MAIL_FROM, unpack(ns.Colors.highlight))
		if (sender1) then
			GameTooltip:AddLine(sender1, unpack(oUF.colors.green))
		end
		if (sender2) then
			GameTooltip:AddLine(sender2, unpack(oUF.colors.green))
		end
		if (sender3) then
			GameTooltip:AddLine(sender3, unpack(oUF.colors.green))
		end
	else
		GameTooltip:AddLine(L_HAVE_MAIL, unpack(oUF.colors.highlight))
	end

	-- Add crafting order notifier.
	--if (ns.IsRetail) and (self.countInfos and #self.countInfos > 0) then
	--	GameTooltip:AddLine(" ")
	--	GameTooltip:AddLine(MAILFRAME_CRAFTING_ORDERS_TOOLTIP_TITLE)
	--	for _,countInfo in ipairs(mail.countInfos) do
	--		GameTooltip:AddLine(string.format(PERSONAL_CRAFTING_ORDERS_AVAIL_FMT, countInfo.numPersonalOrders, countInfo.professionName))
	--	end
	--end

	GameTooltip:Show()
end

local Mail_OnLeave = function(self)
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:Hide()
end

MinimapModule.StyleMinimap = function(self)

	local mapScale = 198/140 -- 1 in retail, larger in classics
	local hider = CreateFrame("Frame")
	hider:Hide()

	--MinimapCluster:EnableMouse(false)
	MinimapCluster:SetFrameLevel(1)

	Minimap:SetMaskTexture(ns.GetMedia("minimap-mask-transparent"))
	--Minimap:SetMovable(true)
	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", Minimap_OnMouseWheel)
	Minimap:SetScript("OnMouseUp", Minimap_OnMouseUp) -- HookScript? Will SetScript taint?

	-- hide the clutter
	MinimapCluster.BorderTop:SetParent(hider)
	--MinimapCluster.Tracking:SetParent(hider)
	MinimapCluster.ZoneTextButton:SetParent(hider)
	MinimapBackdrop:SetParent(hider)
	MinimapBorder:SetParent(hider)
	MinimapZoomIn:SetParent(hider)
	MinimapZoomOut:SetParent(hider)
	MinimapCompassTexture:SetParent(hider)
	MinimapToggleButton:SetParent(hider)
	--AddonCompartmentFrame:SetParent(hider)
	GameTimeFrame:SetParent(hider)
	TimeManagerClockButton:SetParent(hider)

	-- create our custom backdrop
	-- *not showing up?
	local backdropFrame = CreateFrame("Frame", nil, Minimap)
	backdropFrame:SetFrameLevel(Minimap:GetFrameLevel())

	local backdrop = backdropFrame:CreateTexture(nil, "BACKGROUND", nil, -7)
	--backdrop:SetIgnoreParentScale(true)
	backdrop:SetScale(1/mapScale)
	backdrop:SetTexture(ns.GetMedia("minimap-mask-opaque"))
	backdrop:SetVertexColor(0, 0, 0, .75)
	backdrop:SetSize(198,198)
	backdrop:SetPoint("CENTER", Minimap, "CENTER")

	-- create our custom border
	local borderFrame = CreateFrame("Frame", nil, Minimap)
	--borderFrame:SetIgnoreParentScale(true)
	borderFrame:SetScale(1/mapScale)
	--borderFrame:SetFrameLevel(Minimap:GetFrameLevel() + 10)
	borderFrame:SetPoint("CENTER")
	borderFrame:SetSize(398,398)
	--borderFrame:SetAllPoints()

	local borderTexture = borderFrame:CreateTexture(nil, "BORDER", nil, 5)
	borderTexture:SetTexture(GetMedia("minimap-border"))
	borderTexture:SetVertexColor(192/255, 192/255, 192/255)
	borderTexture:SetPoint("CENTER")
	--borderTexture:SetSize(360,360)
	borderTexture:SetSize(398,398)

	-- Create our custom elements
	local frame = CreateFrame("Frame", nil, Minimap)
	frame:SetFrameLevel(Minimap:GetFrameLevel())
	frame:SetAllPoints(Minimap)

	self.widgetFrame = frame

	-- Compass
	local compass = CreateFrame("Frame", nil, frame)
	compass:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	compass:SetPoint("TOPLEFT", 14, -14)
	compass:SetPoint("BOTTOMRIGHT", -14, 14)

	local north = compass:CreateFontString(nil, "ARTWORK", nil, 1)
	north:SetFontObject(GetFont(16,true))
	north:SetTextColor(oUF.colors.normal:GetRGB())
	north:SetAlpha(.75)
	north:SetText("N")
	compass.north = north

	self.compass = compass

	-- Coordinates
	local coordinates = frame:CreateFontString(nil, "OVERLAY", nil, 1)
	coordinates:SetJustifyH("CENTER")
	coordinates:SetJustifyV("MIDDLE")
	coordinates:SetFontObject(GetFont(12, true))
	coordinates:SetTextColor(oUF.colors.offwhite:GetRGB())
	coordinates:SetAlpha(.75)
	coordinates:SetPoint("BOTTOM", 3, 23)

	self.coordinates = coordinates

	-- Mail
	local mailFrame = CreateFrame("Button", nil, frame)
	mailFrame:SetFrameLevel(mailFrame:GetFrameLevel() + 5)
	mailFrame:SetScript("OnEnter", Mail_OnEnter)
	mailFrame:SetScript("OnLeave", Mail_OnLeave)

	local mail = frame:CreateFontString(nil, "OVERLAY", nil, 1)
	mail.frame = mailFrame
	mail:SetFontObject(GetFont(15, true))
	mail:SetTextColor(oUF.colors.offwhite:GetRGB())
	mail:SetAlpha(.85)
	mail:SetJustifyH("CENTER")
	mail:SetJustifyV("BOTTOM")
	mail:SetFormattedText("%s", MAIL_LABEL)
	mail:SetPoint("BOTTOM", 0, 30)
	mailFrame:SetAllPoints(mail)

	self.mail = mail

	self:RegisterEvent("CVAR_UPDATE", "UpdateTimers")
	self:RegisterEvent("UPDATE_PENDING_MAIL", "UpdateMail")
	self:RegisterEvent("VARIABLES_LOADED", "OnEvent")

end

MinimapModule.UpdateCompass = function(self)
	local compass = self.compass
	if (not compass) then
		return
	end
	if (self.rotateMinimap) then
		local radius = self.compassRadius
		if (not radius) then
			local width = compass:GetWidth()
			if (not width) then
				return
			end
			radius = width/2
		end

		local playerFacing = GetPlayerFacing()
		if (not playerFacing) or (self.supressCompass) or (IN_TORGHAST) then
			compass:SetAlpha(0)
		else
			compass:SetAlpha(1)
		end

		-- In Torghast, map is always locked. Weird.
		--local angle = (IN_TORGHAST) and 0 or (self.rotateMinimap and playerFacing) and -playerFacing or 0
		--compass.north:SetPoint("CENTER", radius*math.cos(angle + math.pi/2), radius*math.sin(angle + math.pi/2))

	else
		compass:SetAlpha(0)
	end
end

MinimapModule.UpdateMail = function(self)
	local mail = self.mail
	if (not mail) then
		return
	end

	local hasMail = HasNewMail()
	local hasCraftingOrder

	--[[--if (ns.IsRetail) then
		mail.countInfos = C_CraftingOrders.GetPersonalOrdersInfo()
		hasCraftingOrder = mail.countInfos and #mail.countInfos > 0

		local mailText = ""

		if (hasCraftingOrder) then
			mailText = mailText .. string.format("%s |cff888888(|r"..ns.Colors.normal.colorCode..#mail.countInfos.."|r|cff888888)|r", PROFESSIONS_CRAFTING, L_MAIL, #mail.countInfos)
		end

		if (hasMail) then
			if (hasCraftingOrder) then
				mailText = string.format("%s %s", L_NEW, L_MAIL) .. "|n" .. mailText
			else
				mailText = string.format("%s %s", L_NEW, L_MAIL)
			end
		end

		mail:SetText(mailText)
	--]]--end

	if (hasMail or hasCraftingOrder) then
		mail:Show()
		mail.frame:Show()

		--local resting = self.resting
		--if (resting) then
		--	resting:ClearAllPoints()
		--	resting:SetPoint("BOTTOM", mail, "TOP", 0, 0)
		--end
	else
		mail:Hide()
		mail.frame:Hide()

		--local resting = self.resting
		--if (resting) then
		--	resting:ClearAllPoints()
		--	resting:SetPoint(mail:GetPoint())
		--end
	end

end

MinimapModule.UpdateTimers = function(self)

	-- In Torghast, map is always locked. Weird.
	-- *Note that this is only in the tower, not the antechamber.
	-- *We're resting in the antechamber, and it's a sanctuary. Good indicators.
	-- *Also, we know there is an API call for it. We like ours better.
	--IN_TORGHAST = (not IsResting()) and (GetRealZoneText() == GetRealZoneText(TORGHAST_ZONE_ID))

	self.rotateMinimap = GetCVarBool("rotateMinimap")

	if (self.rotateMinimap) then
		if (not self.compassTimer) then
			self.compassTimer = self:ScheduleRepeatingTimer("UpdateCompass", 1/60)
			self:UpdateCompass()
		end

	elseif (self.compassTimer) then
		self:CancelTimer(self.compassTimer)
		self:UpdateCompass()
	end
end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling.
MinimapModule.UpdateSettings = function(self)
	self:UpdateCompass()
	self:UpdateMail()
	self:UpdateTimers()
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
MinimapModule.RefreshConfig = function(self)
	self:UpdateSettings()
end

MinimapModule.OnEnable = function(self)

	--local mapScale = 198/140 -- 1 in retail, larger in classics

	--Minimap:SetScale(mapScale)
	--Minimap:ClearAllPoints()
	--Minimap:SetPoint("BOTTOMRIGHT", -30 * mapScale, 30 * mapScale)

	self:StyleMinimap()
end

MinimapModule.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("Minimap", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end
