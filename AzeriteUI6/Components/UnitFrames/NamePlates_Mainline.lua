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

local L = LibStub("AceLocale-3.0"):GetLocale((...))

local NamePlates = ns:NewModule("NamePlates", nil, "LibMoreEvents-1.0", "AceTimer-3.0")

-- Custom API locals
local AbbreviateNumber = ns.AbbreviateNumber
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia
local UnitIsUnit = ns.UnitIsUnit

local AllNamePlates, ActiveNamePlates, InActiveNamePlates = {}, {}, {}
local TargetNamePlate, FocusNamePlate
local SoftEnemyNamePlate, SoftFriendNamePlate, SoftInteractNamePlate

local IN_COMBAT

-- Our CVar settings
local cVars = {

	-- Distance
	nameplateMaxDistance = 20, 								-- The max distance to show nameplates. Practical hard cap 40-45. (Default 45)
	nameplatePlayerMaxDistance = 20, 						-- The max distance to show player nameplates. (Default 60)
	--nameplateMaxVerticalDistance = 0, 					-- Vertical cutoff (added in Forever beta). 0 disables the check. 

	-- Screen Insets
	nameplateOtherTopInset = .8, 							-- Screen-edge clamping. Set to -1 to disable.
	nameplateOtherBottomInset = .1, 						-- Same for bottom.
	nameplateLargeTopInset = .8, 							-- Same for larger plates
	nameplateLargeBottomInset = .1, 						-- Same for bottom
	nameplateOverlapH = .8, 								-- Overlap offsets.
	nameplateOverlapV = 1.1, 								-- Overlap offsets.

	--nameplateMotion = 0, 									-- Stacking behavior (0 = overlapping, 1 = stacking).
	--nameplateMotionSpeed = .025 							-- Stacking animation speed.
	--nameplateTargetBehindMaxDistance = .1, 				-- Target plate when behind camera.
	--nameplateTargetRadialPosition = 0, 					-- Radial positioning of target plate.

	-- Alpha
	nameplateMinAlpha = .6,									-- Distance-based minimum alpha. (Default .6) (.45 super immersive)
	nameplateMaxAlpha = .9,									-- Distance-based maximum alpha. (Default 1) (.75 very unintrusive)
	nameplateSelectedAlpha = 1, 							-- Selected nameplate alpha. (Default 1)
	nameplateNotSelectedAlpha = .6, 						-- Non-target alpha when having a target. (Default .6) (.4 for invisible ones)
	nameplateOccludedAlphaMult = .4, 						-- Alpha of occluded nameplates. (Behind walls, etc) (Default .4) (.3 for invisible ones)

	-- Scale
	nameplateSize = 2, 										-- Scale slider in the UI (1-5) (Default 1)
	nameplateMinScale = .6, 								-- Distance-based minimum scale. (Default .8) 
	nameplateMaxScale = .9,									-- Distance-based maximum scale. (Default 1)
	nameplateSelectedScale = 1.1, 							-- Extra scale on current target. (Default 1.2)
	nameplateGlobalScale = 1, 								-- Overall size multiplier. (Default 1) (Not really used anymore)
	nameplateSimplifiedScale = .6, 							-- Scale used for simplified nameplates. (Default .3)

	-- Visibility
	nameplateShowAll = 1, 									-- If true, nameplates are shown all the time. If false, nameplates are only shown in combat. (Default 0)

	-- Units
	nameplateShowEnemies = 1, 								-- Whether enemy nameplates are shown. (Default 1)
	nameplateShowEnemyGuardians = 1, 						-- Whether enemy guardian nameplates are shown. (Default 0)
	nameplateShowEnemyMinions = 1, 							-- Whether enemy minion nameplates are shown. (Default 0)
	nameplateShowEnemyMinus = 1, 							-- Whether enemy nameplates for entities with a minus sign (indicating they are weaker than the player) are shown. (Default 1)
	nameplateShowEnemyPets = 1, 							-- Whether enemy pet nameplates are shown. (Default 0)
	nameplateShowEnemyTotems = 1, 							-- Whether enemy totem nameplates are shown. (Default 0)
	nameplateShowFriendlyNpcs = 1, 							-- Whether nameplates are shown for friendly npcs. (Default 0)
	nameplateShowFriendlyPlayerGuardians = 1, 				-- Whether friendly player guardian nameplates are shown. (Default 0)
	nameplateShowFriendlyPlayerMinions = 1, 				-- Whether friendly player minion nameplates are shown. (Default 0)
	nameplateShowFriendlyPlayerPets = 1, 					-- Whether friendly player pet nameplates are shown. (Default 0)
	nameplateShowFriendlyPlayers = 1, 						-- Whether nameplates are shown for friendly players. (Default 0)
	nameplateShowFriendlyPlayerTotems = 1, 					-- Whether friendly player totem nameplates are shown.  (Default 0)

	-- Elements
	nameplateShowCastBars = 1, 								-- Show cast bars for unit nameplates. (Default 1)
	nameplateAuraScale = 1, 								-- Controls the size multiplier for buffs and debuffs on nameplates. (Default 1)

	-- Coloring
	nameplateShowClassColor = 1, 							-- Used to display the class color in enemy nameplate health bars (Default 1)
	nameplateShowFriendlyClassColor = 1, 					-- Used to display the class color in friendly nameplate health bars (Default 1)
	nameplateShowOnlyNameForFriendlyPlayerUnits = 1, 		-- Used to hide every part of the nameplate but the name for friendly player units. (Default 0)
	nameplateShowOnlyNameForFriendlyNPCUnits = 1, 			-- Only show the unit name for friendly NPC units (NOT A CVAR!)
	nameplateUseClassColorForFriendlyPlayerUnitNames = 1, 	-- Used to display the class color in friendly player unit nameplate names. (Default 0)
	nameplateUseReactionColorForFriendlyNPCUnitNames = 1, 	-- Reaction colored friendly NPC unitname (NOT A CVAR!)
}

