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
local oUF = ns.oUF

local KeyBound = LibStub("LibKeyBound-1.0", true)
local LAB = LibStub("LibActionButton-1.0")

-- Custom API locals
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia

local UIHider = CreateFrame("Frame")
UIHider:SetAllPoints()
UIHider:Hide()

local defaults = {
	outOfRangeColoring = "button", -- "button", "hotkey"
	tooltip = "enabled", -- "enabled", "disabled", "nocombat"
	showGrid = false, -- empty buttons should be hidden by default, only visible when moving spells
	colors = {
		range = { 1, .15, .15 },
		mana = { .25, .25, 1 }
	},
	hideElements = {
		macro = true,
		hotkey = false,
		equipped = true, -- use brighter border?
		border = false,
		borderIfEmpty = true
	},
	keyBoundTarget = false, -- will be set by the actionbar object on each of its buttons
	keyBoundClickButton = "LeftButton", -- just leave this as is
	clickOnDown = false, 
	cooldownCount = nil, -- nil: use cvar, true/false: enable/disable
	lossOfControlCooldown = true,
	flyoutDirection = "UP",
	actionButtonUI = true, -- register the button with SetActionUIButton, this has some side-effects if the button changes from action type to another type, but is required for certain UI integrations. Recommended to only set on pure type=action buttons
	assistedHighlight = true, -- requires actionButtonUI to be set to work
	spellCastVFX = false, -- enable cast vfx
	text = {
		hotkey = {
			font = {
				fontObject = GetFont(15, "Outline", "Number"),
				size = 17,
				flags = "THINOUTLINE"
			},
			color = { 128/255, 128/255, 128/255, .75 },
			position = {
				anchor = "TOPLEFT",
				relAnchor = "TOPLEFT",
				offsetX = 3, 
				offsetY = -3 
			},
			justifyH = "LEFT",
			justifyV = "TOP"
		},
		count = {
			font = {
				fontObject = GetFont(16, "Outline", "Number"),
				size = 18,
				flags = "THINOUTLINE"
			},
			color = { 229/255, 178/255, 38/255, .85 },
			position = {
				anchor = "BOTTOMRIGHT",
				relAnchor = "BOTTOMRIGHT",
				offsetX = -3,
				offsetY = 3 
			},
			justifyH = "RIGHT",
			justifyV = "MIDDLE"
		},
		macro = {
			font = {
				fontObject = GetFont(10, "Outline", "Number"),
				size = 10,
				flags = "THINOUTLINE"
			},
			color = { 128/255, 128/255, 128/255, .75 },
			position = {
				anchor = "BOTTOM",
				relAnchor = "BOTTOM",
				offsetX = 0,
				offsetY = 2
			},
			justifyH = "CENTER",
			justifyV = "BOTTOM"
		}
	}
}

local UpdateTooltip = function(self)
	if (GameTooltip:IsForbidden()) then
		return
	end
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:SetPetAction(self.id)
end

local OnEnter = function(self, ...)
	self.UpdateTooltip = UpdateTooltip
	self:UpdateTooltip()
	--self:OnEnter(...)
end

local OnLeave = function(self)
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:Hide()
end

local OnDragStart = function(self)
	if (InCombatLockdown()) then return end
	if (IsAltKeyDown() and IsControlKeyDown() or IsShiftKeyDown()) or (IsModifiedClick("PICKUPACTION")) then
		self:SetChecked(false)
		PickupPetAction(self.id)
		self:Update()
	end
end

local OnReceiveDrag = function(self)
	if (InCombatLockdown()) then return end
	if (GetCursorInfo() == "petaction") then
		self:SetChecked(false)
		PickupPetAction(self.id)
		self:Update()
	end
end

local OnDragStart = function(self)
	if (InCombatLockdown()) then return end
	if (IsAltKeyDown() and IsControlKeyDown() or IsShiftKeyDown()) or (IsModifiedClick("PICKUPACTION")) then
		self:SetChecked(false)
		PickupPetAction(self.id)
		self:Update()
	end
end

local PetButton = {} -- CreateFrame("CheckButton")
--local PetButton_MT = { __index = PetButton }

ns.PetButtons = {}

ns.PetActionButton = {}
ns.PetActionButton.prototype = PetActionButton
ns.PetActionButton.defaults = defaults

ns.PetActionButton.Create = function(self, id, name, header)

	--local button = setmetatable(CreateFrame("CheckButton", name, header, "PetActionButtonTemplate"), PetButton_MT)
	local button = CreateFrame("CheckButton", name, header, "PetActionButtonTemplate")
	button.showgrid = 0
	button.id = id
	button.parent = header
	button.config = ns:Copy(defaults)

	-- Overwrite some default methods with our own
	for name,method in pairs(PetButton) do
		button[name] = method
	end

	button:SetFrameStrata("MEDIUM")

	-- general size and click settings
	--button:SetHitRectInsets(-10, -10, -10, -10)
	button:SetSize(header.buttonWidth, header.buttonHeight)


	button:SetID(id)
	button:SetAttribute("type", "pet")
	button:SetAttribute("action", id)
	button:SetAttribute("buttonLock", true)
	button:SetAttribute("checkselfcast", true)
	button:SetAttribute("checkfocuscast", true)
	button:SetAttribute("checkmouseovercast", true)

	button:RegisterForDrag("LeftButton", "RightButton")
	button:RegisterForClicks("AnyUp", "AnyDown")

	button:UnregisterAllEvents()
	button:SetScript("OnEvent", nil)

	button.OnEnter = button:GetScript("OnEnter")
	button:SetScript("OnEnter", OnEnter)
	button:SetScript("OnLeave", OnLeave)
	button:SetScript("OnDragStart", OnDragStart)
	button:SetScript("OnReceiveDrag", OnReceiveDrag)

	ns.PetButtons[button] = true

	return button
