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

for _,addon in next,{ "Bartender4", "ConsolePort_Bar", "Dominos" } do 
	if (C_AddOns.GetAddOnEnableState(addon, UnitGUID("player")) == Enum.AddOnEnableState.All) then
		return 
	end
end

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

-- ID to barName
local barToMod = {
	["bar1"] 		= "MainActionBar",
	["bar2"] 		= "MultiBar1", -- bottom left
	["bar3"] 		= "MultiBar2", -- bottom right
	["bar4"] 		= "MultiBar3", -- rightmost sidebar
	["bar5"] 		= "MultiBar4", -- leftmost sidebar
	["bar6"] 		= (ns.WoW12 or ns.WoWCamelot) and "MultiBar5" or nil,
	["bar7"] 		= (ns.WoW12 or ns.WoWCamelot) and "MultiBar6" or nil,
	["bar8"] 		= (ns.WoW12 or ns.WoWCamelot) and "MultiBar7" or nil,
	["pet"] 		= "PetBar",
	["petbar"] 		= "PetBar",
	["stance"] 		= "StanceBar", 
	["stancebar"] 	= "StanceBar",
	["forms"] 		= "StanceBar"
}
for i = 1,8 do 
	barToMod[tostring(i)] = barToMod["bar"..i] -- add a numeric alias (as string) for each bar
end

