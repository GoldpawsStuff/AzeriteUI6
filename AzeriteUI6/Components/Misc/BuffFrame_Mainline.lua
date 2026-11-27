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

local PlayerAuras = ns:NewModule("PlayerAuras", nil, "AceHook-3.0", "LibMoreEvents-1.0", "LibMovableFrames-1.0", "LibFadingFrames-1.0")

-- Declare module defaults
local defaults = { profile = {
	enabled = true,
	fadePlayerAuras = true,
	hideWithTarget = true
}}

local style = function(self)

	self:SetSize(.001, .001)
	self:SetPoint("TOPRIGHT", -50, -50)
	self:EnableMouse(false)

	-- Little hack to avoid "stuck" numbers on auras with no duration
	local binding = C_DurationUtil.CreateDurationTextBinding()
	binding:SetZeroDurationText("") -- clears the stuck number
	binding:SetExpiredText("") -- optional, for fully expired
	--binding:SetFormatter(...) -- if you want custom formatting
	--binding:SetUpdateInterval(0.1) -- optional

	local buffs = self:CreateAurasElement({ layoutLimit = 272, initialAnchor = "TOPRIGHT", growthX = "LEFT", growthY = "DOWN" })
	buffs:SetSize(272, 136) 
	buffs:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -50, -50)

	buffs.durationBinding = binding
	buffs.showCount = true
	buffs.showDuration = true
	buffs.showBuffBorder = false

	-- Group options
	buffs.size = 30
	buffs.elementSpacing = 4 -- Spacing between each button (number) 
	buffs.forceNewLine = false -- Whether to force a new row or column between each group (boolean)
	buffs.groupSpacing = 4 -- Spacing between each group (number) 
	buffs.groupLineSpacing = 4 -- Spacing between each group row or column 
	buffs.lineSpacing = 4 -- Spacing between each button row or column (number) 
	buffs.maxFrameCount = 32 -- Number of buttons to display. Defaults to an infinite number (number)
	buffs.sortDirection = AuraContainerSortDirection.Normal
	buffs.sortMethod = AuraContainerSortMethod.ExpirationOnly

	-- Right-click to cancel (uses C_UnitAuras.CancelAuraByInstanceID)
	buffs.cancelButton = "RightButtonUp" -- does not work?

	-- Buffs
	buffs:AddGroup("HELPFUL", {
		initializeFrame = ns.AuraButton_InitializeFloatingBuff,
	})

	local debuffs = self:CreateAurasElement({ layoutLimit = 240, initialAnchor = "TOPRIGHT", growthX = "LEFT", growthY = "DOWN" })
	debuffs:SetSize(240, 60)
	debuffs:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -50, -192)

	debuffs.durationBinding = binding
	debuffs.showCount = true
	debuffs.showDuration = true
	debuffs.showBuffBorder = false

	-- Group options
	debuffs.size = 26
	debuffs.elementSpacing = 4 -- Spacing between each button (number) 
	debuffs.forceNewLine = false -- Whether to force a new row or column between each group (boolean)
	debuffs.groupSpacing = 4 -- Spacing between each group (number) 
	debuffs.groupLineSpacing = 4 -- Spacing between each group row or column 
	debuffs.lineSpacing = 4 -- Spacing between each button row or column (number) 
	debuffs.maxFrameCount = 16 -- Number of buttons to display. Defaults to an infinite number (number)
	debuffs.sortDirection = AuraContainerSortDirection.Normal
	debuffs.sortMethod = AuraContainerSortMethod.ExpirationOnly

	-- Debuffs
	debuffs:AddGroup("HARMFUL", {
		initializeFrame = ns.AuraButton_InitializeFloatingDebuff,
	})

	self.Buffs = buffs
	self.Debuffs = debuffs
end

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
					ns:ShowPrompt("Reload UI", "Toggling this option requires a user interface reload.|n|nAre you sure?", {
						{ text = ACCEPT, onClick = function() 
							self.db.profile.enabled = val
							ns.Reload()
						end },
						{ text = CANCEL, cancel = true, onClick = function() end },
					})
				end,
				order = 10
			},
			hideWithTarget = {
				type = "toggle", width = "full",
				name = "Hide with Target",
				desc = "",
				disabled = function() return InCombatLockdown() end,
				hidden = function() return not self.db.profile.enabled end,
				get = function(info) return self.db.profile.hideWithTarget end,
				set = function(info, val) 
					if (InCombatLockdown()) then return end
					self.db.profile.hideWithTarget = val
					self:UpdateSettings()
				end,
				order = 100
			},
		}
	}
end

PlayerAuras.GetFrame = function(self)
	return self.BuffAnchor, self.DebuffAnchor
end

