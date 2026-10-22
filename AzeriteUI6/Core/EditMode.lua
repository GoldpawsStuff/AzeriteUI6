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

local EditModePreset = ns:NewModule("EditMode", nil, "LibMoreEvents-1.0")

local defaults = { profile = {
	enabled = true
}}

local LAYOUT_NAME = "Azerite UI Default"
local applied = false

local function FindSystem(systems, systemID)
	for _, sys in ipairs(systems) do
		if sys.system == systemID then return sys end
	end
end

local function AnchorSystem(sys, point, relativePoint, x, y)
	if not sys then return end
	sys.isInDefaultPosition = false
	sys.anchorInfo = {
		point = point,
		relativeTo = "UIParent",
		relativePoint = relativePoint,
		offsetX = x,
		offsetY = y,
	}
end

local function SetSetting(sys, settingID, value)
	if not sys then return end
	sys.settings = sys.settings or {}
	for _, row in ipairs(sys.settings) do
		if row.setting == settingID then
			row.value = value
			return
		end
	end
	sys.settings[#sys.settings + 1] = { setting = settingID, value = value }
end

local function SetChatSize(sys, width, height)
	if not sys then return end
	width  = math.floor(width)
	height = math.floor(height)
	SetSetting(sys, 0, math.floor(width  / 100))  -- WidthHundreds
	SetSetting(sys, 1, width  % 100)              -- WidthTensAndOnes
	SetSetting(sys, 2, math.floor(height / 100))  -- HeightHundreds
	SetSetting(sys, 3, height % 100)              -- HeightTensAndOnes
end

local function CreateOrUpdateLayout()
	if applied or InCombatLockdown() then return end
	if not C_EditMode or not EditModePresetLayoutManager then return end

	local info = C_EditMode.GetLayouts()
	if not info or not info.layouts then return end

	local existingIndex
	for i, layout in ipairs(info.layouts) do
		if layout.layoutName == LAYOUT_NAME then
			existingIndex = i
			break
		end
	end

	local target
	if existingIndex then
		target = info.layouts[existingIndex]
	else
		local presets = EditModePresetLayoutManager:GetCopyOfPresetLayouts()
		local base
		for _, p in ipairs(presets) do
			-- "Modern" on Retail/Forever; fall back to the first preset if missing
			if p.layoutName == "Modern" then base = p break end
		end
		base = base or presets[1]
		if not base then return end

		target = CopyTable(base)
		target.layoutName = LAYOUT_NAME
		target.layoutType = Enum.EditModeLayoutType.Account
		if Enum.InputDeviceInterfaceType then
			target.interfaceStyle = Enum.InputDeviceInterfaceType.Mkb
		end

		table.insert(info.layouts, target)
		existingIndex = #info.layouts
	end

	-- Minimap
	local minimap = FindSystem(target.systems, Enum.EditModeSystem.Minimap)
	AnchorSystem(minimap, "BOTTOMRIGHT", "BOTTOMRIGHT", -30, 30) -- different positions for different clients. figure it out
	SetSetting(minimap, 0, 0) -- Header Underneath = off
	SetSetting(minimap, 2, (ns.WoWRetail or ns.WoWCamelot) and 5 or 8) -- Size 5 ~ 100% (adjust as needed)

	-- Chat 
	local chat = FindSystem(target.systems, Enum.EditModeSystem.ChatFrame)
	AnchorSystem(chat, "BOTTOMLEFT", "BOTTOMLEFT", 60, 306)
	SetChatSize(chat, 440, 220)

	-- HUD Tooltip
	local tooltip = FindSystem(target.systems, Enum.EditModeSystem.HudTooltip)
	AnchorSystem(tooltip, "BOTTOMRIGHT", "BOTTOMRIGHT", -319, 166)

	-- Tracker height (example: value 5; higher = taller)
	local tracker = FindSystem(target.systems, Enum.EditModeSystem.ObjectiveTracker)
	AnchorSystem(tracker, "BOTTOMRIGHT", "BOTTOMRIGHT", -30, 330)
	SetSetting(tracker, 0, 1)   -- Height

	-- Set the flag before any API call that can re-enter the event
	applied = true

	-- Save layouts. This takes a moment to kick in.
	C_EditMode.SaveLayouts(info)

	-- Defer the switch so the save is processed first.
    C_Timer.After(0, function()
        local fresh = C_EditMode.GetLayouts()
        if not fresh or not fresh.layouts then return end

        local customIndex
        for i, layout in ipairs(fresh.layouts) do
            if layout.layoutName == LAYOUT_NAME then
                customIndex = i
                break
            end
        end
        if not customIndex then return end

        local presetCount = (Enum.EditModePresetLayoutsMeta and Enum.EditModePresetLayoutsMeta.NumValues) or 2
        local fullIndex = presetCount + customIndex

        if fresh.activeLayout ~= fullIndex then
            C_EditMode.SetActiveLayout(fullIndex)
        end
    end)
end

EditModePreset.OnEvent = function(self, event, ...)
	CreateOrUpdateLayout()

	-- Remove events when no longer needed, or we'll get C stack overflows.
	if (applied) then
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
end

EditModePreset.OnEnable = function(self)
	self:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
end
