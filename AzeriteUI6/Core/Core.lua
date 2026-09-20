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
local LibDeflate = LibStub("LibDeflate") -- intended for profile sharing later on. TODO!

ns = LibStub("AceAddon-3.0"):NewAddon(ns, addonName, "AceConsole-3.0", "AceTimer-3.0", "LibMoreEvents-1.0", "AceSerializer-3.0", "LibMovableFrames-1.0", "LibFadingFrames-1.0")
ns.callbacks = LibStub("CallbackHandler-1.0"):New(ns, nil, nil, false)

-- Changing this number forces a full settings reset.
ns.SETTINGS_VERSION = -1 

-- WoW client version
local buildVersion, buildNumber, buildDate, interfaceVersion = GetBuildInfo()

ns.WoWBuild = tonumber(buildNumber) -- numerical build number for pure larger than/smaller than comparisons
ns.WoWVersion = interfaceVersion -- patch version as string for display purposes

-- Flavor Flags
ns.WoWRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
ns.WoWVanilla = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
ns.WoWTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
ns.WoWWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
ns.WoWCata = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)
ns.WoWMists = (WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC)
ns.WoWMidnight = (ns.WoWVersion >= 120000 and ns.WoWVersion < 130000)
ns.WoWCamelot = (ns.WoWVersion >= 16000 and ns.WoWVersion < 20000)
--ns.WoWCamelot = (WOW_PROJECT_ID == WOW_PROJECT_CAMELOT) -- doesn't exist yet?

-- Minimum Version Flags
ns.WoW12 = (ns.WoWVersion >= 120000) -- current expansion, added secrecy
ns.WoW13 = (ns.WoWVersion >= 130000) -- future expansion

-- Flag to disable currently unsupported alpha/beta versions for the public
ns.IsCompatible = ns.WoWMidnight or ns.WoWVanilla -- if this addon is compatible with the current client

-- Tinkerers rejoyce!
-- *We give public access through the WoW API, but adding this global for convenience.
_G[addonName] = ns

-- Saved variables globals
-- *note we have to check for existence, 
--  as the addon is set to load variables before running,
--  so we'll constantly overwrite with the defaults if not.
_G.AzeriteUI6_DB = _G.AzeriteUI6_DB or {} -- handled by AceDB
_G.AzeriteUI6_Positions_DB = _G.AzeriteUI6_Positions_DB or {} -- handled by us

-- Addon defaults (just the core)
local defaults = { 
	char = {
		profile = nil,
		showStartupMessage = true
	},
	global = {
		version = -1
	},
	profile = {} 
}

ns.exportableSettings, ns.exportableLayouts = {}, {}

-- Temporary solution while developing. 
-- *Doesn't actually hide anything, just adds hover visibility.
ns.HideClutter = function(self)
	for element, fadeGroup in next,{
		--["BagsBar"] = "BagsBar",
		["BuffFrame"] = "PlayerAuras",
		["DebuffFrame"] = "PlayerAuras",
		--["MainStatusTrackingBarContainer"] = "StatusBars",
		--["MicroMenu"] = "MicroMenu",
		--["MicroMenuContainer"] = "MicroMenu",
		["LibDBIcon10_BugSack"] = true
	} do
		if (_G[element]) then
			self:RegisterFrameForFading(_G[element], fadeGroup == true and element or fadeGroup)
		end
	end
end

-- Toggle movable frame anchors
ns.ToggleFrameLocks = function(self)
	self:ToggleAllMovableFrameAnchors()
	if (self:AreMovableFrameAnchorsVisible()) then
		self.movableFrameAnchorsVisible = true
		self:Fire("MovableFrameAnchorsVisible") -- tell other modules anchors are visible
		self:RegisterEvent("PLAYER_REGEN_DISABLED", "PostMovableFrameAnchorsHiddenOnCombat")
	else
		self.movableFrameAnchorsVisible = nil
		self:Fire("MovableFrameAnchorsHidden") -- tell other modules anchors are hidden
		self:UnregisterEvent("PLAYER_REGEN_DISABLED", "PostMovableFrameAnchorsHiddenOnCombat")
	end
