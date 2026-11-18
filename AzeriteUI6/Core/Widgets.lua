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

local AceGUI = LibStub("AceGUI-3.0")

local function IsModernClient()
	return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE or WOW_PROJECT_ID == WOW_PROJECT_CAMELOT
end

do 
	local AceGUI = LibStub("AceGUI-3.0")

	local Type = "ModernCheckBox"
	local Version = 1

	local function ApplyModernTextures(widget)
		local checkbg   = widget.checkbg
		local check     = widget.check
		local highlight = widget.highlight

		if IsModernClient() then
			-- Modern Settings UI style
			checkbg:SetAtlas("checkbox-minimal", true)
			check:SetAtlas("checkmark-minimal", true)
			highlight:SetAtlas("checkbox-minimal", true)
			highlight:SetBlendMode("ADD")
			highlight:SetAlpha(0.25)

			-- Atlas is 30x29; scale it down slightly to match the Settings panel feel
			local size = 22
			checkbg:SetSize(30,29)
			check:SetAllPoints(checkbg)
			highlight:SetAllPoints(checkbg)
		else
			-- Classic fallback
			checkbg:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
			checkbg:SetTexCoord(0, 1, 0, 1)
			check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
			check:SetTexCoord(0, 1, 0, 1)
			highlight:SetTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
			highlight:SetBlendMode("ADD")
			highlight:SetAlpha(1)

			local size = 24
			checkbg:SetSize(size, size)
			check:SetAllPoints(checkbg)
			highlight:SetAllPoints(checkbg)
		end
	end

	local function Constructor()
		local widget = AceGUI:Create("CheckBox")
		widget.type = Type

		-- Override SetType so AceGUI doesn’t stomp our textures later
		local originalSetType = widget.SetType
		widget.SetType = function(self, type)
			if originalSetType then
				originalSetType(self, type)
			end
			ApplyModernTextures(self)
		end

		-- Apply immediately
		ApplyModernTextures(widget)

		-- Optional indent support
		function widget:SetIndent(pixels)
			pixels = pixels or 0
			local frame = widget.frame
			local checkbg = widget.checkbg
			local text = widget.text

			checkbg:ClearAllPoints()
			checkbg:SetPoint("LEFT", frame, "LEFT", pixels, 0)
			text:ClearAllPoints()
			text:SetPoint("LEFT", checkbg, "RIGHT", IsModernClient() and 6 or 2, 0)
			text:SetPoint("RIGHT", frame, "RIGHT")
		end

		widget:SetIndent(0)

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)

end

do 
	local AceGUI = LibStub("AceGUI-3.0")

	local Type = "ModernIndentedCheckBox"
	local Version = 1

	local function ApplyModernTextures(widget)
		local checkbg   = widget.checkbg
		local check     = widget.check
		local highlight = widget.highlight

		if IsModernClient() then
			-- Modern Settings UI style
			checkbg:SetAtlas("checkbox-minimal", true)
			check:SetAtlas("checkmark-minimal", true)
			highlight:SetAtlas("checkbox-minimal", true)
			highlight:SetBlendMode("ADD")
			highlight:SetAlpha(0.25)

			-- Atlas is 30x29; scale it down slightly to match the Settings panel feel
			local size = 30
			checkbg:SetSize(30,29)
			check:SetAllPoints(checkbg)
			highlight:SetAllPoints(checkbg)
		else
			-- Classic fallback
			checkbg:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
			checkbg:SetTexCoord(0, 1, 0, 1)
			check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
			check:SetTexCoord(0, 1, 0, 1)
			highlight:SetTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
			highlight:SetBlendMode("ADD")
			highlight:SetAlpha(1)

			local size = 24
			checkbg:SetSize(size, size)
			check:SetAllPoints(checkbg)
			highlight:SetAllPoints(checkbg)
		end
	end

	local function Constructor()
		local widget = AceGUI:Create("CheckBox")
		widget.type = Type

		-- Override SetType so AceGUI doesn’t stomp our textures later
		local originalSetType = widget.SetType
		widget.SetType = function(self, type)
			if originalSetType then
				originalSetType(self, type)
			end
			ApplyModernTextures(self)
		end

		-- Apply immediately
		ApplyModernTextures(widget)

		-- Optional indent support
		function widget:SetIndent(pixels)
			pixels = pixels or 0
			local frame = widget.frame
			local checkbg = widget.checkbg
			local text = widget.text

			checkbg:ClearAllPoints()
			checkbg:SetPoint("LEFT", frame, "LEFT", pixels, 0)
			text:ClearAllPoints()
			text:SetPoint("LEFT", checkbg, "RIGHT", IsModernClient() and 6 or 2, 0)
			text:SetPoint("RIGHT", frame, "RIGHT")
		end

		widget:SetIndent(32)

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)

end

