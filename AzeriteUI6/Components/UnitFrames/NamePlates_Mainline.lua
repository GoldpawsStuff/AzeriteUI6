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

local AllNamePlates, ActiveNamePlates, InActiveNamePlates = {}, {}, {}
local TargetNamePlate, FocusNamePlate
local SoftEnemyNamePlate, SoftFriendNamePlate, SoftInteractNamePlate

local IN_COMBAT

-- Declare module defaults
-- *some of these are overwritten by saved blizzard settings on first run,
--  but the user can choose to restore "addon defaults" in the options menu. 
local defaults = { profile = {
	enabled = true,

	nameplateMaxDistance = 20, 								-- Max display distance (yards). Practical hard cap 40-45. (Default 45)
	--nameplateMaxVerticalDistance = 0, 					-- Vertical cutoff (added in Forever beta). 0 disables the check. 

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

	nameplateMinAlpha = .45,								-- Distance-based minimum alpha. (Default .6)
	nameplateMaxAlpha = .75,								-- Distance-based maximum alpha. (Default 1)
	nameplateSelectedAlpha = 1, 							-- Selected nameplate alpha. (Default 1)
	nameplateNotSelectedAlpha = .4, 						-- Non-target alpha when having a target. (Default .6)
	nameplateOccludedAlphaMult = .3, 						-- Alpha of occluded nameplates. (Behind walls, etc) (Default .4)

	nameplateMinScale = .6, 								-- Distance-based minimum scale. (Default .8) 
	nameplateMaxScale = .9,									-- Distance-based maximum scale. (Default 1)
	nameplateSelectedScale = 1.1, 							-- Extra scale on current target. (Default 1.2)
	nameplateGlobalScale = 1, 								-- Overall size multiplier. (Default 1)

	nameplateShowClassColor = 1, 							-- Class colored enemy nameplates
	nameplateShowFriendlyClassColor = 0, 					-- Class colored friendly player nameplates
	nameplateShowOnlyNameForFriendlyPlayerUnits = 1, 		-- Only show the unit name for friendly player units
	nameplateShowOnlyNameForFriendlyNPCUnits = 1, 			-- Only show the unit name for friendly NPC units (NOT A CVAR!)
	nameplateUseClassColorForFriendlyPlayerUnitNames = 1, 	-- Class colored friendly player unitname
	nameplateUseReactionColorForFriendlyNPCUnitNames = 1, 	-- Reaction colored friendly NPC unitname (NOT A CVAR!)

	--[[--

	layout

	scale

	visibility

	showHostile = true,
		classColorHostilePlayer = true,
		showHostilePlayerMinion = true,
			showOnlyNameHostilePlayerMinion = false,
		showHostilePlayerMinor = true,
			showOnlyNameHostilePlayerMinor = true,

		reverseEnemyOrientation = true,

	showFriendly = true,
		showFriendlyNPC = true,
			showOnlyNameFriendlyNPC = true,
			reactionColorFriendlyNPCName = true,
		showFriendlyPlayer = true,
			showOnlyNameFriendlyPlayer = true,
			classColorFriendlyPlayer = false, 
			classColorFriendlyPlayerName = true,
		showFriendlyPlayerMinion = true,
			showOnlyNameFriendlyPlayerMinion = true,


		showAuras




	--]]--
}}

-- Cache of current targets
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

