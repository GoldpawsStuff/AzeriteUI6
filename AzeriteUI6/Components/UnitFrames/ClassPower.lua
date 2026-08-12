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

local ClassPower = ns:NewModule("ClassPower", nil, "LibMoreEvents-1.0", "LibMovableFrames-1.0")

-- Declare module defaults
local defaults = { 
	char = { 
		showClassPower = true -- keep toggling a character specific setting
	}, 
	profile = {

	} 
} 

-- Custom API locals
local AbbreviateNumber = ns.AbbreviateNumber
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia

local playerClass = UnitClassBase("player")
local toRadians = function(d) return d*(math.pi/180) end

-- Note that the following are just layout names.
-- They may not always be used for what their name implies.
-- The important part is number of points and layout. Not powerType.
local layouts = {
	Stagger = { --[[ 3 ]]
		[1] = {
			position = { "TOPLEFT", 62, -109 },
			size = { 13, 13 }, backdropSize = { 60, 60 },
			texture = GetMedia("point_crystal"), backdropTexture = GetMedia("point_plate"),
			rotation = toRadians(5)
		},
		[2] = {
			position = { "TOPLEFT", 41, -58 },
			size = { 39, 40 }, backdropSize = { 80, 80 },
			texture = GetMedia("point_hearth"), backdropTexture = GetMedia("point_plate"),
			rotation = nil
		},
		[3] = {
			position = { "TOPLEFT", 64, -36 },
			size = { 13, 13 }, backdropSize = { 60, 60 },
			texture = GetMedia("point_crystal"), backdropTexture = GetMedia("point_plate"),
			rotation = nil
		}
	},
	ArcaneCharges = { --[[ 4 ]]
		[1] = {
			position = { "TOPLEFT", 78, -139 },
			size = { 13, 13 }, backdropSize = { 58, 58 },
			texture = GetMedia("point_crystal"), backdropTexture = GetMedia("point_plate"),
			rotation = toRadians(6)
		},
		[2] = {
			position = { "TOPLEFT", 57, -111 },
			size = { 13, 13 }, backdropSize = { 60, 60 },
			texture = GetMedia("point_crystal"), backdropTexture = GetMedia("point_plate"),
			rotation = toRadians(5)
		},
		[3] = {
			position = { "TOPLEFT", 49, -76 },
			size = { 13, 13 }, backdropSize = { 60, 60 },
			texture = GetMedia("point_crystal"), backdropTexture = GetMedia("point_plate"),
			rotation = toRadians(4)
		},
		[4] = {
			position = { "TOPLEFT", 72, -33 },
			size = { 51, 52 }, backdropSize = { 104, 104 },
			texture = GetMedia("point_hearth"), backdropTexture = GetMedia("point_plate"),
			rotation = nil
		}
	},
	ComboPoints = { --[[ 5 ]]
		[1] = {
			position = { "TOPLEFT", 82, -137 },
			size = { 13, 13 }, backdropSize = { 58, 58 },
			texture = GetMedia("point_crystal"), backdropTexture = GetMedia("point_plate"),
			rotation = toRadians(6)
		},
		[2] = {
			position = { "TOPLEFT", 64, -111 },
			size = { 13, 13 }, backdropSize = { 60, 60 },
			texture = GetMedia("point_crystal"), backdropTexture = GetMedia("point_plate"),
			rotation = toRadians(5)
		},
		[3] = {
			position = { "TOPLEFT", 54, -79 },
			size = { 13, 13 }, backdropSize = { 60, 60 },
			texture = GetMedia("point_crystal"), backdropTexture = GetMedia("point_plate"),
			rotation = toRadians(4)
		},
		[4] = {
			position = { "TOPLEFT", 60, -44 },
			size = { 13, 13 }, backdropSize = { 60, 60 },
			texture = GetMedia("point_crystal"), backdropTexture = GetMedia("point_plate"),
			rotation = nil
		},
		[5] = {
			position = { "TOPLEFT", 82, -11 },
			size = { 14, 21 }, backdropSize = { 82, 96 },
			texture = GetMedia("point_crystal"), backdropTexture = GetMedia("point_diamond"),
			rotation = toRadians(1)
		}
	},
	Chi = { --[[ 5 ]]
		[1] = {
			position = { "TOPLEFT", 82, -137 },
			size = { 13, 13 }, backdropSize = { 58, 58 },
			texture = GetMedia("point_crystal"), backdropTexture = GetMedia("point_plate"),
			rotation = toRadians(6)
		},
		[2] = {
			position = { "TOPLEFT", 62, -109 },
			size = { 13, 13 }, backdropSize = { 60, 60 },
			texture = GetMedia("point_crystal"), backdropTexture = GetMedia("point_plate"),
			rotation = toRadians(5)
		},
		[3] = {
			position = { "TOPLEFT", 51, -73 },
			size = { 39, 40  }, backdropSize = { 80, 80 },
			texture = GetMedia("point_hearth"), backdropTexture = GetMedia("point_plate"),
			rotation = nil
		},
		[4] = {
			position = { "TOPLEFT", 64, -36 },
			size = { 13, 13 }, backdropSize = { 60, 60 },
			texture = GetMedia("point_crystal"), backdropTexture = GetMedia("point_plate"),
			rotation = nil
		},
		[5] = {
			position = { "TOPLEFT", 82, -9 },
			size = { 13, 13 }, backdropSize = { 60, 60 },
			texture = GetMedia("point_crystal"), backdropTexture = GetMedia("point_plate"),
			rotation = nil
		}
	},
	SoulShards = { --[[ 5 ]]
		[1] = {
			position = { "TOPLEFT", 82, -137 },
			size = { 12, 12 }, backdropSize = { 54, 54 },
			texture = GetMedia("point_crystal"), backdropTexture = GetMedia("point_plate"),
			rotation = toRadians(6)
		},
		[2] = {
			position = { "TOPLEFT", 64, -111 },
			size = { 13, 13 }, backdropSize = { 60, 60 },
			texture = GetMedia("point_crystal"), backdropTexture = GetMedia("point_plate"),
			rotation = toRadians(5)
		},
		[3] = {
			position = { "TOPLEFT", 50, -80 },
			size = { 11, 15 }, backdropSize = { 65, 60 },
			texture = GetMedia("point_crystal"), backdropTexture = GetMedia("point_diamond"),
			rotation = toRadians(3)
		},
		[4] = {
			position = { "TOPLEFT", 58, -44 },
			size = { 12, 18 }, backdropSize = { 78, 79 },
			texture = GetMedia("point_crystal"), backdropTexture = GetMedia("point_diamond"),
			rotation = toRadians(3)
		},
		[5] = {
			position = { "TOPLEFT", 82, -11 },
			size = { 14, 21 }, backdropSize = { 82, 96 },
			texture = GetMedia("point_crystal"), backdropTexture = GetMedia("point_diamond"),
			rotation = toRadians(1)
		}
	},
	Runes = { --[[ 6 ]]
		[1] = {
			position = { "TOPLEFT", 82, -131 },
			size = { 28, 28 }, backdropSize = { 58, 58 },
			texture = GetMedia("point_rune2"), backdropTexture = GetMedia("point_dk_block"),
			rotation = nil
		},
		[2] = {
			position = { "TOPLEFT", 58, -107 },
			size = { 28, 28 }, backdropSize = { 68, 68 },
			texture = GetMedia("point_rune4"), backdropTexture = GetMedia("point_dk_block"),
			rotation = nil
		},
		[3] = {
			position = { "TOPLEFT", 32, -83 },
			size = { 30, 30 }, backdropSize = { 74, 74 },
			texture = GetMedia("point_rune1"), backdropTexture = GetMedia("point_dk_block"),
			rotation = nil
		},
		[4] = {
			position = { "TOPLEFT", 65, -64 },
			size = { 28, 28 }, backdropSize = { 68, 68 },
			texture = GetMedia("point_rune3"), backdropTexture = GetMedia("point_dk_block"),
			rotation = nil
		},
		[5] = {
			position = { "TOPLEFT", 39, -38 },
			size = { 32, 32 }, backdropSize = { 78, 78 },
			texture = GetMedia("point_rune2"), backdropTexture = GetMedia("point_dk_block"),
			rotation = nil
		},
		[6] = {
			position = { "TOPLEFT", 79, -10 },
			size = { 40, 40 }, backdropSize = { 98, 98 },
			texture = GetMedia("point_rune1"), backdropTexture = GetMedia("point_dk_block"),
			rotation = nil
		}
	}
}

