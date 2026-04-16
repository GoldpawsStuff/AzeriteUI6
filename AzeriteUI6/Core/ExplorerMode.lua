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

local ExplorerMode = ns:NewModule("ExplorerMode", nil, "AceTimer-3.0", "LibMoreEvents-1.0", "LibFadingFrames-1.0", "LibMovableFrames-1.0")
local LFF = LibStub("LibFadingFrames-1.0")

-- Declare module defaults
local defaults = { 
	profile = {
		enabled = true,

		-- How long to wait before initiating
		-- Explorer Mode after a loading screen.
		delayOnLogin = 15,
		delayOnReload = 5,
		delayOnZoning = 0,
		delayOnCombatEnd = 5,

		-- These options are kind of backwards,
		-- as they set when to EXIT the Explorer Mode.
		fadeInCombat = false,
		fadeInGroups = false,
		fadeInInstances = false,
		fadeWithFriendlyTarget = false,
		fadeWithHostileTarget = false,
		fadeWithDeadTarget = true,
		fadeWithFocusTarget = false,
		fadeInVehicles = false,
		--fadeWithLowHealth = false, -- doesn't work anymore because of secrets

		-- Which elements to fade out
		-- while in Explorer Mode.
		fadeActionBars = true,
		fadePetBar = true,
		fadeStanceBar = true,
		fadePlayerFrame = true,
		fadePlayerClassPower = true,
		fadePetFrame = true,
		fadeFocusFrame = true,
		--fadeTracker = true,
		fadeChatFrames = true
	}
}

ExplorerMode.CheckForForcedState = function(self)
	local db = self.db.profile

	if (self.delayTimer) then
		return true
	end

	if (self.movableFrameAnchorsVisible) then
		return true
	end

	if (self.inCombat and not db.fadeInCombat) then
		return true
	end

	-- Check for the various targeting options.
	if (self.hasTarget) then

		-- Only check for hostile/friendly targets if the target is living
		-- and the option to keep faded with dead targets isn't selected.
		if not(self.hasDeadTarget and db.fadeWithDeadTarget) then

			-- Hostile target and no hostile target fade selected.
			if (self.hasAttackableTarget and not db.fadeWithHostileTarget) then
				return true

			-- Non-attackable target an no friendly fade selected.
			elseif (not self.hasAttackableTarget and not db.fadeWithFriendlyTarget) then
				return true
			end
		end
	end

	if (self.hasFocus and not db.fadeWithFocusTarget)
	or (self.inGroup and not db.fadeInGroups)
	or (self.hasOverride and not db.fadeInVehicles)
	or (self.hasPossess and not db.fadeInVehicles)
	or (self.isDragonRiding and not db.fadeInVehicles)
	or (self.inVehicle and not db.fadeInVehicles)
	or (self.inInstance and not db.fadeInInstances)
	--or (self.lowHealth and not db.fadeWithLowHealth)
	or (self.busyCursor) then
		return true
	end

	return nil
end

ExplorerMode.CheckCursor = function(self)
	--if (CursorHasSpell() or CursorHasItem()) then
	--	self.busyCursor = true
	--	return
	--end

	-- other values: money, merchant
	local cursor = GetCursorInfo()
	if (cursor == "petaction")
	or (cursor == "spell")
	or (cursor == "macro")
	or (cursor == "mount")
	or (cursor == "item") then
		self.busyCursor = true
		return
	end

	self.busyCursor = nil
end

--[[ExplorerMode.CheckHealth = function(self)
	local current = UnitHealth("player")
	local maxHealth = UnitHealthMax("player")

	-- this never fires?
	if (issecretvalue(current) == issecretvalue(maxHealth)) then
		if (current == maxHealth) then
			self.lowHealth = nil
		else
			self.lowHealth = true
		end

	-- this ALWAYS fires?
	elseif (issecretvalue(current) or issecretvalue(maxHealth)) then
		self.lowHealth = true

	-- this never fires.
	else
		if (current == maxHealth) then
			self.lowHealth = nil
		else
			self.lowHealth = true
		end
	end
end--]]

ExplorerMode.CheckVehicle = function(self)
	-- Only check for vehicle bars where you have actions,
	-- ignore vehicles you're just riding in like the
	-- alliance/horde chopper mounts where you're a passenger.
	if (HasVehicleActionBar()) then
		self.inVehicle = true
		return
	end
	self.inVehicle = nil
end

