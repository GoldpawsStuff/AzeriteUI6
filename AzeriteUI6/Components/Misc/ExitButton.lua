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

local VehicleExit = ns:NewModule("VehicleExit", nil, "LibMoreEvents-1.0", "AceHook-3.0")

-- Custom API locals
local GetMedia = ns.GetMedia

-- Declare module defaults
local defaults = { profile = {
	enable = true
}}

local ExitButton_OnClick = function(self, button)
	if (UnitOnTaxi("player") and (not InCombatLockdown())) then
		TaxiRequestEarlyLanding()
	end
end

local ExitButton_OnEnter = function(self)
	if (GameTooltip:IsForbidden()) then return end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)

	if (UnitOnTaxi("player")) then
		GameTooltip:AddLine(TAXI_CANCEL)
		GameTooltip:AddLine(TAXI_CANCEL_DESCRIPTION, oUF.colors.green:GetRGB())
	elseif (CanExitVehicle("player")) then
		GameTooltip:AddLine(BINDING_NAME_VEHICLEEXIT)
	elseif (IsMounted()) then
		GameTooltip:AddLine(BINDING_NAME_DISMOUNT)
	end
	GameTooltip:Show()
end

local ExitButton_OnLeave = function(self)
	if (GameTooltip:IsForbidden()) then return end

	GameTooltip:Hide()
end

VehicleExit.TakeTaxiNode = function(self)
	if (UnitOnTaxi("player")) then
		return self:StartFlight()
	end
	self.pendingTaxi = GetTime()
	self:RegisterEvent("PLAYER_CONTROL_LOST", "OnEvent")
end

VehicleExit.StartFlight = function(self)
	self.TaxiExitButton:Show()
	self.usingTaxi = GetTime()
	self.pendingTaxi = nil
	self:RegisterEvent("PLAYER_CONTROL_GAINED", "OnEvent")
end

VehicleExit.StopFlight = function(self)
	self.TaxiExitButton:Hide()
	self.usingTaxi = nil
	self:UnregisterEvent("PLAYER_CONTROL_GAINED", "OnEvent")
end

VehicleExit.OnEvent = function(self, event, ...)
	if (event == "PLAYER_CONTROL_LOST") then 
		self:UnregisterEvent("PLAYER_CONTROL_LOST", "OnEvent")

		-- Already on a taxi
		if (UnitOnTaxi("player")) then
			return self:StartFlight()
		end

		local ticks = 0
		C_Timer.NewTicker(1/20, function(timer)
			ticks = ticks + 1
			if (UnitOnTaxi("player")) then
				timer:Cancel()
				self:StartFlight()
			elseif (ticks >= 30) then
				timer:Cancel()
			end
		end)

	elseif (event == "PLAYER_CONTROL_GAINED") then 
		self:StopFlight()
	end
end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling.
VehicleExit.UpdateSettings = function(self)
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
VehicleExit.RefreshConfig = function(self)
	self:UpdateSettings()
end

VehicleExit.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("VehicleExit", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

VehicleExit.OnEnable = function(self)

	local container = CreateFrame("Frame", "AzeriteUI6ExitButton", UIParent)
	container:SetSize(32,32)
	container:SetFrameStrata("MEDIUM")
	container:SetFrameLevel(100)
	container:SetPoint("BOTTOMRIGHT", -220, 200)

	local secure = CreateFrame("Button", "$parentSecure", container, "SecureActionButtonTemplate")
	secure:SetAllPoints(container)
	secure:SetAttribute("macrotext", "/dismount [mounted]\n/leavevehicle [canexitvehicle]")
	secure:SetAttribute("type", "macro")
	secure:SetScript("OnMouseDown", ExitButton_OnClick)
	secure:SetScript("OnEnter", ExitButton_OnEnter)
	secure:SetScript("OnLeave", ExitButton_OnLeave)

	local texture = secure:CreateTexture(nil, "ARTWORK", nil, 1)
	texture:SetPoint("CENTER", 0, 0)
	texture:SetSize(80, 80)
	texture:SetTexture(GetMedia("icon_exit_flight"))

	RegisterStateDriver(secure, "visibility", "[canexitvehicle][mounted]show;hide")

	local notsecure = CreateFrame("Button", "$parentSecure", container)
	notsecure:SetAllPoints(container)
	notsecure:SetScript("OnMouseDown", ExitButton_OnClick)
	notsecure:SetScript("OnEnter", ExitButton_OnEnter)
	notsecure:SetScript("OnLeave", ExitButton_OnLeave)

	local texture = notsecure:CreateTexture(nil, "ARTWORK", nil, 1)
	texture:SetPoint("CENTER", 0, 0)
	texture:SetSize(80, 80)
	texture:SetTexture(GetMedia("icon_exit_flight"))

	self.TaxiExitButton = notsecure

	self:SecureHook("TakeTaxiNode", "TakeTaxiNode")

	if (UnitOnTaxi("player")) then
		self:StartFlight()
	else
		self.TaxiExitButton:Hide()
	end
end
