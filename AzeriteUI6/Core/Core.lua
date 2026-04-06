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
local LibDeflate = LibStub("LibDeflate")

ns = LibStub("AceAddon-3.0"):NewAddon(ns, addonName, "AceConsole-3.0", "LibMoreEvents-1.0", "LibMovableFrames-1.0", "LibFadingFrames-1.0", "AceSerializer-3.0")
ns.callbacks = LibStub("CallbackHandler-1.0"):New(ns, nil, nil, false)

-- Changing this number forces a full settings reset.
ns.SETTINGS_VERSION = -1 -- use client dependant settings version to avoid resets in unaffected builds.

-- WoW client version
local buildVersion, buildNumber, buildDate, interfaceVersion = GetBuildInfo()
ns.WoWBuild = tonumber(buildNumber)
ns.WoWVersion = interfaceVersion
ns.WoW12 = interfaceVersion >= 120000
ns.WoW13 = interfaceVersion >= 130000
ns.IsCompatible = ns.WoW12 and not ns.WoW13

-- Tinkerers rejoyce!
_G[addonName] = ns

-- Saved variables globals
AzeriteUI6_DB = {} -- handled by AceDB
AzeriteUI6_Positions_DB = {} -- handled by us

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
ns.HideBlizzard = function(self)

	-- buffs and debuffs
	self:RegisterFrameForFading(BuffFrame, "PlayerAuras")
	self:RegisterFrameForFading(DebuffFrame, "PlayerAuras")

	-- bags bar and micro menu
	self:RegisterFrameForFading(BagsBar, "BagsBar")
	self:RegisterFrameForFading(MicroMenu, "MicroMenu")
	self:RegisterFrameForFading(MicroMenuContainer, "MicroMenu")

	-- stance and pet action bar
	for i = 1,10 do
		self:RegisterFrameForFading(_G["PetActionButton"..i], "PetBars")
		self:RegisterFrameForFading(_G["StanceButton"..i], "StanceBars")
	end

	-- xp- and reputation bars
	self:RegisterFrameForFading(MainStatusTrackingBarContainer, "StatusBars")
end

-- Toggle movable frame anchors
ns.ToggleFrameLocks = function(self)
	self:ToggleAllMovableFrameAnchors()
end


-- Proxy method to avoid modules using the callback object directly
ns.Fire = function(self, name, ...)
	self.callbacks:Fire(name, ...)
end

ns.ResetSettings = function(self, noreload)
	self.db:ResetDB(self:GetDefaultProfileKey())
	self.db.global.version = ns.SETTINGS_VERSION
	if (not noreload) then
		ReloadUI()
	end
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

-- Returns a localized "Default" string, 
-- usable as the key for the default profile.
ns.GetDefaultProfileKey = function(self)
	return DEFAULT
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

local barToMod = {
	["bar1"] 		= "MainActionBar",
	["bar2"] 		= "MultiBar1",
	["bar3"] 		= "MultiBar2",
	["bar4"] 		= "MultiBar3",
	["bar5"] 		= "MultiBar4",
	["bar6"] 		= "MultiBar5",
	["bar7"] 		= "MultiBar6",
	["bar8"] 		= "MultiBar7",
	["1"] 			= "MainActionBar",
	["2"] 			= "MultiBar1",
	["3"] 			= "MultiBar2",
	["4"] 			= "MultiBar3",
	["5"] 			= "MultiBar4",
	["6"] 			= "MultiBar5",
	["7"] 			= "MultiBar6",
	["8"] 			= "MultiBar7",
	["pet"] 		= "PetBar",
	["petbar"] 		= "PetBar",
	["stance"] 		= "StanceBar",
	["stancebar"] 	= "StanceBar",
	["forms"] 		= "StanceBar",
}

local enablebar = function(barID)
	print("enable <barID>", barID)
	if (not barID or not barToMod[barID]) then return end
	local mod = ns:GetModule(barToMod[barID], true)
	if (mod) then
		mod.db.profile.enabled = true
		local bar = mod:GetBar()
		if (bar) then bar:Update() end
	end
end

local disablebar = function(barID)
	print("disable <barID>", barID)
	if (not barID or not barToMod[barID]) then return end
	local mod = ns:GetModule(barToMod[barID], true)
	if (mod) then
		mod.db.profile.enabled = false
		local bar = mod:GetBar()
		if (bar) then bar:Update() end
	end
end

ns.OnChatCommand = function(self, input)
	local command, arg1, arg2 = self:GetArgs(string.lower(input), 3)
	if (command == "enable") then
		if (arg1 and barToMod[arg1]) then
			enablebar(arg1)
		end
	elseif (command == "disable") then
		if (arg1 and barToMod[arg1]) then
			disablebar(arg1)
		end
	end
end

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
	-- Temporary solution to clean things up during development.
	self:HideBlizzard()
end

ns.OnInitialize = function(self)
	self.db = LibStub("AceDB-3.0"):New("AzeriteUI6_DB", defaults, self:GetDefaultProfileKey())

	if (self.db.global.version < ns.SETTINGS_VERSION) then
		self:ResetSettings(true)
	end

	self.db.RegisterCallback(self, "OnNewProfile", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	self:RegisterChatCommand("lock", "ToggleFrameLocks") -- toggle movable frame anchors
	self:RegisterChatCommand("resetsettings", "ResetSettings") -- reset all addon settings
	self:RegisterChatCommand("azerite", "OnChatCommand") -- settings
	self:RegisterChatCommand("az", "OnChatCommand") -- settings shorthand
end
