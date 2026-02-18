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
local addonName, ns = ...

-- We're just going to piggyback on oUF's color table
-- for all colors in the entire user interface.
local oUF = ns.oUF

-- Various status colors
oUF.colors.disconnected = oUF:CreateColor(120, 120, 120)
oUF.colors.tapped = oUF:CreateColor(121, 101, 96)

-- These are our custom colors. 
-- They're more moderate than the default ones.
oUF.colors.combatfeedback = oUF.colors.combatfeedback or {} -- shouldn't exist
oUF.colors.combatfeedback.STANDARD = oUF:CreateColor(214, 191, 165)
oUF.colors.combatfeedback.IMMUNE = oUF:CreateColor(214, 191, 165)
oUF.colors.combatfeedback.DAMAGE = oUF:CreateColor(176, 79, 79)
oUF.colors.combatfeedback.CRUSHING = oUF:CreateColor(176, 79, 79)
oUF.colors.combatfeedback.CRITICAL = oUF:CreateColor(176, 79, 79)
oUF.colors.combatfeedback.GLANCING = oUF:CreateColor(176, 79, 79)
oUF.colors.combatfeedback.ABSORB = oUF:CreateColor(214, 191, 165)
oUF.colors.combatfeedback.BLOCK = oUF:CreateColor(214, 191, 165)
oUF.colors.combatfeedback.RESIST = oUF:CreateColor(214, 191, 165)
oUF.colors.combatfeedback.MISS = oUF:CreateColor(214, 191, 165)
oUF.colors.combatfeedback.HEAL = oUF:CreateColor(84, 150, 84)
oUF.colors.combatfeedback.CRITHEAL = oUF:CreateColor(84, 150, 84)
oUF.colors.combatfeedback.ENERGIZE = oUF:CreateColor(79, 114, 160)
oUF.colors.combatfeedback.CRITENERGIZE = oUF:CreateColor(79, 114, 160)

-- class colors
-- *Don't worry if some colors appear to be missing, 
--  we're not replacing oUF's tables, we're just adding to them.
oUF.colors.class.DEATHKNIGHT = oUF:CreateColor(176,31, 79)
oUF.colors.class.DEMONHUNTER = oUF:CreateColor(163,48, 201)
oUF.colors.class.DRUID = oUF:CreateColor(245,125, 35)
oUF.colors.class.EVOKER = oUF:CreateColor(51,147, 127)
oUF.colors.class.HUNTER = oUF:CreateColor(191,232, 115)
oUF.colors.class.MAGE = oUF:CreateColor(105,204, 240)
oUF.colors.class.MONK = oUF:CreateColor(0,255, 150)
oUF.colors.class.PALADIN = oUF:CreateColor(245,185, 226)
oUF.colors.class.PRIEST = oUF:CreateColor(176,200, 225)
oUF.colors.class.ROGUE = oUF:CreateColor(255,225, 95)
oUF.colors.class.SHAMAN = oUF:CreateColor(32,122, 222)
oUF.colors.class.WARLOCK = oUF:CreateColor(128,110, 181)
oUF.colors.class.WARRIOR = oUF:CreateColor(229,156, 110)
oUF.colors.class.UNKNOWN = oUF:CreateColor(195,202, 217)

-- blizzard's colors, extracted in-game
--oUF.colors.class.ADVENTURER = oUF:CreateColor(170, 211, 114) 
--oUF.colors.class.TRAVELER = oUF:CreateColor(102, 153, 153) 

-- reputation / reaction colors
oUF.colors.reaction[1] = oUF:CreateColor(205, 46, 36)
oUF.colors.reaction[2] = oUF:CreateColor(205, 46, 36)
oUF.colors.reaction[3] = oUF:CreateColor(192, 98, 0)
oUF.colors.reaction[4] = oUF:CreateColor(249, 225, 55) -- (249, 188, 55)
oUF.colors.reaction[5] = oUF:CreateColor(64, 131, 38)
oUF.colors.reaction[6] = oUF:CreateColor(64, 116, 69)
oUF.colors.reaction[7] = oUF:CreateColor(64, 171, 104)
oUF.colors.reaction[8] = oUF:CreateColor(64, 171, 131)
oUF.colors.reaction.civilian = oUF:CreateColor(64, 161, 38)

-- selection colors
oUF.colors[oUF.Enum.SelectionType.Hostile] = oUF:CreateColor(205, 46, 36)
oUF.colors[oUF.Enum.SelectionType.Unfriendly] = oUF:CreateColor(192, 98, 0)
oUF.colors[oUF.Enum.SelectionType.Neutral] = oUF:CreateColor(249, 225, 55) -- (249, 188, 55)
oUF.colors[oUF.Enum.SelectionType.Friendly] = oUF:CreateColor(64, 131, 38)
oUF.colors[oUF.Enum.SelectionType.PlayerSimple] = oUF:CreateColor(0, 0, 255)
oUF.colors[oUF.Enum.SelectionType.PlayerExtended] = oUF:CreateColor(96, 96, 255)
oUF.colors[oUF.Enum.SelectionType.Party] = oUF:CreateColor(170, 170, 255)
oUF.colors[oUF.Enum.SelectionType.PartyPvP] = oUF:CreateColor(170, 255, 170)
oUF.colors[oUF.Enum.SelectionType.Friend] = oUF:CreateColor(83, 201, 255)
oUF.colors[oUF.Enum.SelectionType.Dead] = oUF:CreateColor(121, 101, 96)
oUF.colors[oUF.Enum.SelectionType.PartyPvPInBattleground] = oUF:CreateColor(0, 153, 0)
oUF.colors[oUF.Enum.SelectionType.RecentAlly] = oUF:CreateColor(83, 201, 255)

