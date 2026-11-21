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

-- ModernButton
-- Version: 2
do
	local Type, Version = "ModernButton", 2

	if (AceGUI:GetWidgetVersion(Type) or 0) < Version then
		local function OnClick(frame, mouseButton)
			AceGUI:ClearFocus()
			PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION or 852)
			frame.obj:Fire("OnClick", mouseButton)
		end

		local function OnEnter(frame)
			frame.obj:Fire("OnEnter")
		end

		local function OnLeave(frame)
			frame.obj:Fire("OnLeave")
		end

		local methods = {
			OnAcquire = function(self)
				self:SetHeight(30)
				self:SetWidth(200)
				self:SetDisabled(false)
				self:SetAutoWidth(false)
				self:SetText()
			end,

			SetText = function(self, text)
				self.text:SetText(text or "")
				if self.autoWidth then
					self:SetWidth(self.text:GetStringWidth() + 40)
				end
			end,

			SetAutoWidth = function(self, autoWidth)
				self.autoWidth = autoWidth
				if autoWidth then
					self:SetWidth(self.text:GetStringWidth() + 40)
				end
			end,

			SetDisabled = function(self, disabled)
				self.disabled = disabled
				if disabled then
					self.frame:Disable()
				else
					self.frame:Enable()
				end
			end,
		}

		local function Constructor()
			local name = "AzeriteUIModernButton" .. AceGUI:GetNextWidgetNum(Type)
			local template = IsModernClient() and "SharedButtonTemplate" or "UIPanelButtonTemplate"
			local frame = CreateFrame("Button", name, UIParent, template)
			frame:Hide()
			frame:EnableMouse(true)
			frame:SetScript("OnClick", OnClick)
			frame:SetScript("OnEnter", OnEnter)
			frame:SetScript("OnLeave", OnLeave)

			if IsModernClient() then
				frame:SetNormalFontObject("GameFontHighlightMedium")
				frame:SetHighlightFontObject("GameFontHighlightMedium")
				frame:SetDisabledFontObject("GameFontDisable")
			end

			local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
			text:SetPoint("CENTER")
			frame:SetFontString(text)
			frame:SetNormalFontObject(IsModernClient() and "GameFontHighlightMedium" or "GameFontNormal")
			frame:SetHighlightFontObject(IsModernClient() and "GameFontHighlightMedium" or "GameFontHighlight")
			frame:SetDisabledFontObject("GameFontDisable")

			local widget = { frame = frame, type = Type }
			for method, func in pairs(methods) do
				widget[method] = func
			end
			widget.text = text

			return AceGUI:RegisterAsWidget(widget)
		end

		AceGUI:RegisterWidgetType(Type, Constructor, Version)
	end
end

-- ModernCheckBox
-- Version: 3
do 
	local Type, Version = "ModernCheckBox", 3

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

		local PAD = 4
		local originalOnAcquire = widget.OnAcquire
		widget.OnAcquire = function(self)
			originalOnAcquire(self)
			self:SetHeight(29 + PAD * 2)
			self:SetIndent(0) -- 32 in ModernCheckBoxIndented
		end

		-- Apply immediately
		ApplyModernTextures(widget)

		local TEXT_GAP = IsModernClient() and 4 or 2

		-- Optional indent support
		function widget:SetIndent(pixels)
			pixels = pixels or 0
			local frame = widget.frame
			local checkbg = widget.checkbg
			local text = widget.text

			checkbg:ClearAllPoints()
			checkbg:SetPoint("LEFT", frame, "LEFT", pixels, 0)
			text:ClearAllPoints()
			text:SetPoint("LEFT", checkbg, "RIGHT", TEXT_GAP, 0)
			text:SetPoint("RIGHT", frame, "RIGHT")
		end

		widget:SetIndent(0)

		local function PlaceText(self)
			self.text:ClearAllPoints()
			self.text:SetPoint("LEFT", self.checkbg, "RIGHT", TEXT_GAP, 0)
			self.text:SetPoint("RIGHT", self.frame, "RIGHT")
		end

		local originalSetImage = widget.SetImage
		widget.SetImage = function(self, ...)
			if originalSetImage then
				originalSetImage(self, ...)
			end
			PlaceText(self)
		end

		widget.frame:HookScript("OnMouseDown", function()
			PlaceText(widget)
		end)
		widget.frame:HookScript("OnMouseUp", function()
			PlaceText(widget)
		end)

		PlaceText(widget)

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)

