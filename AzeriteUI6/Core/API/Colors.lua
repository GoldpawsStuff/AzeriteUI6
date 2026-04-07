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

-- We're just going to piggyback on oUF's color table
-- for all colors in the entire user interface.
local oUF = ns.oUF or oUF

-- general interface colors
oUF.colors.normal = oUF:CreateColor(229, 178, 38)
oUF.colors.highlight = oUF:CreateColor(250, 250, 250)
oUF.colors.title = oUF:CreateColor(255, 234, 137)
oUF.colors.white = oUF:CreateColor(220, 220, 220)
oUF.colors.offwhite = oUF:CreateColor(196, 196, 196)
oUF.colors.green = oUF:CreateColor(25, 178, 25)
oUF.colors.red = oUF:CreateColor(204, 25, 25)
oUF.colors.darkred = oUF:CreateColor(179, 25, 25)
oUF.colors.palered = oUF:CreateColor(204, 68, 68)
oUF.colors.paleblue = oUF:CreateColor(25, 125, 205)
oUF.colors.brightred = oUF:CreateColor(249, 68, 68)
oUF.colors.brightblue = oUF:CreateColor(178, 178, 249)
oUF.colors.gray = oUF:CreateColor(128, 128, 128)
oUF.colors.darkgray = oUF:CreateColor(89, 79, 69)
oUF.colors.verydarkgray = oUF:CreateColor(49, 39, 29) -- 69, 59, 49
oUF.colors.ui = oUF:CreateColor(192, 192, 192)
oUF.colors.uidark = oUF:CreateColor(144, 144, 144)
oUF.colors.aura = oUF:CreateColor(251, 120, 29)

-- movable frames anchor coloring
oUF.colors.anchor = {}
oUF.colors.anchor.general = oUF:CreateColor(128, 255, 128)
oUF.colors.anchor.actionbars = oUF:CreateColor(64, 192, 255)
oUF.colors.anchor.unitframes = oUF:CreateColor(255, 160, 64)
oUF.colors.anchor.floaters = oUF:CreateColor(255, 192, 128)

-- xp, rep and artifact coloring
oUF.colors.xp = oUF:CreateColor(116, 23, 229) -- xp bar
oUF.colors.xpValue = oUF:CreateColor(145, 77, 229) -- xp bar text
oUF.colors.rested = oUF:CreateColor(163, 23, 229) -- xp bar while being rested
oUF.colors.restedValue = oUF:CreateColor(203, 77, 229) -- xp bar text while being rested
oUF.colors.restedBonus = oUF:CreateColor(69, 17, 134) -- rested bonus bar
oUF.colors.artifact = oUF:CreateColor(229, 204, 127)

-- unit specifics
oUF.colors.health = oUF:CreateColor(245, 0, 45)
oUF.colors.healthdark = oUF:CreateColor(195, 0, 45)
oUF.colors.cast = oUF:CreateColor(70, 255, 131)
oUF.colors.disconnected = oUF:CreateColor(120, 120, 120)
oUF.colors.tapped = oUF:CreateColor(121, 101, 96)
oUF.colors.dead = oUF:CreateColor(121, 101, 96)

-- quest difficulty
oUF.colors.quest = {}
oUF.colors.quest.red = oUF:CreateColor(204, 26, 26)
oUF.colors.quest.orange = oUF:CreateColor(255, 106, 26)
oUF.colors.quest.yellow = oUF:CreateColor(255, 178, 38)
oUF.colors.quest.green = oUF:CreateColor(89, 201, 89)
oUF.colors.quest.gray = oUF:CreateColor(120, 120, 120)

-- debuffs
oUF.colors.debuff = {}
oUF.colors.debuff.none = oUF:CreateColor(204, 0, 0)
oUF.colors.debuff.Magic = oUF:CreateColor(51, 153, 255)
oUF.colors.debuff.Curse = oUF:CreateColor(204, 0, 255)
oUF.colors.debuff.Disease = oUF:CreateColor(153, 102, 0)
oUF.colors.debuff.Poison = oUF:CreateColor(0, 153, 0)
oUF.colors.debuff[""] = oUF:CreateColor(0, 0, 0)

-- faction
oUF.colors.faction = {}
oUF.colors.faction.Alliance = oUF:CreateColor(74, 84, 232)
oUF.colors.faction.Horde = oUF:CreateColor(229, 13, 18)
oUF.colors.faction.Neutral = oUF:CreateColor(249, 158, 35)

-- These are our custom colors. 
-- They're more moderate than the default ones.
oUF.colors.combatfeedback = {} -- shouldn't exist
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

-- zone names
oUF.colors.zone = {}
oUF.colors.zone.arena = oUF:CreateColor(175, 76, 56)
oUF.colors.zone.combat = oUF:CreateColor(175, 76, 56)
oUF.colors.zone.contested = oUF:CreateColor(229, 159, 28)
oUF.colors.zone.friendly = oUF:CreateColor(64, 175, 38)
oUF.colors.zone.hostile = oUF:CreateColor(175, 76, 56)
oUF.colors.zone.sanctuary = oUF:CreateColor(104, 204, 239)
oUF.colors.zone.unknown = oUF:CreateColor(255, 234, 137) -- instances, bgs, contested zones on pve realms