do

	local Type = "ModernSlider"
	local Version = 6

	local EXTRA_BOTTOM_PADDING = 16

	local function ApplyModernSlider(widget)
		local slider = widget.slider
		local editbox = widget.editbox
		if not slider or not IsModernClient() then return end

		-- Hide classic backdrop
		if slider.SetBackdrop then
			slider:SetBackdrop(nil)
		end

		-- Modern track
		if not slider.modernLeft then
			slider.modernLeft = slider:CreateTexture(nil, "BACKGROUND")
			slider.modernLeft:SetAtlas("Minimal_SliderBar_Left", true)
			slider.modernLeft:SetPoint("LEFT")

			slider.modernRight = slider:CreateTexture(nil, "BACKGROUND")
			slider.modernRight:SetAtlas("Minimal_SliderBar_Right", true)
			slider.modernRight:SetPoint("RIGHT")

			slider.modernMiddle = slider:CreateTexture(nil, "BACKGROUND")
			slider.modernMiddle:SetAtlas("_Minimal_SliderBar_Middle", true)
			slider.modernMiddle:SetPoint("LEFT", slider.modernLeft, "RIGHT")
			slider.modernMiddle:SetPoint("RIGHT", slider.modernRight, "LEFT")
			slider.modernMiddle:SetHeight(slider.modernLeft:GetHeight())
		end

		-- Diamond thumb
		slider:SetThumbTexture("Minimal_SliderBar_Button")
		local thumb = slider:GetThumbTexture()
		if thumb then
			thumb:SetAtlas("Minimal_SliderBar_Button", true)
		end

		-- Push the editbox down a bit for visual separation
		if editbox and not editbox.modernPadded then
			editbox:ClearAllPoints()
			editbox:SetPoint("TOP", slider, "BOTTOM", 0, -4)
			editbox.modernPadded = true
		end

		-- Tell AceGUI the widget is taller so the next element is pushed down
		if not widget.modernHeightApplied then
			local current = widget.frame:GetHeight()
			if current and current > 0 then
				widget:SetHeight(current + EXTRA_BOTTOM_PADDING)
			end
			widget.modernHeightApplied = true
		end
	end

	local function Constructor()
		local widget = AceGUI:Create("Slider")
		widget.type = Type

		ApplyModernSlider(widget)

		local originalOnAcquire = widget.OnAcquire
		widget.OnAcquire = function(self)
			if originalOnAcquire then originalOnAcquire(self) end
			-- Reset the flag so height can be reapplied cleanly
			self.modernHeightApplied = nil
			ApplyModernSlider(self)
		end

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