-- Create a point used for classpowers, stagger and runes.
local ClassPower_CreatePoint = function(element, index)

	local point = CreateFrame("StatusBar", nil, element)
	point:SetOrientation("VERTICAL")
	point:SetMinMaxValues(0, 1)
	point:SetValue(1)

	local case = point:CreateTexture(nil, "BACKGROUND", nil, -2)
	case:SetPoint("CENTER")
	case:SetVertexColor(211/255, 200/255, 169/255)

	point.case = case

	local slot = point:CreateTexture(nil, "BACKGROUND", nil, -1)
	slot:SetPoint("TOPLEFT", -1.5, 1.5)
	slot:SetPoint("BOTTOMRIGHT", 1.5, -1.5)
	slot:SetVertexColor(130/255 *.3, 133/255 *.3, 130/255 *.3, 2/3)

	point.slot = slot

	return point
end

local ClassPower_PostUpdateColor = function(element, r, g, b)
	--for i = 1, #element do
	--	local point = element[i]
	--	point:SetStatusBarColor(r, g, b) -- needed?
	--end
end

-- Update classpower layout and textures.
-- *also used for one-time setup of stagger and runes.
local ClassPower_PostUpdate = function(element, cur, max, hasMaxChanged, powerType)
	if (not cur or not max) then
		return
	end

	local style
	if (max >= 6) then
		style = "Runes"
	elseif (max == 5) then
		style = playerClass == "MONK" and "Chi" or playerClass == "WARLOCK" and "SoulShards" or "ComboPoints"
	elseif (max == 4) then
		style = "ArcaneCharges"
	elseif (max == 3) then
		style = "Stagger"
	end

	if (not style) then
		return element:Hide()
	end
	
	if (not ClassPower.db.char.showClassPower) then
		return element:Hide()
	end

	if (not element:IsShown()) then
		element:Show()
	end

	for i = 1, #element do
		local point = element[i]
		if (point:IsShown()) then
			local value = point:GetValue()
			local _, pmax = point:GetMinMaxValues()
			if (element.inCombat) then
				point:SetAlpha((cur == max) and 1 or (value < pmax) and .5 or 1)
			else
				point:SetAlpha((cur == max) and 0 or (value < pmax) and .5 or 1)
			end
		end
	end

	if (style ~= element.style) then
		local layout = layouts[style]
		if (layout) then
			local id = 0
			for i,info in next,layout do
				local point = element[i]
				if (point) then
					point:ClearAllPoints()
					point:SetPoint(unpack(info.position))
					point:SetSize(unpack(info.size))
					point:SetStatusBarTexture(info.texture)
					point:GetStatusBarTexture():SetRotation(info.pointRotation or 0)
					point.case:SetSize(unpack(info.backdropSize))
					point.case:SetTexture(info.backdropTexture)
					point.case:SetRotation(info.pointRotation or 0)
					point.slot:SetTexture(info.texture)
					point.slot:SetRotation(info.pointRotation or 0)
					id = id + 1
				end
			end
			-- Should be handled by the element,
			-- no idea why I'm adding it here.
			for i = id + 1, #element do
				element[i]:Hide()
			end
		end
		element.style = style
	end

