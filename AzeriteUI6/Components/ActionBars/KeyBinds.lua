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

local LFF = LibStub("LibFadingFrames-1.0")
local KeyBound = LibStub("LibKeyBound-1.0")

local KeyBinds = ns:NewModule("KeyBinds", nil, "AceConsole-3.0", "LibMoreEvents-1.0")

local overlays = {}

KeyBinds.ToggleBinds = function(self)
	if (not InCombatLockdown()) then
		KeyBound:Toggle()
	end
end

KeyBinds.HideBinds = function(self)
	if (not InCombatLockdown()) then
		if (KeyBound:IsShown()) then
			KeyBound:Deactivate()
		end
	end
end

KeyBinds.HasConflicts = function(self)
	for _,addon in next,{ "Bartender4", "ConsolePort_Bar", "Dominos" } do 
		if (C_AddOns.GetAddOnEnableState(addon, UnitGUID("player")) == Enum.AddOnEnableState.All) then
			return true
		end
	end
end

KeyBinds.OnInitialize = function(self)
	if (self:HasConflicts()) then return self:Disable() end

	local escCatcher = CreateFrame("Frame", nil, UIParent)
	escCatcher:SetPropagateKeyboardInput(true)
	escCatcher:SetScript("OnKeyDown", function(self, key)
		if key == "ESCAPE" and KeyBound:IsShown() then
			self:SetPropagateKeyboardInput(false)
			KeyBound:Deactivate()
		else
			self:SetPropagateKeyboardInput(true)
		end
	end)
	escCatcher:EnableKeyboard(true)
	escCatcher:Hide()

	local OnLibKeyBoundEnabled = function()
		for button in next,ns.ActionButtons do
			if (not overlays[button]) then
				local overlay = button.OverlayFrame:CreateTexture(nil, "OVERLAY", nil, -1)
				overlay:SetPoint("CENTER", 0, 0)
				overlay:SetTexture(ns.GetMedia("actionbutton-mask-circular"))
				overlay:SetSize(72, 72)
				overlay:Hide()

				overlays[button] = overlay
			end

			overlays[button]:SetVertexColor(KeyBound:GetColorKeyBoundMode())
			overlays[button]:Show()
		end
		escCatcher:Show()

		local dialog = KeyboundDialog or KeyBound.dialog
		if (not dialog) then return end

		dialog:ClearAllPoints()
		dialog:SetPoint("CENTER", 0, 200)
	end

	local OnLibKeyBoundDisabled = function()
		for button in next,ns.ActionButtons do
			if (overlays[button]) then
				overlays[button]:Hide()
			end
		end
		escCatcher:Hide()
	end

	KeyBound.RegisterCallback(self, "LIBKEYBOUND_ENABLED", OnLibKeyBoundEnabled)
	KeyBound.RegisterCallback(self, "LIBKEYBOUND_DISABLED", OnLibKeyBoundDisabled)

	self:RegisterChatCommand("bind", "ToggleBinds")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "HideBinds")
end

KeyBinds.OnEnable = function(self)
end
