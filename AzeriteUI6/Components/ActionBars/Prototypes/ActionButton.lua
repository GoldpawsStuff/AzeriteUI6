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
	outOfRangeColoring = "button",
	tooltip = "enabled",
	showGrid = false,
	colors = {
		range = { .8, .1, .1 },
		mana = { .5, .5, 1 }
	},
	hideElements = {
		macro = true,
		hotkey = false,
		equipped = true, -- use brighter border?
		border = false,
		borderIfEmpty = true
	},
	keyBoundTarget = false,
	keyBoundClickButton = "LeftButton",
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

local exitButton = {
	func = function(button)
		if (UnitExists("vehicle")) then
			VehicleExit()
		else
			PetDismiss()
		end
	end,
	tooltip = LEAVE_VEHICLE,
	texture = [[Interface\Icons\achievement_bg_kill_carrier_opposing_flagroom]]
}

local Button_OnEnter = function(self)
	if (self.OnEnter) then
		self:OnEnter()
	end
end

local Button_OnLeave = function(self)
	if (self.OnLeave) then
		self:OnLeave()
	end
end

local ActionButton = {}

ns.ActionButton = {}
ns.ActionButton.prototype = ActionButton
ns.ActionButton.defaults = defaults

ns.ActionButton.Create = function(self, id, name, header)

	local button = LAB:CreateButton(id, name, header, defaults)

	-- Overwrite some default methods with our own
	for name,method in pairs(ActionButton) do
		button[name] = method
	end

	-- Set the states allowing for page switching (forms, vehicles, override etc)
	for k = 1,18 do
		button:SetState(k, "action", (k - 1) * NUM_ACTIONBAR_BUTTONS + button.id)
	end
	button:SetState(0, "action", (header.id - 1) * NUM_ACTIONBAR_BUTTONS + button.id)

	-- Add in a vehicle exit button at slot 7 for the primary action bar.
	if (header.id == 1 and button.id == 7) then
		button:SetState(16, "custom", exitButton)
		button:SetState(17, "custom", exitButton)
		button:SetState(18, "custom", exitButton)
	end

	-- general size and click settings
	button:SetHitRectInsets(-10, -10, -10, -10)
	button:SetSize(header.buttonWidth, header.buttonHeight)
	button:SetAttribute("buttonLock", true)
	button:SetAttribute("checkselfcast", true)
	button:SetAttribute("checkfocuscast", true)
	button:SetAttribute("checkmouseovercast", true)

	-- hide unused elements
	button.BorderShadow:SetParent(UIHider)
	button.CooldownFlash:SetParent(UIHider)
	button.InterruptDisplay:SetParent(UIHider)
	button.NewActionTexture:SetParent(UIHider) -- initial hiding
	button.NewActionTexture:Hide() -- initial hiding
	button.NewActionTexture = false -- should be enough, LAB checks for existence before running methods 
	button.NormalTexture:SetTexture(GetMedia("blank"))
	button.NormalTexture:SetParent(UIHider)
	button.SpellHighlightAnim:Stop() -- default spell highlight, we use our own
	button.SpellHighlightTexture:SetParent(UIHider)
	button.SlotArt:SetParent(UIHider)
	--button.SlotBackground:SetParent(UIHider) -- doesn't exist anymore
	button.SpellCastAnimFrame:SetParent(UIHider)
	button.TargetReticleAnimFrame:SetParent(UIHider)

	-- block BaseActionButtonMixin
	button.SlotArt = nil
	button.SlotBackground = nil -- doesn't exist to begin with

	-- remove default mask texture
	button.icon:RemoveMaskTexture(button.IconMask)

	-- custom overlay frame
	button.OverlayFrame = CreateFrame("Frame", nil, button)
	button.OverlayFrame:SetFrameLevel(button:GetFrameLevel() + 3)
	button.OverlayFrame:SetAllPoints()

	-- custom icon border
	button.IconBorder = button.OverlayFrame:CreateTexture(nil, "BORDER", nil, 1)
	button.IconBorder:SetPoint("CENTER", 0, 0)
	button.IconBorder:SetSize(134.295081967, 134.295081967)
	button.IconBorder:SetTexture(GetMedia("actionbutton-border"))
	button.IconBorder:SetVertexColor(oUF.colors.ui:GetRGB())

	-- custom backdrop
	button.backdrop = button:CreateTexture(nil, "BACKGROUND", nil, -7)
	button.backdrop:SetSize(134.295081967, 134.295081967)
	button.backdrop:SetPoint("CENTER", 0, 0)
	button.backdrop:SetTexture(GetMedia("actionbutton-backdrop"))
	button.backdrop:SetVertexColor(.67, .67, .67, 1)

	-- cooldown
	button.cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
	button.cooldown:ClearAllPoints()
	button.cooldown:SetAllPoints(button.icon)
	button.cooldown:SetUseCircularEdge(true)
	button.cooldown:SetReverse(false)
	button.cooldown:SetSwipeTexture(GetMedia("actionbutton-mask-circular"))
	button.cooldown:SetDrawSwipe(true)
	button.cooldown:SetBlingTexture(GetMedia("blank"), 0, 0, 0, 0)
	button.cooldown:SetDrawBling(false)
	button.cooldown:SetEdgeTexture(GetMedia("blank"))
	button.cooldown:SetDrawEdge(false)
	button.cooldown:SetHideCountdownNumbers(true)

	-- gloss

	-- icon
	button.icon:SetDrawLayer("BACKGROUND", 1)
	button.icon:ClearAllPoints()
	button.icon:SetPoint("CENTER", 0, 0)
	button.icon:SetSize(44, 44)
	button.icon:SetMask(GetMedia("actionbutton-mask-circular"))

	-- normal border 

	-- equipped items border

	-- checked (pet abilities that are on autocast)
	button.CheckedTexture = button:GetCheckedTexture()
	button.CheckedTexture:SetTexture(GetMedia("actionbutton-mask-circular"))
	button.CheckedTexture:SetVertexColor(1, .82, .1, .2)
	button.CheckedTexture:SetAllPoints(button.icon)
	button.CheckedTexture:SetBlendMode("ADD")
	button.CheckedTexture:SetDrawLayer("OVERLAY", 1)

	-- highlight (hover)
	button.HighlightTexture = button:GetHighlightTexture()
	button.HighlightTexture:SetTexture(GetMedia("actionbutton-mask-circular"))
	button.HighlightTexture:SetVertexColor(1, 1, 1, .2)
	button.HighlightTexture:SetAllPoints(button.icon)
	button.HighlightTexture:SetBlendMode("ADD")
	button.HighlightTexture:SetDrawLayer("HIGHLIGHT")

	-- pushed texture
	button.PushedTexture = button:GetPushedTexture()
	button.PushedTexture:SetTexture(GetMedia("actionbutton-mask-circular"))
	button.PushedTexture:SetVertexColor(1, 1, 1, .2)
	button.PushedTexture:SetAllPoints(button.icon)
	button.PushedTexture:SetBlendMode("ADD")
	button.PushedTexture:SetDrawLayer("OVERLAY", 2)

	-- autoattack flash
	button.Flash:SetDrawLayer("OVERLAY", 2)
	button.Flash:SetAllPoints(button.icon)
	button.Flash:SetVertexColor(1, 0, 0, .25)
	button.Flash:SetTexture(GetMedia("actionbutton-mask-circular"))
	--button.Flash:Hide()

	-- hotkey
	button.HotKey.SetFont = function() end -- disables LAB from overriding it
	button.HotKey:SetParent(button.OverlayFrame)
	button.HotKey:SetDrawLayer("OVERLAY", 1)
	button.HotKey:SetFontObject(defaults.text.hotkey.font.fontObject)
	button.HotKey:SetJustifyH(defaults.text.hotkey.justifyH)
	button.HotKey:SetJustifyV(defaults.text.hotkey.justifyV)
	button.HotKey:SetTextColor(oUF.colors.quest.gray:GetRGB())
	button.HotKey:SetAlpha(.75)

	-- spell charges / stack count
	button.Count.SetFont = function() end -- disables LAB from overriding it
	button.Count:SetParent(button.OverlayFrame)
	button.Count:SetDrawLayer("OVERLAY", 1)
	button.Count:SetFontObject(defaults.text.count.font.fontObject)
	button.Count:SetJustifyH(defaults.text.count.justifyH)
	button.Count:SetJustifyV(defaults.text.count.justifyV)
	button.Count:SetTextColor(oUF.colors.normal:GetRGB())
	button.Count:SetAlpha(.85)

	-- macro name
	button.Name.SetFont = function() end -- disables LAB from overriding it
	button.Name:SetParent(button.OverlayFrame)
	button.Name:SetDrawLayer("OVERLAY", 1)
	button.Name:SetFontObject(defaults.text.macro.font.fontObject)
	button.Name:SetJustifyH(defaults.text.macro.justifyH)
	button.Name:SetJustifyV(defaults.text.macro.justifyV)
	button.Name:SetAlpha(0)

	--[[
		AssistedCombatHighlightFrame 
		- blue glow, next in rotation
	--]]
	-- spell highlight
	local highlight = button.OverlayFrame:CreateTexture(nil, "ARTWORK", nil, -7)
	highlight:SetSize(134.295081967, 134.295081967)
	highlight:SetPoint("CENTER", 0, 0)
	highlight:SetTexture(GetMedia("actionbutton-spellhighlight"))
	highlight:SetVertexColor(96/255, 159/255, 238/255, .75) -- AzeriteUI6 blue, closer to Blizz defaults
	--highlight:SetVertexColor(190/255, 119/255, 238/255, .75) -- AzeriteUI5 purple
	highlight:Hide()

	-- create a dummy object to safely take control of the spell highlights
	-- *this objects contain everything LibActionButton calls or references.
	button.AssistedCombatHighlightFrame = {
		Show = function() highlight:Show() end,
		Hide = function() highlight:Hide() end,
		Flipbook = { Anim = { Play = function() end, Stop = function() end } }
	}

	--[[
		SpellActivationAlert 
		- yellow bright glow, activated spell
		- uses LBG
			- LBG.ShowOverlayGlow(button)
			- LBG.HideOverlayGlow(button)
		- does not fit our buttons AT ALL
	--]]

	--highlight:SetVertexColor(249/255, 188/255, 65/255, .75)
	--highlight:Hide()

	-- Stop button skinners from messing with it
	button.MasqueSkinned = true -- disables LAB from changing a few textures
	button.AddToButtonFacade = function() end -- disables LAB from overriding it
	button.AddToMasque = function() end -- disables LAB from overriding it

	-- replace the default scripts with an extra layer
	button.OnEnter = button:GetScript("OnEnter")
	button.OnLeave = button:GetScript("OnLeave")

	button:SetScript("OnEnter", Button_OnEnter)
	button:SetScript("OnLeave", Button_OnLeave)

	return button
