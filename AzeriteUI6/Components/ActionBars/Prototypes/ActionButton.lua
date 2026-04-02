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

-- custom exit button for vehicle/overridebars
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

-- our glorious template with very few methods
local ActionButton = {}

ns.ActionButtons = {}
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
	button.NormalTexture:SetTexture(GetMedia("blank")) -- default border texture
	button.NormalTexture:SetParent(UIHider)
	button.SpellHighlightAnim:Stop() -- default spell highlight, we use our own
	button.SpellHighlightTexture:SetParent(UIHider)
	button.SlotArt:SetParent(UIHider) -- more graphical crap we don't need
	button.SpellCastAnimFrame:SetParent(UIHider) -- we sooo don't need a castbar in the button
	button.TargetReticleAnimFrame:SetParent(UIHider) -- nothing with such a name deserves to exist

	-- block BaseActionButtonMixin
	button.SlotArt = nil -- this prevents the above from modifying or showing it

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
	-- *do we really want this? it just makes it harder to view

	-- icon
	button.icon:SetDrawLayer("BACKGROUND", 1)
	button.icon:ClearAllPoints()
	button.icon:SetPoint("CENTER", 0, 0)
	button.icon:SetSize(44, 44)
	button.icon:SetMask(GetMedia("actionbutton-mask-circular"))

	-- attempt to hijack LABs disabled coloring,
	-- since pure gray looks out of place on our buttons.
	button.icon.__SetVertexColor = button.icon.SetVertexColor
	button.icon.SetVertexColor = function(icon, r, g, b, a)
		local normalized_r = math.floor((r * 100) + .5) / 100
		local normalized_g = math.floor((g * 100) + .5) / 100
		local normalized_b = math.floor((b * 100) + .5) / 100
		if (normalized_r == .4 and normalized_g == .4 and normalized_b == .4) then
			icon:__SetVertexColor(.4, .36, .32)
		else
			icon:__SetVertexColor(r, g, b)
		end
	end

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
	-- assisted combat highlight (basically blizzard's own MaxDPS, sort of)
	-- *note to self, make compatible with MaxDPS if possible
	local ACH = button.OverlayFrame:CreateTexture(nil, "ARTWORK", nil, 1)
	ACH:SetSize(134.295081967, 134.295081967)
	ACH:SetPoint("CENTER", 0, 0)
	ACH:SetTexture(GetMedia("actionbutton-spellhighlight"))
	ACH:SetVertexColor(136/255, 189/255, 249/255, .75) -- AzeriteUI6 blue, closer to Blizz defaults
	--ACH:SetVertexColor(190/255, 119/255, 238/255, .75) -- AzeriteUI5 purple
	ACH:Hide()

	-- create a dummy object to safely take control of the assisted combat highlights
	-- *this objects contain everything LAB calls or references.
	button.AssistedCombatHighlightFrame = {
		Show = function() ACH:Show() end,
		Hide = function() ACH:Hide() end,
		Flipbook = { Anim = { Play = function() end, Stop = function() end } }
	}

	--[[
		SpellActivationAlert 
		- yellow bright glow, activated spell
		- uses LBG
			- LBG.ShowOverlayGlow(button)
			- LBG.HideOverlayGlow(button)
	--]]
	-- spell highlight
	local spellActivationAlert = button.OverlayFrame:CreateTexture(nil, "ARTWORK", nil, -7)
	spellActivationAlert:SetSize(134.295081967, 134.295081967)
	spellActivationAlert:SetPoint("CENTER", 0, 0)
	spellActivationAlert:SetTexture(GetMedia("actionbutton-spellhighlight"))
	spellActivationAlert:SetVertexColor(249/255, 234/255, 137/255, .75) -- bright yellow tinted white
	spellActivationAlert:Hide()

	-- fully faking this one.
	-- *can NOT guarantee it works with anything else than our buttons and Bartender,
	--  will look into it and replace more frame methods if a problem occurs.
	button.__LBGoverlay = {
		-- We don't really do any anims out, we simply hide
		animOut = {
			IsPlaying = function() return not spellActivationAlert:IsShown() end, -- it won't show unless it's hidden. doh.
			Play = function() spellActivationAlert:Hide() end, 
			Stop = function() spellActivationAlert:Hide() end 
		},
		-- This is when the activation alerts are shown
		animIn = {
			IsPlaying = function() return not spellActivationAlert:IsShown() end, -- it won't show unless it's hidden. 
			Play = function() spellActivationAlert:Show() end, -- this is pretty much the only time we want it shown, we don't animate
			Stop = function() spellActivationAlert:Hide() end 
		}
	}

	-- This could break some functionality in other parts of the addon, 
	-- so I should make a habit out of calling the :__IsVisible() original instead.
	button.__IsVisible = button.IsVisible
	button.IsVisible = function() return true end 

	-- Stop button skinners from messing with it
	button.MasqueSkinned = true -- disables LAB from changing a few textures
	button.AddToButtonFacade = function() end -- disables LAB from overriding it
	button.AddToMasque = function() end -- disables LAB from overriding it

	ns.ActionButtons[button] = true

	return button
end

-- Problem: The LAB method 'UpdateHotkeys' is not a public function,
-- so one of the dumber hacks here is to replace the 'GetHotKey' method instead.
-- We toggle the text in the standard hotkey display and our custom gamepad display
-- based on whether or not a gamepad keypad currently is in use for the button.
ActionButton.GetHotkey = function(self)
	local name = ("CLICK %s:%s"):format(self:GetName(), self.config.keyBoundClickButton)
	local key = GetBindingKey(self.config.keyBoundTarget or name)
	if (not key and self.config.keyBoundTarget) then -- when keyBoundTarget is set but returns nothing 
		key = GetBindingKey(name)
	end
	if (key) then
		-- Are we currently using gamepad binds?
		if (IsBindingForGamePad(key)) then 
			local abbr = GetBindingText(key, "KEY_", true) -- small buttons
			if (abbr) then
				-- on-demand creation
				if (not self.GamePadHotKey) then
					self.GamePadHotKey = self.OverlayFrame:CreateFontString(nil, "ARTWORK")
					self.GamePadHotKey:SetPoint("CENTER", self, "TOPLEFT", 10, -10)
					self.GamePadHotKey:SetFontObject(ns.GetFont(18, "Outline", "Number"))
				end
				-- adjust font size for multiple keys
				if (key:find("-")) then
					self.GamePadHotKey:SetFontObject(ns.GetFont(15, "Outline", "Number"))
				else
					self.GamePadHotKey:SetFontObject(ns.GetFont(18, "Outline", "Number"))
				end
				self.GamePadHotKey:SetText(abbr) -- set our custom gamepad bind text

				return "" -- hide the regular hotkey when using gamepad binds
			end
		else
			-- Hide the gamepad binds when using keyboad
			if (self.GamePadHotKey) then
				self.GamePadHotKey:SetText("")
			end
		end
		-- Return the abbreviated keybind
		return KeyBound and KeyBound:ToShortKey(key) or key
	end
end