end

local Runes_PostUpdate = function(element, runemap, hasVehicle, allReady)
	for i = 1, #element do
		local rune = element[i]
		if (rune:IsShown()) then
			local value = rune:GetValue()
			local _, max = rune:GetMinMaxValues()
			if (element.inCombat) then
				rune:SetAlpha(allReady and 1 or (value < max) and .5 or 1)
			else
				rune:SetAlpha(allReady and 0 or (value < max) and .5 or 1)
			end
		end
	end
end

local Runes_PostUpdateColor = function(element, r, g, b, color, rune)
	if (rune) then
		rune:SetStatusBarColor(r, g, b)
	else
		for i = 1, #element do
			element[i]:SetStatusBarColor(element.__owner.colors.power.RUNES:GetRGB())
		end
	end
end

local Stagger_SetStatusBarColor = function(element, r, g, b)
	for i = 1,3 do
		local point = element[i]
		point:SetStatusBarColor(r, g, b)
	end
end

local Stagger_PostUpdate = function(element, cur, max)

	element[1].min = 0
	element[1].max = max * .3
	element[2].min = element[1].max
	element[2].max = max * .6
	element[3].min = element[2].max
	element[3].max = max

	for i = 1,3 do
		local point = element[i]
		local value = (cur > point.max) and point.max or (cur < point.min) and point.min or cur

		point:SetMinMaxValues(point.min, point.max)
		point:SetValue(value)

		if (element.inCombat) then
			point:SetAlpha((cur == max) and 1 or (value < point.max) and .5 or 1)
		else
			point:SetAlpha((cur == 0) and 0 or (value < point.max) and .5 or 1)
		end
	end
