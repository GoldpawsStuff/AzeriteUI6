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

local Tooltips = ns:NewModule("Tooltips", nil, "LibMoreEvents-1.0", "LibMovableFrames-1.0", "AceHook-3.0")

-- Declare module defaults
local defaults = { profile = {
	anchorToCursor = nil
}}

Tooltips.SetDefaultAnchor = function(self, tooltip, parent)
	if (not tooltip or tooltip:IsForbidden()) then return end

	if (GameTooltipStatusBar) then
		GameTooltipStatusBar:SetHeight(2)
		GameTooltipStatusBar:ClearAllPoints()
		GameTooltipStatusBar:SetPoint("BOTTOMLEFT", tooltip, "BOTTOMLEFT", 6, 5)
		GameTooltipStatusBar:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -6, 5)
	end

	if (parent and not parent:IsForbidden()) then
		if (self.db.profile.anchorToCursor) then
			tooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
			return
		else
			local point, x, y = self.anchor:GetPoint()

			tooltip:SetOwner(parent, "ANCHOR_NONE")
			tooltip:ClearAllPoints()
			tooltip:SetPoint(point, self.anchor, point)
		end
	end
end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling.
Tooltips.UpdateSettings = function(self)
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
Tooltips.RefreshConfig = function(self)
	self:UpdateSettings()
end

Tooltips.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("Tooltips", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

Tooltips.OnEnable = function(self)

	local anchor = CreateFrame("Frame", "AZUI6_Tooltip", UIParent)
	--anchor:SetPoint("BOTTOMRIGHT", -20, 70) 
	anchor:SetPoint("BOTTOMRIGHT", -244, 124)
	anchor:SetSize(250, 120)

	self.anchor = anchor

	-- Why doesn't this save...? All other frames do.
	self:RegisterMovableFrameAnchor(self.anchor, HUD_EDIT_MODE_HUD_TOOLTIP_LABEL, "floaters", AzeriteUI6_Positions_DB)

	self:SecureHook("GameTooltip_SetDefaultAnchor", "SetDefaultAnchor")

end