-- Player-applied debuffs (top)
local AuraButton_Initialize = function(button)
	local icon = button:CreateTexture(nil, "BORDER")
	icon:SetAllPoints()
	icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	button.Icon = icon

	local backdrop = button:CreateTexture(nil, "BACKGROUND")
	backdrop:SetAllPoints()
	backdrop:SetColorTexture(1, 1, 1, 1)
	backdrop:SetVertexColor(.15, .15, .15, .7)
	button.Backdrop = backdrop

	local border = CreateFrame("Frame", nil, button, "BackdropTemplate")
	border:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 12 })
	border:SetBackdropBorderColor(oUF.colors.verydarkgray:GetRGB())
	border:SetPoint("TOPLEFT", -6, 6)
	border:SetPoint("BOTTOMRIGHT", 6, -6)
	border:SetFrameLevel(button:GetFrameLevel() + 2)
	button.Border = border

	local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cooldown:SetAllPoints()
	cooldown:SetHideCountdownNumbers(true)
	cooldown:SetDrawBling(false)
	cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
	button.Cooldown = cooldown

	local time = border:CreateFontString(nil, "OVERLAY")
	time:SetFontObject(GetFont(11, true))
	time:SetPoint("CENTER", button, "TOPLEFT", 0, 0)
	button.Time = time

	button:SetSize(22, 22)
	button:SetIcon(icon)
	button:SetDurationCooldown(cooldown)
	button:SetDurationText(time, { textFormatter = timeFormatter })
end

local AuraButton_InitializeSmall = function(button)
	local icon = button:CreateTexture(nil, "BORDER")
	icon:SetAllPoints()
	icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	button.Icon = icon

	local backdrop = button:CreateTexture(nil, "BACKGROUND")
	backdrop:SetAllPoints()
	backdrop:SetColorTexture(1, 1, 1, 1)
	backdrop:SetVertexColor(.15, .15, .15, .7)
	button.Backdrop = backdrop

	local border = CreateFrame("Frame", nil, button, "BackdropTemplate")
	border:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 12 })
	border:SetBackdropBorderColor(oUF.colors.verydarkgray:GetRGB())
	border:SetPoint("TOPLEFT", -6, 6)
	border:SetPoint("BOTTOMRIGHT", 6, -6)
	border:SetFrameLevel(button:GetFrameLevel() + 2)
	button.Border = border

	local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cooldown:SetAllPoints()
	cooldown:SetHideCountdownNumbers(true)
	cooldown:SetDrawBling(false)
	cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
	button.Cooldown = cooldown

	local time = border:CreateFontString(nil, "OVERLAY")
	time:SetFontObject(GetFont(11, true))
	time:SetPoint("CENTER", button, "TOPLEFT", 0, 0)
	button.Time = time

	button:SetSize(18, 18)
	button:SetIcon(icon)
	button:SetDurationCooldown(cooldown)
	button:SetDurationText(time, { textFormatter = timeFormatter })
end

-- Unit comparison compatible with secrets
local UnitIsUnit = function(unit1, unit2)
	return unit1 and unit2 and C_Secrets.CanCompareUnitTokens(unit1, unit2) and _G.UnitIsUnit(unit1, unit2) -- use the global
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

-- Update the target units
local UpdateActiveTargets = function(event)

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

	ActiveTargetPlates.target = targetUnit
	ActiveTargetPlates.focus = focusUnit
	ActiveTargetPlates.softenemy = enemyUnit
	ActiveTargetPlates.softfriend = friendUnit
	ActiveTargetPlates.softinteract = interactUnit
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

local NamePlate_UpdateAlpha = function(self)
	self:SetAlpha(UIParent:GetAlpha())
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

	Classification_Update(self, event, unit)
	TargetHighlight_Update(self, event, unit)
end

