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

local L = LibStub("AceLocale-3.0"):GetLocale((...))
local LAYOUT_NAME = L["Azerite UI Default"]
local LAYOUT_NAME_GAMEPAD = L["Azerite UI Default (Gamepad)"]

local EditModePreset = ns:NewModule("EditMode", nil, "AceConsole-3.0", "LibMoreEvents-1.0")

local defaults = { profile = {
	enabled = true
}}

-- Forever (and some Classic) fallbacks.
-- *EditMode size settings are ignored here, we need to manually set them.
local ForceChatSize = function()
	if (SetChatWindowSavedDimensions) then
		SetChatWindowSavedDimensions(1, 440, 220)
	end
end

-- The MinimapCluster is sized differently on the initial login on some flavors.
-- Forcing the cluster size corrects the first-login misalignment.
local ForceMinimapSize = function()
	if (ns.WoWCamelot or ns.WoWRetail) then return end
	if (not MinimapCluster) then return end
	MinimapCluster:SetSize(230, 216)
end

EditModePreset.GetSystem = function(self, systems, systemID, systemIndex)
	for _, sys in ipairs(systems) do
		if (sys.system == systemID) then
			if (not systemIndex or sys.systemIndex == systemIndex) then
				return sys
			end
		end
	end
end

EditModePreset.SetSystemAnchor = function(self, sys, point, relativePoint, x, y, relativeTo)
	if (not sys) then return end

	sys.isInDefaultPosition = false
	sys.anchorInfo = {
		point = point,
		relativeTo = relativeTo or "UIParent",
		relativePoint = relativePoint,
		offsetX = x,
		offsetY = y,
	}
end

