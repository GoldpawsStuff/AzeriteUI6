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

local LAYOUT_NAME = "Azerite UI Default"
local EditModePreset = ns:NewModule("EditMode", nil, "AceConsole-3.0", "LibMoreEvents-1.0")

local defaults = { profile = {
	enabled = true
}}

EditModePreset.FindSystem = function(self, systems, systemID)
	for _, sys in ipairs(systems) do
		if (sys.system == systemID) then return sys end
	end
end

EditModePreset.AnchorSystem = function(self, sys, point, relativePoint, x, y)
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

EditModePreset.SetSetting = function(self, sys, settingID, value)
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

EditModePreset.SetChatSize = function(self, sys, width, height)
	if (not sys) then return end
	
	width  = math.floor(width)
	height = math.floor(height)
	
	self:SetSetting(sys, 0, math.floor(width  / 100)) 	-- WidthHundreds
	self:SetSetting(sys, 1, width  % 100) 				-- WidthTensAndOnes
	self:SetSetting(sys, 2, math.floor(height / 100)) 	-- HeightHundreds
	self:SetSetting(sys, 3, height % 100) 				-- HeightTensAndOnes
end

-- The MinimapCluster is sized differently on the initial login, for some obscure reason.
-- We're attempting to force its size to fix this misalignment.
-- This appears to do the trick in Era, TBC and Mists so far. 
local ForceMinimapSize = function()
    if (ns.WoWCamelot or ns.WoWRetail) then return end
    if (not MinimapCluster) then return end
    MinimapCluster:SetSize(230, 216) -- All the classics appear to have this cluster size
end

EditModePreset.CreateOrUpdateLayout = function(self, forced)
	if (self.hasAppliedLayout or InCombatLockdown()) then return end
	if (not C_EditMode or not EditModePresetLayoutManager) then return end

	local info = C_EditMode.GetLayouts()
	if (not info or not info.layouts) then return end

	local existingIndex
	for i, layout in ipairs(info.layouts) do
		if (layout.layoutName == LAYOUT_NAME) then
			existingIndex = i
			break
		end
	end

	local target
	if (existingIndex) then
		-- We don't generally switch or change the existing layout, 
		-- users should be able to modify or select another. 
		if (not forced) then 
			self.hasAppliedLayout = true
			return 
		end

		-- if we're going to update the layout
		target = info.layouts[existingIndex]
	else
		local presets = EditModePresetLayoutManager:GetCopyOfPresetLayouts()
		local base
		for _, p in ipairs(presets) do
			-- "Modern" on Retail/Forever; fall back to the first preset if missing
			if (p.layoutName == "Modern") then base = p break end
		end
		base = base or presets[1]
		if (not base) then return end

		target = CopyTable(base)
		target.layoutName = LAYOUT_NAME
		target.layoutType = Enum.EditModeLayoutType.Account
		
		if (Enum.InputDeviceInterfaceType) then
			target.interfaceStyle = Enum.InputDeviceInterfaceType.Mkb
		end

		table.insert(info.layouts, target)
		existingIndex = #info.layouts
	end

	-- Minimap
	-- WoWCamelot = -30, 30, WoWRetail = -30, 30, WoWVanilla = -46, 74, WoWTBC = , WoWWrath = , WoWCata = , WoWMists = 
	local minimap = self:FindSystem(target.systems, Enum.EditModeSystem.Minimap)
	if (ns.WoWCamelot or ns.WoWRetail) then
		self:AnchorSystem(minimap, "BOTTOMRIGHT", "BOTTOMRIGHT", -30, 30) 
	else
		-- Note: Do NOT mess with header beneath/above minimap. It makes it unaligned and requires a /reload to fix! 
		-- Note2: On the initial login on Era/TBC, the Minimap IS misaligned! Why?
		self:AnchorSystem(minimap, "BOTTOMRIGHT", "BOTTOMRIGHT", -46, 74) 
	end
	self:SetSetting(minimap, 0, 0) -- Header Underneath = off (this messes up our expected layout if enabled)
	self:SetSetting(minimap, 2, (ns.WoWRetail or ns.WoWCamelot) and 5 or 8) -- Size 5 ~ 100%, size 8 is 130% (matching)

	-- Chat 
	-- WoWCamelot = 60, 306, WoWRetail = , WoWVanilla = , WoWTBC = , WoWWrath = , WoWCata = , WoWMists = 
	local chat = self:FindSystem(target.systems, Enum.EditModeSystem.ChatFrame)
	self:AnchorSystem(chat, "BOTTOMLEFT", "BOTTOMLEFT", 60, 306)
	self:SetChatSize(chat, 440, 220) -- same in all clients now?

	-- HUD Tooltip
	local tooltip = self:FindSystem(target.systems, Enum.EditModeSystem.HudTooltip)
	self:AnchorSystem(tooltip, "BOTTOMRIGHT", "BOTTOMRIGHT", -319, 166)

	-- Objective Tracker
	-- WoWCamelot = -44, 330, WoWRetail = , WoWVanilla = , WoWTBC = , WoWWrath = , WoWCata = , WoWMists = 
	local tracker = self:FindSystem(target.systems, Enum.EditModeSystem.ObjectiveTracker)
	self:AnchorSystem(tracker, "BOTTOMRIGHT", "BOTTOMRIGHT", -44, 330) 
	self:SetSetting(tracker, 0, 1) -- Height (1 equals 400-440ish)

	-- Group Finder Eye
	-- Equipment Durability/Paper Doll
	-- Buffs & Debuffs

	-- Set the flag before any API call that can re-enter the event
	self.hasAppliedLayout = true

	-- Save layouts. This takes a moment to kick in.
	C_EditMode.SaveLayouts(info)

	-- Defer the switch so the save is processed first.
	C_Timer.After(0, function()
		local fresh = C_EditMode.GetLayouts()
		if (not fresh or not fresh.layouts) then return end

		local customIndex
		for i, layout in ipairs(fresh.layouts) do
			if (layout.layoutName == LAYOUT_NAME) then
				customIndex = i
				break
			end
		end
		if (not customIndex) then return end

		local presetCount = (Enum.EditModePresetLayoutsMeta and Enum.EditModePresetLayoutsMeta.NumValues) or 2
		local fullIndex = presetCount + customIndex

		if (fresh.activeLayout ~= fullIndex) then
			C_EditMode.SetActiveLayout(fullIndex)
		end

		-- Force a visual refresh by switching away and back,
		-- this helps with the problem of changes getting "stuck"
		-- until a layout change or reload.
		C_Timer.After(0.1, function()
			local other = (fullIndex == presetCount + 1) and (presetCount + 2) or (presetCount + 1)
			if other ~= fullIndex then
				C_EditMode.SetActiveLayout(other)
				C_Timer.After(0.1, function()
					C_EditMode.SetActiveLayout(fullIndex)
					ForceMinimapSize()
				end)
			end
		end)

		-- Forever (possibly Classic Era?) fallback: Edit Mode size settings are ignored, we need to manuall set them
		if (SetChatWindowSavedDimensions) then
			SetChatWindowSavedDimensions(1, 440, 220)
		end

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