-- Declare module defaults
-- *some of these are overwritten by saved blizzard settings on first run,
--  but the user can choose to restore "addon defaults" in the options menu. 
local defaults = { profile = {
	enabled = true
}}
-- Include our CVar listing
for cvarName,value in next,cVars do 
	defaults.profile[cvarName] = value
end

-- Cache of current targets (target, focus, softenemy, softinteract, softfriend)
local ActiveTargetPlates = {}

local timeFormatter = C_StringUtil.CreateNumericRuleFormatter()
timeFormatter:SetBreakpoints({
	-- ≥ 1 day
	{
		threshold = 86400,
		format = "%.0fd",
		components = {
			{ div = 86400, rounding = Enum.NumericRuleFormatRounding.Down },
		}
	},
	-- ≥ 1 hour
	{
		threshold = 3600,
		format = "%.0fh",
		components = {
			{ div = 3600, rounding = Enum.NumericRuleFormatRounding.Down },
		}
	},
	-- ≥ 1 minute
	{
		threshold = 60,
		format = "%.0fm",
		components = {
			{ div = 60, rounding = Enum.NumericRuleFormatRounding.Down },
		}
	},
	-- ≥ 5 seconds → whole seconds
	{
		threshold = 5.5,
		format = "%.0f",
		components = {
			{ div = 1, rounding = Enum.NumericRuleFormatRounding.Up },
		}
	},
	-- ≥ 1 second → whole seconds
	{
		threshold = .9,
		format = "|cffff8800%.0f|r",
		components = {
			{ div = 1, rounding = Enum.NumericRuleFormatRounding.Up },
		}
	},
	-- < 1 second, tenths of a second
	{
		threshold = .05,
		format = "|cffff0000%.0f|r",
		components = {
			{ div = 0.1, rounding = Enum.NumericRuleFormatRounding.Up },
		}
	},
	-- < 1/20 second
	{
		threshold = 0,
		format = ""
	}
})

-- Convert CVar values to booleans for menu usage 
local toboolean = function(a)
	local n = tonumber(a)
	if (n == 1) then return true
	elseif (n == 0) then return false
	else return not not n -- booleanify it
	end
end

-- Return a CVar, convert to number when appropriate
local GetCVar = function(cvar)
	local value = C_CVar.GetCVar(cvar)
	return tonumber(value) or value
end

-- Return a CVar default, convert to number when appropriate
local GetCVarDefault = function(cvar)
	local value = C_CVar.GetCVarDefault(cvar)
	return tonumber(value) or value
end

-- Check if unit is a player pet or minion
local UnitIsPet = function(unit)
	return UnitIsUnit(unit, "pet")          -- your own pet
		or UnitIsOtherPlayersPet(unit)      -- other players' pets
		or UnitIsMinion(unit)               -- minions / temporary summons (newer API)
end

-- Unit is a friendly player or AI pretending to be one
local UnitIsFriendlyPlayerUnit = function(unit)
	return (UnitIsPlayer(unit) or UnitInPartyIsAI(unit)) and not UnitCanAttack("player", unit)
end

-- Unit is a friendly NPC
local UnitIsFriendlyNPC = function(unit)
	return not UnitIsPlayer(unit) and not UnitCanAttack("player", unit)	
end

-- Do we need a single nameplate version? Isn't the problem flags not getting cleared on non-targets? 
local UpdateActiveTargets = function(self, event, unit)
end

-- Update all target units
local UpdateAllActiveTargets = function(event)

	local hasTarget = UnitExists("target")
	local hasFocus = UnitExists("target")
	local hasEnemy = UnitExists("softenemy")
	local hasFriend = UnitExists("softfriend")
	local hasInteract = UnitExists("softinteract")

	-- Iterate all plates for relevant units, clear flags on all others
	local targetUnit, focusUnit, enemyUnit, friendUnit, interactUnit
	for nameplate in next,ActiveNamePlates do
		if (hasTarget and not targetUnit and UnitIsUnit(nameplate.__unit, "target")) then
			targetUnit = nameplate.__unit
			nameplate.isTarget = true
		else
			nameplate.isTarget = false
		end
		if (hasFocus and not focusUnit and UnitIsUnit(nameplate.__unit, "focus")) then
			focusUnit = nameplate.__unit
			nameplate.isFocus = true
		else
			nameplate.isFocus = false
		end
		if (hasEnemy and not enemyUnit and UnitIsUnit(nameplate.__unit, "softenemy")) then
			enemyUnit = nameplate.__unit
			nameplate.isSoftEnemy = true
		else
			nameplate.isSoftEnemy = false
		end
		if (hasFriend and not friendUnit and UnitIsUnit(nameplate.__unit, "softfriend")) then
			friendUnit = nameplate.__unit
			nameplate.isSoftFriend = true
		else
			nameplate.isSoftFriend = false
		end
		if (hasInteract and not interactUnit and UnitIsUnit(nameplate.__unit, "softinteract")) then
			interactUnit = nameplate.__unit
			nameplate.isSoftInteract = true
		else
			nameplate.isSoftInteract = false
		end
	end

	ActiveTargetPlates.target = hasTarget and targetUnit
	ActiveTargetPlates.focus = hasFocus and focusUnit
	ActiveTargetPlates.softenemy = hasEnemy and enemyUnit
	ActiveTargetPlates.softfriend = hasFriend and friendUnit
	ActiveTargetPlates.softinteract = hasInteract and interactUnit
