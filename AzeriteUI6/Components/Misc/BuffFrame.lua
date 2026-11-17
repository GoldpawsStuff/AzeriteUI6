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
local oUF = ns.oUF or oUF

local L = LibStub("AceLocale-3.0"):GetLocale((...))

local PlayerAuras = ns:NewModule("PlayerAuras", nil, "LibMoreEvents-1.0", "AceHook-3.0")

-- Declare module defaults
local defaults = { profile = {
	enabled = true,
}}

PlayerAuras.GetDefaults = function(self)
	return defaults
end

PlayerAuras.GetOptions = function(self)
	return {
		type = "group",
		name = L["Buffs & Debuffs"],
		arg = { menuName = L["Buffs & Debuffs"] },
		order = 500,
		args = {
			enable = {
				type = "toggle", width = "full",
				name = L["Enable"],
				desc = L["Toggle the usage of our Buff & Debuff Frames. Note that disabling this will force a user interface reload to re-enable the game's default Buff- and Debuff Frames."],
				disabled = function() return InCombatLockdown() end,
				get = function(info) return self.db.profile.enabled end,
				set = function(info, val) 
					if (InCombatLockdown()) then return end
					self.db.profile.enabled = val 
					self:UpdateSettings()
				end,
				order = 1
			},
		}
	}
end

PlayerAuras.HideBlizzard = function(self)
	local UIHider = CreateFrame("Frame")
	UIHider:Hide()

	BuffFrame:UnregisterAllEvents()
	BuffFrame:SetParent(UIHider)

	if (ns.WoWMainline or ns.WoWCamelot) then
		BuffFrame.numHideableBuffs = 0 -- EditMode bug in Retail/Forever
	end

	if (DebuffFrame) then
		DebuffFrame:UnregisterAllEvents()
		DebuffFrame:SetParent(UIHider)
	end

	if (ns.WoWClassic or ns.WoWWrath or ns.WoWMists) then
		TemporaryEnchantFrame:UnregisterAllEvents()
		TemporaryEnchantFrame:SetParent(UIHider)
	end

	if (ns.WoWWrath or ns.WoWMists) then
		ConsolidatedBuffs:UnregisterAllEvents()
		ConsolidatedBuffs:SetParent(UIHider)
	end
end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling.
PlayerAuras.UpdateSettings = function(self)
	-- These two only fires on manual settings changes
	if (self.db.profile.enabled) and (not self:IsEnabled()) then
		ReloadUI()
	
	elseif (not self.db.profile.enabled) and (self:IsEnabled()) then
		ReloadUI()
	end
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
PlayerAuras.RefreshConfig = function(self)
	self:UpdateSettings()
end

PlayerAuras.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("PlayerAuras", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

PlayerAuras.OnEnable = function(self)
	if (not self.db.profile.enabled) then return self:Disable() end

	self:HideBlizzard()
end
