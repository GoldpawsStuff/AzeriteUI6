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
	nameplateUseClassColorForFriendlyPlayerUnitNames = 1, 	-- Class colored friendly player unitname
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

local UnitIsFriendlyNPC = function(unit)
	return not UnitIsPlayer(unit) and not UnitCanAttack("player", unit)	
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
local NamePlate_UpdateElements = function(self, event, unit)
	unit = unit or self.__unit

	local isFriendlyPlayer = UnitIsFriendlyPlayerUnit(unit)
	local isFriendlyNPC = UnitIsFriendlyNPC(unit)
	local shouldClassColorName = C_CVar.GetCVarBool("nameplateUseClassColorForFriendlyPlayerUnitNames")

	local onlyShowName = (isFriendlyPlayer or isFriendlyNPC) and C_CVar.GetCVarBool("nameplateShowOnlyNameForFriendlyPlayerUnits")
	if (onlyShowName) then
		self.Name:SetAlpha(1)
		self.Health:Hide()
		self.AurasHarmful:Hide()
		self.AurasHelpful:Hide()
		self.AurasCC:Hide()
		self.Classification:Hide()
		-- castbar
		-- rarity icon
	else
		self.Name:SetAlpha(.75)
		self.Health:Show()
		self.AurasHarmful:Show()
		self.AurasHelpful:Show()
		self.AurasCC:Show()
		self.Classification:Show()
	end

	-- Update name coloring
	if (onlyShowName and isFriendlyPlayer and shouldClassColorName) then
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
	elseif (onlyShowName and isFriendlyNPC) then -- shouldReactionColorName
		if (UnitReaction(unit, "player")) then 
			self.Name:SetTextColor(self.colors.reaction[UnitReaction(unit, "player")]:GetRGB())
		else
			self.Name:SetTextColor(self.colors.highlight:GetRGB())
		end
	else
		self.Name:SetTextColor(self.colors.highlight:GetRGB())
	end

	Classification_Update(self, event, unit)
end

-- NAME_PLATE_UNIT_ADDED
local NamePlate_OnShow = function(self, event, unit)
	self.inCombat = IN_COMBAT
	self.isTarget = UnitIsUnit(unit, "target")
	self.isFocus = UnitIsUnit(unit, "focus")
	self.isSoftEnemy = UnitIsUnit(unit, "softenemy")
	self.isSoftFriend = UnitIsUnit(unit, "softfriend")
	self.isSoftInteract = UnitIsUnit(unit, "softinteract")

	ActiveNamePlates[self] = true
	InActiveNamePlates[self] = nil

	NamePlate_UpdateElements(self, event, unit)
end

-- NAME_PLATE_UNIT_REMOVED
local NamePlate_OnHide = function(self, event, unit)

	self.TargetHighlight:Hide()
	self.inCombat = nil
	self.isFocus = nil
	self.isTarget = nil
	self.isSoftEnemy = nil
	self.isSoftFriend = nil
	self.isSoftInteract = nil

	ActiveNamePlates[self] = nil
	InActiveNamePlates[self] = true

	NamePlate_UpdateElements(self, event, unit)
end

local NamePlate_PostUpdate = function(self)
	NamePlate_UpdateAlpha(self)
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

	-- Name
	local name = self:CreateFontString(nil, "OVERLAY")
	name:SetPoint("BOTTOM", health, "TOP", 0, -2)
	name:SetFontObject(GetFont(11, true))
	name:SetTextColor(self.colors.highlight:GetRGB())
	name:SetAlpha(.75)
	name:SetJustifyH("CENTER")
	name:SetJustifyV("MIDDLE")

	self:Tag(name, "[name]")

	self.Name = name

	-- Target highlight
	local targetHighlight = health:CreateTexture(nil, "BACKGROUND", nil, -2)
	targetHighlight:Hide()
	targetHighlight:SetPoint("CENTER", 0, 0)
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

	-- Skull Badge (boss, high level)(right)
	local skull

	-- Classification Badge (elite, rare)(left)
	local classification = health:CreateTexture(nil, "OVERLAY", nil, -2)
	classification:SetSize(40, 40)
	classification:SetPoint("RIGHT", 20, -1)
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
			nameplateShowPersonal = true
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
			nameplateShowAll = true
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
		maxFrameCount = 2,
		initializeFrame = AuraButton_InitializeSmall,
		layout = {
			elementSpacing = 4,
			lineSpacing = 4,
			growthX = "LEFT",
		},
	})

	self.AurasCC = aurasCC

	self.PostUpdate = NamePlate_PostUpdate

	-- Make our nameplates obey UIParent alpha and fade out when Immersion says so.
	hooksecurefunc(UIParent, "SetAlpha", function() NamePlate_UpdateAlpha(self) end)

	-- Callbacks
	--------------------------------------------
	self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED", Classification_Update)

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

		if (not self.db.profile[cvarName]) then return end
		
		self:LoadSettingFromCVar(cvarName, value)

	elseif (event == "PLAYER_ENTERING_WORLD") then
		IN_COMBAT = nil

	elseif (event == "PLAYER_REGEN_DISABLED") then
		IN_COMBAT = true

	elseif (event == "PLAYER_REGEN_ENABLED") then
		IN_COMBAT = nil

	elseif (event == "PLAYER_TARGET_CHANGED") then

		local ActiveTargetPlates = {
			target = nil, 
			focus = nil, 
			softenemy = nil,
			softfriend = nil, -- not used
			softinteract = nil
		}

		-- target priority: target, focus, softenemy, softinteract
		-- *only show the highest priority target type if multiple are the same unit

		-- Figure out what highlight borders are visible
		-- Check active target units if they exist
		-- Iterate plates for potential new target plates
		-- Clear or change any old target plates that does not match the new ones

		-- Does a target exist? 
		-- yes - remove flags from old, add to new
		-- no -- remove flags from old



		local unit = "target"
		local oldTargetNamePlate, newTargetNamePlate = ActiveTargetPlates[unit]

		-- The player has a target
		local hasTarget = UnitExists(unit)
		if (hasTarget) then

			-- Does a target nameplate exist?
			for nameplate in next,ActiveNamePlates do

				-- Is this nameplate the target nameplate?
				local isTargetNamePlate = UnitIsUnit(nameplate.__unit, unit)
				if (isTargetNamePlate and nameplate ~= oldTargetNamePlate) then

					-- The target nameplate has changed
					newTargetNamePlate = nameplate -- store the new one
					break
				end
			end

			-- A new target nameplate was found
			if (newTargetNamePlate) then

				-- Does an old one exist?
				if (oldTargetNamePlate) then
					-- Clear the highlight border
				end

				-- Store the new one
				ActiveTargetPlates[unit] = newTargetNamePlate
			end

		else
			-- Does an old target plate exist?
			if (oldTargetNamePlate) then

				-- Clear the highlight border
				if (oldTargetNamePlate.TargetHighlight.targetType == unit) then
					-- clear
				else

				end

				-- Clear the old one
				ActiveTargetPlates[unit] = nil
			end
		end



		-- Update flags on all plates
		-- Iterate plate flags
			-- Figure out if plate has border at all
			-- Figure out highest priority border


	elseif (event == "PLAYER_FOCUS_CHANGED") then

	elseif (event == "PLAYER_SOFT_ENEMY_CHANGED") then
	
	elseif (event == "PLAYER_SOFT_FRIEND_CHANGED") then
	
	elseif (event == "PLAYER_SOFT_INTERACT_CHANGED") then
	
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