end

-- Update NPC classification badge for rares, elites and bosses.
local Classification_Update = function(self, event, unit, ...)
	if (event and unit ~= self.__unit) then return end -- when called as an event
	unit = unit or self.__unit -- not always called by an event handler

	local element = self.Classification

	if (UnitIsPlayer(unit) or not UnitCanAttack("player", unit)) then
		element:SetTexture("")
		element:SetWidth(.01)
		return
	end

	local l = UnitEffectiveLevel(unit)
	local c = (l and l < 1) and "worldboss" or UnitClassification(unit)
	if (c == "boss" or c == "worldboss") then
		element:SetWidth(40)
		element:SetTexture(element.bossTexture)

	elseif (c == "elite") then
		element:SetWidth(40)
		element:SetTexture(element.eliteTexture)

	elseif (c == "rare" or c == "rareelite") then
		element:SetWidth(40)
		element:SetTexture(element.rareTexture)
	else
		-- "minus"
		element:SetTexture("")
		element:SetWidth(.01)
	end
end

-- Update targeting highlight outline
-- *priority order is target, focus, softenemy, softinteract
local TargetHighlight_Update = function(self, event, unit, ...)
	if (unit ~= self.__unit) then return end

	local element = self.TargetHighlight

	if (self.isTarget) then
		element:SetVertexColor(255/255, 239/255, 169/255)
		element:Show()

	elseif (self.isFocus) then
		element:SetVertexColor(144/255, 195/255, 255/255)
		element:Show()

	elseif (self.isSoftEnemy) then
		element:SetVertexColor(255/255, 250/255, 236/255)
		element:Show()

	elseif (self.isSoftInteract) then
		element:SetVertexColor(185/255, 255/255, 182/255)
		element:Show()
	else
		element:Hide()
	end
end

local GetNamePlateScale = function()
	local entry = NamePlateConstants.NAME_PLATE_SCALES[(tonumber(C_CVar.GetCVar("nameplateSize")) or Enum.NamePlateSize.Small)]
				or NamePlateConstants.NAME_PLATE_SCALES[Enum.NamePlateSize.Small]

	--return entry.horizontal / NamePlateConstants.NAME_PLATE_SCALES[Enum.NamePlateSize.Small].horizontal
	return entry.horizontal
end

-- Hook used to fade out nameplates along with UIParent. Not sure it's always a good idea.
local NamePlate_UpdateAlpha = function(self)
	--self:SetAlpha(UIParent:GetAlpha())
end

local NamePlate_UpdateScale = function(self)
	self:SetScale(GetNamePlateScale() or 1)
	self:ClearAllPoints()
	self:SetPoint("BOTTOM")
end

-- Update visibility and elements based on CVar changes
-- *todo: update on faction changes / quest mobs becoming attackable
local NamePlate_PostUpdateElements = function(self, event, unit)
	unit = unit or self.__unit

	local db = NamePlates.db.profile

	local isFriendlyPlayer = UnitIsFriendlyPlayerUnit(unit)
	local isFriendlyNPC = UnitIsFriendlyNPC(unit)

	local isPriorityUnit = self.isTarget or self.isFocus or self.isSoftInteract or self.isSoftEnemy or self.isSoftFriend

	local onlyShowName = isFriendlyPlayer and not isPriorityUnit and db.nameplateShowOnlyNameForFriendlyPlayerUnits
	local onlyShowNPCName = isFriendlyNPC and not isPriorityUnit and db.nameplateShowOnlyNameForFriendlyNPCUnits

	local shouldClassColorName = db.nameplateUseClassColorForFriendlyPlayerUnitNames
	local shouldClassColorNPCName = db.nameplateUseReactionColorForFriendlyNPCUnitNames

	if (onlyShowName or onlyShowNPCName) then
		self.Name:SetAlpha(1)
		self.Name:SetFontObject(self.Name.fontObjectLarge)
		self.Health:Hide()
		self.AurasHarmful:Hide()
		self.AurasHelpful:Hide()
		self.AurasCC:Hide()
		self.Classification:Hide()

		self:DisableElement("Castbar")
	else
		self.Name:SetAlpha(.75)
		self.Name:SetFontObject(self.Name.fontObject)
		self.Health:Show()
		self.AurasHarmful:Show()
		self.AurasHelpful:Show()
		self.AurasCC:Show()
		self.Classification:Show()

		self:EnableElement("Castbar")
	end

	-- Update name coloring
	if (onlyShowName and shouldClassColorName) then
		local color
		local _, class = UnitClass(unit)
		if(issecretvalue(class)) then
			-- BUG: we can't use custom colors if the class is secret
			-- https://github.com/oUF-wow/oUF/issues/873
			color = C_ClassColor.GetClassColor(class)
		else
			color = self.colors.class[class]
		end
		if (color) then
			self.Name:SetTextColor(color:GetRGB())
		else
			self.Name:SetTextColor(self.colors.highlight:GetRGB())
		end
	elseif (onlyShowNPCName and shouldClassColorNPCName) then
		if (UnitReaction(unit, "player")) then 
			self.Name:SetTextColor(self.colors.reaction[UnitReaction(unit, "player")]:GetRGB())
		else
			self.Name:SetTextColor(self.colors.highlight:GetRGB())
		end
	else
		self.Name:SetTextColor(self.colors.highlight:GetRGB())
	end

	NamePlate_UpdateScale(self)
	Classification_Update(self, event, unit)
	TargetHighlight_Update(self, event, unit)
