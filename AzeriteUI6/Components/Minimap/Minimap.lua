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

local MinimapModule = ns:NewModule("Minimap", nil, "LibMoreEvents-1.0", "LibFadingFrames-1.0")

-- Declare module defaults
local defaults = { profile = {
	fadeClutter = true
}}

-- Custom API locals
local AbbreviateNumber = ns.AbbreviateNumber
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia

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
	borderFrame:SetAllPoints()

	local borderTexture = borderFrame:CreateTexture(nil, "BORDER", nil, 5)
	borderTexture:SetTexture(GetMedia("minimap-border"))
	borderTexture:SetVertexColor(192/255, 192/255, 192/255)
	borderTexture:SetPoint("CENTER")
	borderTexture:SetSize(360,360)

	local hider = CreateFrame("Frame")
	hider:Hide()

	-- hide the clutter
	MinimapCluster.BorderTop:SetParent(hider)
	MinimapCluster.Tracking:SetParent(hider)
	MinimapCluster.ZoneTextButton:SetParent(hider)
	Minimap.ZoomIn:SetParent(hider)
	Minimap.ZoomOut:SetParent(hider)
	MinimapCompassTexture:SetParent(hider)
	AddonCompartmentFrame:SetParent(hider)
	GameTimeFrame:SetParent(hider)
	TimeManagerClockButton:SetParent(hider)

	-- get this out of the way
	MinimapCluster:EnableMouse(false)
	MinimapCluster:SetFrameLevel(1)

	-- make the blob textures slightly less horrible
	Minimap:SetArchBlobRingScalar(0)
	Minimap:SetQuestBlobRingScalar(0)

	-- add the tracking menu on middle-click
	Minimap:HookScript("OnMouseUp", Minimap_OnMouseUp)

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
