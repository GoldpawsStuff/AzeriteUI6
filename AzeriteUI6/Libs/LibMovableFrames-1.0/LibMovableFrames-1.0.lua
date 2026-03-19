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
local MAJOR_VERSION = "LibMovableFrames-1.0"
local MINOR_VERSION = 1

if (not LibStub) then
	error(MAJOR_VERSION .. " requires LibStub.")
end

local lib, oldversion = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if (not lib) then
	return
end

-- Library registries
lib.embeds = lib.embeds or {}
lib.frame = lib.frame or CreateFrame("Frame")

-- Constant to track login status
local _LOGGED_IN = IsLoggedIn()

local Anchor = CreateFrame("Button")
local Anchor_MT = { __index = Anchor }

local Scale = CreateFrame("Button")
local Scale_MT = { __index = Scale }

-- Anchor registry
lib.Anchors = lib.Anchors or {} -- currently registered anchors
lib.AnchorCache = lib.AnchorCache or {} -- cache of unused anchor frames
lib.AnchorGroups = lib.AnchorGroups or { general = {}, actionbars = {}, unitframes = {}, floaters = {} } -- registered anchor groups
lib.AnchorGroupColors = lib.AnchorGroupColors or { -- anchor group colors
	general = 		{ 128/255, 255/255, 128/255 }, 	-- bright green
	actionbars = 	{ 64/255, 192/255, 255/255 }, 	-- bright blue
	unitframes = 	{ 255/255, 160/255, 64/255 }, 	-- orange
	floaters = 		{ 255/255, 192/255, 128/255 } 	-- warm yellow
}

-- Speed!
local Anchors = lib.Anchors 						--[[-- [<frameHandle1>] = Anchor1, [<frameHandle2>] = Anchor2, ... } 		--]]--
local AnchorCache = lib.AnchorCache 				--[[-- { <CachedAnchor1>, <CachedAnchor2>, ... } 							--]]--
local AnchorGroups = lib.AnchorGroups 				--[[-- [<"groupname">] = { [<anchor1>] = true, [<anchor2>] = true, ...  } 	--]]--
local AnchorGroupColors = lib.AnchorGroupColors 	--[[-- [<"groupname">] = { r, g, b } 										--]]--

-- Clean up a number for display purposes.
-- *do not save these numbers, as they are graphically inaccurate
local clean = function(float) return math.floor((float * 100) + .5)/100 end

-- Figure out the point within the given coordinate space,
-- return values converted to the frame's own scale.
--[[--
					1/3w            2/3w
		_______________________________________ (uiWidth, uiHeight)
		| TOPLEFT  |     TOP       | TOPRIGHT |
		|__________|_______________|__________| 3/4h
		|      1/4w     CENTER       3/4w     |
		| LEFT  |                     | RIGHT |
		|       |_________1/3w________|       |
		|_______|__                 __|_______| 1/4h
		| BOTTOM   |    BOTTOM     |   BOTTOM |
		|_LEFT_____|_______________|____RIGHT_|
	(0,0)

--]]--
local GetNormalizedCoords = function(frame, normalizeToUIParent)

	-- ui and frame scales
	local uiScale = UIParent:GetEffectiveScale()
	local uiWidth = UIParent:GetWidth() * uiScale
	local uiHeight = UIParent:GetHeight() * uiScale
	local frameScale = frame:GetEffectiveScale()

	-- relative distances from the edges
	local bottom = frame:GetBottom() * frameScale
	local left = frame:GetLeft() * frameScale
	local top = uiHeight - frame:GetTop() * frameScale 
	local right = uiWidth - frame:GetRight() * frameScale 

	-- centered coordinates, origin is bottom left
	local x, y = frame:GetCenter(); x = x * frameScale; y = y * frameScale
	local point, offsetX, offsetY -- for the return values

	-- Top Row
	if (y > uiHeight * 3/4) then

		-- Top Left
		if (x < uiWidth * 1/3) then
			point, offsetX, offsetY = "TOPLEFT", left, -top

		-- Top Right
		elseif (x > uiWidth * 2/3) then
			point, offsetX, offsetY = "TOPRIGHT", -right, -top

		-- Top Center
		else
			point, offsetX, offsetY = "TOP", (x - uiWidth/2), -top
		end

	-- Mid & Bottom Segments
	else
		-- Mid to Bottom Left Columns
		if (x < uiWidth * 1/4) then

			-- Mid Left
			if (y > uiHeight * 1/4) then
				point, offsetX, offsetY = "LEFT", left, (y - uiHeight/2)

			-- Bottom Left
			else
				point, offsetX, offsetY = "BOTTOMLEFT", left, bottom
			end

		-- Mid to Bottom Right Columns
		elseif (x > uiWidth * 3/4) then

			-- Mid Right
			if (y > uiHeight * 1/4) then
				point, offsetX, offsetY = "RIGHT", -right, (y - uiHeight/2)

			-- Bottom Right
			else
				point, offsetX, offsetY = "BOTTOMRIGHT", -right, bottom
			end

		-- Mid and Bottom Center Columns
		else
			-- Center
			if (y > uiHeight * 1/3) then
				point, offsetX, offsetY = "CENTER", (x - uiWidth/2), (y - uiHeight/2)

			-- Bottom Center Segment
			else
				-- Bottom Left
				if (x < uiWidth * 1/3) then
					point, offsetX, offsetY = "BOTTOMLEFT", left, bottom

				-- Bottom Right
				elseif (x > uiWidth * 2/3) then
					point, offsetX, offsetY = "BOTTOMRIGHT", -right, bottom

				-- Bottom Center
				else
					point, offsetX, offsetY = "BOTTOM", (x - uiWidth/2), bottom
				end
			end
		end
	end
	if (normalizeToUIParent) then
		return point, offsetX/frameScale, offsetY/frameScale
	else
		return point, offsetX, offsetY
	end
