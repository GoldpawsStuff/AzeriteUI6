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

local PetBar = ns:NewModule("PetBar", nil, "LibMoreEvents-1.0", "LibFadingFrames-1.0", "LibMovableFrames-1.0")
local KeyBound = LibStub("LibKeyBound-1.0")

-- Declare module defaults
local defaults = { 
	profile = {
		enabled = false, -- true,

		layout = "grid", -- <grid, zigzag>
		layoutGridSize = NUM_PET_ACTION_SLOTS, -- when to start a new grid row
		layoutGrowth = "horizontal", -- which direction the bar initially grows in
		layoutGrowthHorizontal = "RIGHT", -- which direction the bar grows in horizontally
		layoutGrowthVertical = "UP", -- which direction the bar grows in vertically
		layoutPaddingX = 8, -- horizontal padding between the buttons
		layoutPaddingY = 8, -- vertical padding between the buttons
	
		enableBarFading = true, -- whether to enable non-combat/hover button fading
		fadeInCombat = false, -- whether to keep fading out even in combat
		fadeFrom = 1, -- which button to start the button fading from

		numbuttons = NUM_PET_ACTION_SLOTS, -- 10
		visibility = {
			dragon = true,
			possess = true,
			overridebar = true,
			vehicleui = true
		}
	}
}

local PetActionBar = CreateFrame("Frame")
local PetActionBar_MT = { __index = PetActionBar }

PetActionBar.CreateButton = function(self, id)
	local name = "AZUI6_PetActionBarButton" .. id
	local button = ns.PetActionButton:Create(id, name, self)



	return button
end