end

-- ModernCheckBoxIndented
-- Version: 2
do 
	local Type, Version = "ModernCheckBoxIndented", 2

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

		local TEXT_GAP = IsModernClient() and 4 or 2

		-- Optional indent support
		function widget:SetIndent(pixels)
			pixels = pixels or 0
			local frame = widget.frame
			local checkbg = widget.checkbg
			local text = widget.text

			checkbg:ClearAllPoints()
			checkbg:SetPoint("LEFT", frame, "LEFT", pixels, 0)
			text:ClearAllPoints()
			text:SetPoint("LEFT", checkbg, "RIGHT", TEXT_GAP, 0)
			text:SetPoint("RIGHT", frame, "RIGHT")
		end

		widget:SetIndent(32)

		local function PlaceText(self)
			self.text:ClearAllPoints()
			self.text:SetPoint("LEFT", self.checkbg, "RIGHT", TEXT_GAP, 0)
			self.text:SetPoint("RIGHT", self.frame, "RIGHT")
		end

		local originalSetImage = widget.SetImage
		widget.SetImage = function(self, ...)
			if originalSetImage then
				originalSetImage(self, ...)
			end
			PlaceText(self)
		end

		widget.frame:HookScript("OnMouseDown", function()
			PlaceText(widget)
		end)
		widget.frame:HookScript("OnMouseUp", function()
			PlaceText(widget)
		end)

		PlaceText(widget)

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)

end

-- ModernDropdown
-- Version: 19
do 
	local Type, Version = "ModernDropdown", 19

	local BUTTON_HEIGHT = 32
	local BUTTON_WIDTH  = 220
	local WIDGET_HEIGHT = 48
	local LABEL_WIDTH   = 260 

	local function FitPullout(pullout)
		if not pullout or not pullout.frame then return end
		local count = pullout.items and #pullout.items or 0
		local content = 8 + count * 16
		local maxHeight = pullout.maxHeight or 600
		if pullout.itemFrame then
			pullout.itemFrame:SetHeight(content)
		end
		local frameHeight = math.max(math.min(content + 28, maxHeight), 32)
		pullout.frame:SetHeight(frameHeight)
		if pullout.slider and content + 24 < frameHeight then
			pullout.slider:Hide()
		end
	end

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
		if pullout then
			pullout.modernOwner = widget
			if not pullout.modernHooked then
				local originalPulloutOpen = pullout.Open
				pullout.Open = function(self, point, rel, relPoint, x, y)
					local owner = self.modernOwner
					if owner and owner.modernButton then
						originalPulloutOpen(self, "TOPLEFT", owner.modernButton, "BOTTOMLEFT", 0, -2)
						ForcePulloutPosition(owner)
					else
						originalPulloutOpen(self, point, rel, relPoint, x, y)
					end
					FitPullout(self)
				end
				pullout.modernHooked = true
			end

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

	local function UpdateDisabledState(widget)
		local btn = widget.modernButton
		if not btn then return end
		local disabled = widget.disabled
		if btn.bg then
			btn.bg:SetDesaturated(disabled)
			btn.bg:SetAlpha(disabled and 0.5 or 1)
		end
		if btn.text then
			btn.text:SetTextColor(disabled and 0.5 or 1, disabled and 0.5 or 1, disabled and 0.5 or 1)
		end
	end

	local function MultiButtonText(count)
		if count == 0 then
			return NONE
		end
		return count == 1 and "1 selected" or (count .. " selected")
	end

	local function StripClose(self)
		local pullout = self.pullout
		if not pullout or not pullout.items then return end
		local items = pullout.items
		for i = #items, 1, -1 do
			local item = items[i]
			if item and item.type == "Dropdown-Item-Execute" then
				table.remove(items, i)
				AceGUI:Release(item)
			end
		end
		self.hasClose = true
	end

	local function SelectedCount(self)
		local count = 0
		if not self.pullout or not self.pullout.IterateItems then
			return 0
		end
		for _, item in self.pullout:IterateItems() do
			if item.type == "Dropdown-Item-Toggle" and item.GetValue and item:GetValue() then
				count = count + 1
			end
		end
		return count
	end

	local function Constructor()
		local widget = AceGUI:Create("Dropdown")
		widget.type = Type

		ApplyModernDropdown(widget)

		local originalSetList = widget.SetList
		widget.SetList = function(self, ...)
			originalSetList(self, ...)
			if self.multiselect then
				StripClose(self)
			end
		end

		local originalSetMultiselect = widget.SetMultiselect
		widget.SetMultiselect = function(self, multi)
			originalSetMultiselect(self, multi)
			if multi then
				StripClose(self)
			end
		end

		local originalOnAcquire = widget.OnAcquire
		widget.OnAcquire = function(self)
			if originalOnAcquire then originalOnAcquire(self) end
			self.modernHeightApplied = nil
			ApplyModernDropdown(self)
		end

		local originalOnRelease = widget.OnRelease
		widget.OnRelease = function(self)
			if self.pullout then
				self.pullout.modernOwner = nil
			end
			self.modernHeightApplied = nil
			if originalOnRelease then
				originalOnRelease(self)
			end
		end

		widget.SetText = function(self, text)
			if self.multiselect then
				text = MultiButtonText(SelectedCount(self))
			end
			if originalSetText then originalSetText(self, text) end
			if self.modernButton then
				self.modernButton.text:SetWordWrap(false)
				self.modernButton.text:SetText(text or "")
			end
			if self.text then
				self.text:Hide()
				self.text:SetAlpha(0)
			end
		end

		local originalSetDisabled = widget.SetDisabled
		if originalSetDisabled then
			widget.SetDisabled = function(self, disabled)
				if originalSetDisabled then
					originalSetDisabled(self, disabled)
				end
				self.disabled = disabled
				UpdateDisabledState(self)
				if self.button_cover then
					self.button_cover:EnableMouse(false)
				end
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

