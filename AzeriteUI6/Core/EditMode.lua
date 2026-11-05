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

-- Forever (possibly Classic Era?) fallback
-- *EditMode size settings are ignored here, we need to manually set them
local ForceChatSize = function()
	if (SetChatWindowSavedDimensions) then
		SetChatWindowSavedDimensions(1, 440, 220)
	end
end

-- The MinimapCluster is sized differently on the initial login, for some obscure reason.
-- We're attempting to force its size to fix this misalignment.
-- This appears to do the trick in Era, TBC and Mists so far. 
local ForceMinimapSize = function()
    if (ns.WoWCamelot or ns.WoWRetail) then return end
    if (not MinimapCluster) then return end
    MinimapCluster:SetSize(230, 216) -- All the classics appear to have this cluster size
end

EditModePreset.GetSystem = function(self, systems, systemID)
	for _, sys in ipairs(systems) do
		if (sys.system == systemID) then return sys end
	end
end

EditModePreset.SetSystemAnchor = function(self, sys, point, relativePoint, x, y)
	if (not sys) then return end
	
	sys.isInDefaultPosition = false
	sys.anchorInfo = {
		point = point,
		relativeTo = "UIParent",
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
	
	self:SetSystemSetting(system, 0, math.floor(width  / 100)) 	-- WidthHundreds
	self:SetSystemSetting(system, 1, width  % 100) 				-- WidthTensAndOnes
	self:SetSystemSetting(system, 2, math.floor(height / 100)) 	-- HeightHundreds
	self:SetSystemSetting(system, 3, height % 100) 				-- HeightTensAndOnes
end

EditModePreset.ApplySystemSettings = function(self, target)
	if (not target) then return end

	-- Minimap
	local minimap = self:GetSystem(target.systems, Enum.EditModeSystem.Minimap)
	if (ns.WoWCamelot or ns.WoWRetail) then
		self:SetSystemAnchor(minimap, "BOTTOMRIGHT", "BOTTOMRIGHT", -30, 30) 
	else
		-- Note: Do NOT mess with header beneath/above minimap. It makes it unaligned and requires a /reload to fix! 
		-- Note2: On the initial login on Era/TBC, the Minimap IS misaligned! Why?
		self:SetSystemAnchor(minimap, "BOTTOMRIGHT", "BOTTOMRIGHT", -46, 74) 
	end
	self:SetSystemSetting(minimap, 0, 0) -- Header Underneath = off (this messes up our expected layout if enabled)
	self:SetSystemSetting(minimap, 2, (ns.WoWRetail or ns.WoWCamelot) and 5 or 8) -- Size 5 ~ 100%, size 8 is 130% (matching)

	-- Chat 
	local chat = self:GetSystem(target.systems, Enum.EditModeSystem.ChatFrame)
	self:SetSystemAnchor(chat, "BOTTOMLEFT", "BOTTOMLEFT", 60, 306)

	if (ns.WoWTBC) then
		self:SetChatSize(chat, 440, 180) 
	else
		self:SetChatSize(chat, 440, 220) 
	end

	-- HUD Tooltip
	local tooltip = self:GetSystem(target.systems, Enum.EditModeSystem.HudTooltip)
	self:SetSystemAnchor(tooltip, "BOTTOMRIGHT", "BOTTOMRIGHT", -319, 166)

	-- Objective Tracker
	local tracker = self:GetSystem(target.systems, Enum.EditModeSystem.ObjectiveTracker)
	self:SetSystemAnchor(tracker, "BOTTOMRIGHT", "BOTTOMRIGHT", -44, 330) 
	self:SetSystemSetting(tracker, 0, 1) -- Height (1 equals 400-440ish)

	-- Group Finder Eye
	-- Equipment Durability/Paper Doll
	-- Buffs & Debuffs
end

EditModePreset.CreateOrUpdateLayout = function(self, forced)
	if (self.hasAppliedLayout or InCombatLockdown()) then return end
	if (not C_EditMode or not EditModePresetLayoutManager) then return end

	local info = C_EditMode.GetLayouts()
	if (not info or not info.layouts) then return end

	-- See if the old Account wide layout is there, and remove it. We're using Character layouts now.
	for i, layout in ipairs(info.layouts) do
		if (layout.layoutName == LAYOUT_NAME and layout.layoutType == Enum.EditModeLayoutType.Account) then
			table.remove(info.layouts, i)
			--C_EditMode.SaveLayouts(info)
			break
		end
	end
	
	-- Search for the standard keyboard/mouse layout
	local existingIndex
	for i, layout in ipairs(info.layouts) do
		if (layout.layoutName == LAYOUT_NAME) then
			existingIndex = i
			break
		end
	end

	-- Create or update standard layout
	local target
	if (existingIndex) then
		-- We don't generally switch or change the existing layout, 
		-- users should be able to modify or select another. 
		if (not forced) then 
			self.hasAppliedLayout = true
			--return 
		end

		-- if we're going to update the layout
		target = info.layouts[existingIndex]
	else
		local presets = EditModePresetLayoutManager:GetCopyOfPresetLayouts()
		local base
		for _, p in ipairs(presets) do
			if (p.layoutName == LAYOUT_STYLE_MODERN) then base = p break end
		end
		base = base or presets[1]
		if (not base) then return end

		target = CopyTable(base)
		target.layoutName = LAYOUT_NAME
		target.layoutType = Enum.EditModeLayoutType.Character
		target.interfaceStyle = Enum.InputDeviceInterfaceType and Enum.InputDeviceInterfaceType.Mkb

		table.insert(info.layouts, target)
		existingIndex = #info.layouts
	end
	if (not self.hasAppliedLayout) then
		self:ApplySystemSettings(target)
	end

	-- Search for the gamepad layout
	if (ns.WoWCamelot) then
		local existingIndex
		for i, layout in ipairs(info.layouts) do
			if (layout.layoutName == LAYOUT_NAME_GAMEPAD) then
				existingIndex = i
				break
			end
		end

		-- Create or update gamepad layout
		local target
		if (existingIndex) then
			-- We don't generally switch or change the existing layout, 
			-- users should be able to modify or select another. 
			if (not forced) then 
				self.hasAppliedGamepadLayout = true
				--return 
			end

			-- if we're going to update the layout
			target = info.layouts[existingIndex]
		else
			local presets = EditModePresetLayoutManager:GetCopyOfPresetLayouts()
			local base
			for _, p in ipairs(presets) do
				if (p.layoutName == LAYOUT_STYLE_GAMEPAD) then base = p break end
			end
			base = base or presets[1]
			if (not base) then return end

			target = CopyTable(base)
			target.layoutName = LAYOUT_NAME_GAMEPAD
			target.layoutType = Enum.EditModeLayoutType.Character
			target.interfaceStyle = Enum.InputDeviceInterfaceType.Gamepad

			table.insert(info.layouts, target)
			existingIndex = #info.layouts
		end
		if (not self.hasAppliedGamepadLayout) then
			self:ApplySystemSettings(target)
		end

		self.hasAppliedGamepadLayout = true
	end

	-- Messy
	if (self.hasAppliedLayout) then
		return
	end

	-- Set the flag before any API call that can re-enter the event
	self.hasAppliedLayout = true

	-- Save layouts. This takes a moment to kick in.
	C_EditMode.SaveLayouts(info)

	-- Defer the switch so the save is processed first.
	C_Timer.After(0, function()
		if (InCombatLockdown()) then
			return
		end

		local fresh = C_EditMode.GetLayouts()
		if (not fresh or not fresh.layouts) then return end

		local customIndex
		for i, layout in ipairs(fresh.layouts) do
			if (layout.layoutName == ((ns.WoWCamelot and C_GamePad.IsEnabled()) and LAYOUT_NAME_GAMEPAD or LAYOUT_NAME)) then
				customIndex = i
				break
			end
		end
		if (not customIndex) then return end

		local presetCount = (Enum.EditModePresetLayoutsMeta and Enum.EditModePresetLayoutsMeta.NumValues) or #EditModePresetLayoutManager.presetLayoutInfo -- 2 or 3
		local fullIndex = presetCount + customIndex

		if (fresh.activeLayout ~= fullIndex) then
			C_EditMode.SetActiveLayout(fullIndex)
		end

		-- Force a visual refresh by switching away and back,
		-- this helps with the problem of changes getting "stuck"
		-- until a layout change or reload.
		C_Timer.After(.1, function()
			if (InCombatLockdown()) then
				return
			end

			local other = (fullIndex == presetCount + 1) and (presetCount + 2) or (presetCount + 1)
			if (other ~= fullIndex) then
				C_EditMode.SetActiveLayout(other)
				C_Timer.After(.1, function()
					if (InCombatLockdown()) then
						return
					end
					C_EditMode.SetActiveLayout(fullIndex)
					ForceMinimapSize()
				end)
			end
		end)

		ForceChatSize()
		ForceMinimapSize()
	end)
end

EditModePreset.ResetLayout = function(self)
	self.hasAppliedLayout = false 
	self:CreateOrUpdateLayout(true)
end

EditModePreset.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		-- EditMode loads more unpredictably on the initial login, 
		-- so we need to add an extra delay here to make sure we catch it, 
		-- or our custom preset won't get created until the next /reload.
		local isInitialLogin, isReloadingUi = ...
		if (isInitialLogin) then
			C_Timer.After(1.5, function() self:CreateOrUpdateLayout() end)
		else
			self:CreateOrUpdateLayout()
		end
	else
		self:CreateOrUpdateLayout()
	end

	-- Remove events when no longer needed, or we'll get C stack overflows.
	if (self.hasAppliedLayout) then
		self:UnregisterEvent("EDIT_MODE_LAYOUTS_UPDATED", "OnEvent")
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	end
end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling.
EditModePreset.UpdateSettings = function(self)
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
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
