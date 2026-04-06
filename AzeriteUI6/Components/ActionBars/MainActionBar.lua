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

local MainActionBarMod = ns:NewModule("MainActionBar", nil, "AceConsole-3.0", "LibMoreEvents-1.0", "LibFadingFrames-1.0", "LibMovableFrames-1.0")

-- Declare module defaults
local defaults = { 
	profile = {
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
	
		enableBarFading = true, -- whether to enable non-combat/hover button fading
		fadeInCombat = false, -- whether to keep fading out even in combat
		fadeFrom = 8, -- which button to start the button fading from

		numbuttons = NUM_ACTIONBAR_BUTTONS, -- 12
		visibility = {
			dragon = true,
			possess = true,
			overridebar = true,
			vehicleui = true
		}
	}
}

local MainActionBar = {}

MainActionBar.UpdateVisibilityDriver = function(self)
	if (InCombatLockdown()) then return end

	local visdriver

	if (self.config.enabled) then
		visdriver = "[petbattle]hide;"
		visdriver = visdriver.."[possessbar]show;"
		--visdriver = visdriver.."[possessbar]hide;"
		visdriver = visdriver.."[overridebar]show;" 
		--visdriver = visdriver.."[overridebar]hide;"
		visdriver = visdriver.."[vehicleui]show;" -- vehicle ui
		--visdriver = visdriver.."[vehicleui]hide;"
		--visdriver = visdriver.."[target=vehicle,exists]show;" -- vehicle passenger
		visdriver = visdriver.."[bonusbar:5,mounted]show;" -- dragonriding
		--visdriver = visdriver.."[bonusbar:5]hide;" 
		visdriver = visdriver.."show"
	end

	UnregisterStateDriver(self, "vis")
	self:SetAttribute("state-vis", "0")
	RegisterStateDriver(self, "vis", visdriver or "hide")

end

MainActionBarMod.GetBar = function(self)
	if (not self.Bar) then 
		local bar = ns.ActionBar:Create(1, self.db.profile, "AZUI6_ActionBar1")
		bar:SetScale(.9) -- default scale
		bar:SetPoint("BOTTOMLEFT", 60/.9, 42/.9) -- default position

		-- Overwrite some default methods with our own
		for name,method in pairs(MainActionBar) do
			bar[name] = method
		end

		bar:Update() 

		self.Bar = bar
	end
	return self.Bar
end

MainActionBarMod.ReassignBindings = function(self)
	if (self.Bar) then
		self.Bar:UpdateBindings()
	end
end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling and combat end.
MainActionBarMod.UpdateSettings = function(self)
	if (self.Bar) then
		--self.Bar:UpdateBindings()
		self.Bar:Update()
	end
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
MainActionBarMod.RefreshConfig = function(self)
	self:UpdateSettings()
end

MainActionBarMod.OnInitialize = function(self)
	if (ns.IsAddOnEnabled("ConsolePort_Bar")) then return self:Disable() end

	self.db = ns.db:RegisterNamespace("MainActionBar", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

MainActionBarMod.OnEnable = function(self)
	self:RegisterMovableFrameAnchor(self:GetBar(), string.lower(string.format(HUD_EDIT_MODE_ACTION_BAR_LABEL, 1)), "actionbars", AzeriteUI6_Positions_DB)
	self:RegisterEvent("UPDATE_BINDINGS", "ReassignBindings")
	self:ReassignBindings()
	--self:UpdateSettings()
end
