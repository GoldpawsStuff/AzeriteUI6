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
local MAJOR_VERSION = "LibOrb-1.0"
local MINOR_VERSION = 10

if (not LibStub) then
	error(MAJOR_VERSION .. " requires LibStub.")
end

local lib, oldversion = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if (not lib) then
	return
end

-- Lua API
local _G = _G
local math_abs = math.abs
local math_max = math.max
local math_sqrt = math.sqrt
local select = select
local setmetatable = setmetatable
local type = type
local unpack = unpack

-- WoW API
local CreateFrame = _G.CreateFrame
local GetTime = _G.GetTime

-- Library registries
lib.orbs = lib.orbs or {}
lib.data = lib.data or {}
lib.embeds = lib.embeds or {}

-- Speed shortcuts
local Orbs = lib.orbs

----------------------------------------------------------------
-- Orb template
----------------------------------------------------------------
local Orb = CreateFrame("StatusBar")
local Orb_MT = { __index = Orb }

-- Grab some of the original methods before we change them
local Orig_GetScript = getmetatable(Orb).__index.GetScript
local Orig_SetScript = getmetatable(Orb).__index.SetScript

-- Noop out the old blizzard methods.
local noop = function() end
Orb.GetFillStyle = noop
Orb.GetMinMaxValues = noop
Orb.GetOrientation = noop
Orb.GetReverseFill = noop
Orb.GetRotatesTexture = noop
Orb.GetStatusBarAtlas = noop
Orb.GetStatusBarColor = noop
Orb.GetStatusBarTexture = noop
Orb.GetValue = noop
Orb.SetFillStyle = noop
Orb.SetMinMaxValues = noop
Orb.SetOrientation = noop
Orb.SetReverseFill = noop
Orb.SetValue = noop
Orb.SetRotatesTexture = noop
Orb.SetStatusBarAtlas = noop
Orb.SetStatusBarColor = noop
Orb.SetStatusBarTexture = noop

local OnSizeChanged = function(self, width, height)
	local data = Orbs[self]
	local leftCrop = data.barLeftCrop
	local rightCrop = data.barRightCrop
	self:SetHitRectInsets(leftCrop, rightCrop, 0, 0)

	-- WoW 12.0.1: contentHolder needs full orb height
	-- It's anchored to BOTTOM of clipFrame, so we set explicit height
	local contentHolder = data.contentHolder
	contentHolder:SetHeight(height)
	contentHolder:SetWidth(width)

	-- clipFrame anchors
	local clipFrame = data.clipFrame
	clipFrame:ClearAllPoints()
	clipFrame:SetPoint("BOTTOM", leftCrop/2 - rightCrop/2, 0)
	clipFrame:SetPoint("LEFT", leftCrop, 0)
	clipFrame:SetPoint("RIGHT", -rightCrop, 0)

	-- TOP anchored to native statusbar texture for automatic height based on value
	local nativeBar = data.nativeStatusBar
	if (nativeBar) then
		clipFrame:SetPoint("TOP", nativeBar:GetStatusBarTexture(), "TOP")
	end
	
	if (data.OnSizeChanged) then
		data.OnSizeChanged(self, width, height)
	end
end

----------------------------------------------------------------
-- Custom API
----------------------------------------------------------------
-- forces a hard reset to zero
Orb.Clear = function(self)
	local data = Orbs[self]
	data.barValue = 0
	data.barDisplayValue = 0

	-- WoW 12.0.1: Reset native statusbar
	local nativeBar = data.nativeStatusBar
	if (nativeBar) then
		nativeBar:SetValue(0, Enum.StatusBarInterpolation.Immediate)
	end
end

----------------------------------------------------------------
-- Standard API
----------------------------------------------------------------
-- Sets the value the orb should move towards
Orb.SetValue = function(self, value, overrideSmoothing)
	local data = Orbs[self]

	-- WoW 12.0.1: Use native StatusBar to handle secret values
	local nativeBar = data.nativeStatusBar
	if (nativeBar) then
		-- Convert boolean overrideSmoothing to interpolation enum
		local interpMode
		if (overrideSmoothing) == true then
			interpMode = Enum.StatusBarInterpolation.Immediate
		elseif (type(overrideSmoothing) == "number") then
			interpMode = overrideSmoothing
		else
			interpMode = Enum.StatusBarInterpolation.Linear
		end
		nativeBar:SetValue(value, interpMode)
	end

	-- Store value (may be secret)
	data.barValue = value
end