end

Anchor.OnShow = function(self)
	self.scale = self.owner:GetScale() -- current frame scale
	self.baseWidth = self.owner:GetWidth() -- unscaled width
	self.baseHeight = self.owner:GetHeight() -- unscaled height

	self:SetUserResizable(self.isResizable)

	-- position to its owner
	-- scale and size to its owner
	-- update its saved position

end

Anchor.OnDragStart = function(self)
	self.owner:ClearAllPoints()
	self.owner:SetPoint("CENTER", self) -- correct while it's centered

	-- set OnUpdate script
		-- update anchor, coords, scale

	self:StartMoving()
	self:SetUserPlaced(false) -- the above enables this, we don't want it
end

Anchor.OnDragStop = function(self)
	self:StopMovingOrSizing()
	self:SetScript("OnUpdate", nil)

	local point, x, y = GetNormalizedCoords(self) 	-- Get the normalized position of the anchor 
	local scale = self.owner:GetEffectiveScale() 	-- We need the frame's effective scale relative to the WorldFrame

	self.owner:ClearAllPoints()
	self.owner:SetPoint(point, x/scale, y/scale) 	-- Convert anchor's coordinates to same space as the frame
end

Anchor.OnSizeChanged = function(self, width, height)
	local baseWidth, baseHeight = self.baseWidth, self.baseHeight
	local scale = width / baseWidth 

	-- limit the scale
	if (scale > 1.5) then
		scale = 1.5
		width = baseWidth * 1.5
	elseif (scale < .5) then
		scale = .5
		width = baseWidth * .5
	end

	-- keep the ratio
	width = baseWidth * scale
	height = baseHeight * scale

	self.scale = scale

	self.owner:SetScale(scale)
	self.owner:ClearAllPoints() 					-- Need to reset the points
	self.owner:SetPoint("CENTER", self) 			-- or it will become misaligned when rescaled

	self:SetSize(width, height) 					-- resize the anchor

	local point, x, y = GetNormalizedCoords(self) 	-- Get the normalized position of the anchor 
	local scale = self.owner:GetEffectiveScale() 	-- We need the frame's effective scale relative to the WorldFrame 

	self.owner:ClearAllPoints()
	self.owner:SetPoint(point, x/scale, y/scale) 	-- Convert anchor's coordinates to same space as the frame
end

Anchor.SetUserResizable = function(self, isResizable)
	self.isResizable = isResizable and true or nil
	self.sizer:SetShown(self.isResizable)
	self:SetResizable(self.isResizable)
end