end

-- This is called on UpdateAllElements,
-- which is called when a frame is shown or when its unit changed.
local NamePlate_PostUpdate = function(self, event, unit)
	-- Too spammy here? Will fire for ALL nameplates, on every nameplate update. 
	-- Make a single nameplate version? Still have to do all the checks.
	UpdateAllActiveTargets(event) 

	NamePlate_UpdateAlpha(self, event, unit or self.__unit)
	NamePlate_PostUpdateElements(self, event, unit or self.__unit)
end

-- When a unit nameplate becomes visible on-screen. (NAME_PLATE_UNIT_ADDED)
-- *not related to nameplate creation, as that only triggers once per plate.
local NamePlate_OnShow = function(self, event, unit)

	self.inCombat = IN_COMBAT

	ActiveNamePlates[self] = true
	InActiveNamePlates[self] = nil

	-- NamePlate_PostUpdate fires after this.
end

-- When a unit nameplate is removed from the screen. (NAME_PLATE_UNIT_REMOVED)
local NamePlate_OnHide = function(self, event, unit)

	self.inCombat = nil

	ActiveNamePlates[self] = nil
	InActiveNamePlates[self] = true

	-- On hide we need to call this manually. 
	NamePlate_PostUpdate(self, event, unit)
end

local NamePlate_OnEvent = function(self, event, unit, ...)
	if (unit and unit ~= self.__unit) then return end

	unit = unit or self.__unit

	NamePlate_PostUpdateElements(self, event, unit, ...)
end