PetActionBar.OnEvent = function(self, event, arg1)
	if (event == "PET_BAR_UPDATE" or (event == "UNIT_PET" and arg1 == "player") or event == "PET_UI_UPDATE" or event == "UPDATE_VEHICLE_ACTIONBAR") then
		self:ForAll("Update")
	elseif (event == "PLAYER_CONTROL_LOST" or event == "PLAYER_CONTROL_GAINED" or event == "PLAYER_FARSIGHT_FOCUS_CHANGED" or event == "PET_BAR_UPDATE_USABLE" or event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_MOUNT_DISPLAY_CHANGED" ) then
		self:ForAll("Update")
	elseif ((event == "UNIT_FLAGS") or (event == "UNIT_AURA") ) then
		if arg1 == "pet" then
			self:ForAll("Update")
		end
	elseif (event =="PET_BAR_UPDATE_COOLDOWN" ) then
		self:ForAll("UpdateCooldown")
	elseif (event == "PET_BAR_SHOWGRID") then
		self:ForAll("ShowGrid")
	elseif (event == "PET_BAR_HIDEGRID") then
		self:ForAll("HideGrid")
	end
end

PetActionBar.Enable = function(self)
	if (InCombatLockdown()) then return end
	self.enabled = true
	self:RegisterEvent("PLAYER_CONTROL_LOST")
	self:RegisterEvent("PLAYER_CONTROL_GAINED")
	self:RegisterEvent("PLAYER_FARSIGHT_FOCUS_CHANGED")
	self:RegisterEvent("UNIT_PET")
	self:RegisterEvent("UNIT_FLAGS")
	self:RegisterEvent("PET_BAR_UPDATE")
	self:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
	self:RegisterEvent("PET_BAR_UPDATE_USABLE")
	self:RegisterEvent("PET_UI_UPDATE")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
	self:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
	self:RegisterUnitEvent("UNIT_AURA", "pet")
	self:RegisterEvent("PET_BAR_SHOWGRID")
	self:RegisterEvent("PET_BAR_HIDEGRID")
end

PetActionBar.Disable = function(self)
	if (InCombatLockdown()) then return end
	self.enabled = false
	self:UnregisterAllEvents()
end

PetActionBar.SetEnabled = function(self, enable)
	if (InCombatLockdown()) then return end

	if (enable) then
		self:Enable()
	else
		self:Disable()
	end
end

PetActionBar.IsEnabled = function(self)
	return self.enabled
end

PetActionBar.GetAll = function(self)
	return pairs(self.buttons)
end

PetActionBar.ForAll = function(self, method, ...)
	for id,button in next,self.buttons do
		if (type(method) == "string") then
			local func = button[method]
			if (func) then
				func(button, ...)
			end
		elseif (type(method) == "function") then
			method(button, ...)
		end
	end
end

PetActionBar.Update = function(self)
	if (InCombatLockdown()) then return end

	self:UpdateButtonCount()
	self:UpdateButtonLayout()
	self:UpdateStateDriver()
	self:UpdateVisibilityDriver()
	self:UpdateBindings()
	self:UpdateFading()
end

PetActionBar.UpdateFading = function(self)
	if (self.config.enabled and self.config.enableBarFading) then
		for id,button in next,self.buttons do

			-- remove any previous fade registrations
			PetBar:UnregisterFrameForFading(button)

			-- register current fade for selected buttons
			if (id >= self.config.fadeFrom) then
				local button = self.buttons[id]
				if (button:GetTexture()) then
					PetBar:RegisterFrameForFading(button, self.config.fadeAlone and self:GetName() or "petactionbuttons", unpack(self.config.fadeButtonHitRects))
				else
					-- update button?
				end
			end
		end
	else
		-- unregister all fading
		for id,button in next,self.buttons do
			PetBar:UnregisterFrameForFading(button)

			-- whyever did I add this?
			if (not button:GetTexture()) then
				-- update button?
			end
		end
	end
end

PetActionBar.UpdateButtonCount = function(self)
	if (InCombatLockdown()) then return end

	for id,button in next,self.buttons do
		if (id <= self.config.numbuttons) then
			button:Show()
			button:SetAttribute("statehidden", nil)
		else
			button:Hide()
			button:SetAttribute("statehidden", true)
		end
	end
end

PetActionBar.UpdateButtonConfig = function(self)
	for id,button in next,self.buttons do
		button.config.clickOnDown = self.config.clickOnDown
	end
end

PetActionBar.UpdateButtonLayout = function(self)
	if (InCombatLockdown()) then return end

	local buttons = self.buttons
	local numbuttons = self.numButtons or self.config.numbuttons or #buttons

	if (numbuttons == 0) then
		self:SetSize(self.buttonWidth, self.buttonHeight)
		return
	end

	local layout = self.config.layout

	if (layout == "zigzag") then

		self:SetSize(2,2) -- Just set a temporary size to avoid positioning bugs

		local config = self.config
		local buttonWidth = self.buttonWidth
		local buttonHeight = self.buttonHeight

		local counter = 0
		local left, right, top, bottom = 0, 0, 0, 0
		local point = (config.layoutGrowthVertical == "UP" and "BOTTOM" or "TOP")..(config.layoutGrowthHorizontal == "RIGHT" and "LEFT" or "RIGHT")
		local offsetX, offsetY

		for id,button in next,buttons do

			local isZigZag = (id >= config.layoutZigZagStart) and ((config.layoutZigZagStart - id)%2 == 0)

			if (config.layoutGrowth == "horizontal") then

				if (config.layoutGrowthHorizontal == "RIGHT") then
					offsetX = (buttonWidth + config.layoutPaddingX) * (counter - (isZigZag and 1 or 0)) + (isZigZag and (config.layoutZigZagOffset * buttonWidth) or 0)
					if (id <= numbuttons) then
						left = 0
						right = math.max(right, offsetX + buttonWidth)
					end

				elseif (config.layoutGrowthHorizontal == "LEFT") then
					offsetX = -((buttonWidth + config.layoutPaddingX) * (counter - (isZigZag and 1 or 0)) + (isZigZag and (config.layoutZigZagOffset * buttonWidth) or 0))
					if (id <= numbuttons) then
						left = math.min(left, offsetX - buttonWidth)
						right = 0
					end
				end

				if (config.layoutGrowthVertical == "UP") then
					offsetY = isZigZag and (buttonHeight + config.layoutPaddingY) or 0
					if (id <= numbuttons) then
						top = math.max(top, offsetY + buttonHeight)
						bottom = 0
					end

				elseif (config.layoutGrowthVertical == "DOWN") then
					offsetY = isZigZag and -(buttonHeight + config.layoutPaddingY) or 0
					if (id <= numbuttons) then
						top = 0
						bottom = math.min(bottom, offsetY - buttonHeight)
					end
				end


			elseif (config.layoutGrowth == "vertical") then

				if (config.layoutGrowthVertical == "DOWN") then
					offsetY = -((buttonHeight + config.layoutPaddingX) * counter + (isZigZag and (config.layoutZigZagOffset * buttonWidth) or 0))
					if (id <= numbuttons) then
						top = 0
						bottom = math.min(bottom, offsetY - buttonHeight)
					end

				elseif (config.layoutGrowthVertical == "UP") then
					offsetY = (buttonHeight + config.layoutPaddingX) * counter + (isZigZag and (config.layoutZigZagOffset * buttonWidth) or 0)
					if (id <= numbuttons) then
						top = math.max(top, offsetY + buttonHeight)
						bottom = 0
					end
				end

				if (config.layoutGrowthHorizontal == "RIGHT") then
					offsetX = isZigZag and (buttonWidth + config.layoutPaddingX) or 0
					if (id <= numbuttons) then
						left = 0
						right = math.max(right, offsetX + buttonWidth)
					end

				elseif (config.layoutGrowthHorizontal == "LEFT") then
					offsetX = isZigZag and -(buttonWidth + config.layoutPaddingX) or 0
					if (id <= numbuttons) then
						left = math.min(left, offsetX - buttonWidth)
						right = 0
					end
				end

			end

			if (not isZigZag) then
				counter = counter + 1
			end

			button:ClearAllPoints()
			button:SetPoint(point, offsetX, offsetY)
		end

		self:SetSize(math.abs(left - right), math.abs(top - bottom))

	elseif (layout == "grid") then

		local config = self.config

		local buttonWidth = self.buttonWidth
		local buttonHeight = self.buttonHeight

		local totalbreaks = math.ceil(config.numbuttons/config.layoutGridSize)
		local width, height

		if (config.layoutGrowth == "horizontal") then
			if (numbuttons < config.layoutGridSize) then
				width = buttonWidth*numbuttons + config.layoutPaddingX*(numbuttons - 1)
				height = buttonHeight
			else
				width = buttonWidth*config.layoutGridSize + config.layoutPaddingX*(config.layoutGridSize - 1)
				height = buttonHeight*totalbreaks + (config.layoutPaddingY or config.layoutPaddingX)*(totalbreaks-1)
			end

		elseif (config.layoutGrowth == "vertical") then
			if (numbuttons < config.layoutGridSize) then
				width = buttonWidth
				height = buttonHeight*numbuttons + config.layoutPaddingX*(numbuttons - 1)
			else
				width = buttonWidth*totalbreaks + (config.layoutPaddingY or config.layoutPaddingX)*(totalbreaks-1)
				height = buttonHeight*config.layoutGridSize + config.layoutPaddingX*(config.layoutGridSize - 1)
			end
		end

		self:SetSize(width, height)

		local point = (config.layoutGrowthVertical == "UP" and "BOTTOM" or "TOP")..(config.layoutGrowthHorizontal == "RIGHT" and "LEFT" or "RIGHT")
		local offsetX, offsetY = 0,0

		for id,button in next,buttons do

			local breakpoint = (id - 1)%config.layoutGridSize == 0
			local numbreaks = breakpoint and math.floor((id - 1)/config.layoutGridSize)

			if (config.layoutGrowth == "horizontal") then
				if (breakpoint) then
					offsetX = 0
					if (config.layoutGrowthVertical == "UP") then
						offsetY = (buttonHeight + (config.layoutPaddingY or config.layoutPaddingX)) * numbreaks
					elseif (config.layoutGrowthVertical == "DOWN") then
						offsetY = -(buttonHeight + (config.layoutPaddingY or config.layoutPaddingX)) * numbreaks
					end
				else
					if (config.layoutGrowthHorizontal == "RIGHT") then
						offsetX = offsetX + (buttonWidth + config.layoutPaddingX)
					elseif (config.layoutGrowthHorizontal == "LEFT") then
						offsetX = offsetX - (buttonWidth + config.layoutPaddingX)
					end
				end

			elseif (config.layoutGrowth == "vertical") then
				if (breakpoint) then
					if (config.layoutGrowthHorizontal == "RIGHT") then
						offsetX = (buttonWidth + (config.layoutPaddingY or config.layoutPaddingX)) * numbreaks
					elseif (config.layoutGrowthHorizontal == "LEFT") then
						offsetX = -(buttonWidth + (config.layoutPaddingY or config.layoutPaddingX)) * numbreaks
					end
					offsetY = 0
				else
					if (config.layoutGrowthVertical == "DOWN") then
						offsetY = offsetY - (buttonWidth + config.layoutPaddingX)
					elseif (config.layoutGrowthVertical == "UP") then
						offsetY = offsetY + (buttonWidth + config.layoutPaddingX)
					end
				end
			end

			button:ClearAllPoints()
			button:SetPoint(point, offsetX, offsetY)
		end
	end
end

PetActionBar.UpdateBindings = function(self)
	if (InCombatLockdown()) then return end
	if (not next(self.buttons)) then return end

	ClearOverrideBindings(self)

	for i = 1,NUM_PET_ACTION_SLOTS do
		local button, real_button = ("BONUSACTIONBUTTON%d"):format(i), "AZUI6_PetActionBarButton"..i
		for k = 1, select("#", GetBindingKey(button)) do
			local key = select(k, GetBindingKey(button))
			SetOverrideBindingClick(self, false, key, real_button)
		end
	end
end

PetActionBar.UpdateStateDriver = function(self)
	if (InCombatLockdown()) then return end
end

PetActionBar.UpdateVisibilityDriver = function(self)
	if (InCombatLockdown()) then return end

	local visdriver

	local config = self.config
	if (config.enabled) then

		visdriver = "[petbattle]hide;"

		if (config.visibility.possess) then
			visdriver = visdriver.."[possessbar]show;"
		else
			visdriver = visdriver.."[possessbar]hide;"
		end

		if (config.visibility.overridebar) then
			visdriver = visdriver.."[overridebar]show;"
		else
			visdriver = visdriver.."[overridebar]hide;"
		end

		if (config.visibility.vehicleui) then
			visdriver = visdriver.."[vehicleui]show;"
		else
			visdriver = visdriver.."[vehicleui]hide;"
		end

		if (config.visibility.dragon) then
			visdriver = visdriver.."[bonusbar:5]show;"
		else
			visdriver = visdriver.."[bonusbar:5]hide;"
		end

		visdriver = visdriver.."show"
	end

	UnregisterStateDriver(self, "vis")
	self:SetAttribute("state-vis", "0")
	RegisterStateDriver(self, "vis", visdriver or "hide")
end



PetBar.GetBar = function(self)
	if (not self.Bar) then 
		local bar -- = ns.ActionBar:Create(1, self.db.profile, "AZUI6_PetActionBar")
		local bar = setmetatable(CreateFrame("Frame", "AZUI6_PetActionBar", UIParent, "SecureHandlerStateTemplate"), PetActionBar_MT)

		bar.config = self.db.profile

		bar.buttons = {}
		bar.buttonWidth = 48 -- why exactly are we storing it directly on the bar object?
		bar.buttonHeight = 48

		for i = 1,NUM_PET_ACTION_SLOTS do
			local button = bar:CreateButton(i)

			bar.buttons[i] = button -- lua reference
			bar:SetFrameRef("Button"..i, button) -- secure environment reference

			local keyBoundTarget = "BONUSACTIONBUTTON"..i
			button.config.keyBoundTarget = keyBoundTarget
		end

		bar:SetScript("OnEvent", PetActionBar.OnEvent)

		bar:SetScale(.9) -- default scale
		bar:SetPoint("BOTTOM", 0, 220/.9) -- default position

		bar:Update() -- update size and layout

		self.Bar = bar
	end

	return self.Bar
end

PetBar.ReassignBindings = function(self)
	if (self.Bar) then
		self.Bar:UpdateBindings()
	end
end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling and combat end.
PetBar.UpdateSettings = function(self)
	if (self.Bar) then
		self.Bar:UpdateBindings()
	end
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
PetBar.RefreshConfig = function(self)
	self:UpdateSettings()
end

PetBar.OnInitialize = function(self)
	if (ns.IsAddOnEnabled("ConsolePort_Bar")) then return self:Disable() end

	self.db = ns.db:RegisterNamespace("PetBar", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

end

PetBar.OnEnable = function(self)
	self:GetBar():Enable()
	self:RegisterMovableFrameAnchor(self:GetBar(), string.lower(HUD_EDIT_MODE_PET_ACTION_BAR_LABEL), "actionbars", AzeriteUI6_Positions_DB)
	self:RegisterEvent("UPDATE_BINDINGS", "ReassignBindings")
	self:ReassignBindings()
end