-- This is called on UpdateAllElements,
-- which is called when a frame is shown or when its unit changed.
local NamePlate_PostUpdate = function(self, event, unit)
	NamePlate_UpdateAlpha(self, event, unit or self.__unit)
	UpdateActiveTargets(event) -- too spammy here?
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
	self:SetSize(90, 26)
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
	self.Health.UpdateColor = ns.UpdateHealthColor -- work around secret bug in oUF

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
	aurasHarmful:AddGroup("HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL", {
		candidateFilters = {
			nameplateShowPersonal = true,
			excludeSpellIDs = {
			}
		},
		maxFrameCount = 4, -- blizz default
		initializeFrame = AuraButton_Initialize,
		layout = {
			elementSpacing = 4, -- horizontal gap between icons
			lineSpacing = 4 -- vertical gap between rows
		}
	})

	self.AurasHarmful = aurasHarmful

	-- Right: Important buffs (nameplateShowAll)
	local aurasHelpful = self:CreateAuras()
	aurasHelpful:SetPoint("LEFT", self.Classification, "RIGHT", 4, 1)
	aurasHelpful:AddGroup("HELPFUL|INCLUDE_NAME_PLATE_ONLY", {
		candidateFilters = {
			nameplateShowAll = true,
			excludeSpellIDs = {}
		},
		maxFrameCount = 2,
		initializeFrame = AuraButton_InitializeSmall,
		layout = {
			elementSpacing = 4,
			lineSpacing = 4
		}
	})

	self.AurasHelpful = aurasHelpful

	-- Left: Crowd Control
	local aurasCC = self:CreateAuras()
	aurasCC:SetPoint("RIGHT", self.Health, "LEFT", -4, 0)
	aurasCC:AddGroup("HARMFUL|CROWD_CONTROL", {
		candidateFilters = {
			excludeSpellIDs = {
			}
		},
		maxFrameCount = 2,
		initializeFrame = AuraButton_InitializeSmall,
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

	self.db.profile.nameplateMaxDistance = GetCVar("nameplateMaxDistance") or defaults.profile.nameplateMaxDistance 
	self.db.profile.nameplateOtherTopInset = GetCVar("nameplateOtherTopInset") or defaults.profile.nameplateOtherTopInset 
	self.db.profile.nameplateOtherBottomInset = GetCVar("nameplateOtherBottomInset") or defaults.profile.nameplateOtherBottomInset 
	self.db.profile.nameplateLargeTopInset = GetCVar("nameplateLargeTopInset") or defaults.profile.nameplateLargeTopInset 
	self.db.profile.nameplateLargeBottomInset = GetCVar("nameplateLargeBottomInset") or defaults.profile.nameplateLargeBottomInset 
	self.db.profile.nameplateOverlapH = GetCVar("nameplateOverlapH") or defaults.profile.nameplateOverlapH 
	self.db.profile.nameplateOverlapV = GetCVar("nameplateOverlapV") or defaults.profile.nameplateOverlapV 
	self.db.profile.nameplateMinAlpha = GetCVar("nameplateMinAlpha") or defaults.profile.nameplateMinAlpha 
	self.db.profile.nameplateMaxAlpha = GetCVar("nameplateMaxAlpha") or defaults.profile.nameplateMaxAlpha 
	self.db.profile.nameplateSelectedAlpha = GetCVar("nameplateSelectedAlpha") or defaults.profile.nameplateSelectedAlpha 
	self.db.profile.nameplateNotSelectedAlpha = GetCVar("nameplateNotSelectedAlpha") or defaults.profile.nameplateNotSelectedAlpha 
	self.db.profile.nameplateOccludedAlphaMult = GetCVar("nameplateOccludedAlphaMult") or defaults.profile.nameplateOccludedAlphaMult 
	self.db.profile.nameplateMinScale = GetCVar("nameplateMinScale") or defaults.profile.nameplateMinScale 
	self.db.profile.nameplateMaxScale = GetCVar("nameplateMaxScale") or defaults.profile.nameplateMaxScale 
	self.db.profile.nameplateSelectedScale = GetCVar("nameplateSelectedScale") or defaults.profile.nameplateSelectedScale 
	self.db.profile.nameplateGlobalScale = GetCVar("nameplateGlobalScale") or defaults.profile.nameplateGlobalScale 
	self.db.profile.nameplateShowClassColor = GetCVar("nameplateShowClassColor") or defaults.profile.nameplateShowClassColor 
	self.db.profile.nameplateShowFriendlyClassColor = GetCVar("nameplateShowFriendlyClassColor") or defaults.profile.nameplateShowFriendlyClassColor 
	self.db.profile.nameplateUseClassColorForFriendlyPlayerUnitNames = GetCVar("nameplateUseClassColorForFriendlyPlayerUnitNames") or defaults.profile.nameplateUseClassColorForFriendlyPlayerUnitNames 
end

NamePlates.SaveSettingsToCVars = function(self)
	if (InCombatLockdown()) then return end

	C_CVar.SetCVar("nameplateMaxDistance", self.db.profile.nameplateMaxDistance)
	C_CVar.SetCVar("nameplateOtherTopInset", self.db.profile.nameplateOtherTopInset)
	C_CVar.SetCVar("nameplateOtherBottomInset", self.db.profile.nameplateOtherBottomInset)
	C_CVar.SetCVar("nameplateLargeTopInset", self.db.profile.nameplateLargeTopInset)
	C_CVar.SetCVar("nameplateLargeBottomInset", self.db.profile.nameplateLargeBottomInset)
	C_CVar.SetCVar("nameplateOverlapH", self.db.profile.nameplateOverlapH)
	C_CVar.SetCVar("nameplateOverlapV", self.db.profile.nameplateOverlapV)
	C_CVar.SetCVar("nameplateMinAlpha", self.db.profile.nameplateMinAlpha)
	C_CVar.SetCVar("nameplateMaxAlpha", self.db.profile.nameplateMaxAlpha)
	C_CVar.SetCVar("nameplateSelectedAlpha", self.db.profile.nameplateSelectedAlpha)
	C_CVar.SetCVar("nameplateNotSelectedAlpha", self.db.profile.nameplateNotSelectedAlpha)
	C_CVar.SetCVar("nameplateOccludedAlphaMult", self.db.profile.nameplateOccludedAlphaMult)
	C_CVar.SetCVar("nameplateMinScale", self.db.profile.nameplateMinScale)
	C_CVar.SetCVar("nameplateMaxScale", self.db.profile.nameplateMaxScale)
	C_CVar.SetCVar("nameplateSelectedScale", self.db.profile.nameplateSelectedScale)
	C_CVar.SetCVar("nameplateGlobalScale", self.db.profile.nameplateGlobalScale)
	C_CVar.SetCVar("nameplateShowClassColor", self.db.profile.nameplateShowClassColor)
	C_CVar.SetCVar("nameplateShowFriendlyClassColor", self.db.profile.nameplateShowFriendlyClassColor)
	C_CVar.SetCVar("nameplateUseClassColorForFriendlyPlayerUnitNames", self.db.profile.nameplateUseClassColorForFriendlyPlayerUnitNames)
end

NamePlates.RestoreDefaults = function(self)
	if (InCombatLockdown()) then return end

	self.db.profile.nameplateMaxDistance = defaults.profile.nameplateMaxDistance
	self.db.profile.nameplateOtherTopInset = defaults.profile.nameplateOtherTopInset
	self.db.profile.nameplateOtherBottomInset = defaults.profile.nameplateOtherBottomInset
	self.db.profile.nameplateLargeTopInset = defaults.profile.nameplateLargeTopInset
	self.db.profile.nameplateLargeBottomInset = defaults.profile.nameplateLargeBottomInset
	self.db.profile.nameplateOverlapH = defaults.profile.nameplateOverlapH
	self.db.profile.nameplateOverlapV = defaults.profile.nameplateOverlapV
	self.db.profile.nameplateMinAlpha = defaults.profile.nameplateMinAlpha
	self.db.profile.nameplateMaxAlpha = defaults.profile.nameplateMaxAlpha
	self.db.profile.nameplateSelectedAlpha = defaults.profile.nameplateSelectedAlpha
	self.db.profile.nameplateNotSelectedAlpha = defaults.profile.nameplateNotSelectedAlpha
	self.db.profile.nameplateOccludedAlphaMult = defaults.profile.nameplateOccludedAlphaMult
	self.db.profile.nameplateMinScale = defaults.profile.nameplateMinScale
	self.db.profile.nameplateMaxScale = defaults.profile.nameplateMaxScale
	self.db.profile.nameplateSelectedScale = defaults.profile.nameplateSelectedScale
	self.db.profile.nameplateGlobalScale = defaults.profile.nameplateGlobalScale
	self.db.profile.nameplateShowClassColor = defaults.profile.nameplateShowClassColor 
	self.db.profile.nameplateShowFriendlyClassColor = defaults.profile.nameplateShowFriendlyClassColor 
	self.db.profile.nameplateUseClassColorForFriendlyPlayerUnitNames = defaults.profile.nameplateUseClassColorForFriendlyPlayerUnitNames 

	self:SaveSettingsToCVars()
end

NamePlates.RestoreBlizzardDefaults = function(self)
	if (InCombatLockdown()) then return end

	self.db.profile.nameplateMaxDistance = GetCVarDefault("nameplateMaxDistance") or defaults.profile.nameplateMaxDistance 
	self.db.profile.nameplateOtherTopInset = GetCVarDefault("nameplateOtherTopInset") or defaults.profile.nameplateOtherTopInset 
	self.db.profile.nameplateOtherBottomInset = GetCVarDefault("nameplateOtherBottomInset") or defaults.profile.nameplateOtherBottomInset 
	self.db.profile.nameplateLargeTopInset = GetCVarDefault("nameplateLargeTopInset") or defaults.profile.nameplateLargeTopInset 
	self.db.profile.nameplateLargeBottomInset = GetCVarDefault("nameplateLargeBottomInset") or defaults.profile.nameplateLargeBottomInset 
	self.db.profile.nameplateOverlapH = GetCVarDefault("nameplateOverlapH") or defaults.profile.nameplateOverlapH 
	self.db.profile.nameplateOverlapV = GetCVarDefault("nameplateOverlapV") or defaults.profile.nameplateOverlapV 
	self.db.profile.nameplateMinAlpha = GetCVarDefault("nameplateMinAlpha") or defaults.profile.nameplateMinAlpha 
	self.db.profile.nameplateMaxAlpha = GetCVarDefault("nameplateMaxAlpha") or defaults.profile.nameplateMaxAlpha 
	self.db.profile.nameplateSelectedAlpha = GetCVarDefault("nameplateSelectedAlpha") or defaults.profile.nameplateSelectedAlpha 
	self.db.profile.nameplateNotSelectedAlpha = GetCVarDefault("nameplateNotSelectedAlpha") or defaults.profile.nameplateNotSelectedAlpha 
	self.db.profile.nameplateOccludedAlphaMult = GetCVarDefault("nameplateOccludedAlphaMult") or defaults.profile.nameplateOccludedAlphaMult 
	self.db.profile.nameplateMinScale = GetCVarDefault("nameplateMinScale") or defaults.profile.nameplateMinScale 
	self.db.profile.nameplateMaxScale = GetCVarDefault("nameplateMaxScale") or defaults.profile.nameplateMaxScale 
	self.db.profile.nameplateSelectedScale = GetCVarDefault("nameplateSelectedScale") or defaults.profile.nameplateSelectedScale 
	self.db.profile.nameplateGlobalScale = GetCVarDefault("nameplateGlobalScale") or defaults.profile.nameplateGlobalScale 
	self.db.profile.nameplateShowClassColor = GetCVarDefault("nameplateShowClassColor") or defaults.profile.nameplateShowClassColor 
	self.db.profile.nameplateShowFriendlyClassColor = GetCVarDefault("nameplateShowFriendlyClassColor") or defaults.profile.nameplateShowFriendlyClassColor 
	self.db.profile.nameplateUseClassColorForFriendlyPlayerUnitNames = GetCVarDefault("nameplateUseClassColorForFriendlyPlayerUnitNames") or defaults.profile.nameplateUseClassColorForFriendlyPlayerUnitNames 

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

		UpdateActiveTargets(event)

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
		name = L["Nameplates"],
		order = 300,
		args = {
			enable = {
				type = "toggle", width = "full",
				name = L["Enable"],
				disabled = function() return InCombatLockdown() end,
				get = function(info) return self.db.profile.enabled end,
				set = function(info, val) 
					if InCombatLockdown() then return end
					self.db.profile.enabled = val 
					self:UpdateSettings()
				end,
				order = 1
			},


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
		self:Enable()
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
