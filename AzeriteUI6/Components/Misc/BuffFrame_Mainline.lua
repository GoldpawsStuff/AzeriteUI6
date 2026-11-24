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

-- Constants matching Forever/Retail BuffFrame
local BUFF_DURATION_WARNING_TIME = 60
local BUFF_MAX_DISPLAY = 32
local DEBUFF_MAX_DISPLAY = 16

-- Local helpers
local function IsModern()
	return ns.WoWCamelot or ns.WoWMainline
end

local function GetCVarBool(name)
	return C_CVar.GetCVarBool(name)
end

local function ShouldConsolidate()
	return GetCVarBool("consolidateBuffs")
end

local function ShouldCollapseExpand()
	return GetCVarBool("collapseExpandBuffs") and not ShouldConsolidate()
end

-- Hide Blizzard's floating aura frames
PlayerAuras.HideBlizzard = function(self)
	local UIHider = CreateFrame("Frame")
	UIHider:Hide()

	if (BuffFrame) then
		BuffFrame:UnregisterAllEvents()
		BuffFrame:SetParent(UIHider)
		if (IsModern()) then
			BuffFrame.numHideableBuffs = 0 -- EditMode bug in Retail/Forever
		end
	end

	if (DebuffFrame) then
		DebuffFrame:UnregisterAllEvents()
		DebuffFrame:SetParent(UIHider)
	end
end

-- Collapse / consolidation state
local isExpanded = true
local numHideableBuffs = 0
local auraInfo = {}

local function IsExpanded()
	if (ShouldCollapseExpand()) then
		return isExpanded
	elseif (ShouldConsolidate()) then
		return false
	end
	return true
end

local function HasHiddenBuffs()
	return not IsExpanded() and numHideableBuffs > 0
end

-- Evaluate whether a buff should be hidden when collapsed
local function IsHideUnlessExpanded(duration, expirationTime)
	if (not duration or not expirationTime) then return true end
	if (duration == 0 or expirationTime == 0) then return true end
	local timeLeft = expirationTime - GetTime()
	return timeLeft > BUFF_DURATION_WARNING_TIME
end

-- Build the hideable set (out of combat only; secrets block this in combat)
local function RebuildHideableSet()
	if (InCombatLockdown() or C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret()) then
		return
	end

	wipe(auraInfo)
	numHideableBuffs = 0

	local index = 0
	AuraUtil.ForEachAura("player", "HELPFUL", BUFF_MAX_DISPLAY, function(auraData)
		index = index + 1
		local hide = IsHideUnlessExpanded(auraData.duration, auraData.expirationTime)
		if (hide) then
			numHideableBuffs = numHideableBuffs + 1
		end
		auraInfo[index] = {
			auraInstanceID = auraData.auraInstanceID,
			hideUnlessExpanded = hide,
			expirationTime = auraData.expirationTime,
		}
		return index >= BUFF_MAX_DISPLAY
	end)
end

-- Promote buffs that have fallen under the warning threshold
local function PromoteExpiringBuffs()
	if (not HasHiddenBuffs()) then return end

	local needsUpdate = false
	for _, info in ipairs(auraInfo) do
		if (info.hideUnlessExpanded and info.expirationTime and info.expirationTime > 0) then
			local timeLeft = info.expirationTime - GetTime()
			if (timeLeft <= BUFF_DURATION_WARNING_TIME) then
				info.hideUnlessExpanded = false
				numHideableBuffs = math.max(0, numHideableBuffs - 1)
				needsUpdate = true
			end
		end
	end

	if (needsUpdate) then
		PlayerAuras:UpdateVisibility()
	end
end