local style = function(self, unit)

	AllNamePlates[self] = true

	-- Looks dumb on most things, remove it for now? 
	-- *one problem, amongst many, is that it can show an extra question mark for trivial quests 
	--  even if we have chosen through the settings to hide trivial quests.
	local parent = self:GetParent()
	local realUnitFrame = parent and parent.UnitFrame and parent.UnitFrame
	if (realUnitFrame and realUnitFrame.SoftTargetFrame) then
		self.SoftTargetFrame = realUnitFrame.SoftTargetFrame
		self.SoftTargetFrame:SetPoint("BOTTOM", UIParent, "TOP", 0, 100) -- off-screen. goodbye. (default: "BOTTOM", self, "TOP", 0, -8)
	end

	-- General frame settings
	self:SetSize(90, 32)
	self:ClearAllPoints()
	self:SetPoint("BOTTOM") -- other anchorpoints create weirdness when plates change size or scale
	self:SetFrameLevel(self:GetFrameLevel() + 5)

	-- Frame for font Overlays
	local overlay = CreateFrame("Frame", nil, self)
	overlay:SetFrameLevel(self:GetFrameLevel() + 7)
	overlay:SetAllPoints()

	-- Health bar
	local health = CreateFrame("StatusBar", nil, self)
	health:SetSize(84, 22)
	health:SetPoint("TOP", 0, -2)
	health:SetStatusBarTexture(GetMedia("nameplate_bar_scaled"))
	
	-- Health background
	local healthBg = health:CreateTexture(nil, "BACKGROUND")
	healthBg:SetSize(94, 25)
	healthBg:SetPoint("CENTER", 0, 0)
	healthBg:SetTexture(GetMedia("nameplate_backdrop"))
	healthBg:SetVertexColor(1, 1, 1, .9)

	-- Options
	health.colorDisconnected = true
	health.colorHealth = true
	health.colorTapping = true
	health.colorThreat = true
	health.colorClass = false -- true
	health.colorClassPet = false -- true
	health.colorHappiness = true
	health.colorReaction = true
	health.frequentUpdates = true

	self.Health = health
	self.Health.Backdrop = healthBg
	self.Health.UpdateColor = ns.Health_UpdateColor -- work around secret bug in oUF

	-- Castbar
	--------------------------------------------
	local castbar = CreateFrame("StatusBar", nil, overlay)
	castbar:SetFrameLevel(castbar:GetFrameLevel() + 5)
	castbar:SetSize(84, 22)
	castbar:SetPoint("TOP", health, "BOTTOM", 0, 9)
	castbar:SetStatusBarTexture(GetMedia("nameplate_bar_scaled"))
	castbar:SetStatusBarColor(self.colors.normal:GetRGB())
	castbar.timeToHold = .5

	local castBackdrop = castbar:CreateTexture(nil, "BACKGROUND", nil, -1)
	castBackdrop:SetSize(94, 25)
	castBackdrop:SetPoint("CENTER", 0, 0)
	castBackdrop:SetTexture(GetMedia("nameplate_backdrop"))
	castBackdrop:SetAlpha(.96)

	local castText = castbar:CreateFontString(nil, "OVERLAY", nil, 1)
	castText:SetPoint("TOP", castbar, "BOTTOM", 0, 4)
	castText:SetJustifyH("CENTER")
	castText:SetJustifyV("MIDDLE")
	castText:SetFontObject(GetFont(11, true))
	castText:SetTextColor(self.colors.highlight:GetRGB())
	castText:SetAlpha(.75)
	castText:SetScale(.9)

	self.Castbar = castbar
	self.Castbar.Backdrop = castBackdrop
	self.Castbar.Text = castText

	-- Name
	local name = overlay:CreateFontString(nil, "OVERLAY")
	name:SetPoint("BOTTOM", health, "TOP", 0, -2)
	name:SetFontObject(GetFont(11, true))
	name:SetTextColor(self.colors.highlight:GetRGB())
	name:SetAlpha(.75)
	name:SetJustifyH("CENTER")
	name:SetJustifyV("MIDDLE")
	name.fontObject = GetFont(11, true)
	name.fontObjectLarge = GetFont(13, true)

	self:Tag(name, "[name]")

	self.Name = name

	-- Target highlight
	local targetHighlight = overlay:CreateTexture(nil, "BACKGROUND", nil, -2)
	targetHighlight:Hide()
	targetHighlight:SetPoint("CENTER", health, "CENTER", 0, 0)
	targetHighlight:SetSize(96, 28)
	targetHighlight:SetTexture(GetMedia("nameplate_outline"))

	self.TargetHighlight = targetHighlight

	-- Level (right)
	--local level = health:CreateFontString(nil, "OVERLAY")
	--level:SetPoint("LEFT", health, "RIGHT", 4, 0)
	--level:SetFontObject(GetFont(11, true))
	--level:SetAlpha(.85)
	--level:SetJustifyH("CENTER")
	--level:SetJustifyV("MIDDLE")

	--self:Tag(level, "[azui:level]")

	local raidTarget = self:CreateTexture(nil, "OVERLAY", nil, 1)
	raidTarget:SetSize(48, 48)
	raidTarget:SetPoint("BOTTOM", self, "TOP", 0, 16)
	raidTarget:SetTexture(GetMedia("raid_target_icons"))
	raidTarget:SetIgnoreParentAlpha(true)
	raidTarget:SetIgnoreParentScale(true)

	self.RaidTargetIndicator = raidTarget

	-- Classification Badge (elite, rare)(left)
	local classification = overlay:CreateTexture(nil, "BACKGROUND", nil, 2)
	classification:SetSize(40, 40)
	classification:SetPoint("RIGHT", health, "RIGHT", 20, -1)
	classification.bossTexture = GetMedia("icon_badges_boss")
	classification.eliteTexture = GetMedia("icon_classification_elite")
	classification.rareTexture = GetMedia("icon_classification_rare")

	self.Classification = classification


	-- Top: The player's running DoTs and Debuffs (nameplateShowPersonal)
	local aurasHarmful = self:CreateAuras()
	aurasHarmful:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", -8, 10)
	aurasHarmful:SetWidth(100)
	aurasHarmful:SetFrameLevel(self:GetFrameLevel() + 15)
	aurasHarmful:AddGroup("HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL", {
		candidateFilters = {
			nameplateShowPersonal = true,
			excludeSpellIDs = {
			}
		},
		maxFrameCount = 4, -- blizz default
		initializeFrame = ns.AuraButton_InitializeNamePlateDebuff,
		layout = {
			elementSpacing = 4, -- horizontal gap between icons
			lineSpacing = 4 -- vertical gap between rows
		}
	})

	self.AurasHarmful = aurasHarmful

	-- Right: Important buffs (nameplateShowAll)
	local aurasHelpful = self:CreateAuras()
	aurasHelpful:SetPoint("LEFT", self.Classification, "RIGHT", 4, 1)
	aurasHelpful:SetFrameLevel(self:GetFrameLevel() + 15)
	aurasHelpful:AddGroup("HELPFUL|INCLUDE_NAME_PLATE_ONLY", {
		candidateFilters = {
			nameplateShowAll = true,
			excludeSpellIDs = {}
		},
		maxFrameCount = 2,
		initializeFrame = ns.AuraButton_InitializeNamePlateBuff,
		layout = {
			elementSpacing = 4,
			lineSpacing = 4
		}
	})

	self.AurasHelpful = aurasHelpful

	-- Left: Crowd Control
	local aurasCC = self:CreateAuras()
	aurasCC:SetPoint("RIGHT", self.Health, "LEFT", -4, 0)
	aurasCC:SetFrameLevel(self:GetFrameLevel() + 15)
	aurasCC:AddGroup("HARMFUL|CROWD_CONTROL", {
		candidateFilters = {
			excludeSpellIDs = {
			}
		},
		maxFrameCount = 2,
		initializeFrame = ns.AuraButton_InitializeNamePlateCC,
		layout = {
			elementSpacing = 4,
			lineSpacing = 4,
			growthX = "LEFT",
		},
	})

	self.AurasCC = aurasCC

	-- Make our nameplates obey UIParent alpha and fade out when Dialogue UI and Immersion say so.
	hooksecurefunc(UIParent, "SetAlpha", function() NamePlate_UpdateAlpha(self) end)

	-- Callbacks
	--------------------------------------------
	self:RegisterEvent("UNIT_FACTION", NamePlate_OnEvent)
	self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED", NamePlate_OnEvent)

	-- General PostUpdate
	self.PostUpdate = NamePlate_PostUpdate