ExplorerMode.CheckOverride = function(self)
	if (HasOverrideActionBar() or HasTempShapeshiftActionBar()) then
		self.hasOverride = true
		return
	end
	self.hasOverride = nil
end

ExplorerMode.CheckPossess = function(self)
	if (IsPossessBarVisible()) then
		self.hasPossess = true
		return
	end
	self.hasPossess = nil
end

ExplorerMode.CheckDragonRiding = function(self)
	if (HasBonusActionBar()) then
		if (GetBonusBarOffset() == 5) then
			if (IsMounted()) then
				self.isDragonRiding = true
				return
			end
		end
	end
	self.isDragonRiding = nil
end

ExplorerMode.CheckTarget = function(self)
	if (UnitExists("target")) then
		self.hasTarget = true
		self.hasAttackableTarget = UnitCanAttack("player", "target")
		self.hasDeadTarget = UnitIsDeadOrGhost("target")
		return
	end
	self.hasTarget = nil
	self.hasAttackableTarget = nil
	self.hasDeadTarget = nil
end

ExplorerMode.CheckFocus = function(self)
	if (UnitExists("focus")) then
		self.hasFocus = true
		return
	end
	self.hasFocus = nil
end

ExplorerMode.CheckGroup = function(self)
	if (IsInGroup()) then
		self.inGroup = true
		return
	end
	self.inGroup = nil
end

ExplorerMode.CheckInstance = function(self)
	if (IsInInstance()) then
		self.inInstance = true
		return
	end
	self.inInstance = nil
end

ExplorerMode.OnTimedForcedStateEnd = function(self)
	if (self.delayTimer) then
		self:CancelTimer(self.delayTimer)
		self.delayTimer = nil
	end

	-- Restore the library's default fade out duration.
	if (self.restoreFadeOutDuration) then
		LFF:SetFadeOutDuration(nil)
		self.restoreFadeOutDuration = nil
	end

	self:UpdateSettings()
end

ExplorerMode.OnMovableFrameAnchorsVisible = function(self)
	self.movableFrameAnchorsVisible = true
	self:UpdateSettings()
end

ExplorerMode.OnMovableFrameAnchorsHidden = function(self)
	self.movableFrameAnchorsVisible = nil
	self:UpdateSettings()
end

ExplorerMode.SetTimedForcedState = function(self, duration)
	if (self.delayTimer) then
		self:CancelTimer(self.delayTimer)
		self.delayTimer = nil
	end

	self.delayTimer = self:ScheduleTimer("OnTimedForcedStateEnd", duration)
end

ExplorerMode.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		local isInitialLogin, isReloadingUi = ...

		-- Kill off remnant timers
		-- from pure loading screens.
		if (self.delayTimer) then
			self:CancelTimer(self.delayTimer)
			self.delayTimer = nil
		end

		local db = self.db.profile

		-- Initiate a delay according to settings.
		if (isInitialLogin) then
			if (db.delayOnLogin > 0) then
				self.hasLoadingScreenDelay = true
				self:SetTimedForcedState(db.delayOnLogin)
			end
		elseif (isReloadingUi) then
			if (db.delayOnReload > 0) then
				self.hasLoadingScreenDelay = true
				self:SetTimedForcedState(db.delayOnReload)
			end
		else
			if (db.delayOnZoning > 0) then
				self.hasLoadingScreenDelay = true
				self:SetTimedForcedState(db.delayOnZoning)
			end
		end

		if (self.delayTimer) then
			-- Restore the library's default fade out duration.
			LFF:SetFadeOutDuration(nil)
		else
			-- Hack to bypass the initial fadeout.
			-- Without it we'll have half a second of frame visibility.
			LFF:SetFadeOutDuration(0)
			self.restoreFadeOutDuration = true
		end

		self.inCombat = InCombatLockdown()

		self:CheckInstance()
		self:CheckGroup()
		self:CheckTarget()
		self:CheckFocus()
		self:CheckVehicle()
		self:CheckOverride()
		self:CheckPossess()
		self:CheckDragonRiding()
		--self:CheckHealth()
		self:CheckCursor()

	elseif (event == "PLAYER_REGEN_DISABLED") then
		self.inCombat = true
		--self:UnregisterEvent("UNIT_HEALTH", "OnEvent", "player")

	elseif (event == "PLAYER_REGEN_ENABLED") then
		self.inCombat = false
		--self:RegisterUnitEvent("UNIT_HEALTH", "OnEvent", "player")

		if (self.db.profile.delayOnCombatEnd > 0) then
			self:SetTimedForcedState(self.db.profile.delayOnCombatEnd)
		end

	elseif (event == "CURSOR_CHANGED") then
		self:CheckCursor()

	elseif (event == "PLAYER_TARGET_CHANGED") then
		self:CheckTarget()

	elseif (event == "PLAYER_FOCUS_CHANGED") then
		self:CheckFocus()

	elseif (event == "GROUP_ROSTER_UPDATE") then
		self:CheckGroup()

	elseif (event == "UPDATE_POSSESS_BAR") then
		self:CheckPossess()

	elseif (event == "UPDATE_OVERRIDE_ACTIONBAR") then
		self:CheckOverride()

	elseif (event == "UPDATE_BONUS_ACTIONBAR") then
		self:CheckDragonRiding()

	elseif (event == "UNIT_ENTERING_VEHICLE")
		or (event == "UNIT_ENTERED_VEHICLE")
		or (event == "UNIT_EXITING_VEHICLE")
		or (event == "UNIT_EXITED_VEHICLE")
		or (event == "UPDATE_VEHICLE_ACTIONBAR") then
		self:CheckVehicle()

	--elseif (event == "UNIT_HEALTH") then
	--	self:CheckHealth()

	elseif (event == "ZONE_CHANGED_NEW_AREA") then
		self:CheckInstance()
	end

	self:UpdateSettings()