Orb.SetMinMaxValues = function(self, min, max, overrideSmoothing)
	local data = Orbs[self]

	-- WoW 12.0.1: Use native StatusBar to handle secret values
	local nativeBar = data.nativeStatusBar
	if (nativeBar) then
		nativeBar:SetMinMaxValues(min, max)
	end

	-- Store values (may be secret)
	data.barMin = min
	data.barMax = max
end

Orb.GetValue = function(self)
	return Orbs[self].barValue
end

Orb.GetMinMaxValues = function(self)
	local data = Orbs[self]
	return data.barMin, data.barMax
end

Orb.SetStatusBarColor = function(self, ...)
	local data = Orbs[self]
	local r, g, b = ...
	data.layer1:SetVertexColor(r, g, b)
	data.layer2:SetVertexColor(r * 4/5, g * 4/5 * 3/4, b * 4/5)
	data.layer3:SetVertexColor(r * 3/4, g * 3/4 * 2/3, b * 3/4)
	data.layer4:SetVertexColor(r * 2/3, g * 2/3 * 1/2, b * 2/3)
end

Orb.GetStatusBarColor = function(self, id)
	local r, g, b = Orbs[self].layer1:GetVertexColor()
	return r, g, b
end

Orb.SetStatusBarTexture = function(self, ...)
	local data = Orbs[self]

	-- set all the layers at once
	local numArgs = select("#", ...)
	for i = 1, numArgs do
		local layer = data["layer"..i]
		if (not layer) then
			break
		end
		local path = select(i, ...)
		layer:SetTexture(path)
	end

	-- We hide layers that aren't set
	for i = numArgs+1,4 do
		local layer = data["layer"..i]
		if (layer) then
			layer:SetTexture(nil)
		end
	end
end

Orb.GetStatusBarTexture = function(self)
	local data = Orbs[self]
	return data.layer1, data.layer2, data.layer3, data.layer4
end

-- Can not allow the scaffold to get its scripts overwritten
Orb.SetScript = function(self, ...)
	local scriptHandler, func = ...
	if (scriptHandler == "OnUpdate") then
		Orbs[self].OnUpdate = func
	elseif (scriptHandler == "OnSizeChanged") then
		Orbs[self].OnSizeChanged = func
	elseif (scriptHandler == "OnDisplayValueChanged") then
		Orbs[self].OnDisplayValueChanged = func
	else
		Orig_SetScript(self, ...)
	end
end

Orb.GetScript = function(self, ...)
	local scriptHandler, func = ...
	if (scriptHandler == "OnUpdate") then
		return Orbs[self].OnUpdate
	elseif (scriptHandler == "OnSizeChanged") then
		return Orbs[self].OnSizeChanged
	elseif (scriptHandler == "OnDisplayValueChanged") then
		return Orbs[self].OnDisplayValueChanged
	else
		return Orig_GetScript(self, ...)
	end
end

Orb.GetAnchor = function(self) return Orbs[self].clipFrame end
Orb.GetOverlay = function(self) return Orbs[self].clipFrame end
Orb.GetObjectType = function(self) return "StatusBar" end
Orb.IsObjectType = function(self, type) return type == "Orb" or type == "StatusBar" or type == "Frame" end
Orb.IsForbidden = function(self) return true end