end

NamePlates.LoadSettingFromCVar = function(self, cvarName, value)
	if (self.db.profile[cvarName]) then
		self.db.profile[cvarName] = value or GetCVar(cvarName) or defaults.profile[cvarName] 
	end
end

NamePlates.LoadSettingsFromCVars = function(self)
	if (InCombatLockdown()) then return end

	for cvarName,value in next,cVars do 
		self.db.profile[cvarName] = GetCVar(cvarName) or defaults.profile[cvarName]
	end
end

NamePlates.SaveSettingsToCVars = function(self)
	if (InCombatLockdown()) then return end

	for cvarName,value in next,cVars do 
		C_CVar.SetCVar(cvarName, self.db.profile[cvarName])	
	end
end

NamePlates.RestoreDefaults = function(self)
	if (InCombatLockdown()) then return end

	for cvarName,value in next,cVars do 
		self.db.profile[cvarName] = defaults.profile[cvarName]
	end

	self:SaveSettingsToCVars()
end

NamePlates.RestoreBlizzardDefaults = function(self)
	if (InCombatLockdown()) then return end

	for cvarName,value in next,cVars do 
		self.db.profile[cvarName] = GetCVarDefault(cvarName) or defaults.profile[cvarName]
	end

	self:SaveSettingsToCVars()
end

NamePlates.OnEvent = function(self, event, ...)
	if (event == "VARIABLES_LOADED") then
		self.variablesLoaded = true  -- flag to indicate variables now are loaded

		self:LoadSettingsFromCVars() -- load saved CVars into our saved settings
		self:UpdateSettings() -- update addon settings
		self:UnregisterEvent("VARIABLES_LOADED", "OnEvent") -- only do this once

	elseif (event == "CVAR_UPDATE") then
		local cvarName, value = ...

		-- Avoid a nightmare of mismatching lower and upper caps
		local settingsName
		for setting in next,defaults.profile do 
			if (string.lower(setting) == string.lower(cvarName)) then
				settingsName = setting
				break
			end
		end
		if (not settingsName or not self.db.profile[settingsName]) then return end
		
		self:LoadSettingFromCVar(settingsName, value)

		for nameplate in next,ActiveNamePlates do
			nameplate:UpdateAllElements("CVAR_UPDATE")
			NamePlate_PostUpdateElements(nameplate)
		end

	elseif (event == "PLAYER_ENTERING_WORLD") then
		IN_COMBAT = nil

	elseif (event == "PLAYER_REGEN_DISABLED") then
		IN_COMBAT = true

	elseif (event == "PLAYER_REGEN_ENABLED") then
		IN_COMBAT = nil

	elseif (event == "PLAYER_TARGET_CHANGED") 
		or (event == "PLAYER_FOCUS_CHANGED") 
		or (event == "PLAYER_SOFT_ENEMY_CHANGED") 
		or (event == "PLAYER_SOFT_FRIEND_CHANGED") 
		or (event == "PLAYER_SOFT_INTERACT_CHANGED") 
		or (event == "NAME_PLATE_UNIT_ADDED") 
		or (event == "NAME_PLATE_UNIT_REMOVED") then

		UpdateAllActiveTargets(event)

		for nameplate in next,ActiveNamePlates do
			NamePlate_PostUpdateElements(nameplate, event, nameplate.__unit)
		end
	end
end

NamePlates.GetDefaults = function(self)
	return defaults
end

