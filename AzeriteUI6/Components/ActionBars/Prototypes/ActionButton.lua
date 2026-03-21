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

local LAB = LibStub("LibActionButton-1.0")

-- Custom API locals
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia

local Hider= CreateFrame("Frame")
Hider:SetAllPoints()
Hider:Hide()

local config = {
	outOfRangeColoring = "button",
	tooltip = "enabled",
	showGrid = false,
	colors = {
		range = { 0.8, 0.1, 0.1 },
		mana = { 0.5, 0.5, 1.0 }
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
	actionButtonUI = false, -- register the button with SetActionUIButton, this has some side-effects if the button changes from action type to another type, but is required for certain UI integrations. Recommended to only set on pure type=action buttons
	assistedHighlight = true, -- requires actionButtonUI to be set to work
	spellCastVFX = false, -- enable cast vfx
	text = {
		hotkey = {
			font = {
				fontObject = GetFont(15, "Outline", "Number"),
				size = 15,
				flags = "THINOUTLINE"
			},
			color = { 128/255, 128/255, 128/255, .75 },
			position = {
				anchor = "TOPLEFT",
				relAnchor = "TOPLEFT",
				offsetX = -3,
				offsetY = 2
			},
			justifyH = "LEFT",
			justifyV = "TOP"
		},
		count = {
			font = {
				fontObject = GetFont(16, "Outline", "Number"),
				size = 16,
				flags = "THINOUTLINE"
			},
			color = { 229/255, 178/255, 38/255, .85 },
			position = {
				anchor = "BOTTOMRIGHT",
				relAnchor = "BOTTOMRIGHT",
				offsetX = 3,
				offsetY = -5
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

local ActionButton = CreateFrame("CheckButton")
local ActionButton_MT = { __index = ActionButton }

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

ns.ActionButton = {}
ns.ActionButton.prototype = ActionButton
ns.ActionButton.defaults = defaults

ns.ActionButton.Create = function(self, id, name, header)

	local button = LAB:CreateButton(id, name, header, config)

	for k = 1,18 do
		button:SetState(k, "action", (k - 1) * NUM_ACTIONBAR_BUTTONS + button.id)
	end

	button:SetState(0, "action", (header.id - 1) * NUM_ACTIONBAR_BUTTONS + button.id)
	--button:Show()
	--button:SetAttribute("statehidden", nil)
	--button:UpdateAction()

	-- Add in a vehicle exit button at slot 7 for the primary action bar.
	if (header.id == 1 and button.id == 7) then
		button:SetState(16, "custom", exitButton)
		button:SetState(17, "custom", exitButton)
		button:SetState(18, "custom", exitButton)
	end

	button:SetSize(header.buttonWidth, header.buttonHeight)
	button:SetAttribute("checkselfcast", true)
	button:SetAttribute("checkfocuscast", true)
	button:SetAttribute("checkmouseovercast", true)

	-- Hide unused elements
	button.CooldownFlash:SetParent(Hider)
	button.InterruptDisplay:SetParent(Hider)
	button.NewActionTexture:SetParent(Hider)
	button.NormalTexture:SetTexture()
	button.NormalTexture:SetParent(Hider)
	button.SpellHighlightAnim:Stop()
	button.SpellHighlightTexture:SetParent(Hider)
	button.SlotArt:SetParent(Hider)
	--button.SlotBackground:SetParent(Hider)
	button.SpellCastAnimFrame:SetParent(Hider)
	button.TargetReticleAnimFrame:SetParent(Hider)

	if (button.BorderShadow) then
		button.BorderShadow:SetParent(Hider)
	end

	-- Block BaseActionButtonMixin
	button.SlotArt = nil
	--button.SlotBackground = nil

	-- Remove default mask texture
	button.icon:RemoveMaskTexture(button.IconMask)

	button:DisableDrawLayer("ARTWORK")

	button:SetAttribute("buttonLock", true)
	button:SetSize(64, 64)
	button:SetHitRectInsets(-10, -10, -10, -10)
	button.hitRects = { -10, -10, -10, -10 }

	-- Overlay Frame
	button.OverlayFrame = CreateFrame("Frame", nil, button)
	button.OverlayFrame:SetFrameLevel(button:GetFrameLevel() + 3)
	button.OverlayFrame:SetAllPoints()

	-- Icon Border
	button.IconBorder = button.OverlayFrame:CreateTexture(nil, "BORDER", nil, 1)
	button.IconBorder:SetPoint("CENTER", 0, 0)
	button.IconBorder:SetSize(134.295081967, 134.295081967)
	button.IconBorder:SetTexture(GetMedia("actionbutton-border"))
	button.IconBorder:SetVertexColor(oUF.colors.ui:GetRGB())

	-- backdrop
	-- Custom slot texture
	button.backdrop = button:CreateTexture(nil, "BACKGROUND", nil, -7)
	button.backdrop:SetSize(134.295081967, 134.295081967)
	button.backdrop:SetPoint("CENTER", 0, 0)
	button.backdrop:SetTexture(GetMedia("actionbutton-backdrop"))
	button.backdrop:SetVertexColor(.67, .67, .67, 1)

	-- cooldown

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
	button:GetCheckedTexture():SetTexture(GetMedia("actionbutton-mask-circular"))
	button:GetCheckedTexture():SetVertexColor(1, .82, .1, .2)
	button:GetCheckedTexture():SetAllPoints(button.icon)
	button:GetCheckedTexture():SetBlendMode("ADD")
	button:GetCheckedTexture():SetDrawLayer("OVERLAY", 1)

	-- flash (autocast/autoattack)

	-- highlight (hover)
	button:GetHighlightTexture():SetTexture(GetMedia("actionbutton-mask-circular"))
	button:GetHighlightTexture():SetVertexColor(1, 1, 1, .2)
	button:GetHighlightTexture():SetAllPoints(button.icon)
	button:GetHighlightTexture():SetBlendMode("ADD")
	button:GetHighlightTexture():SetDrawLayer("HIGHLIGHT")

	-- pushed texture
	button:GetPushedTexture():SetTexture(GetMedia("actionbutton-mask-circular"))
	button:GetPushedTexture():SetVertexColor(1, 1, 1, .2)
	button:GetPushedTexture():SetAllPoints(button.icon)
	button:GetPushedTexture():SetBlendMode("ADD")
	button:GetPushedTexture():SetDrawLayer("OVERLAY", 2)

	-- autoattack flash
	button.Flash:SetDrawLayer("OVERLAY", 2)
	button.Flash:SetAllPoints(button.icon)
	button.Flash:SetVertexColor(1, 0, 0, .25)
	button.Flash:SetTexture(GetMedia("actionbutton-mask-circular"))
	button.Flash:Hide()

	-- hotkey
	button.HotKey.SetFont = function() end -- disables LAB from overriding it
	button.HotKey:SetFontObject(config.text.hotkey.font.fontObject)
	button.HotKey:SetJustifyH(config.text.hotkey.justifyH)
	button.HotKey:SetJustifyV(config.text.hotkey.justifyV)
	button.HotKey:SetParent(button.OverlayFrame)
	button.HotKey:SetDrawLayer("OVERLAY", 1)
	button.HotKey:ClearAllPoints()
	button.HotKey:SetPoint("TOPLEFT", -5, -5)
	button.HotKey:SetTextColor(oUF.colors.quest.gray:GetRGB())
	button.HotKey:SetAlpha(.75)

	-- spell charges / stack count
	button.Count.SetFont = function() end -- disables LAB from overriding it
	button.Count:SetFontObject(config.text.count.font.fontObject)
	button.Count:SetJustifyH(config.text.count.justifyH)
	button.Count:SetJustifyV(config.text.count.justifyV)
	button.Count:SetParent(button.OverlayFrame)
	button.Count:SetDrawLayer("OVERLAY", 1)
	button.Count:ClearAllPoints()
	button.Count:SetPoint("BOTTOMRIGHT", -3, 3)
	button.Count:SetTextColor(oUF.colors.normal:GetRGB())
	button.Count:SetAlpha(.85)

	-- macro name
	button.Name.SetFont = function() end -- disables LAB from overriding it
	button.Name:SetFontObject(config.text.macro.font.fontObject)
	button.Name:SetJustifyH(config.text.macro.justifyH)
	button.Name:SetJustifyV(config.text.macro.justifyV)

	-- disable the new action texture
	button.NewActionTexture:Hide()
	button.NewActionTexture = false

	-- spell highlight
	local highlight = CreateFrame("Frame", nil, button)

	-- create a dummy object to safely take control of the spell highlights
	button.AssistedCombatHighlightFrame = {
		Flipbook = { Anim = { Play = function() end, Stop = function() end } },
		Show = function() highlight:Show() end,
		Hide = function() highlight:Hide() end
	}

	button.AddToButtonFacade = function() end -- disables LAB from overriding it
	button.AddToMasque = function() end -- disables LAB from overriding it

	button.OnEnter = button:GetScript("OnEnter")
	button.OnLeave = button:GetScript("OnLeave")

	button:SetScript("OnEnter", Button_OnEnter)
	button:SetScript("OnLeave", Button_OnLeave)

	return button
end

