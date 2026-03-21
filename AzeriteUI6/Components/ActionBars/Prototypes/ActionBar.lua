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

local defaults = {
	enabled = true,
	layout = "grid", -- <grid, zigzag>
	layoutZigZagStart = 1, -- at which button the zigzag pattern should begin
	layoutZigZagOffset = 44/64, -- -- relative offset in the growth direction for the alternate zigzag row as a fraction of button size.
	layoutGridSize = NUM_ACTIONBAR_BUTTONS, -- when to start a new grid row
	layoutGrowth = "horizontal", -- which direction the bar initially grows in
	layoutGrowthHorizontal = "RIGHT", -- which direction the bar grows in horizontally
	layoutGrowthVertical = "DOWN", -- which direction the bar grows in vertically
	layoutPaddingX = 8, -- horizontal padding between the buttons
	layoutPaddingY = 8, -- vertical padding between the buttons

	enableBarFading = false, -- whether to enable non-combat/hover button fading
	fadeInCombat = false, -- whether to keep fading out even in combat
	fadeFrom = 1, -- which button to start the button fading from
	fadeButtonHitRects = { -10, -10, -10, -10 },

	numbuttons = NUM_ACTIONBAR_BUTTONS, -- 12
	visibility = {
		dragon = false,
		possess = false,
		overridebar = false,
		vehicleui = false
	}
}

-- Return bindaction by blizzard barID.
local BINDTEMPLATE_BY_ID = {
	[1] = "ACTIONBUTTON%d",
	[BOTTOMLEFT_ACTIONBAR_PAGE] = "MULTIACTIONBAR1BUTTON%d",
	[BOTTOMRIGHT_ACTIONBAR_PAGE] = "MULTIACTIONBAR2BUTTON%d",
	[RIGHT_ACTIONBAR_PAGE] = "MULTIACTIONBAR3BUTTON%d",
	[LEFT_ACTIONBAR_PAGE] = "MULTIACTIONBAR4BUTTON%d",
	[MULTIBAR_5_ACTIONBAR_PAGE] = "MULTIACTIONBAR5BUTTON%d",
	[MULTIBAR_6_ACTIONBAR_PAGE] = "MULTIACTIONBAR6BUTTON%d",
	[MULTIBAR_7_ACTIONBAR_PAGE] = "MULTIACTIONBAR7BUTTON%d"
}

local ActionBar = CreateFrame("Frame")
local ActionBar_MT = { __index = ActionBar }

ns.ActionBar = {}
ns.ActionBar.prototype = ActionBar
ns.ActionBar.defaults = defaults

ns.ActionBar.Create = function(self, id, config, name)
	local bar = setmetatable(CreateFrame("Frame", name, UIParent, "SecureHandlerStateTemplate"), ActionBar_MT)

	bar.id = id
	bar.name = name or id
	bar.config = config or ns:Copy(defaults)

	bar.buttons = {}
	bar.buttonConfig = ns:Merge(config or {}, ns.ActionBar.defaults)
	bar.buttonWidth = 64
	bar.buttonHeight = 64

	-- create buttons
	for i = 1,NUM_ACTIONBAR_BUTTONS do
		local button = ns.ActionButton:Create(i, name.."Button"..i, bar, bar.buttonConfig)
		bar:SetFrameRef("Button"..i, button)
		bar.buttons[i] = button

		local keyBoundTarget = string.format(BINDTEMPLATE_BY_ID[id], button.id)
		button.keyBoundTarget = keyBoundTarget
		bar.buttonConfig.keyBoundTarget = keyBoundTarget
	end

	bar:SetAttribute("UpdateVisibility", [[
		local visibility = self:GetAttribute("visibility");
		local userhidden = self:GetAttribute("userhidden");
		if (visibility == "show") then
			if (userhidden) then
				self:Hide();
			else
				self:Show();
			end
		elseif (visibility == "hide") then
			self:Hide();
		end
	]])

	bar:SetAttribute("_onstate-vis", [[
		if (not newstate) then
			return
		end
		self:SetAttribute("visibility", newstate);
		self:RunAttribute("UpdateVisibility");
	]])

	bar:SetAttribute("_onstate-page", [[
		local hasVehicleBar, hasOverrideBar, hasTempShapeshiftBar, hasPossessBar, isDragonRiding;

		if (newstate == "possess" or newstate == "dragon" or newstate == "11") then
			if HasVehicleActionBar() then
				newstate = GetVehicleBarIndex();
				hasVehicleBar = true;

			elseif HasOverrideActionBar() then
				newstate = GetOverrideBarIndex();
				hasOverrideBar = true;

			elseif HasTempShapeshiftActionBar() then
				newstate = GetTempShapeshiftBarIndex();
				hasTempShapeshiftBar = true;

			elseif HasBonusActionBar() then
				newstate = GetBonusBarIndex();
				if (GetBonusBarOffset() == 5) then
					hasPossessBar = true;
					if (IsMounted()) then
						isDragonRiding = true;
					end
				end
			else
				newstate = nil;
			end
			if (not newstate) then
				newstate = 12;
			end
		end

		self:SetAttribute("isdragonriding", isDragonRiding);
		self:SetAttribute("hasvehiclebar", hasVehicleBar);
		self:SetAttribute("hasoverridebar", hasOverrideBar);
		self:SetAttribute("hastempshapeshiftbar", hasTempShapeshiftBar);
		self:SetAttribute("haspossessbar", hasPossessBar);

		self:CallMethod("UpdateButtonFlags");

		self:SetAttribute("state", newstate);
		control:ChildUpdate("state", newstate);

		self:CallMethod("UpdateFading");
	]])

	-- run a full initial update

	return bar
