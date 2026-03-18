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

local HandleBartender = ns:NewModule("HandleBartender", nil, "LibMoreEvents-1.0", "AceHook-3.0")

HandleBartender.HandleBagBar = function(self)
	local BagBarMod = Bartender4:GetModule("BagBar")
	if (not BagBarMod) then
		return
	end
	BagBarMod:Disable()
	BagBarMod:UnhookAll()
	BagBarMod.Enable = BagBarMod.Disable
end

-- Disable and unhook Bartender's micro menu module
-- as this directly conflicts with our own.
HandleBartender.HandleMicroMenu = function(self)
	local MicroMenuMod = Bartender4:GetModule("MicroMenu")
	if (not MicroMenuMod) then
		return
	end
	MicroMenuMod:Disable()
	MicroMenuMod:UnhookAll()
	MicroMenuMod.Enable = MicroMenuMod.Disable
end

-- Prevent Bartender from transferring keybinds
-- to the blizzard default bars when entering petbattle,
-- as we're doing this already.
HandleBartender.HandlePetBattles = function(self)
	if (Bartender4.petBattleController) then
		UnregisterStateDriver(Bartender4.petBattleController, "petbattle")
		Bartender4.petBattleController:Execute([[ self:ClearBindings(); ]])
	end
	Bartender4.RegisterPetBattleDriver = function() end
end

-- Prevent Bartender from transferring keybinds
-- to the blizzard default bars when entering vehicles,
-- as this will prevent our own bars from functioning.
HandleBartender.HandleVehicle = function(self)
	if (Bartender4.vehicleController) then
		OverrideActionBar:UnregisterAllEvents()
		OverrideActionBar:Hide()
		OverrideActionBar:SetParent(ns.Hider)
		UnregisterStateDriver(Bartender4.vehicleController, "vehicle")
		Bartender4.vehicleController:Execute([[ self:ClearBindings(); ]])
	end
	Bartender4.UpdateBlizzardVehicle = function() end
end

HandleBartender.HandleBartender = function(self, event, addon)
	if (not IsAddOnLoaded("Bartender4")) then
		return self:RegisterEvent("ADDON_LOADED", "HandleBartender")
	elseif (event == "ADDON_LOADED") then
		if (addon ~= "Bartender4") then return end
		self:UnregisterEvent("ADDON_LOADED", "HandleBartender")
	end

	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "HandleBartender")
	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "HandleBartender")
	end

	--self:HandleBagBar()
	--self:HandleMicroMenu()
	self:HandlePetBattles()
	self:HandleVehicle()

	ns.BartenderHandled = true
end

HandleBartender.OnInitialize = function(self)
	if (not ns.IsAddOnEnabled("Bartender4")) then return self:Disable() end
	if (ns.IsAddOnEnabled("ConsolePort_Bar")) then return self:Disable() end

	self:HandleBartender()
end