PlayerAuras.UpdatePlayerAuraFading = function(self)
	local ExplorerMode = ns:GetModule("ExplorerMode", true)
	if (ExplorerMode) then
		if (ExplorerMode.db.profile.enabled and self.db.profile.fadePlayerAuras) then 
			self:RegisterFrameForFading(self.BuffAnchor, "PlayerAurasHUD")
			self:RegisterFrameForFading(self.DebuffAnchor, "PlayerAurasHUD")
		else
			self:UnregisterFrameForFading(self.BuffAnchor)
			self:UnregisterFrameForFading(self.DebuffAnchor)
		end
		return
	end
	if (self.db.profile.fadePlayerAuras) then
		self:RegisterFrameForFading(self.BuffAnchor, "PlayerAurasHUD")
		self:RegisterFrameForFading(self.DebuffAnchor, "PlayerAurasHUD")
	else
		self:UnregisterFrameForFading(self.BuffAnchor)
		self:UnregisterFrameForFading(self.DebuffAnchor)
	end
end

PlayerAuras.UpdateVisibilityDriver = function(self)
	if (InCombatLockdown()) then return end

	local driver
	if (self.db.profile.hideWithTarget) then
		if (ns.WoWMainline) then
			driver = "[petbattle]hide;[@target,exists]hide;show"
		else
			driver = "[@target,exists]hide;show"
		end
	else
		if (ns.WoWMainline) then
			driver = "[petbattle]hide;show"
		else
			driver = "show"
		end
	end

	if (self.BuffAnchor) then
		UnregisterStateDriver(self.BuffAnchor, "visibility")
		RegisterStateDriver(self.BuffAnchor, "visibility", driver)
	end

	if (self.DebuffAnchor) then
		UnregisterStateDriver(self.DebuffAnchor, "visibility")
		RegisterStateDriver(self.DebuffAnchor, "visibility", driver)
	end
end

-- Hide Blizzard's floating aura frames
PlayerAuras.HideBlizzard = function(self)
	local UIHider = CreateFrame("Frame")
	UIHider:Hide()

	if (BuffFrame) then
		BuffFrame:UnregisterAllEvents()
		BuffFrame:SetParent(UIHider)
		BuffFrame.numHideableBuffs = 0 -- EditMode bug in Retail/Forever
	end

	if (DebuffFrame) then
		DebuffFrame:UnregisterAllEvents()
		DebuffFrame:SetParent(UIHider)
	end
end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling.
PlayerAuras.UpdateSettings = function(self)
	self:UpdateVisibilityDriver()
	self:UpdatePlayerAuraFading()
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

	oUF:RegisterStyle("AzeritePlayerAuras", style)
	oUF:Factory(function(self)
		self:SetActiveStyle("AzeritePlayerAuras")

		local buffAnchor = CreateFrame("Frame", "AzeriteUI6PlayerBuffs", UIParent, "SecureHandlerStateTemplate")
		buffAnchor:SetSize(272, 136)
		buffAnchor:SetPoint("TOPRIGHT", -50, -50)
		buffAnchor.__prevent_alpha_reset = true

		PlayerAuras.BuffAnchor = buffAnchor

		local debuffAnchor = CreateFrame("Frame", "AzeriteUI6PlayerDebuffs", UIParent, "SecureHandlerStateTemplate")
		debuffAnchor:SetSize(240, 60)
		debuffAnchor:SetPoint("TOPRIGHT", -50, -192)
		debuffAnchor.__prevent_alpha_reset = true

		PlayerAuras.DebuffAnchor = debuffAnchor

		local frame = self:Spawn("player", "AzeritePlayerAuras")
		frame:SetPoint("BOTTOM", UIParent, "TOP", 0, 100)

		PlayerAuras.UnitFrame = frame

		local buffs = frame.Buffs
		buffs:SetParent(buffAnchor)
		buffs:ClearAllPoints()
		buffs:SetPoint("TOPRIGHT", buffAnchor, "TOPRIGHT", 0, 0)

		PlayerAuras.Buffs = buffs

		local debuffs = frame.Debuffs
		debuffs:SetParent(debuffAnchor)
		debuffs:ClearAllPoints()
		debuffs:SetPoint("TOPRIGHT", debuffAnchor, "TOPRIGHT", 0, 0)

		PlayerAuras.Debuffs = debuffs

		PlayerAuras:RegisterMovableFrameAnchor(buffAnchor, string.lower(L["Player Buffs"]), "floater", AzeriteUI6_Positions_DB)
		PlayerAuras:RegisterMovableFrameAnchor(debuffAnchor, string.lower(L["Player Debuffs"]), "floater", AzeriteUI6_Positions_DB)

		PlayerAuras:UpdateVisibilityDriver()
		PlayerAuras:UpdatePlayerAuraFading()
	end)
end
