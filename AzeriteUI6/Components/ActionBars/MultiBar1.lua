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
local oUF = ns.oUF

local MultiBar1 = ns:NewModule("MultiBar1", nil, "LibMoreEvents-1.0", "LibFadingFrames-1.0", "LibMovableFrames-1.0")

-- Declare module defaults
local defaults = { 
	profile = {
		enabled = false,
		layout = "zigzag", -- <grid, zigzag>
		layoutZigZagStart = 2, -- at which button the zigzag pattern should begin
		layoutZigZagOffset = 28/64, -- -- relative offset in the growth direction for the alternate zigzag row as a fraction of button size.
		--layoutZigZagOffset = 44/64, -- -- relative offset in the growth direction for the alternate zigzag row as a fraction of button size.
		layoutGrowthHorizontal = "RIGHT", -- which direction the bar grows in horizontally
		layoutGrowthVertical = "DOWN", -- which direction the bar grows in vertically

		enableBarFading = true, -- whether to enable non-combat/hover button fading
		fadeInCombat = false, -- whether to keep fading out even in combat
		fadeFrom = 1, -- which button to start the button fading from
	}
}

-- Custom API locals
local AbbreviateNumber = ns.AbbreviateNumber
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia

MultiBar1.Spawn = function(self)

	local bar = ns.ActionBar:Create(2, self.db.profile, "AZUI6_ActionBar2")

	self.Bar = bar

	return bar
end

MultiBar1.ReassignBindings = function(self)
	self.Bar:UpdateBindings()
end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling and combat end.
MultiBar1.UpdateSettings = function(self)
	self.Bar:UpdateBindings()
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
MultiBar1.RefreshConfig = function(self)
	self:UpdateSettings()
end

MultiBar1.OnInitialize = function(self)
	if (ns.IsAddOnEnabled("ConsolePort_Bar")) then return self:Disable() end

	self.db = ns.db:RegisterNamespace("MultiBar1", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

MultiBar1.OnEnable = function(self)

	local bar = MultiBar1:Spawn()
	bar:SetScale(.9)
	bar:SetPoint("BOTTOMLEFT", (752-64-8)/.9, 42/.9) -- default position
	bar:Update() -- update size and layout

	self:RegisterEvent("UPDATE_BINDINGS", "ReassignBindings")
	self:ReassignBindings()

	self:RegisterMovableFrameAnchor(bar, string.lower(string.format(HUD_EDIT_MODE_ACTION_BAR_LABEL, 2)), "actionbars", AzeriteUI6_Positions_DB)

end