-- blizzard item rarity colors
oUF.colors.blizzquality = {}
for i,v in pairs(ITEM_QUALITY_COLORS) do
	oUF.colors.blizzquality[i] = oUF:CreateColor(v.r, v.g, v.b)
end

-- indexed item rarity colors
oUF.colors.quality = {}
oUF.colors.quality[0] = oUF:CreateColor(157, 157, 157) -- Poor
oUF.colors.quality[1] = oUF:CreateColor(240, 240, 240) -- Common
oUF.colors.quality[2] = oUF:CreateColor(30, 198, 0) -- Uncommon
oUF.colors.quality[3] = oUF:CreateColor(0, 112, 221) -- Rare
oUF.colors.quality[4] = oUF:CreateColor(163, 53, 238) -- Epic
oUF.colors.quality[5] = oUF:CreateColor(225, 96, 0) -- Legendary
oUF.colors.quality[6] = oUF:CreateColor(229, 204, 127) -- Artifact
oUF.colors.quality[7] = oUF:CreateColor(79, 196, 225) -- Heirloom
oUF.colors.quality[8] = oUF:CreateColor(79, 196, 225) -- Blizzard

-- named item rarity colors
oUF.colors.quality.Poor = oUF.colors.quality[0]
oUF.colors.quality.Common = oUF.colors.quality[1]
oUF.colors.quality.Uncommon = oUF.colors.quality[2]
oUF.colors.quality.Rare = oUF.colors.quality[3]
oUF.colors.quality.Epic = oUF.colors.quality[4]
oUF.colors.quality.Legendary = oUF.colors.quality[5]
oUF.colors.quality.Artifact = oUF.colors.quality[6]
oUF.colors.quality.Heirloom = oUF.colors.quality[7]
oUF.colors.quality.WoWToken = oUF.colors.quality[8]
oUF.colors.quality.Blizard = oUF.colors.quality[8]

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

-- blizzard's new colors, extracted in-game, leaving here for reference
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
oUF.colors.selection[oUF.Enum.SelectionType.Hostile] = oUF:CreateColor(205, 46, 36)
oUF.colors.selection[oUF.Enum.SelectionType.Unfriendly] = oUF:CreateColor(192, 98, 0)
oUF.colors.selection[oUF.Enum.SelectionType.Neutral] = oUF:CreateColor(249, 225, 55) -- (249, 188, 55)
oUF.colors.selection[oUF.Enum.SelectionType.Friendly] = oUF:CreateColor(64, 131, 38)
oUF.colors.selection[oUF.Enum.SelectionType.PlayerSimple] = oUF:CreateColor(0, 0, 255)
oUF.colors.selection[oUF.Enum.SelectionType.PlayerExtended] = oUF:CreateColor(96, 96, 255)
oUF.colors.selection[oUF.Enum.SelectionType.Party] = oUF:CreateColor(170, 170, 255)
oUF.colors.selection[oUF.Enum.SelectionType.PartyPvP] = oUF:CreateColor(170, 255, 170)
oUF.colors.selection[oUF.Enum.SelectionType.Friend] = oUF:CreateColor(83, 201, 255)
oUF.colors.selection[oUF.Enum.SelectionType.Dead] = oUF:CreateColor(121, 101, 96)
oUF.colors.selection[oUF.Enum.SelectionType.PartyPvPInBattleground] = oUF:CreateColor(0, 153, 0)
oUF.colors.selection[oUF.Enum.SelectionType.RecentAlly] = oUF:CreateColor(83, 201, 255)

-- threat coloring
oUF.colors.threat[0] = oUF.colors.reaction[4] -- not really on the threat table
oUF.colors.threat[1] = oUF.colors.reaction[3] -- tanks having lost threat, dps overnuking
oUF.colors.threat[2] = oUF.colors.reaction[2] -- tanks about to lose threat, dps getting aggro
oUF.colors.threat[3] = oUF.colors.reaction[1] -- securely tanking, or totally fucked :)

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

-- are death runes still a thing?
oUF.colors.runes[1] = oUF:CreateColor(196, 31, 60) -- blood
oUF.colors.runes[2] = oUF:CreateColor(63, 103, 154) -- frost
oUF.colors.runes[3] = oUF:CreateColor(73, 180, 28) -- unholy
oUF.colors.runes[4] = oUF:CreateColor(173, 62, 145) -- death

-- timers (breath, fatigue, etc)
oUF.colors.timer = {}
oUF.colors.timer.UNKNOWN = oUF:CreateColor(179, 77, 0) -- fallback for timers and unknowns
oUF.colors.timer.EXHAUSTION = oUF:CreateColor(179, 77, 0)
oUF.colors.timer.BREATH = oUF:CreateColor(0, 128, 255)
oUF.colors.timer.DEATH = oUF:CreateColor(217, 90, 0)
oUF.colors.timer.FEIGNDEATH = oUF:CreateColor(217, 90, 0)
