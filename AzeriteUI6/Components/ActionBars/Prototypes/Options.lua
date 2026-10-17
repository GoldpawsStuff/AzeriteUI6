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

local L = LibStub("AceLocale-3.0"):GetLocale((...))

local barIDtoModuleName = {
	[1] = "MainActionBar",
	[2] = "MultiBar1",
	[3] = "MultiBar2",
	[4] = "MultiBar3",
	[5] = "MultiBar4",
	[6] = "MultiBar5",
	[7] = "MultiBar6",
	[8] = "MultiBar7",
	["pet"] = "PetBar",
	["stance"] = "StanceBar"
}

ns.GenerateActionBarOptionsByBarID = function(barID)
	if (not barID) then return end

	local mod = ns:GetModule(barIDtoModuleName[barID])
	if (not mod) then return end

	if (tonumber(barID)) then
		return {
			type = "group",
			name = L["Action Bar "..barID],
			args = {
				--[[--
				layout
					layoutZigZagStart
					layoutZigZagOffset
					layoutGridSize
					layoutGrowth
					layoutGrowthHorizontal
					layoutGrowthVertical
					layoutPaddingX
					layoutPaddingY
				enableBarFading
					fadeInCombat
					fadeFrom
				--]]--
				enable = {
					type = "toggle", width = "full",
					name = L["Enable"],
					disabled = function() return InCombatLockdown() end,
					get = function(info) return mod.db.profile.enabled end,
					set = function(info, val) 
						if InCombatLockdown() then return end
						mod.db.profile.enabled = val 
						mod:UpdateSettings()
					end,
					order = 1
				},
				layout = {
					type = "select", style = "dropdown", 
					name = L["Action Bar layout"],
					desc = L["Sets the layout type of the Action Bar.|n|n|cff4488ffGrid:|r|nDisplay the Action Bar as a standard row, column or retangular grid of buttons.|n|n|cff4488ffZigZag:|r|nDisplay the Action Bar as the ZigZag pattern seen on the default settings for the Primary Action Bar."],
					values = { ["grid"] = L["Grid"], ["zigzag"] = L["ZigZag"] },
					disabled = function() return InCombatLockdown() end,
					hidden = function() return not mod.db.profile.enabled end,
					get = function(info) return mod.db.profile.layout end,
					set = function(info,val)
						if InCombatLockdown() then return end
						mod.db.profile.layout = val
						mod:UpdateSettings()
					end,
					order = 15
				}, 
				layoutSpacer1 = {
					type = "description", 
					name = "",
					disabled = function() return InCombatLockdown() end,
					hidden = function() return not mod.db.profile.enabled end,
					order = 16
				},
				primarygrowth = {
					type = "select", style = "dropdown", 
					name = L["Primary growth direction"],
					desc = L["Sets which direction the Action Bar initially should expand in."],
					disabled = function() return InCombatLockdown() end,
					hidden = function() return not mod.db.profile.enabled end,
					values = function() 
						if mod.db.profile.layoutGrowth == "horizontal" then 
							return { ["RIGHT"] = "Right", ["LEFT"] = "Left" }
						elseif mod.db.profile.layoutGrowth == "vertical" then 
							return { ["DOWN"] = "Down", ["UP"] = "Up" }
						end
					end,
					get = function(info)
						if mod.db.profile.layoutGrowth == "horizontal" then
							return mod.db.profile.layoutGrowthHorizontal
						elseif mod.db.profile.layoutGrowth == "vertical" then
							return mod.db.profile.layoutGrowthVertical
						end
					end,
					set = function(info,val)
						if InCombatLockdown() then return end
						if mod.db.profile.layoutGrowth == "horizontal" then
							mod.db.profile.layoutGrowthHorizontal = val
						elseif mod.db.profile.layoutGrowth == "vertical" then
							mod.db.profile.layoutGrowthVertical = val
						end
						mod:UpdateSettings()
					end,
					order = 20,
				},
				secondarygrowth = {
					type = "select", style = "dropdown", 
					name = L["Secondary growth direction"],
					desc = L["Sets which direction the Action Bar should start a new line of buttons in."],
					disabled = function() return InCombatLockdown() end,
					hidden = function() return not mod.db.profile.enabled or mod.db.profile.layout == "zigzag" end,
					values = function() 
						if mod.db.profile.layoutGrowth == "horizontal" then
							return { ["DOWN"] = "Down", ["UP"] = "Up" }
						elseif mod.db.profile.layoutGrowth == "vertical" then
							return { ["RIGHT"] = "Right", ["LEFT"] = "Left" }
						end
					end,
					get = function(info)
						if mod.db.profile.layoutGrowth == "horizontal" then
							return mod.db.profile.layoutGrowthVertical
						elseif mod.db.profile.layoutGrowth == "vertical" then
							return mod.db.profile.layoutGrowthHorizontal
						end
					end,
					set = function(info,val)
						if InCombatLockdown() then return end
						if mod.db.profile.layoutGrowth == "horizontal" then
							mod.db.profile.layoutGrowthVertical = val
						elseif mod.db.profile.layoutGrowth == "vertical" then
							mod.db.profile.layoutGrowthHorizontal = val
						end
						mod:UpdateSettings()
					end,
					order = 21,
				},
				numbuttons = {
					type = "range", width = "full", min = 1, max = 12, step = 1,
					name = L["Number of visible buttons"],
					desc = L["Sets the number of visible buttons on the Action Bar."],
					disabled = function() return InCombatLockdown() end,
					hidden = function() return not mod.db.profile.enabled end,
					get = function(info) return mod.db.profile.numbuttons end,
					set = function(info,val)
						if InCombatLockdown() then return end
						mod.db.profile.numbuttons = val
						mod:UpdateSettings()
					end,
					order = 30
				},
				gridsize = {
					type = "range", width = "full", min = 1, max = 12, step = 1,
					name = L["Number of buttons before line-break."],
					desc = L["Sets the width of the Action Bar in number of buttons in its primary growth direction."],
					disabled = function() return InCombatLockdown() end,
					hidden = function() return not mod.db.profile.enabled or mod.db.profile.layout == "zigzag" end,
					get = function(info) return mod.db.profile.layoutGridSize end,
					set = function(info,val)
						if InCombatLockdown() then return end
						mod.db.profile.layoutGridSize = tonumber(val)
						mod:UpdateSettings()
					end,
					order = 31,
				},
				zigzagstart = {
					type = "range", width = "full", min = 1, max = 12, step = 1,
					name = L["First ZigZag button"],
					desc = L["Sets what button to start the ZigZag pattern from. This is the ID of the first button on the second row of the pattern."],
					disabled = function() return InCombatLockdown() end,
					hidden = function() return not mod.db.profile.enabled or mod.db.profile.layout == "grid" end,
					get = function(info) return mod.db.profile.layoutZigZagStart end,
					set = function(info,val)
						if InCombatLockdown() then return end
						mod.db.profile.layoutZigZagStart = tonumber(val)
						mod:UpdateSettings()
					end,
					order = 31,
				},
			}
		}
	end

	if (barID == "pet") then
	end

	if (barID == "stance") then
	end
end

