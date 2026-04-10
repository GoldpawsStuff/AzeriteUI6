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

local Target = ns:NewModule("Target", nil, "LibMoreEvents-1.0", "LibMovableFrames-1.0")

-- Declare module defaults
local defaults = { profile = {} }

-- Custom API locals
local AbbreviateNumber = ns.AbbreviateNumber
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia

-- Function to create an alpha curve based on min/max values.
-- Useful to hide elements when at (almost) zero.
local createAlphaCurve = function(min, max)
	local alphaCurve = C_CurveUtil.CreateColorCurve()  -- Returns ColorCurveObject
	alphaCurve:SetType(Enum.LuaCurveType.Step) -- Step: instant jump at points
	alphaCurve:AddPoint(0, CreateColor(1, 1, 1, min or 0)) -- At 0%: alpha=<min> (hide)
	alphaCurve:AddPoint(.01, CreateColor(1, 1, 1, max or 1)) -- At 1%+: alpha=<max> (show)
	return alphaCurve
end

-- Safely compare units
local AreUnitsSame = function(u1, u2)
	local g1 = UnitGUID(u1)
	local g2 = UnitGUID(u2)

	-- Bail if different secrecy levels (can't be equal, avoids mixed == error)
	if (issecretvalue(g1) ~= issecretvalue(g2)) then
		return false
	end

	-- Now safe: both non-secret or both secret
	return g1 == g2
end

-- Toggle cast text color on protected casts.
local Castbar_PostCastInterruptible = function(element, unit)
	if (element.notInterruptible) then
		element.Text:SetTextColor(element.__owner.colors.normal:GetRGB())
		element.Text:SetAlpha(.75)
	else
		element.Text:SetTextColor(element.__owner.colors.highlight:GetRGB())
		element.Text:SetAlpha(.5)
	end
end

-- Toggle cast info and health info when castbar is visible.
local Castbar_PostUpdateTexts = function(element)
	if (element:IsShown()) then
		element.Text:Show()
		element.Time:Show()
		element.__owner.Health.Value:Hide()
	else
		element.Text:Hide()
		element.Time:Hide()
		element.__owner.Health.Value:Show()
	end
end

-- Custom castbar update to get our flipped textures
local CastBar_OnUpdate = function(element, elapsed)

	if (element.casting or element.empowering) then
		local durationObject = element:GetTimerDuration()
		local perc = durationObject:GetElapsedPercent(0)

		element.Texture:SetTexCoord(perc, 0, 0, 1)

	elseif (element.channeling) then
		local durationObject = element:GetTimerDuration()
		local perc = durationObject:GetRemainingPercent(0)

		element.Texture:SetTexCoord(perc, 0, 0, 1) 

	-- The rest here is just a copy of oUF's code, 
	-- since we're replacing it with this function.
	elseif (element.holdTime > 0) then
		element.holdTime = element.holdTime - elapsed
	else
		element.castID = nil
		element.casting = nil
		element.channeling = nil
		element.empowering = nil
		element.notInterruptible = nil
		element.spellID = nil
		element.spellName = nil

		for _, pip in next, element.Pips do
			pip:Hide()
		end

		element:Hide()
	end
end

-- Update NPC classification badge for rares, elites and bosses.
local Classification_Update = function(self, event, unit, ...)
	if (unit and unit ~= self.unit) then return end

	local element = self.Classification
	unit = unit or self.unit

	if (UnitIsPlayer(unit)) then
		return element:Hide()
	end
	local l = UnitEffectiveLevel(unit)
	local c = (l and l < 1) and "worldboss" or UnitClassification(unit)
	if (c == "boss" or c == "worldboss") then
		element:SetTexture(element.bossTexture)
		element:Show()

	elseif (c == "elite") then
		element:SetTexture(element.eliteTexture)
		element:Show()

	elseif (c == "rare" or c == "rareelite") then
		element:SetTexture(element.rareTexture)
		element:Show()
	else
		element:Hide()
	end
end

-- API magic to reverse the bar texture.
local Health_OnValueChanged = function(element, val) 
	if (val) then
		-- This returns the health as a value from 0 to 1. 
		local perc = UnitHealthPercent(element.__owner.unit, true, CurveConstants.ZeroToOne)
		element.Texture:SetTexCoord(perc, 0, 0, 1)
	else
		element.Texture:SetTexCoord(1, 0, 0, 1)
	end
end

-- Forward color updates to our flipped health bar texture
local Health_PostUpdateColor = function(element, unit, color)
	if (color) then
		element.Texture:SetVertexColor(color:GetRGB())
	end
end

-- Make the portrait look better for offline or invisible units.
local Portrait_PostUpdate = function(element, unit, hasStateChanged)
	if (not element.state) then
		element:ClearModel()
		if (not element.fallback2DTexture) then
			element.fallback2DTexture = element:CreateTexture()
			element.fallback2DTexture:SetDrawLayer("ARTWORK")
			element.fallback2DTexture:SetAllPoints()
			element.fallback2DTexture:SetTexCoord(.1, .9, .1, .9)
		end
		SetPortraitTexture(element.fallback2DTexture, unit)
		element.fallback2DTexture:Show()
	else
		if (element.fallback2DTexture) then
			element.fallback2DTexture:Hide()
		end
		element:SetCamDistanceScale(element.distanceScale or 1)
		element:SetPortraitZoom(1)
		element:SetPosition(element.positionX or 0, element.positionY or 0, element.positionZ or 0)
		element:SetRotation(element.rotation and element.rotation*degToRad or 0)
		element:ClearModel()
		element:SetUnit(unit)
		element.guid = guid
	end
end

-- Hide power crystal when no power exists.
local Power_UpdateVisibility = function(element, unit, cur, min, max)
	if (UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit)) then
		element:Hide()
		element.Backdrop:Hide()
		element.Value:Hide()
	else
		element:Show()
		element.Backdrop:Show()
		element.Value:Show()
		if (element.alphaCurve) then
			local ptype = UnitPowerType(unit)  -- Safe (non-secret)
			local color = UnitPowerPercent(unit, ptype, true, element.alphaCurve)  -- Secret-safe!
			local _, _, _, a = color:GetRGBA()  -- Safe number!
			element:SetAlpha(a)
		end
	end
