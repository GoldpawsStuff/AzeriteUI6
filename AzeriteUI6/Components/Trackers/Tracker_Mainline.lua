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

local Trackers = ns:NewModule("ObjectiveTracker", nil, "AceTimer-3.0", "LibMoreEvents-1.0", "LibFadingFrames-1.0")

-- Declare module defaults
local defaults = { profile = {
	fadeOutTracker = true
}}

Trackers.UpdateObjectiveTrackerFading = function(self)
	if (self.db.profile.fadeOutTracker) then
		self:RegisterFrameForFading(ObjectiveTrackerFrame, "Trackers")
	else
		self:UnregisterFrameForFading(ObjectiveTrackerFrame)
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
	--self:UpdateSettings()
end