end

PetButton.UpdateConfig = function(self, buttonConfig)
	self.config = buttonConfig or self.config
	self:Update()
end

PetButton.UpdateAction = function(self)
	self:Update()
end

PetButton.Update = function(self)
	local name, texture, isToken, isActive, autoCastAllowed, autoCastEnabled, spellID = GetPetActionInfo(self.id)

	if (not isToken) then
		self.icon:SetTexture(texture)
		self.tooltipName = name
	else
		self.icon:SetTexture(_G[texture])
		self.tooltipName = _G[name]
	end

	self.isToken = isToken

	if (spellID) then
		local spell = Spell:CreateFromSpellID(spellID)
		self.spellDataLoadedCancelFunc = spell:ContinueWithCancelOnSpellLoad(function()
			self.tooltipSubtext = spell:GetSpellSubtext()
		end)
	end

	if (isActive) then
		if (IsPetAttackAction(self.id)) then
			--if (self.StartFlash) then
			--	self:StartFlash()
			--end
			self:GetCheckedTexture():SetAlpha(0.5)
		else
			--if (self.StopFlash) then
			--	self:StopFlash()
			--end
			self:GetCheckedTexture():SetAlpha(1.0)
		end
		--self:SetChecked(not self.parent.config.hideequipped)
	else
		if (self.StopFlash) then
			self:StopFlash()
		end
	end

	self:SetChecked(isActive)

	self.AutoCastOverlay:SetShown(autoCastAllowed)
	self.AutoCastOverlay:ShowAutoCastEnabled(autoCastEnabled)

	if (texture) then
		if (GetPetActionsUsable()) then
			SetDesaturation(self.icon, nil)
		else
			SetDesaturation(self.icon, 1)
		end
		self.icon:Show()
		self:ShowButton()
	else
		self.icon:Hide()
		self:HideButton()
		if (self.showgrid == 0) then

		end
	end
	self:UpdateCooldown()
	self:UpdateHotkeys()
end

PetButton.GetTexture = function(self)
	local name, texture = GetPetActionInfo(self.id)
	return name and texture
end

PetButton.HasAction = function(self)
	return GetPetActionInfo(self.id)
end

PetButton.UpdateCooldown = function(self)
	local start, duration, enable = GetPetActionCooldown(self.id)
	CooldownFrame_Set(self.cooldown, start, duration, enable)

	if (not GameTooltip:IsForbidden() and GameTooltip:GetOwner() == self) then
		self:OnEnter()
	end
end

PetButton.UpdateHotkeys = function(self)
	local key = self:GetHotkey() or ""
	local hotkey = self.HotKey
	if (key == "" or (self.parent.config.hideElements and self.parent.config.hideElements.hotkey)) then
		hotkey:Hide()
	else
		hotkey:SetText(key)
		hotkey:Show()
	end
end

PetButton.ShowButton = function(self)
	self:SetAlpha(1)
end

PetButton.HideButton = function(self)
	if (self.showgrid == 0 and not self.parent.config.showgrid) then
		self:SetAlpha(0)
	end
end

PetButton.ShowGrid = function(self)
	self.showgrid = self.showgrid + 1
	self:SetAlpha(1)
end

PetButton.HideGrid = function(self)
	if (self.showgrid > 0) then
		self.showgrid = self.showgrid - 1
	end
	if (self.showgrid == 0) and not (GetPetActionInfo(self.id)) and (not self.parent.config.showgrid) then
		self:SetAlpha(0)
	end
end

PetButton.GetHotkey = function(self)
	local key = GetBindingKey(format("BONUSACTIONBUTTON%d", self.id)) or GetBindingKey("CLICK "..self:GetName()..":LeftButton")
	return key and KeyBound and KeyBound:ToShortKey(key)
end

PetButton.GetBindings = function(self)
	local keys, binding = "", nil

	binding = string_format("BONUSACTIONBUTTON%d", self.id)
	for i = 1, select("#", GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if (keys ~= "") then
			keys = keys .. ", "
		end
		keys = keys .. GetBindingText(hotKey,"KEY_")
	end

	binding = "CLICK "..self:GetName()..":LeftButton"
	for i = 1, select("#", GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if (keys ~= "") then
			keys = keys .. ", "
		end
		keys = keys.. GetBindingText(hotKey,"KEY_")
	end

	return keys
end