end

-- Problem: The LibActionButton method 'UpdateHotkeys' is not a public function,
-- so one of the dumber hacks here is to replace the 'GetHotKey' method instead.
-- We toggle the text in the standard hotkey display and our custom gamepad display
-- based on whether or not a gamepad keypad currently is in use for the button.
ActionButton.GetHotkey = function(self)
	local name = ("CLICK %s:%s"):format(self:GetName(), self.config.keyBoundClickButton)
	local key = GetBindingKey(self.config.keyBoundTarget or name)
	if not key and self.config.keyBoundTarget then
		key = GetBindingKey(name)
	end
	if key then
		if (IsBindingForGamePad(key)) then 
			local abbr = GetBindingText(key, "KEY_", true) -- small buttons
			if (abbr) then
				if (not self.GamePadHotKey) then
					self.GamePadHotKey = self.OverlayFrame:CreateFontString(nil, "ARTWORK")
					self.GamePadHotKey:SetPoint("CENTER", self, "TOPLEFT", 10, -10)
					self.GamePadHotKey:SetFontObject(ns.GetFont(18, "Outline", "Number"))
				end
				if (key:find("-")) then
					self.GamePadHotKey:SetFontObject(ns.GetFont(15, "Outline", "Number"))
				else
					self.GamePadHotKey:SetFontObject(ns.GetFont(18, "Outline", "Number"))
				end
				self.GamePadHotKey:SetText(abbr)

				return ""
			end
		else
			if (self.GamePadHotKey) then
				self.GamePadHotKey:SetText("")
			end
		end
		return KeyBound and KeyBound:ToShortKey(key) or key
	end
end
