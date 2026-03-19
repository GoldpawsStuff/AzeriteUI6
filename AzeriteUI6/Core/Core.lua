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

ns = LibStub("AceAddon-3.0"):NewAddon(ns, addonName, "LibMoreEvents-1.0", "LibFadingFrames-1.0")
ns.callbacks = LibStub("CallbackHandler-1.0"):New(ns, nil, nil, false)

-- Saved variables globals
AzeriteUI6_DB = {} -- handled by AceDB
AzeriteUI6_Positions_DB = {} -- handled by us

-- Addon defaults (just the core)
local defaults = { profile = {} }

-- Temporary solution while developing. 
-- *Doesn't actually hide anything, just adds hover visibility.
ns.HideBlizzard = function(self)

	-- buffs and debuffs
	self:RegisterFrameForFading(BuffFrame, "PlayerAuras")
	self:RegisterFrameForFading(DebuffFrame, "PlayerAuras")

	-- bags bar and micro menu
	self:RegisterFrameForFading(BagsBar, "BagsBar")
	self:RegisterFrameForFading(MicroMenu, "MicroMenu")
	self:RegisterFrameForFading(MicroMenuContainer, "MicroMenu")

	-- standard action bars
	for i = 1,12 do
		self:RegisterFrameForFading(_G["ActionButton"..i], "ActionBars")
		self:RegisterFrameForFading(_G["MultiBarBottomLeftButton"..i], "ActionBars")
		self:RegisterFrameForFading(_G["MultiBarBottomRightButton"..i], "ActionBars")
		self:RegisterFrameForFading(_G["MultiBarRightButton"..i], "ActionBars")
		self:RegisterFrameForFading(_G["MultiBarLeftButton"..i], "ActionBars")
		self:RegisterFrameForFading(_G["MultiBar5Button"..i], "ActionBars")
		self:RegisterFrameForFading(_G["MultiBar6Button"..i], "ActionBars")
		self:RegisterFrameForFading(_G["MultiBar7Button"..i], "ActionBars")
	end
	
	-- stance and pet action bar
	for i = 1,10 do
		self:RegisterFrameForFading(_G["PetActionButton"..i], "PetBars")
		self:RegisterFrameForFading(_G["StanceButton"..i], "StanceBars")
	end

	-- xp- and reputation bars
	self:RegisterFrameForFading(MainStatusTrackingBarContainer, "StatusBars")

end

ns.RefreshConfig = function(self, event, ...)
	if (event == "OnNewProfile") then
		--local db, profileKey = ...

	elseif (event == "OnProfileChanged") then
		local db, newProfileKey = ...

		db.char.profile = newProfileKey

	elseif (event == "OnProfileCopied") then
		--local db, sourceProfileKey = ...

	elseif (event == "OnProfileReset") then
		--local db = ...

	end
end

ns.OnEnable = function(self)
	--self.db:SetProfile(self.db.char.profile)

	-- Temporary solution to clean things up during development.
	self:HideBlizzard()
end

ns.OnInitialize = function(self)
	self.db = LibStub("AceDB-3.0"):New("AzeriteUI6_DB", defaults, true)
	self.db.RegisterCallback(self, "OnNewProfile", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end