end

-- Clean-up when anchors are hidden by combat
ns.PostMovableFrameAnchorsHiddenOnCombat = function(self)
	if (self.movableFrameAnchorsVisible) then 
		self.movableFrameAnchorsVisible = nil
		self:Fire("MovableFrameAnchorsHidden") -- tell other modules anchors are hidden
		self:UnregisterEvent("PLAYER_REGEN_DISABLED", "PostMovableFrameAnchorsHiddenOnCombat")
	end
end

-- Proxy method to avoid modules using the callback object directly
ns.Fire = function(self, name, ...)
	self.callbacks:Fire(name, ...)
end

-- Temporary fix while developing
ns.ResetSavedPositions = function(self)
	table.wipe(AzeriteUI6_Positions_DB)
	ReloadUI()
end

-- Reset saved settings (not including positions)
ns.ResetDB = function(self, noreload)
	self.db:ResetDB("Default")
	self.db.global.version = ns.SETTINGS_VERSION
	ReloadUI()
end

ns.ProfileExists = function(self, targetProfileKey)
	for _,profileKey in next,self:GetProfiles() do
		if (profileKey == targetProfileKey) then
			return true
		end
	end
end

ns.DuplicateProfile = function(self, newProfileKey, sourceProfileKey)
	if (not sourceProfileKey) then
		sourceProfileKey = self.db:GetCurrentProfile()
	end
	if (self:ProfileExists(newProfileKey) or not self:ProfileExists(sourceProfileKey)) then
		return
	end
	self.db:SetProfile(newProfileKey)
	self.db:CopyProfile(sourceProfileKey)
end

ns.CopyProfile = function(self, sourceProfileKey)
	local currentProfileKey = self.db:GetCurrentProfile()
	if (sourceProfileKey == currentProfileKey) then
		return
	end
	for _,profileKey in next,self:GetProfiles() do
		if (profileKey == sourceProfileKey) then
			self.db:CopyProfile(sourceProfileKey)
			return
		end
	end
end

ns.DeleteProfile = function(self, targetProfileKey)
	local currentProfileKey = self.db:GetCurrentProfile()
	if (targetProfileKey == "Default") then
		return
	end
	for _,profileKey in next,self:GetProfiles() do
		if (profileKey == targetProfileKey) then
			if (profileKey == currentProfileKey) then
				self.db:SetProfile("Default")
			end
			self.db:DeleteProfile(targetProfileKey)
			return
		end
	end
end

ns.ResetProfile = function(self)
	self.db:ResetProfile()
end

ns.SetProfile = function(self, newProfileKey)
	local currentProfileKey = self.db:GetCurrentProfile()
	if (newProfileKey == currentProfileKey) then
		return
	end
	self.db:SetProfile(newProfileKey)
end

ns.GetCurrentProfile = function(self)
	return self.db:GetCurrentProfile()
end

ns.GetProfiles = function(self)
	local profiles = self.db:GetProfiles()
	return profiles
end

ns.Export = function(self, ...)

	-- Decide which modules to export.
	local numModules = select("#", ...)
	local moduleList

	if (numModules > 0) then
		moduleList = {}

		for i = 1, numModules do
			moduleList[(select(i, ...))] = true
		end
	end

	for moduleName in next,ns.exportableSettings do
		if (not moduleList or moduleList[moduleName]) then

			-- serialize, compress and encode
			local module = self:GetModule(moduleName, true)
			if (module) then
				local data
			end

			-- prefix and add to export table
		end
	end

	for moduleName in next,ns.exportableLayouts do
		if (not moduleList or moduleList[moduleName]) then

			-- serialize, compress and encode
			local module = self:GetModule(moduleName, true)
			if (module) then

			end

			-- prefix and add to export table
		end
	end

end

