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

-- Custom API locals
local AbbreviateNumber = ns.AbbreviateNumber
local GetFont = ns.GetFont
local GetMedia = ns.GetMedia

-- Auras
-----------------------------------------
local whitelist = {
	buffs = {}, -- General whitelisted buffs on anybody
	debuffs = {}, -- General whitelisted debuffs on anybody
	playerbuffs = {}, -- Whitelisted buffs on the Player unit frame
	playerdebuffs = {}, -- Whitelisted debuffs on the Player unit frame
	targetbuffs = {}, -- Whitelisted buffs on the Target unit frame
	targetdebuffs = {}, -- Whitelisted debuffs on the Target unit frame
	nameplateccs = {}, -- Whitelisted CC on the nameplates
	nameplatebuffs = {}, -- Whitelisted self buffs on the nameplates
	nameplatedebuffs = {} -- Whitelisted debuffs on the nameplates
}

local cache, list = {}, {}

local clear = function()
	for i in next,cache do
		cache[i] = nil
	end
end

local copy = function(source)
	for auraID in next,source do
		cache[auraID] = true
	end
end

local timeFormatter = C_StringUtil.CreateNumericRuleFormatter()
timeFormatter:SetBreakpoints({
	-- ≥ 1 day
	{
		threshold = 86400,
		format = "%.0fd",
		components = {
			{ div = 86400, rounding = Enum.NumericRuleFormatRounding.Up },
		}
	},
	-- ≥ 1 hour
	{
		threshold = 59*60,
		format = "%.0fh",
		components = {
			{ div = 3600, rounding = Enum.NumericRuleFormatRounding.Up },
		}
	},
	-- ≥ 1 minute
	{
		threshold = 59,
		format = "%.0fm",
		components = {
			{ div = 60, rounding = Enum.NumericRuleFormatRounding.Up },
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

local Auras_CreateFourSlice = function(button, showWhenHarmful, showWhenHelpful)

	local edge = 12
	local file = GetMedia("border-aura")

	-- left, right, top, bottom. Same cuts BackdropTemplate uses on an edge file.
	local slices = {
		{ "TOPLEFT",     .5078125, .6171875, .0625, .9375, "TOPLEFT",     0,  0 },
		{ "TOPRIGHT",    .6328125, .7421875, .0625, .9375, "TOPRIGHT",    0,  0 },
		{ "BOTTOMLEFT",  .7578125, .8671875, .0625, .9375, "BOTTOMLEFT",  0,  0 },
		{ "BOTTOMRIGHT", .8828125, .9921875, .0625, .9375, "BOTTOMRIGHT", 0,  0 },
	}

	local holder = button.Border

	local dispelOptions = {
		style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
		showWhenHarmful = showWhenHarmful,
		showWhenHelpful = showWhenHelpful,
		showWithoutDispelType = true,
		customDispelColorMap = {
			None = oUF.colors.debuff.none,
			Magic = oUF.colors.debuff.Magic,
			Curse = oUF.colors.debuff.Curse,
			Disease = oUF.colors.debuff.Disease,
			Poison = oUF.colors.debuff.Poison,
			Bleed = oUF.colors.debuff.none,
		}
	}

	local ring = {}

	for i = 1, 4 do
		local piece = slices[i]
		local tex = holder:CreateTexture(nil, "OVERLAY", nil, -2)
		tex:SetTexture(file)
		tex:SetTexCoord(piece[2], piece[3], piece[4], piece[5])
		tex:SetSize(edge, edge)
		tex:SetPoint(piece[6], holder, piece[6], piece[7], piece[8])
		tex:Hide()
		button:AddDispelTypeTexture(tex, dispelOptions)
		ring[i] = tex
	end

	-- edges are stored sideways in the file, so these need the 8-argument form
	local Edge = function(name, u1, v1, u2, v2, u3, v3, u4, v4, point, rel, x, y)
		local tex = holder:CreateTexture(nil, "OVERLAY", nil, -2)
		tex:SetTexture(file)
		tex:SetTexCoord(u1, v1, u2, v2, u3, v3, u4, v4)
		tex:SetPoint(point, holder, rel, x, y)
		tex:Hide()
		button:AddDispelTypeTexture(tex, dispelOptions)
		ring[#ring + 1] = tex
		return tex
	end

	local top = Edge("top",
		0.2578125, 1, 0.3671875, 1, 0.2578125, 0.0625, 0.3671875, 0.0625,
		"TOPLEFT", "TOPLEFT", edge, 0)
	top:SetPoint("TOPRIGHT", holder, "TOPRIGHT", -edge, 0)
	top:SetHeight(edge)

	local bottom = Edge("bottom",
		0.3828125, 1, 0.4921875, 1, 0.3828125, 0.0625, 0.4921875, 0.0625,
		"BOTTOMLEFT", "BOTTOMLEFT", edge, 0)
	bottom:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -edge, 0)
	bottom:SetHeight(edge)

	local left = Edge("left",
		0.0078125, 0.0625, 0.0078125, 1, 0.1171875, 0.0625, 0.1171875, 1,
		"TOPLEFT", "TOPLEFT", 0, -edge)
	left:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, edge)
	left:SetWidth(edge)

	local right = Edge("right",
		0.1328125, 0.0625, 0.1328125, 1, 0.2421875, 0.0625, 0.2421875, 1,
		"TOPRIGHT", "TOPRIGHT", 0, -edge)
	right:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, edge)
	right:SetWidth(edge)

	button.DispelRing = ring
end

ns.AuraButton_InitializeBigBuff = function(button)
	local icon = button:CreateTexture(nil, "BORDER")
	icon:SetMask(GetMedia("actionbutton-mask-square"))
	icon:SetPoint("TOPLEFT", 2, -2)
	icon:SetPoint("BOTTOMRIGHT", -2, 2)
	icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	button.Icon = icon

	local border = CreateFrame("Frame", nil, button, "BackdropTemplate")
	border:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 12 })
	border:SetBackdropBorderColor(oUF.colors.verydarkgray:GetRGB())
	border:SetPoint("TOPLEFT", -6, 6)
	border:SetPoint("BOTTOMRIGHT", 6, -6)
	border:SetFrameLevel(button:GetFrameLevel() + 2)
	button.Border = border

	-- adjust the stack count
	local count = border:CreateFontString(nil, "OVERLAY")
	count:SetFontObject(GetFont(12,true))
	count:SetTextColor(oUF.colors.offwhite:GetRGB())
	count:ClearAllPoints()
	count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 3)
	button.Count = count

	local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cooldown:SetAllPoints(icon)
	cooldown:SetHideCountdownNumbers(true)
	cooldown:SetDrawBling(false)
	cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
	button.Cooldown = cooldown

	local time = border:CreateFontString(nil, "OVERLAY")
	time:SetFontObject(GetFont(14, true))
	time:SetPoint("TOPLEFT", button, "TOPLEFT", -5, 5)
	time:SetTextColor(oUF.colors.offwhite:GetRGB())
	button.Time = time

	button:SetSize(36,36)
	button:SetIcon(icon)
	button:SetDurationCooldown(cooldown)
	button:SetDurationText(time, { textFormatter = timeFormatter })