end

-- Only show Horde/Alliance badges,
-- keep this hidding for rare-, elite- and boss NPCs.
local PvPIndicator_Override = function(self, event, unit)
	if (unit and unit ~= self.unit) then return end

	local element = self.PvPIndicator
	unit = unit or self.unit

	local l = UnitEffectiveLevel(unit)
	local c = (l and l < 1) and "worldboss" or UnitClassification(unit)
	if (c == "boss" or c == "worldboss" or c == "elite" or c == "rare") then
		return element:Hide()
	end

	local status
	local factionGroup = UnitFactionGroup(unit) or "Neutral"
	if (factionGroup ~= "Neutral") then
		if (UnitIsPVPFreeForAll(unit)) then
		elseif (UnitIsPVP(unit)) then
			if (ns.IsRetail and UnitIsMercenary(unit)) then
				if (factionGroup == "Horde") then
					factionGroup = "Alliance"
				elseif (factionGroup == "Alliance") then
					factionGroup = "Horde"
				end
			end
			status = factionGroup
		end
	end

	if (status) then
		element:SetTexture(element[status])
		element:Show()
	else
		element:Hide()
	end
end

-- Update target indicator texture.
local TargetIndicator_Update = function(self, event, unit, ...)
	if (unit and unit ~= self.unit) then return end

	local element = self.TargetIndicator
	unit = unit or self.unit

	-- if we are targeting ourselves, hide the targeting eye
	if (AreUnitsSame(unit, "player")) then
		return element:Hide()
	end

	-- get the ToT unit
	local tot = unit .. "target" 

	-- if our target is hostile
	if (UnitExists(tot) and UnitCanAttack("player", unit)) then

		-- if our hostile target is targeting us
		if (AreUnitsSame(tot, "player")) then
			element:SetTexture(element.enemyTexture)

		-- if our hostile target is targeting our pet 
		elseif (AreUnitsSame(tot, "pet")) then
			element:SetTexture(element.petTexture)
		else
			return element:Hide()
		end

	-- if our target is friendly and targeting us
	elseif (AreUnitsSame(tot, "player")) then
		element:SetTexture(element.friendTexture)
	else
		return element:Hide()
	end

	element:Show()
