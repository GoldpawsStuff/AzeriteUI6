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

local HideBlizzardActionBars = ns:NewModule("HideBlizzardActionBars", nil, "LibMoreEvents-1.0", "AceHook-3.0")

-- Hidden parent frame
local UIHider = CreateFrame("Frame")
UIHider:Hide()

local purgeKey = function(t, k)
	t[k] = nil
	local c = 42
	repeat
		if t[c] == nil then
			t[c] = nil
		end
		c = c + 1
	until issecurevariable(t, k)
end

local hideActionBarFrame = function(frame, clearEvents)
	if (frame) then
		if (clearEvents) then
			frame:UnregisterAllEvents()
		end

		-- remove some EditMode hooks
		if (frame.system) then
			-- purge the show state to avoid any taint concerns
			purgeKey(frame, "isShownExternal")
		end

		-- EditMode overrides the Hide function, avoid calling it as it can taint
		if (frame.HideBase) then
			frame:HideBase()
		else
			frame:Hide()
		end
		frame:SetParent(UIHider)
	end
end

local removeEvents = function(frame, clearEvents)
	if (frame) then
		if (clearEvents) then
			frame:UnregisterAllEvents()
		end

		-- remove some EditMode hooks
		if (frame.system) then
			-- purge the show state to avoid any taint concerns
			purgeKey(frame, "isShownExternal")
		end
	end
end

local hideActionButton = function(button)
	if (not button) then return end

	button:Hide()
	button:UnregisterAllEvents()

	if (not ns.WoWCamelot) then
		button:SetAttribute("statehidden", true)
	end

	if (ns.WoWRetail or ns.WoWCamelot) then
		button.bar = nil
	end
end

HideBlizzardActionBars.HideBlizzard = function(self)

	hideActionBarFrame(MainMenuBar, false) -- <= 11.2.5
	hideActionBarFrame(MainActionBar, false) -- >= 11.2.7/12.0

	-- Hide MultiBar Buttons, but keep the bars alive
	for i = 1,12 do
		hideActionButton(_G["ActionButton" .. i])
		hideActionButton(_G["MultiBarBottomLeftButton" .. i])
		hideActionButton(_G["MultiBarBottomRightButton" .. i])
		hideActionButton(_G["MultiBarRightButton" .. i])
		hideActionButton(_G["MultiBarLeftButton" .. i])
		hideActionButton(_G["MultiBar5Button" .. i])
		hideActionButton(_G["MultiBar6Button" .. i])
		hideActionButton(_G["MultiBar7Button" .. i])
	end

	-- Non-action-button only
	hideActionBarFrame(StanceBar, true)
	hideActionBarFrame(PetActionBar, true)
	hideActionBarFrame(MultiCastActionBarFrame, false)
	hideActionBarFrame(PossessActionBar, true)
	hideActionBarFrame(StatusTrackingBarManager, false)
	hideActionBarFrame(BagsBar, true)
	hideActionBarFrame(MicroButtonAndBagsBar, false)
	hideActionBarFrame(MicroMenu, true)
	hideActionBarFrame(MicroMenuContainer, true)

	if (MicroMenu and MicroMenu.BorderArt and MicroMenu.BackgroundArt) then
		MicroMenu.BorderArt:Hide()
		MicroMenu.BackgroundArt:Hide()
	end

	if (C_AddOns.IsAddOnLoaded("Blizzard_NewPlayerExperience")) then
		self:NPE_LoadUI()
	elseif (NPE_LoadUI ~= nil) then
		self:SecureHook("NPE_LoadUI")
	end

	OverrideActionBar:SetParent(UIHider)

	if (QueueStatusFrame) then
		QueueStatusFrame:SetParent(UIParent)
	end

	-- What will this break?
	-- *problem is that the spellbook updates when leveling 
	--  will attempt to show a tainted StanceBar
	--if (ActionBarController) then 
	--	--ActionBarController:UnregisterAllEvents()
	--	ActionBarController:UnregisterEvent("UPDATE_POSSESS_BAR")
	--	ActionBarController:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
	--	ActionBarController:UnregisterEvent("UPDATE_SHAPESHIFT_FORMS")
	--	ActionBarController:UnregisterEvent("UPDATE_SHAPESHIFT_USABLE")
	--end

	-- Call once after the UI is ready
	-- *we know touching the MultiBars taint things, but does this do it too?
	self:HideMicroMenuPopups()

	-- The damn annoying "we just leveld up"-taint
	self:BattleCamelotGamepadTaint()
end

	-- Attempting to fight a weird, gamepad related taint in Forever, 
	-- which occurs even when gamepad hasn't been enabled at all.
	-- It specifically happens after leveling up.
