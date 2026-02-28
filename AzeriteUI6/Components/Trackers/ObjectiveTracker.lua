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

local Trackers = ns:NewModule("ObjectiveTracker", nil, "LibMoreEvents-1.0", "LibFadingFrames-1.0")
local db -- will be assigned a utility function returning the profile settings/defaults during initialization

-- Declare module defaults
local defaults = { profile = {
	fadeOutTracker = true,
	fadeOutBlizzard = true
}}

Trackers.UpdateObjectiveTrackerFading = function(self)
	if (db.fadeOutTracker) then
		self:RegisterFrameForFading(ObjectiveTrackerFrame, "Trackers")
	else
		self:UnregisterFrameForFading(ObjectiveTrackerFrame)
	end
	if (db.fadeOutBlizzard) then

		-- primary action bar
		for i = 1,12 do
			self:RegisterFrameForFading(_G["ActionButton"..i], "ActionBars")
		end
		
		-- pet action bar
		for i = 1,10 do
			self:RegisterFrameForFading(_G["StanceButton"..i], "StanceBars")
		end

		-- buffs and debuffs
		self:RegisterFrameForFading(BuffFrame, "PlayerAuras")
		self:RegisterFrameForFading(DebuffFrame, "PlayerAuras")

		-- bags bar and micro menu
		self:RegisterFrameForFading(BagsBar, "BagsBar")
		self:RegisterFrameForFading(MicroMenu, "MicroMenu")
		self:RegisterFrameForFading(MicroMenuContainer, "MicroMenu")
	else
	end
end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling.
Trackers.UpdateSettings = function(self)
	self:UpdateObjectiveTrackerFading()
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
Trackers.RefreshConfig = function(self)
	self:UpdateSettings()
end

Trackers.OnEnable = function(self)
	-- Doing this manually until we enable settings profiles
	self:UpdateObjectiveTrackerFading()
end

Trackers.OnInitialize = function(self)
	-- Let's not do these until the addon is more stable
	--self.db = ns.db:RegisterNamespace("Trackers", defaults)
	--self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	--self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	--self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	-- Utility to get saved settings or defaults
	-- *Will default to defaults if the saved settings above don't exist (during development)
	db = (function(forceDefaults)
		if (forceDefaults) then return defaults.profile end
		return self.db and self.db.profile or defaults.profile
	end)(false)
end
