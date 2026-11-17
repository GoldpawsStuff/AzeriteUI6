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

local Tooltips = ns:NewModule("Tooltips", nil, "LibMoreEvents-1.0", "AceHook-3.0")

-- Declare module defaults
local defaults = { profile = {
}}

local StyleTooltip = function(tooltip)
	if (not tooltip or tooltip:IsForbidden()) then
		return
	end

	local nineSlice = tooltip.NineSlice
	if (not nineSlice) then
		return
	end

	-- Darker background (near-black with slight blue-gray)
	nineSlice:SetCenterColor(.05, .05, .15, .96)

	-- Darker, more neutral border (instead of the bright gold)
	nineSlice:SetBorderColor(.45, .45, .55, 1)

	-- Optional: hide any overlay textures Forever may add
	if (tooltip.TopOverlay) then
		tooltip.TopOverlay:Hide()
	end
	if (tooltip.BottomOverlay) then
		tooltip.BottomOverlay:Hide()
	end
end

Tooltips.StyleGameTooltip = function(self)

	-- We'd like a few more here, but secrecy made it all so hush-hush
	for tooltipName in next,{
		ItemRefTooltip = true,
		ShoppingTooltip1 = true,
		ShoppingTooltip2 = true,
		GameTooltip = true
	} do
		-- Apply on show and after style resets
		local tooltip = _G[tooltipName]
		if (tooltip) then
			self:HookScript(tooltip, "OnShow", StyleTooltip)
			self:HookScript(tooltip, "OnTooltipCleared", StyleTooltip)
		end
	end

	-- Also catch the common style reset path
	if (SharedTooltip_SetBackdropStyle) then
		self:SecureHook("SharedTooltip_SetBackdropStyle", StyleTooltip)
	end

	-- Put the statusbar inside the tooltip. It's cleaner. 
	if (GameTooltipStatusBar) then
		GameTooltipStatusBar:SetHeight(2)
		GameTooltipStatusBar:ClearAllPoints()
		GameTooltipStatusBar:SetPoint("BOTTOMLEFT", GameTooltip, "BOTTOMLEFT", 6, 5)
		GameTooltipStatusBar:SetPoint("BOTTOMRIGHT", GameTooltip, "BOTTOMRIGHT", -6, 5)
	end

	-- Style the Forever/Mainline unit frame aura tooltip
	-- *tooltip is still hidden, we can't access methods directly, just this.
	if (AuraContainerInbound and AuraContainerInbound.SetTooltipBackdrop) then 
		AuraContainerInbound.SetTooltipBackdrop({
			backdropInfo = {
				bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
				edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
				edgeSize = 12,
			},
			borderColor = CreateColor(.45, .45, .55, 1),
			centerColor = CreateColor(.05, .05, .15, .96),
		})
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
	self:StyleGameTooltip()
end
