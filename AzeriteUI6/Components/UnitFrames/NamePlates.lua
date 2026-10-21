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

local NamePlates = ns:NewModule("NamePlates", nil, "LibMoreEvents-1.0", "LibMovableFrames-1.0")

-- Declare module defaults
local defaults = { profile = {
	enabled = true
}}

-- Custom API locals
local AbbreviateNumber = ns.AbbreviateNumber
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia

local style = function(self, unit)



end

NamePlates.HasConflicts = function(self)
	for _,addon in next,{
		"BetterBlizzPlates",
		"ClassicPlatesPlus",
		"Kui_Nameplates",
		"NamePlateKAI",
		"Nameplates",
		"NDui",
		"NeatPlates",
		"Plater",
		"SimplePlates",
		"TidyPlates",
		"TidyPlates_ThreatPlates",
		"TidyPlatesContinued" } do 
		if (ns.IsAddOnEnabled(addon)) then return true end 
	end
end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling and combat end.
NamePlates.UpdateSettings = function(self)
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
NamePlates.RefreshConfig = function(self)
	self:UpdateSettings()
end

NamePlates.OnInitialize = function(self)
	if (self:HasConflicts()) then return self:Disable() end

	if (not C_AddOns.IsAddOnLoaded("Blizzard_NamePlates")) then
		C_AddOns.LoadAddOn("Blizzard_NamePlates")
	end

	self.db = ns.db:RegisterNamespace("NamePlates", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	if (not self.db.profile.enabled) then return self:Disable() end
end

NamePlates.OnEnable = function(self)
	oUF:RegisterStyle("AzeriteNamePlates", style)
	oUF:SetActiveStyle("AzeriteNamePlates")
	oUF:SpawnNamePlates("Azerite", callback, cvars)
end