end

ns.AuraButton_InitializeBigDebuff = function(button)
	local icon = button:CreateTexture(nil, "BORDER")
	icon:SetMask(GetMedia("actionbutton-mask-square"))
	icon:SetPoint("TOPLEFT", 2, -2)
	icon:SetPoint("BOTTOMRIGHT", -2, 2)
	icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	button.Icon = icon

	local border = CreateFrame("Frame", nil, button)
	border:SetPoint("TOPLEFT", -6, 6)
	border:SetPoint("BOTTOMRIGHT", 6, -6)
	border:SetFrameLevel(button:GetFrameLevel() + 2)
	button.Border = border

	-- adjust the stack count
	local count = border:CreateFontString(nil, "OVERLAY")
	count:SetFontObject(GetFont(12,true))
	count:SetTextColor(oUF.colors.offwhite:GetRGB())
	count:ClearAllPoints()
	count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 3)
	button.Count = count

	local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cooldown:SetAllPoints(icon)
	cooldown:SetHideCountdownNumbers(true)
	cooldown:SetDrawBling(false)
	cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
	button.Cooldown = cooldown

	local time = border:CreateFontString(nil, "OVERLAY")
	time:SetFontObject(GetFont(14, true))
	time:SetPoint("TOPLEFT", button, "TOPLEFT", -5, 5)
	time:SetTextColor(oUF.colors.offwhite:GetRGB())
	button.Time = time

	button:SetSize(36,36)
	button:SetIcon(icon)
	button:SetDurationCooldown(cooldown)
	button:SetDurationText(time, { textFormatter = timeFormatter })

	Auras_CreateFourSlice(button, true, false)
