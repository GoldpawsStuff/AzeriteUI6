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

local UIHider = CreateFrame("Frame")
UIHider:Hide()

-- Declare module defaults
local defaults = { profile = {
	enabled = true,
}}

local function ShouldConsolidate()
	-- Respect the same CVar Blizzard uses (Forever + Classic clients)
	if ns.WoWMainline then return false end
	return C_CVar.GetCVarBool("consolidateBuffs")
end

local function ShowDurations()
	return C_CVar.GetCVarBool("buffDurations")
end

local function CreateAuraContainer(name, unit, filter)
	local container = CreateFrame("AuraContainer", name, UIParent, "CustomAuraContainerTemplate")
	container:SetUnit(unit)

	container:AddAuraGroup(filter == "HELPFUL" and "buffs" or "debuffs", filter, {
		maxFrameCount = filter == "HELPFUL" and 32 or 16,
		sortMethod = AuraContainerSortMethod and AuraContainerSortMethod.Expiration or nil,
		sortDirection = AuraContainerSortDirection and AuraContainerSortDirection.Reverse or nil,
		layout = {
			elementWidth = 30,
			elementHeight = 40,
			elementSpacing = 2,
			groupSpacing = 4,
		},
		initializeFrame = function(button)
			-- Icon (required)
			local icon = button:CreateTexture(nil, "ARTWORK")
			icon:SetSize(30, 30)
			icon:SetPoint("TOP")
			button:SetIcon(icon)					-- must call this

			-- Duration (pick one)
			local duration = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			duration:SetPoint("TOP", icon, "BOTTOM")
			button:SetDurationText(duration)		-- or SetDurationCooldown(cooldown)

			-- Count
			local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
			count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -2, 2)
			button:SetApplicationCount(count)

			-- Optional debuff border
			local border = button:CreateTexture(nil, "OVERLAY")
			border:SetSize(40, 40)
			border:SetPoint("CENTER", icon)
			button:AddDispelTypeTexture(border, {
				style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
				showWithoutDispelType = true,
			})
		end
	})

	-- Weapon enchants (if the API supports it on this build)
	if container.AddItemEnchantment and AuraContainerItemEnchantmentSlot then
		local enchantOptions = {
			layout = { elementWidth = 30, elementHeight = 40 },
			initializeFrame = function(button)
				-- same visual setup + TempEnchantBorder
			end,
		}

		container:AddItemEnchantment(AuraContainerItemEnchantmentSlot.MainHand, enchantOptions)
		container:AddItemEnchantment(AuraContainerItemEnchantmentSlot.OffHand, enchantOptions)
		-- container:AddItemEnchantment(AuraContainerItemEnchantmentSlot.Ranged, enchantOptions) -- only if you want it
	end

	return container
end

