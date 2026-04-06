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
local IS_LOGGED_IN = IsLoggedIn()

local Anchor = CreateFrame("Button")
local Anchor_MT = { __index = Anchor }

local Scale = CreateFrame("Button")
local Scale_MT = { __index = Scale }

-- Anchor registry
lib.Anchors = lib.Anchors or {} -- currently registered anchors
lib.AnchorCache = lib.AnchorCache or {} -- cache of unused anchor frames
lib.AnchorGroups = lib.AnchorGroups or { general = {}, actionbars = {}, unitframes = {}, floaters = {} } -- registered anchor groups
lib.AnchorGroupColors = lib.AnchorGroupColors or {  -- anchor group colors
	general = 		{ 128/255, 255/255, 128/255 }, 	-- bright green
	actionbars = 	{  64/255, 192/255, 255/255 }, 	-- bright blue
	unitframes = 	{ 255/255, 160/255,  64/255 }, 	-- orange
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
local print = function(...)
	_G.print(string.format("|cff3366cc%s:|r", MAJOR_VERSION), ...)
end

-- Figure out the point within the given coordinate space,
-- return values relative to the WorldFrame or UIParent.
--[[--                   
        		  1/3w            2/3w
        _______________________________________ (uiWidth, uiHeight)
        | TOPLEFT  |     TOP       | TOPRIGHT |
        |__________|_______________|__________| 3/4h
        |      1/4w     CENTER       3/4w     |
        | LEFT  |                     | RIGHT |
        |_______|_____________________|_______| 1/3h
        |          |               |          | 
        | BOTTOM   |    BOTTOM     |   BOTTOM |
        |_LEFT_____|_______________|____RIGHT_|
    (0,0)         1/3w            2/3w

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
			if (y > uiHeight * 1/3) then
				point, offsetX, offsetY = "LEFT", left, (y - uiHeight/2)

			-- Bottom Left
			else
				point, offsetX, offsetY = "BOTTOMLEFT", left, bottom
			end

		-- Mid to Bottom Right Columns
		elseif (x > uiWidth * 3/4) then

			-- Mid Right
			if (y > uiHeight * 1/3) then
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
	-- Use this to position the frames
	if (normalizeToUIParent) then
		return point, offsetX/frameScale, offsetY/frameScale
	else
		-- Use this for saving, for accuracy
		return point, offsetX, offsetY
	end
end

-- Setters
---------------------------------------------
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
	self.label:SetText(label or "")
end

Anchor.SetAbove = function(self, isAbove)
	self.isAbove = isAbove and true or nil
	self:SetFrameLevel(self.isAbove and 1100 or self.isBelow and 900 or 1000)
end

Anchor.SetBelow = function(self, isBelow)
	self.isBelow = isBelow and true or nil
	self:SetFrameLevel(self.isAbove and 600 or self.isBelow and 400 or 1000)
end

-- Save & Restore
---------------------------------------------
-- Save current position
Anchor.SaveToDB = function(self)
	-- figure out current position
	local point, x, y = GetNormalizedCoords(self, true) -- Get the normalized position of the anchor 
	local scale = self.owner:GetScale() -- We need the frame's effective scale relative to the WorldFrame
	local name = self.owner:GetName() or self.owner:GetDebugName()

	-- store in the global table
	self.db[name] = { scale = scale, position = { point, x, y } }
end

-- Restore last saved position
Anchor.RestoreFromDB = function(self)
	local savedPosition = self.db[(self.owner:GetName() or self.owner:GetDebugName())] -- is it saved?
	if (savedPosition) then
		local position, x, y = unpack(savedPosition.position)
		if (position and x and y) then

			-- restore frame positions
			--self.owner:SetScale((savedPosition.scale and savedPosition.scale / UIParent:GetScale()) or 1)
			self.owner:SetScale(savedPosition.scale or 1)
			self.owner:ClearAllPoints()
			self.owner:SetPoint(position, x, y)

			self:OnShow() -- update anchor to new position
		end
	end
	self:UpdatePositionDisplay()
end

-- Restore to the default position and scale
Anchor.RestoreFromDefaults = function(self)
	local defaultPosition = self.default
	if (defaultPosition) then
		local position, x, y = unpack(defaultPosition.position)
		if (position and x and y) then

			-- restore frame positions
			--self.owner:SetScale((defaultPosition.scale and defaultPosition.scale / UIParent:GetScale()) or 1)
			self.owner:SetScale(defaultPosition.scale or 1)
			self.owner:ClearAllPoints()
			self.owner:SetPoint(position, x, y)

			self:OnShow() -- update anchor to new position
			self:SaveToDB() -- save current anchor position to db
		end
	end
	self:UpdatePositionDisplay()
end

-- Restore to the position and scale the anchor had when shown
Anchor.RestoreFromPrevious = function(self)
	local previousPosition = self.previous
	if (previousPosition) then
		local position, x, y = unpack(previousPosition.position)
		if (position and x and y) then

			-- restore frame positions
			--self.owner:SetScale((previousPosition.scale and previousPosition.scale / UIParent:GetScale()) or 1)
			self.owner:SetScale(previousPosition.scale or 1)
			self.owner:ClearAllPoints()
			self.owner:SetPoint(position, x, y)

			self:OnShow() -- update anchor to new position
			self:SaveToDB() -- save current anchor position to db
		end
	end
	self:UpdatePositionDisplay()
end

-- Updates
---------------------------------------------
Anchor.UpdatePositionDisplay = function(self)
	-- update displayed coords and scale
	local point, x, y = GetNormalizedCoords(self) 	-- Get the normalized position of the anchor 
	--local scale = self.owner:GetEffectiveScale() 	-- We need the frame's effective scale relative to the WorldFrame
	local scale = self.owner:GetScale()

	self.position:SetFormattedText("|cff888888%s|r  %.0f, %.0f   |cff888888%.02f|r", point, x, y, scale)
	--self.position:SetFormattedText("|cff888888%s|r  %.0f, %.0f   |cff888888%.02f|r", point, x, y, scale/UIParent:GetScale())
end

-- Script Handlers 
---------------------------------------------
Anchor.OnShow = function(self)

	-- Store current position and scale as "previous"
	self.previous = { scale = self.owner:GetScale(), position = { GetNormalizedCoords(self.owner, true) } }

	-- store owner's size and scale for this session
	self.scale = self.owner:GetScale() -- current frame scale
	self.baseWidth = self.owner:GetWidth() -- unscaled width
	self.baseHeight = self.owner:GetHeight() -- unscaled height

	-- position, scale and size the anchor to its owner
	self:SetScale(self.scale)
	self:SetSize(self.baseWidth, self.baseHeight)
	self:ClearAllPoints()
	self:SetPoint(GetNormalizedCoords(self.owner, true))

	self:UpdatePositionDisplay()
end

Anchor.OnHide = function(self)
	self.previous = nil	
end

Anchor.OnDragStart = function(self)
	self.owner:ClearAllPoints()
	self.owner:SetPoint("CENTER", self) -- correct while it's centered

	self:SetScript("OnUpdate", self.OnUpdate)


	self:StartMoving()
	self:SetUserPlaced(false) -- the above enables this, we don't want it

	self:UpdatePositionDisplay()
end

Anchor.OnDragStop = function(self)
	self:StopMovingOrSizing()
	self:SetScript("OnUpdate", nil)

	--local point, x, y = GetNormalizedCoords(self) 	-- Get the normalized position of the anchor 
	--local scale = self.owner:GetEffectiveScale() 	-- We need the frame's effective scale relative to the WorldFrame

	self.owner:ClearAllPoints()
	--self.owner:SetPoint(point, x/scale, y/scale) 	-- Convert anchor's coordinates to same space as the frame
	self.owner:SetPoint(GetNormalizedCoords(self, true)) 	-- Convert anchor's coordinates to same space as the frame

	self:SaveToDB()
	self:UpdatePositionDisplay()
end

Anchor.OnMouseDown = function(self, button)
	if (button == "LeftButton") then
		-- restore last saved position
		if (IsShiftKeyDown()) then
			self:RestoreFromPrevious()
			return
		end

		for frame,anchor in next,Anchors do 
			anchor:SetFrameLevel(anchor == self and 2000 or anchor.isAbove and 1100 or anchor.isBelow and 900 or 1000)
		end

	elseif (button == "RightButton") then
		-- restore default
		if (IsShiftKeyDown()) then
			self:RestoreFromDefaults()
			return
		end

		for frame, anchor in next,Anchors do 
			anchor:SetFrameLevel(anchor == self and 500 or anchor.isAbove and 600 or anchor.isBelow and 400 or 1000)
		end

	elseif (button == "MiddleButton") then
		-- restore last saved scale
		self.scale = self.default.scale
		self:UpdateScale()
	end
end

Anchor.UpdateScale = function(self)
	-- retrieve unscaled position
	local point, x, y = GetNormalizedCoords(self.owner)

	-- change the scale
	self.owner:SetScale(self.scale)

	-- figure out the new effective scale
	local effectiveScale = self.owner:GetEffectiveScale()

	-- adjust position to match the old anchorpoint
	self.owner:ClearAllPoints()
	self.owner:SetPoint(point, x / effectiveScale, y / effectiveScale)

	-- update the anchor
	self:SetScale(self.scale)
	self:ClearAllPoints()
	self:SetPoint(point, x / effectiveScale, y / effectiveScale)

	self:SaveToDB()
	self:UpdatePositionDisplay()
end

Anchor.OnMouseWheel = function(self, delta)

	if (delta > 0 ) then
		self.scale = math.min(1.5, self.scale + .02)
	elseif (delta < 0) then
		self.scale = math.max(.5, self.scale - .02)
	end

	self:UpdateScale()
end

Anchor.OnUpdate = function(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if (self.elapsed < 1/30) then
		return 
	end
	self.elapsed = 0 -- full reset

	self:UpdatePositionDisplay()
end

Scale.OnMouseDown = function(self)
	self:GetParent():StartSizing("BOTTOMRIGHT", false)
	self:GetParent():SetUserPlaced(false)
	self:SetButtonState("PUSHED", true)
	self:GetParent():UpdatePositionDisplay()
end

Scale.OnMouseUp = function(self)
	self:SetButtonState("NORMAL", false)
	self:GetParent():StopMovingOrSizing()
	self:GetParent():UpdatePositionDisplay()
end

--[[ RegisterMovableFrameAnchor(self, frame, [label], [group])
Register a frame for movement.

* self      - the module registered for the event
* frame     - <frame> handle of the frame to be moved 
* name 	    - <string> label to display on the anchor (optional)
* group     - <string> group to add anchor to (optional)
* db        - <table> a table to store the position in, preferably your SavedVariables
--]]
lib.RegisterMovableFrameAnchor = function(_, frame, name, group, db)
	if (not frame) then 
		return print("[RegisterMovableFrameAnchor]: No 'frame' provided for anchoring.")
	end
	if (not frame:GetParent() == "UIParent") then 
		return print("[RegisterMovableFrameAnchor]: Frame must be parented to 'UIParent'.") 
	end
	if (not frame:GetScale() or not frame:GetWidth() or not frame:GetSize()) then
		return print("[RegisterMovableFrameAnchor]: Function requires a frame with valid position and dimensions.")
	end

	-- validate the optional group name or add to 'general'
	group = group and AnchorGroups[group] and group or "general" 

	-- don't save the frame in WoWs cache, we handle it ourselves
	if (frame:IsMovable()) then
		frame:SetUserPlaced(false) -- disable saving in the on-disk frame cache
	end

	-- retrieve or create an anchor
	local anchor = table.remove(AnchorCache) or setmetatable(CreateFrame("Button", nil, UIParent), Anchor_MT)
	anchor:Hide() -- hiding early prevents some calculations, but they're fucked up without it, and will be fucked up later. WHAT THE FUCK?!?!
	anchor.owner = frame
	anchor.scale = frame:GetScale() -- current frame scale
	anchor.baseWidth = frame:GetWidth() -- unscaled width
	anchor.baseHeight = frame:GetHeight() -- unscaled height
	anchor.isResizable = true -- by default scalable
	anchor.db = db -- link to your saved variables, or any random table to store the position in
	anchor.default = { scale = frame:GetScale(), position = { GetNormalizedCoords(frame, true) --[[ point,x,y ]]} } -- TODO
	anchor.previous = nil -- erase this

	-- retrieve or create visible overlay
	local overlay = anchor.overlay or CreateFrame("Frame", nil, anchor, "BackdropTemplate")
	overlay:SetIgnoreParentScale(true) -- don't scale this
	overlay:SetPoint("TOPLEFT", -1, 1) -- these aligns perfectly with the texture edges, 
	overlay:SetPoint("BOTTOMRIGHT", 1, -1) -- so don't freaking change them for prettyness!
	overlay:SetBackdrop({
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
		edgeSize = 16, tile = true, tileSize = 16,
		insets = { left = 4, right = 3, top = 3, bottom = 4 }
	})
	anchor.overlay = overlay

	-- retrieve or create label text
	local label = anchor.label or overlay:CreateFontString(nil, "OVERLAY", nil, 1)
	label:SetScale(.75)
	label:SetDrawLayer("OVERLAY")
	label:SetFontObject(SystemFont_Outline_Med2) -- Friz 15 Outline
	label:SetPoint("CENTER", anchor, "CENTER", 0, 2)
	label:SetShadowColor(0, 0, 0, 0)
	label:SetShadowOffset(0, 0)
	label:SetTextColor(1, .82, .2, .72)
	anchor.label = label

	-- retrieve or create position text
	local position = anchor.position or overlay:CreateFontString(nil, "OVERLAY", nil, 1)
	position:SetScale(.75)
	position:SetDrawLayer("OVERLAY")
	position:SetFontObject(NumberFont_Outline_Med) -- Arial 14 Outline (Number12FontOutline)
	position:SetPoint("TOP", label, "BOTTOM", 0, -6)
	position:SetShadowColor(0, 0, 0, 0)
	position:SetShadowOffset(0, 0)
	position:SetTextColor(.7, .7, .7, .96)
	anchor.position = position

	anchor:SetFrameStrata("HIGH")
	anchor:SetFrameLevel(1000)
	anchor:SetSize(anchor.baseWidth, anchor.baseHeight)
	anchor:SetScale(anchor.scale)
	anchor:ClearAllPoints()
	anchor:SetPoint(GetNormalizedCoords(frame, true))

	anchor:RegisterForClicks("AnyUp", "AnyDown")
	anchor:RegisterForDrag("LeftButton")
	anchor:SetScript("OnShow", Anchor.OnShow)
	anchor:SetScript("OnDragStart", Anchor.OnDragStart)
	anchor:SetScript("OnDragStop", Anchor.OnDragStop)
	anchor:SetScript("OnMouseDown", Anchor.OnMouseDown)
	anchor:SetScript("OnMouseWheel", Anchor.OnMouseWheel)

	-- final setup
	anchor:EnableMouse(true)
	anchor:SetClampedToScreen(false)
	anchor:SetMovable(true)
	anchor:SetUserPlaced(false) -- disable saving in the on-disk frame cache, it messes with our system
	anchor:SetLabel(name or "") -- set the label, if any
	anchor:SetGroup(group) -- this also colors the anchor
	anchor:Hide() -- initially hide

	-- add to a groups
	Anchors[frame] = anchor
	AnchorGroups[group][anchor] = true
	AnchorGroups[anchor] = group

	-- restore last saved position, if any 
	if (IS_LOGGED_IN) then
		anchor:RestoreFromDB()
	end

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

--[[ RegisterMovableFrameGroup(self, group, r, g, b)
Shows all registered and active movable frame anchors.

* self      - the module registered for the event
* group - name of the new group <string>
* r         - <number> [0-1] red component of the group color 
* g         - <number> [0-1] green component of the group color 
* b         - <number> [0-1] blue component of the group color 
--]]
lib.RegisterMovableFrameGroup = function(_, group, r, g, b)
	if (AnchorGroups[group]) then 
		return 
	end
	AnchorGroups[group] = {}
	AnchorGroupColors[group] = { r, g, b }
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

--[[ ToggleAllMovableFrameAnchors(self)
Toggles all registered and active movable frame anchors.
--]]
lib.ToggleAllMovableFrameAnchors = function()
	if (InCombatLockdown()) then return end
	local shown
	for frame,anchor in next,Anchors do
		if (anchor:IsShown()) then
			shown = true -- if one is shown, consider all to be
			break
		end
	end
	for frame,anchor in next,Anchors do
		anchor:SetShown(not shown)
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

		-- Restore already registered frame anchors
		for frame,anchor in next,Anchors do
			anchor:RestoreFromDB()
		end

		-- Don't do this again
		IS_LOGGED_IN = true 

	elseif (event == "PLAYER_REGEN_DISABLED") then -- combat started, hide anchors
		lib:HideAllMovableFrameAnchors()
	end
end)

-- Always need this one
frame:RegisterEvent("PLAYER_REGEN_DISABLED")

-- Manually fire this if we're already logged in
-- *might happen with Load on Demand addons, though unlikely
if (IS_LOGGED_IN) then
	frame:GetScript("OnEvent")(frame, "PLAYER_LOGIN")
else
	frame:RegisterEvent("PLAYER_LOGIN")
end

local mixins = {
	RegisterMovableFrameAnchor = true,
	UnregisterMovableFrameAnchor = true,
	ShowAllMovableFrameAnchors = true,
	HideAllMovableFrameAnchors = true,
	ToggleAllMovableFrameAnchors = true
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