local function Style(self)

	self:SetSize(1, 1)
	self:SetAlpha(0)
	self:EnableMouse(false)

	-- Little hack to avoid "stuck" numbers on auras with no duration
	local binding = C_DurationUtil.CreateDurationTextBinding()
	binding:SetZeroDurationText("") -- clears the stuck number
	binding:SetExpiredText("") -- optional, for fully expired
	--binding:SetFormatter(...) -- if you want custom formatting
	--binding:SetUpdateInterval(0.1) -- optional

	local buffs = self:CreateAurasElement({
		initialAnchor = "TOPRIGHT",
		growthX = "LEFT",
		growthY = "DOWN",
		layout = AnchorUtil.FlowLayoutAxis.Horizontal,
		layoutLimit = 800, -- prevent wrapping on the 1x1 dummy frame
	})

	buffs:SetSize(30*math.floor(BUFF_MAX_DISPLAY/4) - 4, 30*math.ceil(BUFF_MAX_DISPLAY/(math.floor(BUFF_MAX_DISPLAY/4))) - 4)
	buffs:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -40, -40)
	buffs:SetParent(UIParent)

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
	buffs.maxFrameCount = 8 -- Number of buttons to display. Defaults to an infinite number (number)
	buffs.sortDirection = AuraContainerSortDirection.Normal
	buffs.sortMethod = AuraContainerSortMethod.ExpirationOnly 

	-- Right-click to cancel (uses C_UnitAuras.CancelAuraByInstanceID)
	buffs.cancelButton = "RightButtonUp"

	-- Buffs
	buffs:AddGroup("HELPFUL", {
		maxFrameCount = BUFF_MAX_DISPLAY,
		sortMethod = AuraContainerSortMethod and AuraContainerSortMethod.Expiration or nil,
		sortDirection = AuraContainerSortDirection and AuraContainerSortDirection.Reverse or nil,
		initializeFrame = ns.AuraButton_InitializeFloatingBuff,
	})

	local debuffs = self:CreateAurasElement({
		initialAnchor = "TOPRIGHT",
		growthX = "LEFT",
		growthY = "DOWN",
		layout = AnchorUtil.FlowLayoutAxis.Horizontal,
		layoutLimit = 800, -- prevent wrapping on the 1x1 dummy frame
	})

	debuffs:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, -(40 + buffs:GetHeight()) + 20)
	debuffs:SetParent(UIParent)

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
	debuffs.maxFrameCount = 8 -- Number of buttons to display. Defaults to an infinite number (number)
	debuffs.sortDirection = AuraContainerSortDirection.Normal
	debuffs.sortMethod = AuraContainerSortMethod.ExpirationOnly 

	-- Debuffs
	debuffs:AddGroup("HARMFUL", {
		maxFrameCount = DEBUFF_MAX_DISPLAY,
		sortMethod = AuraContainerSortMethod and AuraContainerSortMethod.Expiration or nil,
		sortDirection = AuraContainerSortDirection and AuraContainerSortDirection.Reverse or nil,
		initializeFrame = ns.AuraButton_InitializeBigDebuff,
	})

	self.Buffs = buffs
	self.Debuffs = debuffs
end

-- Apply visibility based on expanded state (simple approach: hide/show the whole group or individual buttons)
PlayerAuras.UpdateVisibility = function(self)
	local expanded = IsExpanded()
	local buffs = self.Buffs
	if (not buffs) then return end

	-- When fully expanded or no hideable buffs, show everything
	if (expanded or numHideableBuffs == 0) then
		buffs:SetShown(true)
		return
	end

	-- Collapsed: we still show the container but the layout will naturally
	-- only contain the non-hideable ones if we filter them.
	-- For a pure visual match we keep the container visible and rely on
	-- the group filter + our tracking. Full per-button hide is limited by secrets.
	buffs:SetShown(true)
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
				name = L["Disable Default Auras"],
				desc = "",
				disabled = function() return InCombatLockdown() end,
				get = function(info) return self.db.profile.enabled end,
				set = function(info, val)
					if (InCombatLockdown()) then return end
					if (IsModern()) then
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
				confirm = not IsModern() and true or nil,
				order = 10
			},
		}
	}
end

PlayerAuras.UpdateSettings = function(self)
	if (not IsModern() or not self.frame) then return end
	RebuildHideableSet()
	self:UpdateVisibility()
end

PlayerAuras.RefreshConfig = function(self)
	self:UpdateSettings()
end

PlayerAuras.OnCVarUpdate = function(self, event, cvar)
	if (cvar == "consolidateBuffs" or cvar == "collapseExpandBuffs") then
		self:UpdateSettings()
	end
end

PlayerAuras.OnUnitAura = function(self, event, unit)
	if (unit ~= "player") then return end
	if (not InCombatLockdown()) then
		RebuildHideableSet()
	end
	self:UpdateVisibility()
end

PlayerAuras.OnInitialize = function(self)
	if (not IsModern()) then return end

	self.db = ns.db:RegisterNamespace("PlayerAuras", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

PlayerAuras.OnEnable = function(self)
	if (not IsModern()) then return end
	if (not self.db.profile.enabled) then return self:Disable() end

	self:HideBlizzard()

	oUF:RegisterStyle("AzeritePlayerAuras", Style)
	oUF:Factory(function(self)
		self:SetActiveStyle("AzeritePlayerAuras")
		local frame = self:Spawn("player", "AzeritePlayerAuras")
		PlayerAuras.frame = frame
		PlayerAuras.Buffs = frame.Auras
	end)

	-- Track CVar changes and aura updates
	self:RegisterEvent("CVAR_UPDATE", "OnCVarUpdate")
	self:RegisterEvent("UNIT_AURA", "OnUnitAura")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateSettings")

	-- Throttled OnUpdate for promoting expiring buffs
	local updater = CreateFrame("Frame")
	updater.timer = 0
	updater:SetScript("OnUpdate", function(self, elapsed)
		self.timer = self.timer - elapsed
		if (self.timer > 0) then return end
		self.timer = 0.2
		PromoteExpiringBuffs()
	end)
	self.updater = updater

	self:UpdateSettings()
end

PlayerAuras.OnDisable = function(self)
	if (self.frame) then
		self.frame:Hide()
	end
	if (self.updater) then
		self.updater:SetScript("OnUpdate", nil)
	end
end