Anchor.SetGroup = function(self, group)
	-- validate the optional group name or add to 'general'
	group = group and AnchorGroups[group] and group or "general" 

	local oldGroup = AnchorGroups[self]
	if (oldGroup) then
		AnchorGroups[oldGroup][self] = nil
	end

	AnchorGroups[self] = group
	AnchorGroups[group][self] = true

	local r, g, b = unpack(AnchorGroupColors[group])
	self.overlay:SetBackdropColor(r, g, b, .5)
	self.overlay:SetBackdropBorderColor(r, g, b, .75)

end

Anchor.SetLabel = function(self, label)
end

Scale.OnMouseDown = function(self)
	self:GetParent():StartSizing("BOTTOMRIGHT", false)
	self:GetParent():SetUserPlaced(false)
	self:SetButtonState("PUSHED", true)
end

Scale.OnMouseUp = function(self)
	self:SetButtonState("NORMAL", false)
	self:GetParent():StopMovingOrSizing()
end

--[[ RegisterMovableFrameAnchor(self, frame, [label], [group])
Register a frame for movement.

* self      	- the module registered for the event
* frame     	- <frame> handle of the frame to be moved 
* displayName 	- <string> label to display on the anchor (optional)
* group 		- <string> group to add anchor to (optional)
--]]
lib.RegisterMovableFrameAnchor = function(_, frame, displayName, group, savedVariables)
	if (not frame) then 
		return 
	end

	-- validate the optional group name or add to 'general'
	group = group and AnchorGroups[group] and group or "general" 

	-- retrieve or create an anchor
	local anchor = table.remove(AnchorCache) or setmetatable(CreateFrame("Button", nil, UIParent), Anchor_MT)
	anchor.owner = frame
	anchor.scale = frame:GetScale() -- current frame scale
	anchor.baseWidth = frame:GetWidth() -- unscaled width
	anchor.baseHeight = frame:GetHeight() -- unscaled height
	anchor.isResizable = true
	anchor.savedVariables = savedVariables

	-- retrieve or create label
	local label = anchor.label 

	anchor.label = label

	-- retrieve or create scale button
	local sizer = anchor.sizer or setmetatable(CreateFrame("Button", nil, anchor), Scale_MT)
	sizer:SetPoint("BOTTOMRIGHT")
	sizer:SetSize(16, 16) 																-- keep it small, because of the fugly graphics 
	sizer:SetNormalTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]]) 			-- these graphics, yes.
	sizer:SetHighlightTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Highlight]]) 	-- and these.
	sizer:SetPushedTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Down]]) 			-- and definitely these.
	sizer:SetHitRectInsets(-16, 0, -16, 0) 												-- make the adjustable corner grow a bit into the frame

	anchor.sizer = sizer

	-- retrieve or create visible overlay
	local overlay = anchor.overlay or CreateFrame("Frame", nil, anchor, "BackdropTemplate")
	overlay:SetIgnoreParentScale(true)
	overlay:SetPoint("TOPLEFT", -1, 1)
	overlay:SetPoint("BOTTOMRIGHT", 1, -1)
	overlay:SetBackdrop({
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
		edgeSize = 16, tile = true, tileSize = 16,
		insets = { left = 4, right = 3, top = 3, bottom = 4 }
	})

	local r, g, b = unpack(AnchorGroupColors[group])
	overlay:SetBackdropColor(r, g, b, .5)
	overlay:SetBackdropBorderColor(r, g, b, .75)

	anchor.overlay = overlay

	anchor:SetLabel(displayName or "")
	anchor:SetGroup(group)
	anchor:SetSize(anchor.baseWidth * anchor.scale, anchor.baseHeight * anchor.scale) -- scaled size
	anchor:ClearAllPoints()
	anchor:SetPoint(GetNormalizedCoords(frame, true))

	anchor:SetFrameStrata("HIGH")
	anchor:SetFrameLevel(1000)

	anchor:EnableMouse(true)
	anchor:SetMovable(true)
	anchor:SetUserResizable(true)
	anchor:SetUserPlaced(false) -- disable saving in the on-disk frame cache, it messes with our system
	anchor:SetClampedToScreen(false)

	anchor:RegisterForDrag("LeftButton")
	anchor:RegisterForClicks("AnyUp")

	anchor:SetScript("OnDragStart", Anchor.OnDragStart)
	anchor:SetScript("OnDragStop", Anchor.OnDragStop)
	anchor:SetScript("OnSizeChanged", Anchor.OnSizeChanged)

	sizer:SetScript("OnMouseDown", Scale.OnMouseDown)
	sizer:SetScript("OnMouseUp", Scale.OnMouseUp)

	-- add to a groups
	Anchors[frame] = anchor
	AnchorGroups[group][anchor] = true
	AnchorGroups[anchor] = group

	-- return to the user
	return anchor