local function CreateSecureAuraHeader(name, filter)
	local header = CreateFrame("Frame", name, UIParent, "SecureAuraHeaderTemplate")
	header:SetAttribute("unit", "player")
	header:SetAttribute("filter", filter)
	header:SetAttribute("template", "AzeriteAuraButtonTemplate")
	header:SetAttribute("weaponTemplate", "AzeriteAuraButtonTemplate")

	-- Size & layout matching Blizzard defaults (30×40 buttons, ~2 px spacing)
	header:SetAttribute("style-width", 30)
	header:SetAttribute("style-height", 40)
	header:SetAttribute("minWidth", 30)
	header:SetAttribute("minHeight", 40)
	header:SetAttribute("point", "TOPRIGHT")
	header:SetAttribute("xOffset", -32)
	header:SetAttribute("yOffset", 0)
	header:SetAttribute("wrapAfter", 8)
	header:SetAttribute("wrapXOffset", 0)
	header:SetAttribute("wrapYOffset", -42)
	header:SetAttribute("maxWraps", 4)
	header:SetAttribute("sortMethod", "TIME")
	header:SetAttribute("sortDirection", "+")
	header:SetAttribute("separateOwn", 1)
	header:SetAttribute("includeWeapons", 1)

	-- Consolidation (only when the CVar is on, same thresholds Blizzard uses)
	if ShouldConsolidate() then
		header:SetAttribute("consolidateTo", 1)
		header:SetAttribute("consolidateDuration", 30)
		header:SetAttribute("consolidateThreshold", 10)
		header:SetAttribute("consolidateFraction", 0.10)
	else
		header:SetAttribute("consolidateTo", 0)
	end

	-- Update visuals when the secure header changes an index
	header:SetScript("OnAttributeChanged", function(self, attr, value)
		if attr ~= "index" then return end
		local button = self:GetAttribute("child"..value) or self:GetAttribute("tempEnchant"..value)
		if not button then return end

		local unit = self:GetAttribute("unit")
		local filter = self:GetAttribute("filter")
		local name, icon, count, debuffType, duration, expirationTime, _, _, _, _, _, _, _, _, isTempEnchant = UnitAura(unit, value, filter)

		if icon then
			button.Icon:SetTexture(icon)
			button:Show()

			-- Count
			if count and count > 1 then
				button.Count:SetText(count)
				button.Count:Show()
			else
				button.Count:Hide()
			end

			-- Duration (respect buffDurations CVar)
			if ShowDurations() and duration and duration > 0 and expirationTime then
				button.Duration:Show()
				-- simple remaining time; you can refine with your existing time formatter
				local remaining = expirationTime - GetTime()
				if remaining > 0 then
					button.Duration:SetText(format("%.0f", remaining))
				else
					button.Duration:SetText("")
				end
			else
				button.Duration:Hide()
			end

			-- Borders
			if debuffType then
				button.DebuffBorder:Show()
				-- optional: color by type if you want the classic colored borders
			else
				button.DebuffBorder:Hide()
			end

			if isTempEnchant then
				button.TempEnchantBorder:Show()
			else
				button.TempEnchantBorder:Hide()
			end
		else
			button:Hide()
		end
	end)

	return header
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
				name = L["Disable Default Auras"], -- L["Enable"],
				desc = "", -- L["Toggle the usage of our Buff & Debuff Frames. Note that disabling this will force a user interface reload to re-enable the game's default Buff- and Debuff Frames."],
				disabled = function() return InCombatLockdown() end,
				get = function(info) return self.db.profile.enabled end,
				set = function(info, val) 
					if (InCombatLockdown()) then return end
					if (ns.WoWCamelot or ns.WoWMainline) then
						ns:ShowPrompt("Reload UI", "Toggling this option requires a user interface reload.|n|nAre you sure?", {
							{ text = ACCEPT, onClick = function() 
								self.db.profile.enabled = val
								ns.Reload()
							end },
							{ text = CANCEL, cancel = true, onClick = function() end },
						})
						return
					end
					self.db.profile.enabled = val 
					ns.Reload()
				end,
				confirm = not (ns.WoWCamelot or ns.WoWMainline) and true or nil,
				order = 10
			},
		}
	}
end

PlayerAuras.HideBlizzard = function(self)
	if (BuffFrame) then
		BuffFrame:UnregisterAllEvents()
		BuffFrame:SetParent(UIHider)

		if (ns.WoWMainline or ns.WoWCamelot) then
			BuffFrame.numHideableBuffs = 0 -- EditMode bug in Retail/Forever
		end
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

	if (ns.WoWCamelot or ns.WoWMainline) then 
		self.Buffs = CreateAuraContainer("AzeriteBuffs", "player", "HELPFUL")
		self.Debuffs = CreateAuraContainer("AzeriteDebuffs", "player", "HARMFUL")
	else
		self.Buffs = CreateSecureAuraHeader("AzeriteBuffHeader", "HELPFUL")
		self.Debuffs = CreateSecureAuraHeader("AzeriteDebuffHeader", "HARMFUL")
	end

	self.Buffs:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -36, -36)
	self.Debuffs:SetPoint("TOPRIGHT", buffs, "BOTTOMRIGHT", -15, -4)

	local testbackdrop = self.Buffs:CreateTexture(nil, "BACKGROUND")
	testbackdrop:SetAllPoints()
	testbackdrop:SetColorTexture(0, .7, 0, .3)

end