lib.CreateOrb = function(self, name, parent, template, rotateClockwise, speedModifier)

	local orb = setmetatable(CreateFrame("Frame", name, parent, template), Orb_MT)
	orb:SetSize(1,1)
	Orig_SetScript(orb, "OnSizeChanged", OnSizeChanged)

	-- WoW 12.0.1: Create native StatusBar to handle secret values
	-- Native StatusBar accepts secret values without Lua comparisons
	local nativeStatusBar = CreateFrame("StatusBar", nil, orb)
	nativeStatusBar:SetAllPoints()
	nativeStatusBar:SetOrientation("VERTICAL")
	nativeStatusBar:SetReverseFill(false) -- fill from bottom to top
	nativeStatusBar:SetStatusBarTexture([[Interface\Buttons\WHITE8X8]])
	nativeStatusBar:GetStatusBarTexture():SetAlpha(0) -- hide the texture, we use our own
	nativeStatusBar:SetMinMaxValues(0, 1)
	nativeStatusBar:SetValue(0)

	-- WoW 12.0.1: Use clipping frame instead of ScrollFrame
	-- clipFrame clips content, its height follows native statusbar
	local clipFrame = CreateFrame("Frame", nil, orb)
	--clipFrame:SetFrameLevel(orb:GetFrameLevel()) -- seems to be too low?
	clipFrame:SetClipsChildren(true)
	clipFrame:SetPoint("BOTTOM")
	clipFrame:SetPoint("LEFT")
	clipFrame:SetPoint("RIGHT")
	-- TOP anchored to native statusbar texture - height follows fill level
	clipFrame:SetPoint("TOP", nativeStatusBar:GetStatusBarTexture(), "TOP")

	-- contentHolder sits inside clipFrame, anchored to BOTTOM
	-- It has full orb height, so top part gets clipped when health is low
	local contentHolder = CreateFrame("Frame", nil, clipFrame)
	contentHolder:SetFrameLevel(orb:GetFrameLevel())
	contentHolder:SetPoint("BOTTOM")
	contentHolder:SetPoint("LEFT")
	contentHolder:SetPoint("RIGHT")
	-- Height will be set by OnSizeChanged to match orb height

	local orbTex1 = contentHolder:CreateTexture()
	orbTex1:SetDrawLayer("BACKGROUND", 0)
	orbTex1:SetAllPoints()

	local orbTex2 = contentHolder:CreateTexture()
	orbTex2:SetDrawLayer("BACKGROUND", -1)
	orbTex2:SetAllPoints()

	local orbTex3 = contentHolder:CreateTexture()
	orbTex3:SetDrawLayer("BACKGROUND", -2)
	orbTex3:SetAllPoints()

	local orbTex4 = contentHolder:CreateTexture()
	orbTex4:SetDrawLayer("BACKGROUND", -3)
	orbTex4:SetAllPoints()

	-- Alpha values for top two layers
	local high, low = .75, .25

	-- Layer one animations
	local t1ag1 = orbTex1:CreateAnimationGroup()

		local t1a2 = t1ag1:CreateAnimation("Alpha")
		t1a2:SetFromAlpha(low)
		t1a2:SetToAlpha(high)
		t1a2:SetDuration(6)
		t1a2:SetOrder(1)

		local t1a3 = t1ag1:CreateAnimation("Alpha")
		t1a3:SetFromAlpha(high)
		t1a3:SetToAlpha(low)
		t1a3:SetDuration(3)
		t1a3:SetOrder(2)

	t1ag1:SetLooping("REPEAT")
	t1ag1:Play()

	local t1ag2 = orbTex1:CreateAnimationGroup()

		local t1ag2a1 = t1ag2:CreateAnimation("Rotation")
		t1ag2a1:SetDegrees(-360)
		t1ag2a1:SetDuration(24)
		t1ag2a1:SetOrder(1)

	t1ag2:SetLooping("REPEAT")
	t1ag2:Play()

	-- Layer two animations
	local t2ag1 = orbTex2:CreateAnimationGroup()

		local t2a2 = t2ag1:CreateAnimation("Alpha")
		t2a2:SetFromAlpha(high)
		t2a2:SetToAlpha(low)
		t2a2:SetDuration(6)
		t2a2:SetOrder(1)

		local t2a3 = t2ag1:CreateAnimation("Alpha")
		t2a3:SetFromAlpha(low)
		t2a3:SetToAlpha(high)
		t2a3:SetDuration(3)
		t2a3:SetOrder(2)

	t2ag1:SetLooping("REPEAT")
	t2ag1:Play()

	local t2ag2 = orbTex2:CreateAnimationGroup()

		local t2ag2a1 = t2ag2:CreateAnimation("Rotation")
		t2ag2a1:SetDegrees(360)
		t2ag2a1:SetDuration(24)
		t2ag2a1:SetOrder(1)

	t2ag2:SetLooping("REPEAT")
	t2ag2:Play()

	local data = {}

	-- framework
	data.contentHolder = contentHolder
	data.clipFrame = clipFrame
	data.nativeStatusBar = nativeStatusBar

	-- layers
	data.layer1 = orbTex1
	data.layer2 = orbTex2
	data.layer3 = orbTex3
	data.layer4 = orbTex4

	data.barMin = 0 -- min value
	data.barMax = 1 -- max value
	data.barValue = 0 -- real value
	data.barDisplayValue = 0 -- displayed value while smoothing
	data.barLeftCrop = 0 -- percentage of the orb cropped from the left
	data.barRightCrop = 0 -- percentage of the orb cropped from the right
	data.barSmoothingMode = "bezier-fast-in-slow-out"

	Orbs[orb] = data

	-- Initial state - clipFrame anchored to statusbar texture handles filling
	clipFrame:Show()

	return orb
end

local mixins = {
	CreateOrb = true
}

lib.Embed = function(self, target)
	for method in pairs(mixins) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

for target in pairs(lib.embeds) do
	lib:Embed(target)
end