NamePlates.GetOptions = function(self)
	return {
		type = "group",
		name = L["Unit Frame: Name Plates"],
		arg = { menuName = L["UF: Name Plates"] },
		order = 300,
		args = {
			enable = {
				type = "toggle", width = "full", dialogControl = "ModernCheckBox",
				name = L["Enable"],
				desc = L["Toggle the usage of our Name Plates. Note that disabling this will force a user interface reload to re-enable the game's default Name Plates."],
				disabled = function() return InCombatLockdown() end,
				get = function(info) return self.db.profile.enabled end,
				set = function(info, val) 
					if (InCombatLockdown()) then return end
					self.db.profile.enabled = val 
					self:UpdateSettings()
				end,
				order = 1
			},

			--nameplateShowAll = {
			--	type = "toggle", width = "full", dialogControl = "ModernCheckBox",
			--},
			nameplateShowEnemies = {
				type = "toggle", width = "full", dialogControl = "ModernCheckBox",
				name = "Show Enemy Unit Nameplates",
				desc = "",
				disabled = function() return InCombatLockdown() end,
				get = function(info) return toboolean(GetCVar("nameplateShowEnemies")) end, 
				set = function(info, val) 
					if (InCombatLockdown()) then return end
					SetCVar("nameplateShowEnemies", val and "1" or "0")
				end,
				order = 100,
			},
			nameplateShowEnemyMinions = {
				type = "toggle", width = "full", dialogControl = "ModernIndentedCheckBox",
				name = "Show Enemy Minions",
				desc = "",
				disabled = function() return InCombatLockdown() end,
				hidden = function() return not toboolean(GetCVar("nameplateShowEnemies")) end,
				get = function(info) return toboolean(GetCVar("nameplateShowEnemyMinions")) end, 
				set = function(info, val) 
					if (InCombatLockdown()) then return end
					SetCVar("nameplateShowEnemyMinions", val and "1" or "0")
					SetCVar("nameplateShowEnemyPets", val and "1" or "0")
					SetCVar("nameplateShowEnemyGuardians", val and "1" or "0")
				end,
				order = 101,
			},
			--nameplateShowEnemyPets = {
			--},
			--nameplateShowEnemyPets = 1, 							-- Whether enemy pet nameplates are shown. (Default 0)
			--nameplateShowEnemyGuardians = 1, 						-- Whether enemy guardian nameplates are shown. (Default 0)
			--nameplateShowEnemyMinions = 1, 							-- Whether enemy minion nameplates are shown. (Default 0)

			--nameplateShowEnemyTotems = 1, 							-- Whether enemy totem nameplates are shown. (Default 0)

			--nameplateShowEnemyMinus = 1, 							-- Whether enemy nameplates for entities with a minus sign (indicating they are weaker than the player) are shown. (Default 1)

			--nameplateShowFriends = {
			--},
			
			
			
			--nameplateShowAll = {},
			--nameplateShowAll = {},
			--nameplateShowAll = {},
			--nameplateShowAll = {},
			--nameplateShowAll = {},
			--nameplateShowAll = {},
			--nameplateShowAll = {},
			--nameplateShowAll = {},
			--nameplateShowAll = {},
			--nameplateShowAll = {},
			--nameplateShowAll = {},
			--nameplateShowAll = {},


			nameplateSize = {
				type = "range", width = "full", min = Enum.NamePlateSize.Small, max = Enum.NamePlateSize.Huge, step = 1, bigStep = 1, dialogControl = "ModernSlider",
				name = "General Size", -- UNIT_NAMEPLATES_GLOBAL_SCALE, "Size"
				desc = UNIT_NAMEPLATES_GLOBAL_SCALE_TOOLTIP, -- "Controls the size nameplates are displayed on the screen."
				disabled = function() return InCombatLockdown() end,
				hidden = function() return not self.db.profile.enabled end,
				get = function()
					return tonumber(C_CVar.GetCVar(NamePlateConstants and NamePlateConstants.SIZE_CVAR or "nameplateSize")) or Enum.NamePlateSize.Small
				end,
				set = function(_, value)
					if (InCombatLockdown()) then return end
					C_CVar.SetCVar(NamePlateConstants and NamePlateConstants.SIZE_CVAR or "nameplateSize", (math.floor(value + .5)))
				end,
				order = 1000,
			},
			nameplateSelectedScale = {
				type = "range", width = "full", min = 1, max = 1.4, step = .05, dialogControl = "ModernSlider",
				name = L["Selected NamePlate Scale"],
				desc = L["Sets the scale of your current target."],
				disabled = function() return InCombatLockdown() end,
				hidden = function() return not self.db.profile.enabled end,
				get = function() return tonumber(C_CVar.GetCVar("nameplateSelectedScale")) end,
				set = function(_, value)
					if (InCombatLockdown()) then return end
					C_CVar.SetCVar("nameplateSelectedScale", value)
				end,
				order = 1001,
			},
			nameplateMinScale = {
				type = "range", width = "full", min = .4, max = 1, step = .05, dialogControl = "ModernSlider",
				name = L["Minimum Scale"],
				desc = L["The minimum scale based on distance. Does not apply to current target."],
				disabled = function() return InCombatLockdown() end,
				hidden = function() return not self.db.profile.enabled end,
				get = function() return tonumber(C_CVar.GetCVar("nameplateMinScale")) end,
				set = function(_, value)
					if (InCombatLockdown()) then return end
					C_CVar.SetCVar("nameplateMinScale", value)
				end,
				order = 1002,
			},
			nameplateMaxScale = {
				type = "range", width = "full", min = .6, max = 1, step = .05, dialogControl = "ModernSlider",
				name = L["Maximum Scale"],
				desc = L["The maximum scale based on distance. Does not apply to current target."],
				disabled = function() return InCombatLockdown() end,
				hidden = function() return not self.db.profile.enabled end,
				get = function() return tonumber(C_CVar.GetCVar("nameplateMaxScale")) end,
				set = function(_, value)
					if (InCombatLockdown()) then return end
					C_CVar.SetCVar("nameplateMaxScale", value)
				end,
				order = 1003,
			},
			nameplateSimplifiedScale = {
				type = "range", width = "full", min = .3, max = 1, step = .05, dialogControl = "ModernSlider",
				name = L["Simplified NamePlate Scale"],
				desc = L["Sets the scale of simplified NamePlates. Simplified NamePlates refer to critters and various other unimportant NPCs and creatures. Does not apply to current target."],
				disabled = function() return InCombatLockdown() end,
				hidden = function() return not self.db.profile.enabled end,
				get = function() return tonumber(C_CVar.GetCVar("nameplateSimplifiedScale")) end,
				set = function(_, value)
					if (InCombatLockdown()) then return end
					C_CVar.SetCVar("nameplateSimplifiedScale", value)
				end,
				order = 1004,
			},
			nameplateMaxDistance = {
				type = "range", width = "full", min = 5, max = (ns.WoWCamelot or ns.WoWVanilla) and 45 or 60, step = 1, bigStep = 1, dialogControl = "ModernSlider",
				name = L["Max Visibility Distance."],
				desc = (ns.WoWCamelot or ns.WoWVanilla) and L["Sets the maximum distance NamePlates are visible. Note that this has an effective cap of 20-45 in Forever and Classic Era."] or L["Sets the maximum distance NamePlates are visible. Note that this has an effective cap of 20-45 in Forever and Classic Era."],
				disabled = function() return InCombatLockdown() end,
				hidden = function() return not self.db.profile.enabled end,
				get = function() return tonumber(C_CVar.GetCVar("nameplateMaxDistance")) end,
				set = function(_, value)
					if (InCombatLockdown()) then return end
					C_CVar.SetCVar("nameplateMaxDistance", (math.floor(value + .5)))
					C_CVar.SetCVar("nameplatePlayerMaxDistance", (math.floor(value + .5)))
				end,
				order = 2000,
			},


			resetToGameDefaults = {
				type = "execute", width = "1.3",
				name = L["Game Defaults"],
				desc = L["Reset the NamePlate settings to the Game Defaults. Note that your current settings are not backed up, and will be lost if you click this button."],
				disabled = function() return InCombatLockdown() end,
				hidden = function() return not self.db.profile.enabled end,
				func = function(info) NamePlates:RestoreBlizzardDefaults() end,
				order = 100002
			},
			resetToAddOnDefault = {
				type = "execute", width = "1.3",
				name = L["Azerite Defaults"],
				desc = L["Reset the NamePlate settings to the Azerite UI Defaults. Note that your current settings are not backed up, and will be lost if you click this button."],
				disabled = function() return InCombatLockdown() end,
				hidden = function() return not self.db.profile.enabled end,
				func = function(info) NamePlates:RestoreDefaults() end,
				order = 100003
			},

			--[[--

			- general settings (color, elements, etc)

			- target nameplate specific settings
			- other plates specific settings when having a target 
			- all plates specific settings when not having a target

			--]]--
		}
	}