end

-- NamePlate debuffs
ns.AuraButton_InitializeNamePlateDebuff = function(button)
	local icon = button:CreateTexture(nil, "BORDER")
	icon:SetMask(GetMedia("actionbutton-mask-square"))
	icon:SetPoint("TOPLEFT", 2, -2)
	icon:SetPoint("BOTTOMRIGHT", -2, 2)
	icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	button.Icon = icon

	local border = CreateFrame("Frame", nil, button, "BackdropTemplate")
	border:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 12 })
	border:SetBackdropBorderColor(oUF.colors.verydarkgray:GetRGB())
	border:SetPoint("TOPLEFT", -6, 6)
	border:SetPoint("BOTTOMRIGHT", 6, -6)
	border:SetFrameLevel(button:GetFrameLevel() + 2)
	button.Border = border

	local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cooldown:SetAllPoints(icon)
	cooldown:SetHideCountdownNumbers(true)
	cooldown:SetDrawBling(false)
	cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
	button.Cooldown = cooldown

	local time = border:CreateFontString(nil, "OVERLAY")
	time:SetFontObject(GetFont(11, true))
	time:SetPoint("TOPLEFT", button, "TOPLEFT", -5, 5)
	time:SetTextColor(oUF.colors.offwhite:GetRGB())
	button.Time = time

	button:SetSize(22, 22)
	button:SetIcon(icon)
	button:SetDurationCooldown(cooldown)
	button:SetDurationText(time, { textFormatter = timeFormatter })
end

-- NamePlate CC
ns.AuraButton_InitializeNamePlateCC = function(button)
	local icon = button:CreateTexture(nil, "BORDER")
	icon:SetMask(GetMedia("actionbutton-mask-square"))
	icon:SetPoint("TOPLEFT", 2, -2)
	icon:SetPoint("BOTTOMRIGHT", -2, 2)
	icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	button.Icon = icon

	local border = CreateFrame("Frame", nil, button, "BackdropTemplate")
	border:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 12 })
	border:SetBackdropBorderColor(oUF.colors.verydarkgray:GetRGB())
	border:SetPoint("TOPLEFT", -6, 6)
	border:SetPoint("BOTTOMRIGHT", 6, -6)
	border:SetFrameLevel(button:GetFrameLevel() + 2)
	button.Border = border

	local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cooldown:SetAllPoints(icon)
	cooldown:SetHideCountdownNumbers(true)
	cooldown:SetDrawBling(false)
	cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
	button.Cooldown = cooldown

	local time = border:CreateFontString(nil, "OVERLAY")
	time:SetFontObject(GetFont(11, true))
	time:SetPoint("TOPLEFT", button, "TOPLEFT", -5, 5)
	time:SetTextColor(oUF.colors.offwhite:GetRGB())
	button.Time = time

	button:SetSize(18, 18)
	button:SetIcon(icon)
	button:SetDurationCooldown(cooldown)
	button:SetDurationText(time, { textFormatter = timeFormatter })
end

-- NamePlate Buffs
ns.AuraButton_InitializeNamePlateBuff = function(button)
	local icon = button:CreateTexture(nil, "BORDER")
	icon:SetMask(GetMedia("actionbutton-mask-square"))
	icon:SetPoint("TOPLEFT", 2, -2)
	icon:SetPoint("BOTTOMRIGHT", -2, 2)
	icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	button.Icon = icon

	local border = CreateFrame("Frame", nil, button, "BackdropTemplate")
	border:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 12 })
	border:SetBackdropBorderColor(oUF.colors.verydarkgray:GetRGB())
	border:SetPoint("TOPLEFT", -6, 6)
	border:SetPoint("BOTTOMRIGHT", 6, -6)
	border:SetFrameLevel(button:GetFrameLevel() + 2)
	button.Border = border

	local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cooldown:SetAllPoints(icon)
	cooldown:SetHideCountdownNumbers(true)
	cooldown:SetDrawBling(false)
	cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
	button.Cooldown = cooldown

	local time = border:CreateFontString(nil, "OVERLAY")
	time:SetFontObject(GetFont(11, true))
	time:SetPoint("TOPLEFT", button, "TOPLEFT", -5, 5)
	time:SetTextColor(oUF.colors.offwhite:GetRGB())
	button.Time = time

	button:SetSize(18, 18)
	button:SetIcon(icon)
	button:SetDurationCooldown(cooldown)
	button:SetDurationText(time, { textFormatter = timeFormatter })
