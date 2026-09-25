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

local Trackers = ns:NewModule("ObjectiveTracker", nil, "AceTimer-3.0", "LibMoreEvents-1.0", "LibMovableFrames-1.0", "LibFadingFrames-1.0")

-- Declare module defaults
local defaults = { profile = {
	fadeOutTracker = true
}}

Trackers.UpdateTrackerFading = function(self)
	if (not self.anchor) then return end
	--if (not self.db.profile.enabled) then return end

	if (self.db.profile.fadeOutTracker) then
		self:RegisterFrameForFading(QuestWatchFrame, "Trackers")
	else
		self:UnregisterFrameForFading(QuestWatchFrame)
	end
end

Trackers.UpdateTrackerPosition = function(self)
	if (not self.anchor) then return end
	--if (not self.db.profile.enabled) then return end

	QuestWatchFrame:SetParent(self.anchor)
	QuestWatchFrame:SetWidth(255)
	QuestWatchFrame:SetClampedToScreen(false)
	QuestWatchFrame:SetAlpha(.9)
	QuestWatchFrame:ClearAllPoints()
	QuestWatchFrame:SetPoint("BOTTOMRIGHT", self.anchor, "BOTTOMRIGHT", 0, 20) -- weird
end


-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling.
Trackers.UpdateSettings = function(self)
	self:UpdateTrackerFading()
	self:UpdateTrackerPosition()
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
Trackers.RefreshConfig = function(self)
	self:UpdateSettings()
end

Trackers.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("Trackers", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

Trackers.OnEnable = function(self)

	local ExplorerMode = ns:GetModule("ExplorerMode", true)
	if (ExplorerMode) then
		self:ScheduleTimer("UpdateSettings", math.min(ExplorerMode.db.profile.delayOnLogin, ExplorerMode.db.profile.delayOnReload))
	else
		self:ScheduleTimer("UpdateSettings", 5)
	end

	local anchor = CreateFrame("Frame", "AZUI6_Tracker", UIParent)
	anchor:SetFrameStrata("LOW")
	anchor:SetSize(255, 440)
	anchor:SetPoint("BOTTOMRIGHT", -60, 320)

	self.anchor = anchor

 	-- Re-position after UIParent messes with it.
	hooksecurefunc(QuestWatchFrame, "SetPoint", function(_,_, this)
		--if (not self.db.profile.enabled) then return end
		if (this ~= self.anchor) then
			self:UpdateTrackerPosition()
		end
	end)

	-- Just in case some random addon messes with it.
	hooksecurefunc(QuestWatchFrame, "SetAllPoints", function()
		--if (not self.db.profile.enabled) then return end
		self:UpdateTrackerPosition()
	end)

	self:RegisterMovableFrameAnchor(self.anchor, TRACKER_HEADER_OBJECTIVE, "floaters", AzeriteUI6_Positions_DB)

end