end

ActionBar.Enable = function(self)
	if (InCombatLockdown()) then return end
	self.enabled = true
end

ActionBar.Disable = function(self)
	if (InCombatLockdown()) then return end
	self.enabled = false
end

ActionBar.SetEnabled = function(self, enable)
	if (InCombatLockdown()) then return end

	if (enable) then
		self:Enable()
	else
		self:Disable()
	end
end

ActionBar.IsEnabled = function(self)
	return self.enabled
end

ActionBar.ForAll = function(self, method, ...)
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

ActionBar.Update = function(self)
	if (InCombatLockdown()) then return end

	self:UpdateButtonCount()
	self:UpdateButtonLayout()
	self:UpdateStateDriver()
	self:UpdateVisibilityDriver()
	self:UpdateBindings()
	self:UpdateFading()
end

ActionBar.UpdateFading = function(self)
	--if (InCombatLockdown()) then return end

	if (self.config.enabled and self.config.enableBarFading) then

		-- Remove any previous fade registrations.
		for id = 1, #self.buttons do
			local button = self.buttons[id]
			LFF:UnregisterFrameForFading(button)
		end

		-- Register fading for selected buttons.
		for id = self.config.fadeFrom or 1, #self.buttons do
			local button = self.buttons[id]
			if (button:GetTexture()) then
				LFF:RegisterFrameForFading(button, self.config.fadeAlone and self:GetName() or "actionbuttons", unpack(self.config.fadeButtonHitRects))
			else
				button:ForceUpdate()
			end
		end

	else

		-- Unregister all fading.
		for id, button in next,self.buttons do
			LFF:UnregisterFrameForFading(self.buttons[id])
			if (not button:GetTexture()) then
				--button:ForceUpdate()
			end
		end
	end

end

ActionBar.UpdateButtonCount = function(self)
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

ActionBar.UpdateButtonConfig = function(self)
	for id,button in next,self.buttons do
		button.config.clickOnDown = self.config.clickOnDown
	end
end

ActionBar.UpdateButtonLayout = function(self)
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

ActionBar.UpdateButtonFlags = function(self)
	self.isDragonRiding = self:GetAttribute("isdragonriding")
	self.hasVehicleBar = self:GetAttribute("hasvehiclebar")
	self.hasOverrideBar = self:GetAttribute("hasoverridebar")
	self.hasTempShapeshiftBar = self:GetAttribute("hastempshapeshiftbar")
	self.hasPossessBar = self:GetAttribute("haspossessbar")

	for id,button in next,self.buttons do
		button.isDragonRiding = self.isDragonRiding
		button.hasVehicleBar = self.hasVehicleBar
		button.hasOverrideBar = self.hasOverrideBar
		button.hasTempShapeshiftBar = self.hasTempShapeshiftBar
		button.hasPossessBar = self.hasPossessBar
	end
end

ActionBar.UpdateBindings = function(self)
	if (InCombatLockdown()) then return end
	if (not next(self.buttons)) then return end

	ClearOverrideBindings(self)

	--if (not self:IsEnabled()) then return end

	for id,button in pairs(self.buttons) do
		local bindingAction = button.keyBoundTarget
		if (bindingAction) then
			-- iterate through the registered keys for the action
			local buttonName = button:GetName()
			for keyNumber = 1,select("#", GetBindingKey(bindingAction)) do

				-- get a key for the action
				local key = select(keyNumber, GetBindingKey(bindingAction))
				if (key and (key ~= "")) then
					-- this is why we need named buttons
					SetOverrideBindingClick(self, false, key, buttonName) -- assign the key to our own button
				end
			end
		end
	end
end

ActionBar.UpdateStateDriver = function(self)
	if (InCombatLockdown()) then return end

	local statedriver
	if (self.id == 1) then
		statedriver = "[overridebar] possess; [possessbar] possess; [shapeshift] possess; [bonusbar:5] dragon; [form,noform] 0; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6"

		local playerClass = UnitClassBase("player")
		if (playerClass == "DRUID") then
			statedriver = statedriver .. "; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10"

		elseif (playerClass == "MONK") then
			statedriver = statedriver .. "; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9"

		elseif (playerClass == "ROGUE") then
			statedriver = statedriver .. "; [bonusbar:1] 7"

		elseif (playerClass == "WARRIOR") then
			statedriver = statedriver .. "; [bonusbar:1] 7; [bonusbar:2] 8"
		end

		statedriver = statedriver .. "; 1"
	else
		statedriver = tostring(self.id)
	end

	UnregisterStateDriver(self, "page")
	self:SetAttribute("state-page", "0")
	RegisterStateDriver(self, "page", statedriver or "0")
end

ActionBar.UpdateVisibilityDriver = function(self)
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
