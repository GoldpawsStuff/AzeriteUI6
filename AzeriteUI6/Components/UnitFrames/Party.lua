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

local Party = ns:NewModule("Party", nil, "LibMoreEvents-1.0", "LibMovableFrames-1.0")

-- Declare module defaults
local defaults = { profile = {
	enabled = true,
	showParty = true, -- show while in a non-raid 2-5p group (party)
	showPlayer = true, -- include the player while in a non-raid 2-5p group (party)
	showRaid = true, -- show while in a raid of 2-5p. 
}}

-- Custom API locals
local AbbreviateNumber = ns.AbbreviateNumber
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia

local style = function(self, unit)
end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling and combat end.
Party.UpdateSettings = function(self)
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
Party.RefreshConfig = function(self)
	self:UpdateSettings()
end

Party.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("Party", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

Party.OnEnable = function(self)
	oUF:RegisterStyle("AzeriteUnitFrameParty", style)	
	oUF:Factory(function(self) 
		self:SetActiveStyle("AzeriteUnitFrameParty")

--		local frame = self:Spawn("player", "AzeriteUnitFrameParty")
--
--		-- Need to do this once for oUF_Classic
--		local parent = frame:GetParent()
--		if (parent ~= UIParent) then
--			parent:SetAllPoints(UIParent)
--		end
--
--		frame:SetScale(.9)
--		frame:SetPoint("BOTTOMLEFT", 46/.9, 100/.9) -- scaled coords
--
--		Player.frame = frame
--
--		Party:RegisterMovableFrameAnchor(frame, string.lower(PLAYER), "unitframes", AzeriteUI6_Positions_DB)
	end)
end