ns.Import = function(self, encoded)

	-- return string encoded by LibDeflate:EncodeForPrint
	local compressed = LibDeflate:DecodeForPrint(encoded)
	if (compressed) then

		-- return data compressed by LibDeflate:CompressDeflate
		local serialized = LibDeflate:DecompressDeflate(compressed)
		if (serialized) then

			-- convert the serialized data into a table again
			local success, table = self:Deserialize(serialized)
			if (success) then

				-- start importing the data into our current profile
				local currentProfileKey = self.db:GetCurrentProfile() 

			end
		end
	end
end

-- ID to barName
local barToMod = {
	["bar1"] 		= "MainActionBar",
	["bar2"] 		= "MultiBar1", -- bottom left
	["bar3"] 		= "MultiBar2", -- bottom right
	["bar4"] 		= "MultiBar3", -- rightmost sidebar
	["bar5"] 		= "MultiBar4", -- leftmost sidebar
	["bar6"] 		= (ns.WoW12 or ns.WoWCamelot) and "MultiBar5" or nil,
	["bar7"] 		= (ns.WoW12 or ns.WoWCamelot) and "MultiBar6" or nil,
	["bar8"] 		= (ns.WoW12 or ns.WoWCamelot) and "MultiBar7" or nil,
	["pet"] 		= "PetBar",
	["petbar"] 		= "PetBar",
	["stance"] 		= "StanceBar", 
	["stancebar"] 	= "StanceBar",
	["forms"] 		= "StanceBar"
}
for i = 1,8 do 
	barToMod[tostring(i)] = barToMod["bar"..i] -- add a numeric alias (as string) for each bar
end

ns.EnableActionBar = function(self, input)
	if (InCombatLockdown()) then return end

	local barID = self:GetArgs(string.lower(input))
	if (not barID or not barToMod[barID]) then return end

	local mod = ns:GetModule(barToMod[barID], true)
	if (mod) then
		if (mod.db.profile.enabled) then return end

		mod.db.profile.enabled = true

		-- Tell bar mod to update bar settings
		local bar = mod:GetBar()
		if (bar) then bar:Update() end		
	end
end

ns.DisableActionBar = function(self, input)
	if (InCombatLockdown()) then return end

	local barID = self:GetArgs(string.lower(input))
	if (not barID or not barToMod[barID]) then return end

	local mod = ns:GetModule(barToMod[barID], true)
	if (mod) then
		if (not mod.db.profile.enabled) then return end

		mod.db.profile.enabled = false

		-- Tell bar mod to update bar settings
		local bar = mod:GetBar()
		if (bar) then bar:Update() end
	end
end

