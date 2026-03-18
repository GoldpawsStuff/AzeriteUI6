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

local MainActionBar = ns:NewModule("MainActionBar", nil, "LibMoreEvents-1.0", "LibFadingFrames-1.0")

-- Declare module defaults
local defaults = { profile = {}}
local db -- will be assigned a utility function returning the profile settings/defaults during initialization

-- Custom API locals
local AbbreviateNumber = ns.AbbreviateNumber
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia

local defaults = {
	enabled = true,
	layout = "zigzag", -- <grid, zigzag>
	layoutZigZagStart = 9, -- at which button the zigzag pattern should begin
	layoutZigZagOffset = 44/64, -- -- relative offset in the growth direction for the alternate zigzag row as a fraction of button size.
	layoutGridSize = NUM_ACTIONBAR_BUTTONS, -- when to start a new grid row
	layoutGrowth = "horizontal", -- which direction the bar initially grows in
	layoutGrowthHorizontal = "RIGHT", -- which direction the bar grows in horizontally
	layoutGrowthVertical = "UP", -- which direction the bar grows in vertically
	layoutPaddingX = 8, -- horizontal padding between the buttons
	layoutPaddingY = 8, -- vertical padding between the buttons
	buttonHitRects = { -10, -10, -10, -10 },
	numbuttons = NUM_ACTIONBAR_BUTTONS, -- 12
	visibility = {
		dragon = true,
		possess = true,
		overridebar = true,
		vehicleui = true
	}
}

-- Return blizzard barID by from own bar numbers.
local BAR_TO_ID = {
	[1] = 1,
	[2] = BOTTOMLEFT_ACTIONBAR_PAGE,
	[3] = BOTTOMRIGHT_ACTIONBAR_PAGE,
	[4] = RIGHT_ACTIONBAR_PAGE,
	[5] = LEFT_ACTIONBAR_PAGE,
	[6] = MULTIBAR_5_ACTIONBAR_PAGE,
	[7] = MULTIBAR_6_ACTIONBAR_PAGE,
	[8] = MULTIBAR_7_ACTIONBAR_PAGE
}

-- Return our bar number from blizzard barID.
local ID_TO_BAR = {}
for i,j in next,BAR_TO_ID do ID_TO_BAR[j] = i end

MainActionBar.Spawn = function(self)

	local bar = ns.ActionBar:Create(BAR_TO_ID[1], defaults, "AZUI6_ActionBar1")

	self.bar = bar

	return bar
end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling and combat end.
MainActionBar.UpdateSettings = function(self)
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
MainActionBar.RefreshConfig = function(self)
	self:UpdateSettings()
end

MainActionBar.OnInitialize = function(self)
	if (ns.IsAddOnEnabled("ConsolePort_Bar")) then return self:Disable() end

	-- Let's not do these until the addon is more stable
	--self.db = ns.db:RegisterNamespace("MainActionBar", defaults)
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

MainActionBar.OnEnable = function(self)

	local bar = MainActionBar:Spawn()
	bar:SetSize(400,64)
	bar:SetPoint("BOTTOMLEFT", 50, 50)
	bar:Update()

end