-- ModernHeader
-- Version: 2
do
	if IsModernClient() then 

		local Version = 2

		local function ApplyHeader(group)
			local frame = group.frame
			local label = group.label
			local content = group.content
			if not (frame and label and content) then return end

			label:SetFontObject("GameFontHighlightHuge")
			label:SetTextColor(1, 1, 1)
			label:SetJustifyH("LEFT")
			label:SetJustifyV("TOP")
			label:ClearAllPoints()
			label:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -16)
			label:SetPoint("RIGHT", frame, "RIGHT", -16, 0)

			local line = frame.azeriteDivider
			if not line then
				line = frame:CreateTexture(nil, "ARTWORK")
				line:SetAtlas("Options_HorizontalDivider", true)
				frame.azeriteDivider = line
			end
			line:ClearAllPoints()
			line:SetPoint("TOP", frame, "TOP", 0, -46)

			content:ClearAllPoints()
			content:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -64)
			content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
		end

		local function StyleScrollBar(bar)
			if bar.azeriteStyled or not bar.GetThumbTexture then return end
			local name = bar.GetName and bar:GetName()
			local up = bar.ScrollUpButton or (name and _G[name .. "ScrollUpButton"])
			local down = bar.ScrollDownButton or (name and _G[name .. "ScrollDownButton"])
			if not (up and down) then return end
			bar.azeriteStyled = true

			local function HideButton(button)
				button:SetAlpha(0)
				button:Hide()
				hooksecurefunc(button, "Show", function(self) self:Hide() end)
			end
			HideButton(up)
			HideButton(down)

			local parent = bar:GetParent()
			bar:ClearAllPoints()
			bar:SetPoint("TOPLEFT", parent, "TOPRIGHT", 4, 0)
			bar:SetPoint("BOTTOMLEFT", parent, "BOTTOMRIGHT", 4, 0)
			bar:SetWidth(8)
			bar:SetHitRectInsets(-6, -6, 0, 0)

			local thumb = bar:GetThumbTexture()
			if thumb then
				thumb:SetAlpha(0)
				thumb:SetWidth(8)
			end
			for _, region in ipairs({ bar:GetRegions() }) do
				if region:IsObjectType("Texture") and region ~= thumb then
					region:SetAlpha(0)
				end
			end

			local function Slice(parentFrame, topAtlas, midAtlas, botAtlas, layer)
				local top = parentFrame:CreateTexture(nil, layer)
				top:SetAtlas(topAtlas, true)
				top:SetPoint("TOPLEFT")
				local bot = parentFrame:CreateTexture(nil, layer)
				bot:SetAtlas(botAtlas, true)
				bot:SetPoint("BOTTOMLEFT")
				local mid = parentFrame:CreateTexture(nil, layer)
				mid:SetAtlas(midAtlas, true)
				mid:SetPoint("TOPLEFT", top, "BOTTOMLEFT")
				mid:SetPoint("BOTTOMRIGHT", bot, "TOPRIGHT")
			end

			local track = CreateFrame("Frame", nil, bar)
			track:SetAllPoints()
			Slice(track, "minimal-scrollbar-track-top", "!minimal-scrollbar-track-middle", "minimal-scrollbar-track-bottom", "BACKGROUND")

			local grip = CreateFrame("Frame", nil, bar)
			grip:SetFrameLevel(bar:GetFrameLevel() + 2)
			if thumb then
				grip:SetPoint("TOPLEFT", thumb, "TOPLEFT")
				grip:SetPoint("BOTTOMRIGHT", thumb, "BOTTOMRIGHT")
			end
			Slice(grip, "minimal-scrollbar-small-thumb-top", "minimal-scrollbar-small-thumb-middle", "minimal-scrollbar-small-thumb-bottom", "ARTWORK")

			local function UpdateThumbSize(self)
				if self.azeriteSizing then return end
				local min, max = self:GetMinMaxValues()
				local range = max - min
				local track = self:GetHeight()
				local thumbTex = self:GetThumbTexture()
				if not thumbTex or track <= 0 then return end

				local height = track
				if range > 0 then
					height = math.max(24, (track * track) / (track + range))
					if height > track then
						height = track
					end
				end

				thumbTex:SetWidth(8)
				thumbTex:SetHeight(height)

				self.azeriteSizing = true
				self:SetValue(self:GetValue())
				self.azeriteSizing = false
			end

			bar:HookScript("OnMinMaxChanged", UpdateThumbSize)
			bar:HookScript("OnSizeChanged", UpdateThumbSize)
			UpdateThumbSize(bar)			
		end

		local function WalkScrollBars(frame)
			if not frame or not frame.GetChildren then return end
			for _, child in ipairs({ frame:GetChildren() }) do
				if child.GetObjectType and child:GetObjectType() == "Slider" then
					StyleScrollBar(child)
				end
				WalkScrollBars(child)
			end
		end

		local hooked = {}

		local function EnsureHook(group)
			if hooked[group] or type(group) ~= "table" or not group.SetTitle then return end
			hooked[group] = true
			hooksecurefunc(group, "SetTitle", ApplyHeader)
			ApplyHeader(group)
		end

		local function HookOurGroups()
			local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
			local bliz = AceConfigDialog and AceConfigDialog.BlizOptions
			if not bliz then return end

			for appName, groups in pairs(bliz) do
				if type(appName) == "string" and appName:find("AzeriteUI6", 1, true) then
					for _, group in pairs(groups) do
						EnsureHook(group)
						if group.frame then
							WalkScrollBars(group.frame)
						end
					end
				end
			end
		end

		local AceConfigDialog = LibStub("AceConfigDialog-3.0")
		if not AceConfigDialog.modernTitleStyled then
			-- SetTitle runs inside FeedGroup, still before the frame is painted
			hooksecurefunc(AceConfigDialog, "FeedGroup", HookOurGroups)
			hooksecurefunc(AceConfigDialog, "AddToBlizOptions", HookOurGroups)
			AceConfigDialog.modernTitleStyled = true
		end

		HookOurGroups()
	end