end 

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling and combat end.
ExplorerMode.UpdateSettings = function(self)

	local db = self.db.profile

	if (db.enabled and not self.enabled) then

		self:RegisterEvent("CURSOR_CHANGED", "OnEvent")
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnEvent")
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
		self:RegisterEvent("PLAYER_LEAVING_WORLD", "OnEvent")
		self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
		self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnEvent")
		self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnEvent")
		self:RegisterEvent("PLAYER_FOCUS_CHANGED", "OnEvent")
		self:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR", "OnEvent")
		self:RegisterEvent("UPDATE_POSSESS_BAR", "OnEvent")
		self:RegisterEvent("UPDATE_BONUS_ACTIONBAR", "OnEvent")
		self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR", "OnEvent", "player")
		self:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "OnEvent", "player")
		self:RegisterUnitEvent("UNIT_ENTERING_VEHICLE", "OnEvent", "player")
		self:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "OnEvent", "player")
		self:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "OnEvent", "player")

		--if (not InCombatLockdown()) then
		--	self:RegisterUnitEvent("UNIT_HEALTH", "OnEvent", "player")
		--end

		self.enabled = true

	elseif (not db.enabled and self.enabled) then

		self:UnregisterEvent("CURSOR_CHANGED", "OnEvent")
		self:UnregisterEvent("ZONE_CHANGED_NEW_AREA", "OnEvent")
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
		self:UnregisterEvent("PLAYER_LEAVING_WORLD", "OnEvent")
		self:UnregisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
		self:UnregisterEvent("PLAYER_TARGET_CHANGED", "OnEvent")
		self:UnregisterEvent("GROUP_ROSTER_UPDATE", "OnEvent")
		self:UnregisterEvent("PLAYER_FOCUS_CHANGED", "OnEvent")
		self:UnregisterEvent("UPDATE_OVERRIDE_ACTIONBAR", "OnEvent")
		self:UnregisterEvent("UPDATE_POSSESS_BAR", "OnEvent")
		self:UnregisterEvent("UPDATE_BONUS_ACTIONBAR", "OnEvent")
		self:UnregisterEvent("UPDATE_VEHICLE_ACTIONBAR", "OnEvent", "player")
		self:UnregisterEvent("UNIT_ENTERED_VEHICLE", "OnEvent", "player")
		self:UnregisterEvent("UNIT_ENTERING_VEHICLE", "OnEvent", "player")
		self:UnregisterEvent("UNIT_EXITED_VEHICLE", "OnEvent", "player")
		self:UnregisterEvent("UNIT_EXITING_VEHICLE", "OnEvent", "player")

		--if (not InCombatLockdown()) then
		--	self:UnregisterEvent("UNIT_HEALTH", "OnEvent", "player")
		--end

		self.enabled = nil
	end

	self.FORCED = not db.enabled or self:CheckForForcedState()

	-- Action Bars
	--------------------------------------------
	for i,moduleName in next, {
		"MainActionBar",
		"MultiBar1",
		"MultiBar2",
		"MultiBar3",
		"MultiBar4",
		"MultiBar5",
		"MultiBar6",
		"MultiBar7",
		"PetBar",
		--"StanceBar"
	} do 
		local barModule = ns:GetModule(moduleName, true)
		if (barModule) then
			local bar = barModule:GetBar()
			local fade = not self.FORCED and barModule:IsEnabled() and db.enabled and db.fadeActionBars

			-- Exempt bars that are fully set to fade
			-- in their own actionbar settings.
			local fullyFaded = bar.config.enableBarFading and bar.config.fadeAlone and bar.config.fadeFrom == 1

			if (fade and not fullyFaded) then
				-- Register the bar for fading
				LFF:RegisterFrameForFading(bar, self:GetName())
			else
				-- Unregister the bar for fading, does not affect button fading.
				LFF:UnregisterFrameForFading(bar)
			end

			-- Update the bar's button fading.
			--if (bar.config.enableBarFading) then
			--	bar:UpdateFading() -- is this still needed?
			--end
		end
	end

	-- Unit Frames
	--------------------------------------------
	local Player = ns:GetModule("Player", true)
	if (Player) then
		local fade = not self.FORCED and Player:IsEnabled() and db.enabled and db.fadePlayerFrame
		local playerFrame = Player:GetFrame()
		if (playerFrame) then
			if (fade) then
				LFF:RegisterFrameForFading(playerFrame, self:GetName())
			else
				LFF:UnregisterFrameForFading(playerFrame)
			end
		end
	end

	local ClassPower = ns:GetModule("ClassPower", true)
	if (ClassPower) then
		local fade = not self.FORCED and ClassPower:IsEnabled() and db.enabled and db.fadePlayerClassPower
		local classPowerFrame = ClassPower:GetFrame()
		if (classPowerFrame) then
			if (fade) then
				LFF:RegisterFrameForFading(classPowerFrame, self:GetName())
			else
				LFF:UnregisterFrameForFading(classPowerFrame)
			end
		end
	end

	local Pet = ns:GetModule("Pet", true)
	if (Pet) then
		local fade = not self.FORCED and Pet:IsEnabled() and db.enabled and db.fadePetFrame
		local petFrame = Pet:GetFrame()
		if (petFrame) then
			if (fade) then
				LFF:RegisterFrameForFading(petFrame, self:GetName())
			else
				LFF:UnregisterFrameForFading(petFrame)
			end
		end
	end

	local Focus = ns:GetModule("Focus", true)
	if (Focus) then
		local fade = not self.FORCED and Focus:IsEnabled() and db.enabled and db.fadeFocusFrame
		local focusFrame = Focus:GetFrame()
		if (focusFrame) then
			if (fade) then
				LFF:RegisterFrameForFading(focusFrame, self:GetName())
			else
				LFF:UnregisterFrameForFading(focusFrame)
			end
		end
	end

	-- Objectives Tracker
	--------------------------------------------
	--local ObjectiveTracker = ns:GetModule("ObjectiveTracker", true)
	--if (ObjectiveTracker) then
	--	local fade = not self.FORCED and ObjectiveTracker:IsEnabled() and db.enabled and db.fadeTracker
	--	if (fade) then
	--		LFF:RegisterFrameForFading(ObjectiveTrackerFrame, ObjectiveTracker:GetName())
	--	else
	--		LFF:UnregisterFrameForFading(ObjectiveTrackerFrame)
	--	end
	--end

	-- Chat Windows
	--------------------------------------------
	local fadeChat = not self.FORCED and db.enabled and db.fadeChatFrames
	for _,frameName in pairs(_G.CHAT_FRAMES) do
		local chatFrame = _G[frameName]
		if (chatFrame) then
			if (fadeChat) then
				LFF:RegisterFrameForFading(chatFrame, "ChatFrames")
			else
				LFF:UnregisterFrameForFading(chatFrame)
			end
		end
	end

end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
ExplorerMode.RefreshConfig = function(self)
	self:UpdateSettings()
end

ExplorerMode.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("ExplorerMode", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

ExplorerMode.OnEnable = function(self)
	self:UpdateSettings()

	ns.RegisterCallback(self, "MovableFrameAnchorsVisible", "OnMovableFrameAnchorsVisible")
	ns.RegisterCallback(self, "MovableFrameAnchorsHidden", "OnMovableFrameAnchorsHidden")
end