end

NamePlates.HasConflicts = function(self)
	for _,addon in next,{
		--"AzeriteUI6", -- doh
		"BetterBlizzPlates",
		"ClassicPlatesPlus",
		"Kui_Nameplates",
		"NamePlateKAI",
		"Nameplates",
		"NDui",
		"NeatPlates",
		"Plater",
		"SimplePlates",
		"TidyPlates",
		"TidyPlates_ThreatPlates",
		"TidyPlatesContinued" } do 
		if (C_AddOns.GetAddOnEnableState(addon, UnitGUID("player")) == Enum.AddOnEnableState.All) then
			return true
		end
	end
end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling and combat end.
NamePlates.UpdateSettings = function(self)
	if (not self.variablesLoaded) then return end

	-- These two only fires on manual settings changes
	if (self.db.profile.enabled) and (not self:IsEnabled()) then
		ReloadUI()
	
	elseif (not self.db.profile.enabled) and (self:IsEnabled()) then
		ReloadUI()
	end
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
NamePlates.RefreshConfig = function(self)
	self:UpdateSettings()
end

NamePlates.OnInitialize = function(self)
	if (self:HasConflicts()) then return self:Disable() end

	if (not C_AddOns.IsAddOnLoaded("Blizzard_NamePlates")) then
		C_AddOns.LoadAddOn("Blizzard_NamePlates")
	end

	self.db = ns.db:RegisterNamespace("NamePlates", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	self:RegisterEvent("VARIABLES_LOADED", "OnEvent")
end

NamePlates.OnEnable = function(self)
	if (not self.db.profile.enabled) then return self:Disable() end

	oUF:RegisterStyle("AzeriteNamePlates", style)
	oUF:Factory(function(self) 
		self:SetActiveStyle("AzeriteNamePlates")

		local nameplates = self:SpawnNamePlates("AzeriteNamePlate")
		nameplates:SetSize(90,32)
		nameplates:SetAddedCallback(NamePlate_OnShow)
		nameplates:SetRemovedCallback(NamePlate_OnHide)
	end)

	self:RegisterEvent("CVAR_UPDATE", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnEvent")
	self:RegisterEvent("PLAYER_FOCUS_CHANGED", "OnEvent")
	self:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED", "OnEvent")
	self:RegisterEvent("PLAYER_SOFT_FRIEND_CHANGED", "OnEvent")
	self:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED", "OnEvent")
end