local stringsToTable = function(s)
	local t = {}
	for token in string.gmatch(s, "%S+") do
		t[#t + 1] = token
	end
	return t
end

ns.SetActionBarLayout = function(self, input)
	if (InCombatLockdown()) then return end


	local args = stringsToTable(input)
	--local args = { self:GetArgs(string.lower(input)) }

	if (#args < 2) then return end -- nonsensical

	local barID = args[1]
	if (not barID or not barToMod[barID]) then return end -- invalid bar

	local mod = ns:GetModule(barToMod[barID], true)
	if (mod) then
		if (not mod.db.profile.enabled) then return end

		local db = mod.db.profile -- shorthand for bar settings

		local layout -- layout type (grid or zigzag)
		local growth, growthH, growthV -- first growth direction, horizontal growth direction, vertical growth direction
		local numButtons, breakPoint -- maximum number of visible buttons, number of buttons pr row when grid or from where zigzagging begins
		local fade, noFade, fadeFrom, fadeInCombat, noFadeInCombat -- fade switches

		-- parse the remaining arguments and temporarily store values
		local curArgID, numArgs = 2,#args -- current argument, total number of available arguments
		local arg = string.lower((args[curArgID])) -- retrieve next argument

		while (curArgID <= numArgs) 
		do 
			local prevArgID = curArgID

			-- check for optional layout type
			-- *will use existing layout if not provided
			if (not layout) then
				if (arg == "grid" or arg == "zigzag") then 
					layout = arg -- assign the layout type

					curArgID = curArgID + 1 -- increase argument counter
					if (curArgID > numArgs) then break end -- bail out if all args are parsed

					arg = string.lower(args[curArgID]) -- retrieve next argument

					-- parse for grid width or zigzag start
					if (not breakPoint) then

						-- parse for maximum number of buttons in primary growth direction
						if (layout == "grid" and arg == "size") then
							curArgID = curArgID + 1 -- increase argument counter
							if (curArgID > numArgs) then break end -- bail out if all args are parsed

							arg = string.lower(args[curArgID]) -- retrieve next argument

							breakPoint = tonumber(arg) -- verify it's a number 
							if (breakPoint) then
								curArgID = curArgID + 1 -- increase argument counter
								if (curArgID > numArgs) then break end -- bail out if all args are parsed

								arg = string.lower(args[curArgID]) -- retrieve next argument
							end

						-- parse for button to start zigzagging from
						elseif (layout == "zigzag" and arg == "from") then
							curArgID = curArgID + 1 -- increase argument counter
							if (curArgID > numArgs) then break end -- bail out if all args are parsed

							arg = string.lower(args[curArgID]) -- retrieve next argument

							breakPoint = tonumber(arg) -- verify it's a number 
							if (breakPoint) then
								curArgID = curArgID + 1 -- increase argument counter
								if (curArgID > numArgs) then break end -- bail out if all args are parsed

								arg = string.lower(args[curArgID]) -- retrieve next argument
							end
						end
					end

				end
			end

			-- parse for primary growth direction
			-- *always assume this is the first directional argument
			if (not growth) then
				if (arg == "right" or arg == "left") then
					growth = "horizontal"
					growthH = string.upper(arg)

					curArgID = curArgID + 1 -- increase argument counter
					if (curArgID > numArgs) then break end -- bail out if all args are parsed

					arg = string.lower(args[curArgID]) -- retrieve next argument

					-- parse for breakpoint growth direction
					-- *this is technically optional, since all buttons can be on a row
					if (arg == "up" or arg == "down") then
						growthV = string.upper(arg)

						curArgID = curArgID + 1 -- increase argument counter
						if (curArgID > numArgs) then break end -- bail out if all args are parsed

						arg = string.lower(args[curArgID]) -- retrieve next argument
					end

				elseif (arg == "up" or arg == "down") then
					growth = "vertical"
					growthV = string.upper(arg)

					curArgID = curArgID + 1 -- increase argument counter
					if (curArgID > numArgs) then break end -- bail out if all args are parsed

					arg = string.lower(args[curArgID]) -- retrieve next argument

					-- parse for breakpoint growth direction
					-- *this is technically optional, since all buttons can be on a row
					if (arg == "right" or arg == "left") then
						growthH = string.upper(arg)

						curArgID = curArgID + 1 -- increase argument counter
						if (curArgID > numArgs) then break end -- bail out if all args are parsed

						arg = string.lower(args[curArgID]) -- retrieve next argument
					end
				end
			end

			-- parse for maximum visible buttons
			if (not numButtons) then
				if (arg == "max") then
					curArgID = curArgID + 1 -- increase argument counter
					if (curArgID > numArgs) then break end -- bail out if all args are parsed

					arg = string.lower(args[curArgID]) -- retrieve next argument

					numButtons = tonumber(arg) -- verify it's a number 
					if (numButtons) then
						numButtons = math.max(math.min(numButtons, NUM_ACTIONBAR_BUTTONS), 1)

						curArgID = curArgID + 1 -- increase argument counter
						if (curArgID > numArgs) then break end -- bail out if all args are parsed

						arg = string.lower(args[curArgID]) -- retrieve next argument
					end
				end
			end

			-- parse for button fading (unrelated to explorer mode which fades the entire bar)
			if (arg == "fade" and not noFade) then -- ignore opposite args
				fade = true

				curArgID = curArgID + 1 -- increase argument counter
				if (curArgID > numArgs) then break end -- bail out if all args are parsed

				arg = string.lower(args[curArgID]) -- retrieve next argument

				if (arg == "from") then
					curArgID = curArgID + 1 -- increase argument counter
					if (curArgID > numArgs) then break end -- bail out if all args are parsed

					arg = string.lower(args[curArgID]) -- retrieve next argument

					fadeFrom = tonumber(arg) -- retrieve first fade button
					if (fadeFrom) then
						curArgID = curArgID + 1 -- increase argument counter
						if (curArgID > numArgs) then break end -- bail out if all args are parsed

						arg = string.lower(args[curArgID]) -- retrieve next argument
					end
				end

			elseif (arg == "nofade" and not fade) then -- ignore opposite args
				noFade = true

				curArgID = curArgID + 1 -- increase argument counter
				if (curArgID > numArgs) then break end -- bail out if all args are parsed
				
				arg = string.lower(args[curArgID]) -- retrieve next argument
			end

			-- avoid a neverending loop on bad unrecognized input where nothing was parsed
			if (curArgID == prevArgID) then 
				curArgID = curArgID + 1
			end
		end

		-- assign generic settings
		if (layout) then db.layout = layout end
		if (growth) then db.layoutGrowth = growth end
		if (growthH) then db.layoutGrowthHorizontal = growthH end
		if (growthV) then db.layoutGrowthVertical = growthV end
		if (numButtons) then db.numbuttons = numButtons end
		if (fade) then db.enableBarFading = true end
		if (noFade) then db.enableBarFading = false end
		if (fadeInCombat) then db.fadeInCombat = true end
		if (noFadeInCombat) then db.fadeInCombat = false end
		if (fadeFrom) then db.fadeFrom = fadeFrom end

		-- assign layout depending settings
		-- *note that breakPoint refers to different things in different layouts
		if (breakPoint) then
			if (db.layout == "grid") then
				
				-- illustrates maximum number of buttons on a line
				db.layoutGridSize = breakPoint

			elseif (db.layout == "zigzag") then

				-- illustrates from which button the zigzag pattern begins
				db.layoutZigZagStart = breakPoint

				-- illustrates the fraction of the button size  
				-- the buttons will zigzag relative to the main line
				-- *will leave this uneditable for now
				--db.layoutZigZagOffset
			end
		end

		-- Tell bar mod to update bar settings
		local bar = mod:GetBar()
		if (bar) then bar:Update() end		
	end
end
-- /setbar 1 zigzag 8 fade from 9
ns.RefreshConfig = function(self, event, ...)
	if (event == "OnNewProfile") then
		--local db, profileKey = ...

	elseif (event == "OnProfileChanged") then
		--local db, newProfileKey = ...

		-- we don't need to do this, AceDB tracks profileKeys
		--db.char.profile = newProfileKey

	elseif (event == "OnProfileCopied") then
		--local db, sourceProfileKey = ...

	elseif (event == "OnProfileReset") then
		--local db = ...

	end
end

ns.OnEnable = function(self)
	self:ScheduleTimer("HideClutter", 1) -- some icons require a little time to be created
end

ns.OnInitialize = function(self)
	self.db = LibStub("AceDB-3.0"):New("AzeriteUI6_DB", defaults, true)

	if (self.db.global.version < ns.SETTINGS_VERSION) then
		self:ResetDB(true)
	end

	self.db.RegisterCallback(self, "OnNewProfile", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	self:RegisterChatCommand("lock", "ToggleFrameLocks") -- toggle movable frame anchors
	self:RegisterChatCommand("enablebar", "EnableActionBar") -- enable an action bar
	self:RegisterChatCommand("disablebar", "DisableActionBar") -- disable an action bar
	self:RegisterChatCommand("setbar", "SetActionBarLayout") -- specify bar layout and button count
	self:RegisterChatCommand("resetpositions", "ResetSavedPositions") -- reset all addon saved positions
	self:RegisterChatCommand("resetsettings", "ResetDB") -- reset all addon settings
end