-- power colors
oUF.colors.power.MANA = oUF:CreateColor(80, 116, 255)
oUF.colors.power.RAGE = oUF:CreateColor(215, 7, 7)
oUF.colors.power.FOCUS = oUF:CreateColor(125, 168, 195)
oUF.colors.power.ENERGY = oUF:CreateColor(254, 245, 145)
oUF.colors.power.COMBO_POINTS = oUF:CreateColor(220, 68, 25)
oUF.colors.power.RUNES = oUF:CreateColor(100, 155, 225)
oUF.colors.power.RUNIC_POWER = oUF:CreateColor(0, 236, 255)
oUF.colors.power.SOUL_SHARDS = oUF:CreateColor(148, 130, 201)
oUF.colors.power.LUNAR_POWER = oUF:CreateColor(121, 152, 192)
oUF.colors.power.HOLY_POWER = oUF:CreateColor(245, 254, 145)
oUF.colors.power.MAELSTROM = oUF:CreateColor(0, 188, 255)
oUF.colors.power.INSANITY = oUF:CreateColor(102, 64, 204)
oUF.colors.power.FURY = oUF:CreateColor(255, 0, 111)
oUF.colors.power.PAIN = oUF:CreateColor(142, 191, 0)
oUF.colors.power.CHI = oUF:CreateColor(126, 255, 163)
oUF.colors.power.ARCANE_CHARGES = oUF:CreateColor(121, 152, 192)
oUF.colors.power.ESSENCE = oUF:CreateColor(100, 173, 206)
oUF.colors.power.ALTERNATE = oUF:CreateColor(70, 255, 131)

-- custom named variations specific to the player frame
-- will only ever be used for the mana orb and power crystal.
oUF.colors.power.MANA_ORB = oUF:CreateColor(135, 125, 255)
oUF.colors.power.ENERGY_CRYSTAL = oUF:CreateColor(0, 208, 176)
oUF.colors.power.FOCUS_CRYSTAL = oUF:CreateColor(116, 156, 255)
oUF.colors.power.LUNAR_POWER_CRYSTAL = oUF:CreateColor(116, 156, 255)
oUF.colors.power.MAELSTROM_CRYSTAL = oUF:CreateColor(116, 156, 255)
oUF.colors.power.RUNIC_POWER_CRYSTAL = oUF:CreateColor(116, 156, 255)
oUF.colors.power.FURY_CRYSTAL = oUF:CreateColor(156, 116, 255)
oUF.colors.power.INSANITY_CRYSTAL = oUF:CreateColor(156, 116, 255)
oUF.colors.power.PAIN_CRYSTAL = oUF:CreateColor(156, 116, 255)
oUF.colors.power.RAGE_CRYSTAL = oUF:CreateColor(156, 116, 255)
oUF.colors.power.MANA_CRYSTAL = oUF:CreateColor(101, 93, 191)

-- re-assign fallback integer index to named index
oUF.colors.power[Enum.PowerType.Mana or 0] = oUF.colors.power.MANA
oUF.colors.power[Enum.PowerType.Rage or 1] = oUF.colors.power.RAGE
oUF.colors.power[Enum.PowerType.Focus or 2] = oUF.colors.power.FOCUS
oUF.colors.power[Enum.PowerType.Energy or 3] = oUF.colors.power.ENERGY
oUF.colors.power[Enum.PowerType.ComboPoints or 4] = oUF.colors.power.COMBO_POINTS
oUF.colors.power[Enum.PowerType.Runes or 5] = oUF.colors.power.RUNES
oUF.colors.power[Enum.PowerType.RunicPower or 6] = oUF.colors.power.RUNIC_POWER
oUF.colors.power[Enum.PowerType.SoulShards or 7] = oUF.colors.power.SOUL_SHARDS
oUF.colors.power[Enum.PowerType.LunarPower or 8] = oUF.colors.power.LUNAR_POWER
oUF.colors.power[Enum.PowerType.HolyPower or 9] = oUF.colors.power.HOLY_POWER
oUF.colors.power[Enum.PowerType.Maelstrom or 11] = oUF.colors.power.MAELSTROM
oUF.colors.power[Enum.PowerType.Insanity or 13] = oUF.colors.power.INSANITY
oUF.colors.power[Enum.PowerType.Fury or 17] = oUF.colors.power.FURY
oUF.colors.power[Enum.PowerType.Pain or 18] = oUF.colors.power.PAIN
oUF.colors.power[Enum.PowerType.Chi or 12] = oUF.colors.power.CHI
oUF.colors.power[Enum.PowerType.ArcaneCharges or 16] = oUF.colors.power.ARCANE_CHARGES
oUF.colors.power[Enum.PowerType.Essence or 19] = oUF.colors.power.ESSENCE
oUF.colors.power[Enum.PowerType.Alternate or 10] = oUF.colors.power.ALTERNATE