end

local UnitFrame_OnEvent = function(self, event, unit, ...)
	if (event == "PLAYER_REGEN_DISABLED") then
		local runes = self.Runes
		if (runes and not runes.inCombat) then
			runes.inCombat = true
			runes:ForceUpdate()
		end
		local stagger = self.Stagger
		if (stagger and not stagger.inCombat) then
			stagger.inCombat = true
			stagger:ForceUpdate()
		end
		local classpower = self.ClassPower
		if (classpower and not classpower.inCombat) then
			classpower.inCombat = true
			classpower:ForceUpdate()
		end
	elseif (event == "PLAYER_REGEN_ENABLED") then
		local runes = self.Runes
		if (runes and runes.inCombat) then
			runes.inCombat = false
			runes:ForceUpdate()
		end
		local stagger = self.Stagger
		if (stagger and stagger.inCombat) then
			stagger.inCombat = false
			stagger:ForceUpdate()
		end
		local classpower = self.ClassPower
		if (classpower and classpower.inCombat) then
			classpower.inCombat = false
			classpower:ForceUpdate()
		end
	end
end

local style = function(self, unit)

	-- General frame settings
	self:SetSize(124, 168)
	self:SetHitRectInsets(0, 0, 30, -2)
	self:SetFrameLevel(self:GetFrameLevel() + 10)
	self:EnableMouse(false)

	-- ClassPower
	--------------------------------------------
	local classpower = CreateFrame("Frame", nil, self)
	classpower:SetAllPoints(self)

	local maxPoints = 10 -- for fuck's sake
	for i = 1,maxPoints do
		classpower[i] = ClassPower_CreatePoint(classpower)
	end

	--ClassPower_PostUpdate(classpower, 0, maxPoints)

	self.ClassPower = classpower
	self.ClassPower.PostUpdate = ClassPower_PostUpdate
	self.ClassPower.PostUpdateColor = ClassPower_PostUpdateColor

	-- Monk Stagger
	--------------------------------------------
	if (playerClass == "MONK") then
		local stagger = CreateFrame("Frame", nil, self)
		stagger:SetAllPoints(self)

		stagger.SetValue = function() end
		stagger.SetMinMaxValues = function() end
		stagger.SetStatusBarColor = Stagger_SetStatusBarColor

		for i = 1,3 do
			stagger[i] = ClassPower_CreatePoint(stagger)
		end

		ClassPower_PostUpdate(stagger, 0, 3)

		self.Stagger = stagger
		self.Stagger.PostUpdate = Stagger_PostUpdate
	end

	-- Death Knight Runes
	--------------------------------------------
	if (playerClass == "DEATHKNIGHT") then
		local runes = CreateFrame("Frame", nil, self)
		runes:SetAllPoints(self)

		runes.sortOrder = "ASC"
		for i = 1,6 do
			runes[i] = ClassPower_CreatePoint(runes)
		end

		ClassPower_PostUpdate(runes, 6, 6)

		self.Runes = runes
		self.Runes.PostUpdate = Runes_PostUpdate
		self.Runes.PostUpdateColor = Runes_PostUpdateColor
	end

	self:RegisterEvent("PLAYER_REGEN_ENABLED", UnitFrame_OnEvent, true)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", UnitFrame_OnEvent, true)

end

-- Return the unitframe
ClassPower.GetFrame = function(self)
	return self.frame
end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling and combat end.
ClassPower.UpdateSettings = function(self)
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
ClassPower.RefreshConfig = function(self)
	self:UpdateSettings()
end

ClassPower.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("ClassPower", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

ClassPower.OnEnable = function(self)
	oUF:RegisterStyle("AzeriteUnitFrameClassPower", style)	
	oUF:Factory(function(self) 
		self:SetActiveStyle("AzeriteUnitFrameClassPower")

		local frame = self:Spawn("player")
		frame:SetScale(.9)
		frame:SetPoint("CENTER", -223/.9, -84/.9)

		ClassPower.frame = frame

		ClassPower:RegisterMovableFrameAnchor(frame, string.lower(COMBO_POINTS), "unitframes", AzeriteUI6_Positions_DB)
	end)
end
