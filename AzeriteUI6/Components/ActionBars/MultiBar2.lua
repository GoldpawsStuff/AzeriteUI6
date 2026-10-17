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

local L = LibStub("AceLocale-3.0"):GetLocale((...))

local MultiBar2 = ns:NewModule("MultiBar2", nil, "AceConsole-3.0", "LibMoreEvents-1.0", "LibFadingFrames-1.0", "LibMovableFrames-1.0")

-- Declare module defaults
local defaults = { 
	profile = {
		enabled = false,

		layout = "grid", -- <grid, zigzag>
		layoutGridSize = NUM_ACTIONBAR_BUTTONS, -- when to start a new grid row
		layoutGrowth = "horizontal", -- which direction the bar initially grows in
		layoutGrowthVertical = "UP", -- which direction the bar grows in vertically
	
		enableBarFading = false, -- whether to enable non-combat/hover button fading
	}
}

-- Declare options menu
local mod = MultiBar2
local options = {
	type = "group",
	name = L["Action Bar 3"],
	args = {
		enable = {
			type = "toggle",
			name = L["Enable"],
			disabled = function() return InCombatLockdown() end,
			get = function(info) return mod.db.profile.enabled end,
			set = function(info, val) 
				if InCombatLockdown() then return end

				mod.db.profile.enabled = val 
				mod:UpdateSettings()
			end,
			order = 1
		},
		numbuttons = {
			type = "range", width = "full", min = 0, max = 12, step = 1,
			name = L["Number of visible buttons:"],
			desc = L["Sets the number of visible buttons on the Action Bar."],
			disabled = function() return InCombatLockdown() end,
			hidden = function() return not mod.db.profile.enabled end,
			get = function(info) return mod.db.profile.numbuttons end,
			set = function(info,val)
				if InCombatLockdown() then return end

				mod.db.profile.numbuttons = val
				mod:UpdateSettings()
			end,
			order = 10
		}
	}
}

MultiBar2.GetDefaults = function(self)
	return defaults
end

MultiBar2.GetOptions = function(self)
	return options
end

MultiBar2.GetBar = function(self)
	if (not self.Bar) then 
		local bar = ns.ActionBar:Create(3, self.db.profile, "AZUI6_ActionBar1")
		bar:SetScale(.9) -- default scale
		bar:SetPoint("CENTER", 0, (100 + 64)/.9) -- default position
		bar:Update() -- update size and layout
		self.Bar = bar
	end
	return self.Bar
end

MultiBar2.ReassignBindings = function(self)
	if (self.Bar) then
		self.Bar:UpdateBindings()
	end
end

MultiBar2.HasConflicts = function(self)
	for _,addon in next,{ "ConsolePort_Bar" } do 
		if (ns.IsAddOnEnabled(addon)) then return true end 
	end
end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling and combat end.
MultiBar2.UpdateSettings = function(self)
	if (self.Bar) then
		self.Bar:Update()
	end
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
MultiBar2.RefreshConfig = function(self)
	self:UpdateSettings()
end

MultiBar2.OnInitialize = function(self)
	if (self:HasConflicts()) then return self:Disable() end

	self.db = ns.db:RegisterNamespace("MultiBar2", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

MultiBar2.OnEnable = function(self)
	self:RegisterMovableFrameAnchor(self:GetBar(), string.lower(string.format(HUD_EDIT_MODE_ACTION_BAR_LABEL, 3)), "actionbars", AzeriteUI6_Positions_DB)
	self:RegisterEvent("UPDATE_BINDINGS", "ReassignBindings")
	self:ReassignBindings()
end