end

--[[ UnregisterMovableFrameAnchor(self, frame)
Used to unregister a frame for movement.

* self      - the module registered for the event
* frame     - <frame> handle of the frame to be moved 
--]]
lib.UnregisterMovableFrameAnchor = function(_, frame)
	if (not Anchors[frame]) then 
		return
	end

	-- hide & reset the anchor
	local anchor = Anchors[frame]
	anchor:Hide()
	anchor:SetLabel("")
	anchor:SetGroup("general")

	-- add to unused anchor cache
	AnchorCache[#AnchorCache + 1] = anchor -- move to cache

	-- remove from anchor groups
	local group = AnchorGroups[anchor]
	AnchorGroups[group][anchor] = nil
	AnchorGroups[anchor] = nil

	-- clear the entry
	Anchors[frame] = nil 
end

--[[ RegisterMovableFrameGroup(self, groupName, r, g, b)
Shows all registered and active movable frame anchors.

* self      - the module registered for the event
* groupName - name of the new group <string>
* r 		- <number> [0-1] red component of the group color 
* g 		- <number> [0-1] green component of the group color 
* b 		- <number> [0-1] blue component of the group color 
--]]
lib.RegisterMovableFrameGroup = function(_, groupName, r, g, b)
	if (AnchorGroups[groupName]) then 
		return 
	end
	AnchorGroups[groupName] = {}
	AnchorGroupColors[groupName] = { r, g, b }
end

--[[ ShowAllMovableFrameAnchors(self)
Shows all registered and active movable frame anchors.

* self      - the module registered for the event
--]]
lib.ShowAllMovableFrameAnchors = function()
	if (InCombatLockdown()) then return end

	for frame,anchor in next,Anchors do
		-- update texts
		-- x, y, scale
		-- show the anchor
		anchor:Show()
	end
end

--[[ HideAllMovableFrameAnchors(self)
Hides all registered and active movable frame anchors.
--]]
lib.HideAllMovableFrameAnchors = function()
	if (InCombatLockdown()) then return end
	for frame,anchor in next,Anchors do
		anchor:Hide()
	end
end

-- Event						When it fires								All variables?	Recommend?
-------------------------------------------------------------------------------------------------------------------------			
-- ADDON_LOADED (own name)		Per addon, when that addon's vars load		No (only own)	Yes — for own addon only
-- PLAYER_LOGIN					Once, after all startup addons loaded		Yes (non-LoD)	Best general choice
-- PLAYER_ENTERING_WORLD		When entering world (initial login)			Yes (non-LoD)	Very safe, slightly later
-- VARIABLES_LOADED				Blizzard vars (CVars, bindings, etc.)		No				Avoid for addons
-------------------------------------------------------------------------------------------------------------------------			
local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, ...) 
	if (event == "PLAYER_LOGIN") then -- initial setup, re-apply saved positions
		self:UnregisterEvent("PLAYER_LOGIN") -- only need this one once

		for frame,anchor in next,Anchors do
			if (anchor.savedVariables) then
				local frameName = frame:GetName() or frame:GetDebugName()
				local savedPosition = anchor.savedVariables[frameName]

			end

		end

		_LOGGED_IN = true 

	elseif (event == "PLAYER_REGEN_DISABLED") then -- combat started, hide anchors
		lib:HideAllMovableFrameAnchors()
	end
end)

-- Always need this one
frame:RegisterEvent("PLAYER_REGEN_DISABLED")

-- Manually fire this if we're already logged in
-- *might happen with Load on Demand addons, though unlikely
if (_LOGGED_IN) then
	frame:GetScript("OnEvent")(frame, "PLAYER_LOGIN")
else
	frame:RegisterEvent("PLAYER_LOGIN")
end

local mixins = {
	RegisterMovableFrameAnchor = true,
	UnregisterMovableFrameAnchor = true,
	ShowAllMovableFrameAnchors = true,
	HideAllMovableFrameAnchors = true
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