end

-- ModernPopup
-- Version: 4
do
	if IsModernClient() then

		local Version = 4

		local popup
		local function GetPopup()
			if popup then
				return popup
			end

			local frame = CreateFrame("Frame", nil, UIParent)
			frame:SetFrameStrata("DIALOG")
			frame:SetToplevel(true)
			frame:EnableMouse(true)
			frame:SetSize(460, 160)
			frame:SetPoint("CENTER")
			frame:Hide()

			local border = CreateFrame("Frame", nil, frame, "DialogBorderDarkTemplate")
			border:SetAllPoints()

			local header = CreateFrame("Frame", nil, frame, "DialogHeaderTemplate")
			header:SetFrameLevel(border:GetFrameLevel() + 2)
			frame.header = header

			local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			text:SetPoint("TOP", frame, "TOP", 0, -48)
			text:SetWidth(400)
			text:SetJustifyH("CENTER")
			text:SetJustifyV("TOP")
			frame.text = text

			frame.buttons = {}
			for i = 1, 3 do
				local button = CreateFrame("Button", nil, frame, "SharedButtonTemplate")
				button:SetHeight(36)
				button:SetNormalFontObject("GameFontHighlightMedium")
				button:SetHighlightFontObject("GameFontHighlightMedium")
				button:SetDisabledFontObject("GameFontDisable")
				button:SetFrameLevel(border:GetFrameLevel() + 3)
				button:SetScript("OnClick", function(self)
					local handler = self.handler
					if handler then
						handler()
					end
					frame:Hide()
				end)
				frame.buttons[i] = button
			end

			frame.SetTitleText = function(self, title)
				self.header:Setup(title or "")
			end

			frame:SetScript("OnKeyDown", function(self, key)
				if key ~= "ESCAPE" then
					self:SetPropagateKeyboardInput(true)
					return
				end
				self:SetPropagateKeyboardInput(false)
				local cancel = self.cancelButton
				if cancel and cancel.handler then
					cancel.handler()
				end
				self:Hide()
			end)

			frame:SetScript("OnShow", function(self)
				if self.SetPropagateKeyboardInput then
					self:SetPropagateKeyboardInput(false)
				end
			end)

			popup = frame
			return frame
		end

		function ns:ShowPrompt(title, text, buttons)
			local frame = GetPopup()
			frame:SetTitleText(title)
			frame.text:SetText(text or "")

			local count = math.min(#buttons, 3)
			local gap = 12
			local width = (frame:GetWidth() - 48 - gap * (count - 1)) / count
			local previous

			frame.cancelButton = nil
			for i = 1, 3 do
				local button = frame.buttons[i]
				local info = buttons[i]
				if i <= count and info then
					button.handler = info.onClick
					button:SetText(info.text or "")
					button:SetWidth(width)
					button:ClearAllPoints()
					if not previous then
						button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 24, 20)
					else
						button:SetPoint("LEFT", previous, "RIGHT", gap, 0)
					end
					button:Show()
					previous = button
					if info.cancel then
						frame.cancelButton = button
					end
				else
					button.handler = nil
					button:Hide()
				end
			end

			frame:SetHeight(math.max(150, 108 + frame.text:GetStringHeight()))
			frame:Show()
		end
	end
end

-- ModernSlider
-- Version: 7
do
	local Type, Version = "ModernSlider", 7

	local EXTRA_BOTTOM_PADDING = 12
	local EXTRA_TOP_PADDING = 10

	local function ApplyModernSlider(widget)
		local slider = widget.slider
		local editbox = widget.editbox
		if not slider or not IsModernClient() then return end

		-- Add some air above the label
		if widget.label then
			widget.label:SetPoint("TOPLEFT", widget.frame, "TOPLEFT", 0, -EXTRA_TOP_PADDING)
			widget.label:SetPoint("TOPRIGHT", widget.frame, "TOPRIGHT", 0, -EXTRA_TOP_PADDING)
		end

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
				widget:SetHeight(current + EXTRA_BOTTOM_PADDING + EXTRA_TOP_PADDING)
				widget.frame:SetHeight(current + EXTRA_BOTTOM_PADDING + EXTRA_TOP_PADDING)
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