EditModePreset.SetSystemSetting = function(self, sys, settingID, value)
	if (not sys) then return end

	sys.settings = sys.settings or {}

	for _, row in ipairs(sys.settings) do
		if (row.setting == settingID) then
			row.value = value
			return
		end
	end
	sys.settings[#sys.settings + 1] = { setting = settingID, value = value }
end

EditModePreset.SetChatSize = function(self, system, width, height)
	if (not system) then return end

	width  = math.floor(width)
	height = math.floor(height)

	self:SetSystemSetting(system, 0, math.floor(width  / 100))	-- WidthHundreds
	self:SetSystemSetting(system, 1, width  % 100)				-- WidthTensAndOnes
	self:SetSystemSetting(system, 2, math.floor(height / 100))	-- HeightHundreds
	self:SetSystemSetting(system, 3, height % 100)				-- HeightTensAndOnes
end

EditModePreset.ApplySystemSettings = function(self, target)
	if (not target) then return end

	-- Minimap
	local minimap = self:GetSystem(target.systems, Enum.EditModeSystem.Minimap)
	if (ns.WoWCamelot or ns.WoWRetail) then
		self:SetSystemAnchor(minimap, "BOTTOMRIGHT", "BOTTOMRIGHT", -30, 30)
	else
		-- Do not touch header-underneath. It desyncs the cluster and needs a /reload.
		self:SetSystemAnchor(minimap, "BOTTOMRIGHT", "BOTTOMRIGHT", -46, 74)
	end
	self:SetSystemSetting(minimap, 0, 0) -- Header Underneath = off
	self:SetSystemSetting(minimap, 2, (ns.WoWRetail or ns.WoWCamelot) and 5 or 8)

	-- Chat
	local chat = self:GetSystem(target.systems, Enum.EditModeSystem.ChatFrame)
	self:SetSystemAnchor(chat, "BOTTOMLEFT", "BOTTOMLEFT", 60, 306)
	self:SetChatSize(chat, 440, 180)

	-- HUD Tooltip
	local tooltip = self:GetSystem(target.systems, Enum.EditModeSystem.HudTooltip)
	self:SetSystemAnchor(tooltip, "BOTTOMRIGHT", "BOTTOMRIGHT", -319, 166)

	-- Objective Tracker
	local tracker = self:GetSystem(target.systems, Enum.EditModeSystem.ObjectiveTracker)
	self:SetSystemAnchor(tracker, "BOTTOMRIGHT", "BOTTOMRIGHT", -44, 330)
	self:SetSystemSetting(tracker, 0, 1)

	-- Buffs
	local buffs = self:GetSystem(target.systems, Enum.EditModeSystem.AuraFrame, Enum.EditModeAuraFrameSystemIndices and Enum.EditModeAuraFrameSystemIndices.BuffFrame or 1)
	self:SetSystemAnchor(buffs, "TOPRIGHT", "TOPRIGHT", -36, -36)
	-- Optional: orientation / size settings if you want them
	-- self:SetSystemSetting(buffs, Enum.EditModeAuraFrameSetting.Orientation, 0) -- 0 = horizontal

	-- Debuffs attached to the BuffFrame
	local debuffs = self:GetSystem(target.systems, Enum.EditModeSystem.AuraFrame, Enum.EditModeAuraFrameSystemIndices and Enum.EditModeAuraFrameSystemIndices.DebuffFrame or 2)
	self:SetSystemAnchor(debuffs, "TOPRIGHT", "BOTTOMRIGHT", -15, -4, "BuffFrame")

	-- Equipment Durability
	local durability = self:GetSystem(target.systems, Enum.EditModeSystem.DurabilityFrame)
	self:SetSystemAnchor(durability, "BOTTOMRIGHT", "BOTTOMRIGHT", -319, 166)
	self:SetSystemSetting(durability, 0, 5) -- Size (0–25, roughly 75% + n*5%)

	-- Group Finder Eye (primarily Forever / later clients)
	local groupFinder = self:GetSystem(target.systems, Enum.EditModeSystem.GroupFinder)
	self:SetSystemAnchor(groupFinder, "TOPLEFT", "TOPLEFT", 10, -10, "Minimap")

	-- Loot Window
	local loot = self:GetSystem(target.systems, Enum.EditModeSystem.LootFrame)
	self:SetSystemAnchor(loot, "BOTTOMRIGHT", "CENTER", -180, -20)

	-- Cast Bar
	local cast = self:GetSystem(target.systems, Enum.EditModeSystem.CastBar)
	self:SetSystemAnchor(cast, "BOTTOM", "BOTTOM", 0, 220)

	-- Duration Bars
	local duration = self:GetSystem(target.systems, Enum.EditModeSystem.TimerBars)
	self:SetSystemAnchor(duration, "BOTTOM", "CENTER", 0, 180)

	-- Loss of Control
	local loc = self:GetSystem(target.systems, Enum.EditModeSystem.LossOfControl)
	self:SetSystemAnchor(loc, "BOTTOM", "CENTER", 0, 60)
	-- self:SetSystemSetting(loc, 0, 5) -- Size if the setting exists

	-- Raid Warning
	local raidWarning = self:GetSystem(target.systems, Enum.EditModeSystem.RaidWarning)
	self:SetSystemAnchor(raidWarning, "TOP", "TOP", 0, -120)

	-- Boss Frames (UnitFrame subsystem)
	local boss = self:GetSystem(target.systems, Enum.EditModeSystem.UnitFrame, Enum.EditModeUnitFrameSystemIndices and Enum.EditModeUnitFrameSystemIndices.Boss or 6)
	self:SetSystemAnchor(boss, "RIGHT", "RIGHT", -50, 0)
	-- Optional common settings:
	-- self:SetSystemSetting(boss, Enum.EditModeUnitFrameSetting.UseLargerFrame, 0)
	-- self:SetSystemSetting(boss, Enum.EditModeUnitFrameSetting.CastBarOnSide, 1)

end

-- Returns the full layout index (presets + custom index) for a layout name,
-- or nil if it is not present in the given layouts table.
local function GetFullIndexForName(layouts, layoutName)
	if (not layouts) then return end

	local customIndex
	for i, layout in ipairs(layouts) do
		if (layout.layoutName == layoutName) then
			customIndex = i
			break
		end
	end
	if (not customIndex) then return end

	local presets = EditModePresetLayoutManager and EditModePresetLayoutManager.GetCopyOfPresetLayouts and EditModePresetLayoutManager:GetCopyOfPresetLayouts()
	local presetCount = (presets and #presets) or (Enum.EditModePresetLayoutsMeta and Enum.EditModePresetLayoutsMeta.NumValues) or 2
	return presetCount + customIndex
end

-- Current interface style. Falls back to Mkb when the API is missing.
local function GetCurrentInterfaceStyle()
	if (InputUtil and InputUtil.GetCurrentInterfaceStyle) then
		return InputUtil.GetCurrentInterfaceStyle()
	end
	return Enum.InputDeviceInterfaceType and Enum.InputDeviceInterfaceType.Mkb
end

EditModePreset.CreateOrUpdateLayout = function(self, forced)
	if (self.hasAppliedLayout or InCombatLockdown()) then return end
	if (not C_EditMode or not EditModePresetLayoutManager) then return end

	local info = C_EditMode.GetLayouts()
	if (not info or not info.layouts) then return end

	-- Remove any leftover account-wide layout with our name.
	for i, layout in ipairs(info.layouts) do
		if (layout.layoutName == LAYOUT_NAME and layout.layoutType == Enum.EditModeLayoutType.Account) then
			table.remove(info.layouts, i)
			break
		end
	end

	local createdNew = false
	local createdNewGamepad = false

	-- -------------------------------------------------
	-- Standard (Mkb) layout
	-- -------------------------------------------------
	local existingIndex
	for i, layout in ipairs(info.layouts) do
		if (layout.layoutName == LAYOUT_NAME) then
			existingIndex = i
			break
		end
	end

	local target
	if (existingIndex) then
		if (forced) then
			target = info.layouts[existingIndex]
			self:ApplySystemSettings(target)
		end
	else
		local presets = EditModePresetLayoutManager:GetCopyOfPresetLayouts()
		local base
		for _, p in ipairs(presets) do
			if (p.layoutName == LAYOUT_STYLE_MODERN) then
				base = p
				break
			end
		end
		base = base or presets[1]
		if (not base) then return end

		target = CopyTable(base)
		target.layoutName = LAYOUT_NAME
		target.layoutType = Enum.EditModeLayoutType.Character
		if (Enum.InputDeviceInterfaceType) then
			target.interfaceStyle = Enum.InputDeviceInterfaceType.Mkb
		end

		table.insert(info.layouts, target)
		existingIndex = #info.layouts
		self:ApplySystemSettings(target)
		createdNew = true
	end

	-- -------------------------------------------------
	-- Gamepad layout (Forever / Camelot only)
	-- -------------------------------------------------
	if (ns.WoWCamelot) then
		local gamepadIndex
		for i, layout in ipairs(info.layouts) do
			if (layout.layoutName == LAYOUT_NAME_GAMEPAD) then
				gamepadIndex = i
				break
			end
		end

		local gamepadTarget
		if (gamepadIndex) then
			if (forced) then
				gamepadTarget = info.layouts[gamepadIndex]
				self:ApplySystemSettings(gamepadTarget)
			end
		else
			local presets = EditModePresetLayoutManager:GetCopyOfPresetLayouts()
			local base
			for _, p in ipairs(presets) do
				if (p.layoutName == LAYOUT_STYLE_GAMEPAD) then
					base = p
					break
				end
			end
			base = base or presets[1]
			if (base) then
				gamepadTarget = CopyTable(base)
				gamepadTarget.layoutName = LAYOUT_NAME_GAMEPAD
				gamepadTarget.layoutType = Enum.EditModeLayoutType.Character
				if (Enum.InputDeviceInterfaceType) then
					gamepadTarget.interfaceStyle = Enum.InputDeviceInterfaceType.Gamepad
				end

				table.insert(info.layouts, gamepadTarget)
				self:ApplySystemSettings(gamepadTarget)
				createdNewGamepad = true
			end
		end
	end

	-- Nothing new was created and we are not forcing an update → done.
	-- This is the "only on first run" gate for activation.
	if (not createdNew and not createdNewGamepad and not forced) then
		self.hasAppliedLayout = true
		return
	end

	-- Decide which layout should become active (only matters on first creation).
	local activateName = LAYOUT_NAME
	if (ns.WoWCamelot) then
		local style = GetCurrentInterfaceStyle()
		if (style == Enum.InputDeviceInterfaceType.Gamepad) then
			activateName = LAYOUT_NAME_GAMEPAD
		end
	end

	local fullIndex = GetFullIndexForName(info.layouts, activateName)

	-- Write the intended active layout into the table we are about to save.
	-- Forever’s manager is much more reliable when the field is set before SaveLayouts.
	if (fullIndex) then
		info.activeLayout = fullIndex
	end

	self.hasAppliedLayout = true
	C_EditMode.SaveLayouts(info)

	-- Only switch on the first run (when we just created the layout).
	-- Subsequent logins leave the player’s current choice alone.
	if (fullIndex and (createdNew or createdNewGamepad)) then
		C_Timer.After(0, function()
			if (InCombatLockdown()) then return end

			C_EditMode.SetActiveLayout(fullIndex)

			-- Light visual refresh. Avoids the “stuck until reload” state on some clients.
			C_Timer.After(0.1, function()
				if (InCombatLockdown()) then return end
				C_EditMode.SetActiveLayout(fullIndex)
				ForceMinimapSize()
			end)

			ForceChatSize()
			ForceMinimapSize()
		end)
	end
end

EditModePreset.ResetLayout = function(self)
	self.hasAppliedLayout = false
	self:CreateOrUpdateLayout(true)
end

EditModePreset.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		local isInitialLogin = ...
		if (isInitialLogin) then
			C_Timer.After(1.5, function() self:CreateOrUpdateLayout() end)
		else
			self:CreateOrUpdateLayout()
		end
	else
		self:CreateOrUpdateLayout()
	end

	if (self.hasAppliedLayout) then
		self:UnregisterEvent("EDIT_MODE_LAYOUTS_UPDATED", "OnEvent")
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	end
end

EditModePreset.UpdateSettings = function(self)
end

EditModePreset.RefreshConfig = function(self)
	self:UpdateSettings()
end

EditModePreset.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("EditMode", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	self:RegisterChatCommand("resetlayout", "ResetLayout")
end

EditModePreset.OnEnable = function(self)
	self:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
end