end

local TargetIndicator_Start = function(self)
	local targetIndicator = self.TargetIndicator
	if (not targetIndicator.Ticker) then
		targetIndicator.Ticker = C_Timer.NewTicker(.1, function() TargetIndicator_Update(self) end)
	end
end

local TargetIndicator_Stop = function(self)
	local targetIndicator = self.TargetIndicator
	if (targetIndicator.Ticker) then
		targetIndicator.Ticker:Cancel()
		targetIndicator.Ticker = nil
		targetIndicator:Hide()
	end
end

local UnitFrame_PostUpdate = function(self, event, unit, ...)
	Classification_Update(self)
	TargetIndicator_Update(self, event, unit, ...)
	TargetIndicator_Start(self)
end

-- Primarily needed to update orb/crystal visibilities
local UnitFrame_OnEvent = function(self, event, unit, ...)
	self.Power:ForceUpdate()
	UnitFrame_PostUpdate(self, event, unit, ...)
end

-- Setup the unitframe
local style = function(self, unit)

	-- General frame settings
	self:SetSize(550, 160) -- 550, 210
	self:SetHitRectInsets(0, 0, 0, 60)

	ns.ApplyUnitFrameScriptsTo(self)

	-- Frame for font Overlays
	local overlay = CreateFrame("Frame", nil, self)
	overlay:SetFrameLevel(self:GetFrameLevel() + 7)
	overlay:SetAllPoints()

	-- Health bar
	--------------------------------------------
	local health = CreateFrame("StatusBar", nil, self)
	health:SetSize(385, 40) -- 385, 37
	health:SetPoint("TOPRIGHT", -140, -66)
	health:SetStatusBarTexture(GetMedia("hp_cap_bar")) 
	health:GetStatusBarTexture():SetAlpha(0) -- hide the bar tex, not the bar
	health:SetReverseFill(true)

	local healthTex = health:CreateTexture(nil, "ARTWORK", nil, 0)
	healthTex:SetSize(385, 40)
	healthTex:SetAllPoints(health:GetStatusBarTexture())
	healthTex:SetTexture(GetMedia("hp_cap_bar"))
	healthTex:SetTexCoord(1, 0, 0, 1)

	-- Health backdrop
	local healthBg = health:CreateTexture(nil, "BORDER", nil, 0)
	healthBg:SetSize(716, 188)
	healthBg:SetPoint("TOPRIGHT", self, "TOPRIGHT", 23, 8)
	healthBg:SetTexture(GetMedia("hp_cap_case"))
	healthBg:SetTexCoord(1, 0, 0, 1) -- Horizontally flip the texture
	healthBg:SetVertexColor(self.colors.ui:GetRGB())

	-- Health overlay for fonts and icons
	local healthOverlay = CreateFrame("Frame", nil, overlay)
	healthOverlay:SetAllPoints(health)

	-- Health Value
	local healthValue = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	healthValue:SetPoint("RIGHT", -27, 4)
	healthValue:SetFontObject(GetFont(18, true))
	healthValue:SetTextColor(self.colors.highlight:GetRGB())
	healthValue:SetAlpha(.5)
	healthValue:SetJustifyH("RIGHT")
	healthValue:SetJustifyV("MIDDLE")

	self:Tag(healthValue, "[azui:shorthealth]")

	local healthPerc = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	healthPerc:SetPoint("LEFT", 27, 4)
	healthPerc:SetFontObject(GetFont(18, true))
	healthPerc:SetTextColor(self.colors.highlight:GetRGB())
	healthPerc:SetAlpha(.4)
	healthPerc:SetJustifyH("LEFT")
	healthPerc:SetJustifyV("MIDDLE")

	self:Tag(healthPerc, "[azui:healthpercent]")

	-- Options
	health.colorDisconnected = true
	health.colorTapping = true
	health.colorThreat = true
	health.colorClass = true
	health.colorReaction = true

	-- This does not work with our reversed bars yet. 
	--health.smoothing = Enum.StatusBarInterpolation.ExponentialEaseOut -- Make the bar move smoothly 

	-- Register it with oUF
	self.Health = health
	self.Health.Value = healthValue
	self.Health.Texture = healthTex
	self.Health.UpdateColor = ns.UpdateHealthColor
	self.Health.PostUpdateColor = Health_PostUpdateColor

	-- Apply scripts that update our reversed bar texture.
	self.Health:SetScript("OnValueChanged", Health_OnValueChanged)
	
	-- CombatFeedback
	--------------------------------------------
	local combatFeedback = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 7)
	combatFeedback:SetPoint("CENTER", 0, 4)
	combatFeedback:SetJustifyH("CENTER")
	combatFeedback:SetJustifyV("MIDDLE")

	-- Options
	combatFeedback.feedbackFont = GetFont(20, true)
	combatFeedback.feedbackFontLarge = GetFont(24, true)
	combatFeedback.feedbackFontSmall = GetFont(18, true)
	combatFeedback.colors = oUF.colors.combatfeedback 
	combatFeedback.maxAlpha = .9

	self.CombatFeedback = combatFeedback

	-- Overlayed Castbar
	--------------------------------------------
	local castbar = CreateFrame("StatusBar", nil, self)
	castbar:SetFrameLevel(self:GetFrameLevel() + 5)
	castbar:SetStatusBarTexture(GetMedia("blank"))
	castbar:GetStatusBarTexture():SetVertexColor(0, 0, 0, 0)
	castbar:SetReverseFill(true)
	castbar:SetAllPoints(self.Health)
	castbar:SetSize(self.Health:GetSize())

	local castbarTex = castbar:CreateTexture(nil, "ARTWORK", nil, 0)
	castbarTex:SetTexture(GetMedia("hp_cap_bar_highlight"))
	castbarTex:SetVertexColor(1, 1, 1, .35)  
	castbarTex:SetTexCoord(1, 0, 0, 1)
	castbarTex:SetBlendMode("ADD")
	castbarTex:SetAllPoints(castbar:GetStatusBarTexture()) -- this is the trick to avoiding math on secret values

	-- Cast Name
	local castName = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	castName:SetPoint("RIGHT", -27, 4)
	castName:SetSize(250, 40)
	castName:SetFontObject(GetFont(16, true))
	castName:SetTextColor(self.colors.highlight:GetRGB())
	castName:SetAlpha(.5)
	castName:SetJustifyH("RIGHT")
	castName:SetJustifyV("MIDDLE")
	castName:Hide()

	-- Cast Time
	-- *Not showing for anybody but the player unit in Midnight?
	local castbarTime = healthOverlay:CreateFontString(nil, "OVERLAY", nil, 1)
	castbarTime:SetPoint("LEFT", 27, 4)
	castbarTime:SetFontObject(GetFont(18, true))
	castbarTime:SetTextColor(self.colors.highlight:GetRGB())
	castbarTime:SetAlpha(.5)
	castbarTime:SetJustifyH("CENTER")
	castbarTime:SetJustifyV("MIDDLE")
	castbarTime:Hide()

	-- Attach scripts
	castbar:HookScript("OnShow", Castbar_PostUpdateTexts)
	castbar:HookScript("OnHide", Castbar_PostUpdateTexts)

	-- Register it with oUF
	self.Castbar = castbar
	self.Castbar.Texture = castbarTex
	self.Castbar.Text = castName
	self.Castbar.Time = castbarTime
	self.Castbar.OnUpdate = CastBar_OnUpdate
	self.Castbar.PostCastInterruptible = Castbar_PostCastInterruptible

	-- Power Crystal
	--------------------------------------------
	-- *why did I create so many frames and layers here? 

	local power = CreateFrame("StatusBar", nil, self)
	power:SetFrameLevel(self:GetFrameLevel() + 5)
	--power:GetStatusBarTexture():SetDrawLayer("BACKGROUND", -6)
	power:SetPoint("TOPRIGHT", 8, -58)
	power:SetSize(80, 80)
	power:SetOrientation("VERTICAL")
	power:SetStatusBarTexture(GetMedia("power_crystal_small_front"))
	power:SetAlpha(.75)
	power.alphaCurve = createAlphaCurve(0,1)
	power.frequentUpdates = true
	power.displayAltPower = true
	power.colorPower = true

	local powerBackdrop = power:CreateTexture(nil, "BACKGROUND", nil, 0)
	powerBackdrop:SetPoint("CENTER", 0, 0)
	powerBackdrop:SetSize(80, 80)
	powerBackdrop:SetTexture(GetMedia("power_crystal_small_back"))
	powerBackdrop:SetVertexColor(1, 1, 1, .85)

	local powerValue = power:CreateFontString(nil, "OVERLAY", nil, 0)
	powerValue:SetPoint("CENTER", 0, -5)
	powerValue:SetJustifyH("CENTER")
	powerValue:SetJustifyV("MIDDLE")
	powerValue:SetFontObject(GetFont(14, true))
	powerValue:SetTextColor(self.colors.highlight:GetRGB())
	powerValue:SetAlpha(.5)

	self:Tag(powerValue, "[azui:shortpower]")

	self.Power = power
	self.Power.Value = powerValue
	self.Power.Backdrop = powerBackdrop
	self.Power.PostUpdate = Power_UpdateVisibility

	-- Portrait
	--------------------------------------------
	local portraitFrame = CreateFrame("Frame", nil, self)
	portraitFrame:SetFrameLevel(self:GetFrameLevel() - 2)
	portraitFrame:SetAllPoints()

	local portrait = CreateFrame("PlayerModel", nil, portraitFrame)
	portrait:SetFrameLevel(portraitFrame:GetFrameLevel())
	portrait:SetPoint("TOPRIGHT", -40, -31)
	portrait:SetSize(85, 85)
	portrait:SetAlpha(.85)

	local portraitBg = portraitFrame:CreateTexture(nil, "BACKGROUND", nil, 0)
	portraitBg:SetPoint("TOPRIGHT", 3, 16)
	portraitBg:SetSize(173, 173)
	portraitBg:SetTexture(GetMedia("party_portrait_back"))
	portraitBg:SetVertexColor(.5, .5, .5)

	local portraitOverlayFrame = nil
	portraitOverlayFrame = CreateFrame("Frame", nil, self, "PingReceiverAttributeTemplate")

	Mixin(portraitOverlayFrame, PingableTypeMixin)

	portraitOverlayFrame.GetContextualPingType = function(self) return PingUtil:GetContextualPingTypeForUnit(self:GetTargetPingGUID()) end
	portraitOverlayFrame.GetTargetPingGUID = function(self) return UnitGUID(unit) end
	portraitOverlayFrame:SetFrameLevel(self:GetFrameLevel() - 1)
	portraitOverlayFrame:SetAllPoints()

	local portraitShade = portraitOverlayFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
	portraitShade:SetPoint("TOPRIGHT", -30, -18)
	portraitShade:SetSize(107, 107)
	portraitShade:SetTexture(GetMedia("shade-circle"))

	local portraitBorder = portraitOverlayFrame:CreateTexture(nil, "BACKGROUND", nil, 0)
	portraitBorder:SetPoint("TOPRIGHT", 10, 22)
	portraitBorder:SetSize(187, 187)
	portraitBorder:SetTexture(GetMedia("portrait_frame_hi"))
	portraitBorder:SetVertexColor(self.colors.ui:GetRGB())

	self.Portrait = portrait
	self.Portrait.Bg = portraitBg
	self.Portrait.Shade = portraitShade
	self.Portrait.Border = portraitBorder
	self.Portrait.PostUpdate = Portrait_PostUpdate

	-- PvP Indicator Badge
	--------------------------------------------
	local PvPIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, -2)
	PvPIndicator:SetSize(84, 84)
	PvPIndicator:SetPoint("TOPRIGHT", -41, -91)
	PvPIndicator.Alliance = GetMedia("icon_badges_alliance")
	PvPIndicator.Horde = GetMedia("icon_badges_horde")

	self.PvPIndicator = PvPIndicator
	self.PvPIndicator.Override = PvPIndicator_Override

	-- Classification Badge
	--------------------------------------------
	local classification = overlay:CreateTexture(nil, "OVERLAY", nil, -2)
	classification:SetSize(84, 84)
	classification:SetPoint("TOPRIGHT", -41, -91)
	classification.bossTexture = GetMedia("icon_badges_boss")
	classification.eliteTexture = GetMedia("icon_classification_elite")
	classification.rareTexture = GetMedia("icon_classification_rare")

	self.Classification = classification

	-- Target Indicator
	--------------------------------------------
	local targetIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, -2)
	targetIndicator:SetPoint("TOPRIGHT", -75, -3)
	targetIndicator:SetSize(96, 48)
	targetIndicator:SetVertexColor(self.colors.ui:GetRGB())
	targetIndicator.petTexture = GetMedia("icon_target_blue")
	targetIndicator.enemyTexture = GetMedia("icon_target_red")
	targetIndicator.friendTexture = GetMedia("icon_target_green")

	self.TargetIndicator = targetIndicator

	-- Unit Name
	--------------------------------------------
	local name = self:CreateFontString(nil, "OVERLAY", nil, 1)
	name:SetPoint("TOPRIGHT", -153, -21)
	name:SetFontObject(GetFont(16, true))
	name:SetTextColor(self.colors.highlight:GetRGB())
	name:SetAlpha(.75)
	name:SetJustifyH("RIGHT")
	name:SetJustifyV("TOP")

	self:Tag(name, "[azui:name(32)][azui:level(true)]")

	self.Name = name

	-- RaidTarget Indicator
	--------------------------------------------
	local raidTargetIndicator = overlay:CreateTexture(nil, "OVERLAY", nil, 2)
	raidTargetIndicator:SetSize(32, 32)
	raidTargetIndicator:SetPoint("RIGHT", self.Name, "LEFT", -2, 2)
	raidTargetIndicator:SetTexture(GetMedia("raid_target_icons"))

	self.RaidTargetIndicator = raidTargetIndicator

	-- Auras
	--------------------------------------------
	local auras = CreateFrame("Frame", nil, self)
	auras:SetSize(316, 76)
	auras:SetPoint("TOPRIGHT", -150, -126)

	-- settings
	auras.disableMouse = false
	auras.disableCooldown = false
	auras.onlyShowPlayer = false

	-- layout
	auras.size = 36
	auras.spacing = 4
	auras.numTotal = 16
	auras.spacingX = 4
	auras.spacingY = 4
	auras.initialAnchor = "TOPRIGHT"
	auras.growthX = "LEFT"
	auras.growthY = "DOWN"
	auras.tooltipAnchor = "ANCHOR_BOTTOMLEFT"

	-- sorting 
	auras.reanchorIfVisibleChanged = true
	auras.sortMethod = "TIME_REMAINING"
	auras.sortDirection = "DESCENDING"
	auras.buffFilter = "HELPFUL|INCLUDE_NAME_PLATE_ONLY|RAID_IN_COMBAT"
	auras.debuffFilter = "HARMFUL|INCLUDE_NAME_PLATE_ONLY"

	self.Auras = auras
	self.Auras.PostCreateButton = ns.AuraButton_PostCreate
	self.Auras.PostUpdateButton = ns.AuraButton_PostUpdateTarget

	-- General post update
	self.PostUpdate = UnitFrame_PostUpdate

	-- Callbacks
	--------------------------------------------
	self:RegisterEvent("PLAYER_ENTERING_WORLD", UnitFrame_OnEvent, true)
	self:RegisterEvent("PLAYER_TARGET_CHANGED", UnitFrame_OnEvent, true)
	self:RegisterEvent("PLAYER_FOCUS_CHANGED", UnitFrame_OnEvent, true)

end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling and combat end.
Target.UpdateSettings = function(self)
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
Target.RefreshConfig = function(self)
	self:UpdateSettings()
end

Target.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("Target", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

Target.OnEnable = function(self)
	oUF:RegisterStyle("AzeriteUnitFrameTarget", style)	
	oUF:Factory(function(self) 
		self:SetActiveStyle("AzeriteUnitFrameTarget")

		local frame = self:Spawn("target")
		frame:SetScale(.9)
		frame:SetPoint("TOPRIGHT", -40/.9, -40/.9)

		Target:RegisterMovableFrameAnchor(frame, string.lower(TARGET), "unitframes", AzeriteUI6_Positions_DB)
	end)
end