HideBlizzardActionBars.BattleCamelotGamepadTaint = function(self)
	if (ns.WoWCamelot) then
		--local function ProtectGamepadClassButtons()
		--	if (not GamepadMainActionBarFrame or not GamepadMainActionBarFrame.PageUnit) then return end
		--
		--	local function wrap(button)
		--		if (not button or button.azuiProtected) then return end
		--		local orig = button:GetScript("OnEvent")
		--		if (not orig) then return end
		--
		--		button:SetScript("OnEvent", function(self, event, ...)
		--			pcall(orig, self, event, ...)
		--		end)
		--		button.azuiProtected = true
		--	end
		--
		--	wrap(GamepadMainActionBarFrame.PageUnit.LeftClassAction)
		--	wrap(GamepadMainActionBarFrame.PageUnit.RightClassAction)
		--end
		--
		--EventUtil.ContinueOnPlayerLogin(ProtectGamepadClassButtons)
		--C_Timer.After(1, ProtectGamepadClassButtons)

		-- Keep the controller from driving StanceBar updates that hit EditMode
		-- *spellbook updates when leveling will attempt to show a tainted StanceBar
		if (ActionBarController) then
			ActionBarController:UnregisterEvent("ACTIONBAR_PAGE_CHANGED")
			ActionBarController:UnregisterEvent("UPDATE_BONUS_ACTIONBAR")
			ActionBarController:UnregisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
			ActionBarController:UnregisterEvent("UPDATE_VEHICLE_ACTIONBAR")
			ActionBarController:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
			ActionBarController:UnregisterEvent("UPDATE_SHAPESHIFT_FORMS")
			ActionBarController:UnregisterEvent("UPDATE_SHAPESHIFT_USABLE")
			ActionBarController:UnregisterEvent("UPDATE_POSSESS_BAR")
			ActionBarController:UnregisterEvent("PLAYER_ENTERING_WORLD")
			ActionBarController:UnregisterEvent("UPDATE_MULTI_CAST_ACTIONBAR")
		end

		--if (ns.WoWCamelot and type(ActionButton_ApplyCooldown) == "function") then
		--	local orig = ActionButton_ApplyCooldown
		--	ActionButton_ApplyCooldown = function(...)
		--		pcall(orig, ...)
		--	end
		--end

		--if (ns.WoWCamelot and ActionBarButtonEventsFrame) then
		--	--local orig = ActionBarButtonEventsFrame.OnEvent
		--	--ActionBarButtonEventsFrame.OnEvent = function(self, event, ...)
		--	--	for _, frame in pairs(self.frames) do
		--	--		if (frame and frame.OnEvent) then
		--	--			pcall(frame.OnEvent, frame, event, ...)
		--	--		end
		--	--	end
		--	--end
		--	ActionBarButtonEventsFrame:SetScript("OnEvent", function(self, event, ...)
		--		for _, frame in pairs(self.frames) do
		--			if (frame and frame.OnEvent) then
		--				pcall(frame.OnEvent, frame, event, ...)
		--			end
		--		end
		--	end)
		--end

		---- Safer than replacing StanceBar methods: skip the layout update that
		---- actually calls the protected SetPointBase on MainActionBar
		--if (EditModeManager and EditModeManager.UpdateBottomActionBarPositions) then
		--	local orig = EditModeManager.UpdateBottomActionBarPositions
		--	EditModeManager.UpdateBottomActionBarPositions = function(self, ...)
		--		if (MainActionBar and MainActionBar:GetParent() == UIHider) then
		--			return
		--		end
		--		return orig(self, ...)
		--	end
		--end
	end
end

HideBlizzardActionBars.HideMicroMenuPopups = function(self)
	-- Modern path (Retail / Midnight / any client that has the HelpTip system)
	if (type(MainMenuMicroButton_ShowAlert) == "function") then
		hooksecurefunc("MainMenuMicroButton_ShowAlert", function(microButton)
			if (HelpTip and HelpTip.HideAllSystem) then
				HelpTip:HideAllSystem("MicroButtons")
			elseif (type(MainMenuMicroButton_HideAlert) == "function") then
				MainMenuMicroButton_HideAlert(microButton)
			end
		end)
	end

	-- Stop the pulsing glow on the buttons (works on most clients that have it)
	if (type(MicroButtonPulse) == "function" and type(MicroButtonPulseStop) == "function") then
		hooksecurefunc("MicroButtonPulse", MicroButtonPulseStop)
	end

	-- Legacy alert frames (Classic Era and older clients that still use *Alert frames)
	local legacyAlerts = {
		"TalentMicroButtonAlert",
		"SpellbookMicroButtonAlert",
		"CharacterMicroButtonAlert",
		"CollectionsMicroButtonAlert",
		"EJMicroButtonAlert",
		"GuildMicroButtonAlert",
		"QuestLogMicroButtonAlert",
		"AchievementMicroButtonAlert",
		"LFDMicroButtonAlert",
		"PVPMicroButtonAlert"
	}

	for _, name in ipairs(legacyAlerts) do
		local frame = _G[name]
		if (frame and frame.HookScript) then
			frame:HookScript("OnShow", frame.Hide)
			if (frame:IsShown()) then
				frame:Hide()
			end
		end
	end

	-- Optional: also kill the small notification dots/overlays on the buttons
	local buttons = {
		PlayerSpellsMicroButton,	-- modern talents/spells
		TalentMicroButton,			-- older clients
		SpellbookMicroButton,
		ProfessionMicroButton,
		CollectionsMicroButton,
		MainMenuMicroButton
	}
	for _,button in ipairs(buttons) do
		if (button and button.NotificationOverlay) then
			button.NotificationOverlay:Hide()
			button.NotificationOverlay:HookScript("OnShow", button.NotificationOverlay.Hide)
		end
	end
end

HideBlizzardActionBars.NPE_LoadUI = function(self)
	if not (Tutorials and Tutorials.AddSpellToActionBar) then return end

	-- Action Bar drag tutorials
	Tutorials.AddSpellToActionBar:Disable()
	Tutorials.AddClassSpellToActionBar:Disable()

	-- these tutorials rely on finding valid action bar buttons, and error otherwise
	Tutorials.Intro_CombatTactics:Disable()

	-- enable spell pushing because the drag tutorial is turned off
	Tutorials.AutoPushSpellWatcher:Complete()
end

HideBlizzardActionBars.HasConflicts = function(self)
	for _,addon in next,{ "Bartender4", "ConsolePort_Bar", "Dominos" } do 
		if (C_AddOns.GetAddOnEnableState(addon, UnitGUID("player")) == Enum.AddOnEnableState.All) then
			return true
		end
	end
end

HideBlizzardActionBars.OnInitialize = function(self)
	if (self:HasConflicts()) then return self:Disable() end
	self:HideBlizzard()
end