do 

	local Type = "ModernDropdown"
	local Version = 15

	local BUTTON_HEIGHT = 32
	local BUTTON_WIDTH  = 220
	local WIDGET_HEIGHT = 48
	local LABEL_WIDTH   = 160

	local function ForcePulloutPosition(widget)
		local pullout = widget.pullout
		local btn = widget.modernButton
		if not pullout or not pullout.frame or not btn then return end
		pullout:SetWidth(BUTTON_WIDTH)
		pullout.frame:ClearAllPoints()
		pullout.frame:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
	end

	local function ForceTooltipPosition(btn)
		if not GameTooltip:IsShown() then return end
		GameTooltip:ClearAllPoints()
		GameTooltip:SetPoint("BOTTOMRIGHT", btn, "TOPRIGHT", 0, 4)
	end

	-- Hook GameTooltip:SetOwner so we can re-anchor after AceConfigDialog
	if not GameTooltip.modernDropdownHooked then
		hooksecurefunc(GameTooltip, "SetOwner", function(self, owner, anchor)
			-- Delay one frame so AceConfig finishes, then fix if owner is one of our buttons
			C_Timer.After(0, function()
				if self:IsShown() and owner and owner.modernDropdownBtn then
					ForceTooltipPosition(owner.modernDropdownBtn)
				end
			end)
		end)
		GameTooltip.modernDropdownHooked = true
	end

	local function ApplyModernDropdown(widget)
		if not IsModernClient() then return end

		local dropdown = widget.dropdown
		local frame    = widget.frame
		local text     = widget.text
		local label    = widget.label
		if not dropdown or not frame then return end

		-- Hide classic pieces
		local name = dropdown:GetName()
		if name then
			for _, suffix in ipairs({ "Left", "Middle", "Right", "Button", "Text", "Icon" }) do
				local obj = _G[name .. suffix]
				if obj then
					obj:Hide()
					obj:SetAlpha(0)
				end
			end
		end
		if widget.button then
			widget.button:Hide()
			widget.button:SetAlpha(0)
		end
		if text then
			text:Hide()
			text:SetAlpha(0)
		end

		if not widget.modernHeightApplied then
			widget:SetHeight(WIDGET_HEIGHT)
			widget.modernHeightApplied = true
		end

		if label then
			label:ClearAllPoints()
			label:SetPoint("LEFT", frame, "LEFT", 0, 0)
			label:SetWidth(LABEL_WIDTH)
			label:SetJustifyH("LEFT")
			label:SetJustifyV("MIDDLE")
			label:SetFontObject("GameFontNormal")
			label:Show()
			label:SetAlpha(1)
			label:EnableMouse(false)
		end

		if not widget.modernButton then
			local btn = CreateFrame("Button", nil, frame)
			btn:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
			btn:SetPoint("LEFT", frame, "LEFT", LABEL_WIDTH + 8, 0)
			btn.modernDropdownBtn = btn -- marker for the tooltip hook

			local bg = btn:CreateTexture(nil, "BACKGROUND")
			bg:SetAllPoints()
			bg:SetAtlas("common-dropdown-b-button", false)
			bg:SetTexCoord(0.05, 0.95, 0.1, 0.9)
			btn.bg = bg

			local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			fs:SetPoint("LEFT", btn, "LEFT", 12, 0)
			fs:SetPoint("RIGHT", btn, "RIGHT", -12, 0)
			fs:SetJustifyH("LEFT")
			fs:SetJustifyV("MIDDLE")
			btn.text = fs

			btn:SetScript("OnClick", function()
				if widget.Open then
					widget:Open()
				elseif widget.button then
					widget.button:Click()
				end
			end)

			btn:SetScript("OnEnter", function()
				-- Make AceConfigDialog think the frame is our button so it owns the tooltip to us
				local realFrame = widget.frame
				widget.frame = btn
				widget:Fire("OnEnter")
				widget.frame = realFrame
			end)
			btn:SetScript("OnLeave", function()
				widget:Fire("OnLeave")
			end)

			widget.modernButton = btn
		end

		-- Inside ApplyModernDropdown, after creating widget.modernButton:

		-- Make the label also route tooltip to the button
		if label and not label.modernTooltipHooked then
			label:EnableMouse(true)
			label:SetScript("OnEnter", function()
				if widget.modernButton then
					local realFrame = widget.frame
					widget.frame = widget.modernButton
					widget:Fire("OnEnter")
					widget.frame = realFrame
				end
			end)
			label:SetScript("OnLeave", function()
				widget:Fire("OnLeave")
			end)
			label.modernTooltipHooked = true
		end

		-- Also catch hover on the parent frame itself
		if not frame.modernTooltipHooked then
			frame:HookScript("OnEnter", function()
				if widget.modernButton then
					local realFrame = widget.frame
					widget.frame = widget.modernButton
					widget:Fire("OnEnter")
					widget.frame = realFrame
				end
			end)
			frame.modernTooltipHooked = true
		end

		if widget.button_cover then
			widget.button_cover:EnableMouse(false)
		end
		
		if widget.modernButton and text then
			widget.modernButton.text:SetText(text:GetText() or "")
		end

		-- Hook the pullout as soon as it exists
		local pullout = widget.pullout
		if pullout and not pullout.modernHooked then
			-- Override its Open so the first call is already correct
			local originalPulloutOpen = pullout.Open
			pullout.Open = function(self, point, rel, relPoint, x, y)
				if widget.modernButton then
					originalPulloutOpen(self, "TOPLEFT", widget.modernButton, "BOTTOMLEFT", 0, -2)
				else
					originalPulloutOpen(self, point, rel, relPoint, x, y)
				end
				ForcePulloutPosition(widget)
			end
			pullout.modernHooked = true

			if pullout.frame and not pullout.modernStyled then
				local pf = pullout.frame
				if pf.SetBackdrop then
					pf:SetBackdrop({
						bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
						edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
						edgeSize = 12,
						insets = { left = 3, right = 3, top = 3, bottom = 3 },
					})
					pf:SetBackdropColor(0, 0, 0, 0.9)
					pf:SetBackdropBorderColor(0.4, 0.35, 0.2, 1)
				end
				pullout.modernStyled = true
			end
		end
	end

	local function Constructor()
		local widget = AceGUI:Create("Dropdown")
		widget.type = Type

		ApplyModernDropdown(widget)

		local originalOnAcquire = widget.OnAcquire
		widget.OnAcquire = function(self)
			if originalOnAcquire then originalOnAcquire(self) end
			self.modernHeightApplied = nil
			ApplyModernDropdown(self)
		end

		local originalSetText = widget.SetText
		widget.SetText = function(self, text)
			if originalSetText then originalSetText(self, text) end
			if self.modernButton then
				self.modernButton.text:SetText(text or "")
			end
			if self.text then
				self.text:Hide()
				self.text:SetAlpha(0)
			end
		end

		local originalOpen = widget.Open
		if originalOpen then
			widget.Open = function(self, ...)
				-- Make sure the pullout exists and is hooked before AceGUI opens it
				if not self.pullout then
					-- Force creation by calling original once, then re-hook
					originalOpen(self, ...)
					ApplyModernDropdown(self)
					if self.pullout then
						self.pullout:Close()
					end
				end
				ApplyModernDropdown(self)
				originalOpen(self, ...)
				ForcePulloutPosition(self)
			end
		end

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)

end