local stringsToTable = function(s)
	local t = {}
	for token in string.gmatch(s, "%S+") do
		t[#t + 1] = token
	end
	return t
end

ns.EnableActionBar = function(self, input)
	if (InCombatLockdown()) then return end

	local barID = self:GetArgs(string.lower(input))
	if (not barID or not barToMod[barID]) then return end

	local mod = ns:GetModule(barToMod[barID], true)
	if (mod and mod:IsEnabled()) then
		if (mod.db.profile.enabled) then return end

		mod.db.profile.enabled = true

		-- Tell bar mod to update bar settings
		local bar = mod:GetBar()
		if (bar) then bar:Update() end		
	end
end

ns.DisableActionBar = function(self, input)
	if (InCombatLockdown()) then return end

	local barID = self:GetArgs(string.lower(input))
	if (not barID or not barToMod[barID]) then return end

	local mod = ns:GetModule(barToMod[barID], true)
	if (mod and mod:IsEnabled()) then
		if (not mod.db.profile.enabled) then return end

		mod.db.profile.enabled = false

		-- Tell bar mod to update bar settings
		local bar = mod:GetBar()
		if (bar) then bar:Update() end
	end
end

ns.GenerateActionBarOptionsByBarID = function(barID)
	if (not barID) then return end

	local mod = ns:GetModule(barIDtoModuleName[barID])
	if (not mod or not mod:IsEnabled()) then return end

	local order, name, numButtons

	local numBar = tonumber(barID)
	if (numBar) then
		order = 100 + numBar
		name = L["Action Bar "..barID]
		numButtons = NUM_ACTIONBAR_BUTTONS or 12

	elseif (barID == "pet") then
		order = 110
		name = L["Pet Bar"]
		numButtons = NUM_PET_ACTION_SLOTS or 10

	elseif (barID == "stance") then
		order = 120
		name = L["Stance Bar"]
		numButtons = GetNumShapeshiftForms() or 10 
	end

	if (not order) then return end

	return {
		type = "group",
		name = name,
		order = order;
		args = {
			-- unfinished settings:
			--[[--
				layoutZigZagOffset
				layoutPaddingX
				layoutPaddingY
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
				type = "description", name = "",
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
			numbuttonsSpacer = { 
				type = "description", fontSize = "medium", name = " ", 
				disabled = function() return InCombatLockdown() end,
				hidden = function() return not mod.db.profile.enabled end,
				order = 29
			},
			numbuttons = {
				type = "range", width = "full", min = 1, max = numButtons, step = 1,
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
				type = "range", width = "full", min = 1, max = numButtons, step = 1,
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
				order = 40,
			},
			zigzagstart = {
				type = "range", width = "full", min = 1, max = numButtons, step = 1,
				name = L["Which button to start the ZigZag pattern from"],
				desc = L["Sets what button to start the ZigZag pattern from. This is the ID of the first button on the second row of the pattern."],
				disabled = function() return InCombatLockdown() end,
				hidden = function() return not mod.db.profile.enabled or mod.db.profile.layout == "grid" end,
				get = function(info) return mod.db.profile.layoutZigZagStart end,
				set = function(info,val)
					if InCombatLockdown() then return end
					mod.db.profile.layoutZigZagStart = tonumber(val)
					mod:UpdateSettings()
				end,
				order = 40,
			},
			fadingSpacer = { 
				type = "description", fontSize = "medium", name = " ", 
				disabled = function() return InCombatLockdown() end,
				hidden = function() return not mod.db.profile.enabled end,
				order = 99 
			},
			enablebarfading = {
				type = "toggle", width = "full",
				name = L["Enable Action Bar fading."],
				desc = L["Sets whether the Action Bar should fade out or not."],
				disabled = function() return InCombatLockdown() end,
				hidden = function() return not mod.db.profile.enabled end,
				get = function(info) return mod.db.profile.enableBarFading end,
				set = function(info, val) 
					if InCombatLockdown() then return end
					mod.db.profile.enableBarFading = val 
					mod:UpdateSettings()
				end,
				order = 100
			},
			fadeincombat = {
				type = "toggle", width = "full",
				name = L["Keep faded while engaged in combat."],
				desc = L["Prevents the faded Action Buttons from automatically becoming visible when engaged in combat. Faded Action Buttons are still visible when moused over."],
				disabled = function() return InCombatLockdown() end,
				hidden = function() return not mod.db.profile.enabled end,
				get = function(info) return mod.db.profile.fadeInCombat end,
				set = function(info, val) 
					if InCombatLockdown() then return end
					mod.db.profile.fadeInCombat = val 
					mod:UpdateSettings()
				end,
				order = 110
			},
			fadefrom = {
				type = "range", width = "full", min = 1, max = numButtons, step = 1,
				name = L["Start fading from button ID"],
				desc = L["Sets what button ID the fading begins at."],
				disabled = function() return InCombatLockdown() end,
				hidden = function() return not mod.db.profile.enabled end,
				get = function(info) return mod.db.profile.fadeFrom end,
				set = function(info,val)
					if InCombatLockdown() then return end
					mod.db.profile.fadeFrom = val
					mod:UpdateSettings()
				end,
				order = 120
			}
		}
	}
end

ns.SetActionBarLayout = function(self, input)
	if (InCombatLockdown()) then return end

	local args = stringsToTable(input)
	--local args = { self:GetArgs(string.lower(input)) }

	if (#args < 2) then return end -- nonsensical

	local barID = args[1]
	if (not barID or not barToMod[barID]) then return end -- invalid bar

	local mod = ns:GetModule(barToMod[barID], true)
	if (mod and mod:IsEnabled()) then
		if (not mod.db.profile.enabled) then return end

		local db = mod.db.profile -- shorthand for bar settings

		local layout -- layout type (grid or zigzag)
		local growth, growthH, growthV -- first growth direction, horizontal growth direction, vertical growth direction
		local numButtons, breakPoint -- maximum number of visible buttons, number of buttons pr row when grid or from where zigzagging begins
		local fade, noFade, fadeFrom, fadeInCombat, noFadeInCombat -- fade switches

		-- parse the remaining arguments and temporarily store values
		local curArgID, numArgs = 2,#args -- current argument, total number of available arguments
		local arg = string.lower((args[curArgID])) -- retrieve next argument

		while (curArgID <= numArgs) 
		do 
			local prevArgID = curArgID

			-- check for optional layout type
			-- *will use existing layout if not provided
			if (not layout) then
				if (arg == "grid" or arg == "zigzag") then 
					layout = arg -- assign the layout type

					curArgID = curArgID + 1 -- increase argument counter
					if (curArgID > numArgs) then break end -- bail out if all args are parsed

					arg = string.lower(args[curArgID]) -- retrieve next argument

					-- parse for grid width or zigzag start
					if (not breakPoint) then

						-- parse for maximum number of buttons in primary growth direction
						if (layout == "grid" and arg == "size") then
							curArgID = curArgID + 1 -- increase argument counter
							if (curArgID > numArgs) then break end -- bail out if all args are parsed

							arg = string.lower(args[curArgID]) -- retrieve next argument

							breakPoint = tonumber(arg) -- verify it's a number 
							if (breakPoint) then
								curArgID = curArgID + 1 -- increase argument counter
								if (curArgID > numArgs) then break end -- bail out if all args are parsed

								arg = string.lower(args[curArgID]) -- retrieve next argument
							end

						-- parse for button to start zigzagging from
						elseif (layout == "zigzag" and arg == "from") then
							curArgID = curArgID + 1 -- increase argument counter
							if (curArgID > numArgs) then break end -- bail out if all args are parsed

							arg = string.lower(args[curArgID]) -- retrieve next argument

							breakPoint = tonumber(arg) -- verify it's a number 
							if (breakPoint) then
								curArgID = curArgID + 1 -- increase argument counter
								if (curArgID > numArgs) then break end -- bail out if all args are parsed

								arg = string.lower(args[curArgID]) -- retrieve next argument
							end
						end
					end

				end
			end

			-- parse for primary growth direction
			-- *always assume this is the first directional argument
			if (not growth) then
				if (arg == "right" or arg == "left") then
					growth = "horizontal"
					growthH = string.upper(arg)

					curArgID = curArgID + 1 -- increase argument counter
					if (curArgID > numArgs) then break end -- bail out if all args are parsed

					arg = string.lower(args[curArgID]) -- retrieve next argument

					-- parse for breakpoint growth direction
					-- *this is technically optional, since all buttons can be on a row
					if (arg == "up" or arg == "down") then
						growthV = string.upper(arg)

						curArgID = curArgID + 1 -- increase argument counter
						if (curArgID > numArgs) then break end -- bail out if all args are parsed

						arg = string.lower(args[curArgID]) -- retrieve next argument
					end

				elseif (arg == "up" or arg == "down") then
					growth = "vertical"
					growthV = string.upper(arg)

					curArgID = curArgID + 1 -- increase argument counter
					if (curArgID > numArgs) then break end -- bail out if all args are parsed

					arg = string.lower(args[curArgID]) -- retrieve next argument

					-- parse for breakpoint growth direction
					-- *this is technically optional, since all buttons can be on a row
					if (arg == "right" or arg == "left") then
						growthH = string.upper(arg)

						curArgID = curArgID + 1 -- increase argument counter
						if (curArgID > numArgs) then break end -- bail out if all args are parsed

						arg = string.lower(args[curArgID]) -- retrieve next argument
					end
				end
			end

			-- parse for maximum visible buttons
			if (not numButtons) then
				if (arg == "max") then
					curArgID = curArgID + 1 -- increase argument counter
					if (curArgID > numArgs) then break end -- bail out if all args are parsed

					arg = string.lower(args[curArgID]) -- retrieve next argument

					numButtons = tonumber(arg) -- verify it's a number 
					if (numButtons) then
						numButtons = math.max(math.min(numButtons, NUM_ACTIONBAR_BUTTONS), 1)

						curArgID = curArgID + 1 -- increase argument counter
						if (curArgID > numArgs) then break end -- bail out if all args are parsed

						arg = string.lower(args[curArgID]) -- retrieve next argument
					end
				end
			end

			-- parse for button fading (unrelated to explorer mode which fades the entire bar)
			if (arg == "fade" and not noFade) then -- ignore opposite args
				fade = true

				curArgID = curArgID + 1 -- increase argument counter
				if (curArgID > numArgs) then break end -- bail out if all args are parsed

				arg = string.lower(args[curArgID]) -- retrieve next argument

				if (arg == "from") then
					curArgID = curArgID + 1 -- increase argument counter
					if (curArgID > numArgs) then break end -- bail out if all args are parsed

					arg = string.lower(args[curArgID]) -- retrieve next argument

					fadeFrom = tonumber(arg) -- retrieve first fade button
					if (fadeFrom) then
						curArgID = curArgID + 1 -- increase argument counter
						if (curArgID > numArgs) then break end -- bail out if all args are parsed

						arg = string.lower(args[curArgID]) -- retrieve next argument
					end
				end

			elseif (arg == "nofade" and not fade) then -- ignore opposite args
				noFade = true

				curArgID = curArgID + 1 -- increase argument counter
				if (curArgID > numArgs) then break end -- bail out if all args are parsed
				
				arg = string.lower(args[curArgID]) -- retrieve next argument
			end

			-- avoid a neverending loop on bad unrecognized input where nothing was parsed
			if (curArgID == prevArgID) then 
				curArgID = curArgID + 1
			end
		end

		-- assign generic settings
		if (layout) then db.layout = layout end
		if (growth) then db.layoutGrowth = growth end
		if (growthH) then db.layoutGrowthHorizontal = growthH end
		if (growthV) then db.layoutGrowthVertical = growthV end
		if (numButtons) then db.numbuttons = numButtons end
		if (fade) then db.enableBarFading = true end
		if (noFade) then db.enableBarFading = false end
		if (fadeInCombat) then db.fadeInCombat = true end
		if (noFadeInCombat) then db.fadeInCombat = false end
		if (fadeFrom) then db.fadeFrom = fadeFrom end

		-- assign layout depending settings
		-- *note that breakPoint refers to different things in different layouts
		if (breakPoint) then
			if (db.layout == "grid") then
				
				-- illustrates maximum number of buttons on a line
				db.layoutGridSize = breakPoint

			elseif (db.layout == "zigzag") then

				-- illustrates from which button the zigzag pattern begins
				db.layoutZigZagStart = breakPoint

				-- illustrates the fraction of the button size  
				-- the buttons will zigzag relative to the main line
				-- *will leave this uneditable for now
				--db.layoutZigZagOffset
			end
		end

		-- Tell bar mod to update bar settings
		local bar = mod:GetBar()
		if (bar) then bar:Update() end		
	end
end

-- Move to actionbar module, only enable if no conflicts are detected
ns:RegisterChatCommand("enablebar", "EnableActionBar") -- enable an action bar
ns:RegisterChatCommand("disablebar", "DisableActionBar") -- disable an action bar
ns:RegisterChatCommand("setbar", "SetActionBarLayout") -- specify bar layout and button count