end

-- Generates a sorted list of whitelisted auras by keywords, with no duplicates
-- *accepted keywords are the whitelist table indices
ns.GetAuraWhitelistByKeywords = function(...)
	clear()
	for i = 1,select("#", ...) do
		local key = select(i, ...)
		local source = whitelist[(string.lower(key))]
		if (source) then
			copy(source)
		end
	end
	for i in next,list do list[i] = nil end
	for auraID in next,cache do
		list[#list + 1] = auraID
	end
	table.sort(list)
	return unpack(list)
end

-- oUF Scripts
-----------------------------------------
local UpdateTooltip = function(self)
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:SetUnit(self.unit)
end

local OnEnter = function(self)
	if (GameTooltip:IsForbidden()) then return end

	local unit = self.__unit or self:GetAttribute("unit")
	if (not unit or not UnitExists(unit)) then return end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)

	if (GameTooltip:SetUnit(unit)) then
		GameTooltip:Show()
	end
end

local OnLeave = function(self)
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:Hide()
end

local RegisterMouseScripts = function(self)
	self:RegisterForClicks("AnyUp")
	self:EnableMouse(true) -- this isn't automatic anymore?
	self:SetScript("OnEnter", OnEnter) 
	self:SetScript("OnLeave", OnLeave)
end

oUF:RegisterMetaFunction("RegisterMouseScripts", RegisterMouseScripts)

-- Classic oUF parents new frames to its own frame, 
-- but that frame hasn't had its points set.
-- This messes up our movable frame system.
local SetAllParentPoints = function(self)
	local parent = self:GetParent()
	if (parent ~= UIParent) then
		parent:ClearAllPoints()
		parent:SetAllPoints(UIParent)
	end
end

oUF:RegisterMetaFunction("SetAllParentPoints", SetAllParentPoints)

-- Note that we still need to replace this method because of our  
-- slightly adjusted threat coloring which is incompatible with secret values.
ns.UpdateHealthColor = function(self, event, unit)
	if(not unit or self.__unit ~= unit) then return end
	local element = self.Health

	local color
	if(element.colorDisconnected and not UnitIsConnected(unit)) then
		color = self.colors.disconnected
	elseif(element.colorTapping and not UnitPlayerControlled(unit) and UnitIsTapDenied(unit)) then
		color = self.colors.tapped
	--elseif(element.colorThreat and not UnitPlayerControlled(unit) and not issecretvalue(UnitThreatSituation('player', unit)) and UnitThreatSituation('player', unit)) then
	elseif(element.colorThreat and not UnitPlayerControlled(unit) and not issecretvalue(UnitThreatSituation('player', unit)) and UnitThreatSituation('player', unit)) then
		color = self.colors.reaction[4 - UnitThreatSituation('player', unit)] -- prettier, but not secret
	elseif(element.colorClass and (UnitIsPlayer(unit) or UnitInPartyIsAI(unit)))
		or (element.colorClassNPC and not (UnitIsPlayer(unit) or UnitInPartyIsAI(unit)))
		or (element.colorClassPet and UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
		local _, class = UnitClass(unit)
		if(issecretvalue(class)) then
			-- BUG: we can't use custom colors if the class is secret
			-- https://github.com/oUF-wow/oUF/issues/873
			color = C_ClassColor.GetClassColor(class)
		else
			color = self.colors.class[class]
		end
	elseif(element.colorSelection and unitSelectionType(unit, element.considerSelectionInCombatHostile)) then
		color = self.colors.selection[unitSelectionType(unit, element.considerSelectionInCombatHostile)]
	elseif(element.colorReaction and UnitReaction(unit, 'player')) then
		color = self.colors.reaction[UnitReaction(unit, 'player')]
	elseif(element.colorSmooth and self.colors.health:GetCurve()) then
		color = element.values:EvaluateCurrentHealthPercent(self.colors.health:GetCurve())
	elseif(element.colorHealth) then
		color = self.colors.health
	end

	if(color) then
		element:SetStatusBarColor(color:GetRGB())
	end

	--[[ Callback: Health:PostUpdateColor(unit, color)
	Called after the element color has been updated.

	* self  - the Health element
	* unit  - the unit for which the update has been triggered (string)
	* color - the used ColorMixin-based object (table?)
	--]]
	if(element.PostUpdateColor) then
		element:PostUpdateColor(unit, color)
	end
end
