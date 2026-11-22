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

local ErrorsFrame = ns:NewModule("ErrorsFrame", nil, "LibMoreEvents-1.0", "LibMovableFrames-1.0")

local FLASH_DURATION = .2
local FLASH_STRENGTH = .4

local flashing = {}

-- Declare module defaults
local defaults = { profile = {
	enabled = true,
	maxLines = 1,
	maxLinesSysMsg = 3,
}}

local getTopFontString = function(frame)
	local regions = { frame:GetRegions() }
	for i = #regions, 1, -1 do
		local region = regions[i]
		if (region and region:IsObjectType("FontString") and region:IsShown() and region:GetText()) then
			return region
		end
	end
end

local onFlashUpdate = function(self)
	local now = GetTime()
	local anyFlashing = false

	for fs, data in next, flashing do
		if (fs and data) then
			local progress = (now - data.start) / FLASH_DURATION
			if (progress >= 1) then
				fs:SetTextColor(data.originalR, data.originalG, data.originalB)
				flashing[fs] = nil
			else
				anyFlashing = true
				local ease = 1 - progress
				local flashR = data.originalR + (1 - data.originalR) * FLASH_STRENGTH * ease
				local flashG = data.originalG + (1 - data.originalG) * FLASH_STRENGTH * ease
				local flashB = data.originalB + (1 - data.originalB) * FLASH_STRENGTH * ease
				fs:SetTextColor(flashR, flashG, flashB)
			end
		else
			flashing[fs] = nil
		end
	end

	if (not anyFlashing) then
		self:SetScript("OnUpdate", nil)
	end
end

local flashFontString = function(frame, fontString)
	if (not fontString) then return end

	local r, g, b = fontString:GetTextColor()
	if (not r) then return end

	flashing[fontString] = {
		start = GetTime(),
		originalR = r,
		originalG = g,
		originalB = b
	}

	if (not frame:GetScript("OnUpdate")) then
		frame:SetScript("OnUpdate", onFlashUpdate)
	end
end

local tryFlashExisting = function(frame, message)
	if (not message or message == "") then return end

	local top = getTopFontString(frame)
	if (top and top:GetText() == message) then
		flashFontString(frame, top)
		return true
	end

	return false
end

local addMessage = function(frame, message, r, g, b, a, messageType)
	if (tryFlashExisting(frame, message)) then
		return
	end

	-- fall through to original
	if (frame.__AddMessage) then
		frame.__AddMessage(frame, message, r, g, b, a, messageType)
	end
end

ErrorsFrame.SetMaxLines = function(self, maxLines)
	maxLines = maxLines or defaults.profile.maxLines

	local _, fontHeight = self.ErrorsFrame:GetFont()
	local lineHeight = fontHeight or 16

	self.ErrorsFrame:SetHeight(lineHeight * maxLines + 6)
end

ErrorsFrame.SetMaxSysLines = function(self, maxLines)
	maxLines = maxLines or defaults.profile.maxLines

	local _, fontHeight = UIErrorsFrame:GetFont()
	local lineHeight = fontHeight or 16

	UIErrorsFrame:SetHeight(lineHeight * maxLines + 6)
end

ErrorsFrame.GetDefaults = function(self)
	return defaults
end

ErrorsFrame.GetOptions = function(self)
	return {
		type = "group",
		name = "System Message Frames",
		arg = { menuName = "Error Messages" },
		order = 8000,
		args = {
			--enable = {
			--	type = "toggle", width = "full",
			--	name = L["Enable"],
			--	desc = "Toggle the usage of the UIErrorsFrame.",
			--	disabled = function() return InCombatLockdown() end,
			--	get = function(info) return self.db.profile.enabled end,
			--	set = function(info, val) 
			--		if InCombatLockdown() then return end
			--		self.db.profile.enabled = val 
			--		self:UpdateSettings()
			--	end,
			--	order = 1
			--},
			maxLines = {
				type = "range", width = "double", min = 1, max = 3, step = 1,
				name = "Number of visible error message lines",
				desc = "Sets the number of visible error message lines at once. Error messages are the red messages below your character informing you that you have too little mana, rage, energy, facing the wrong direction, being too far away and similar.",
				disabled = function() return InCombatLockdown() end,
				hidden = function() return not self.db.profile.enabled end,
				get = function(info) return self.db.profile.maxLines end,
				set = function(info,val)
					if InCombatLockdown() then return end
					self.db.profile.maxLines = tonumber(val)
					self:UpdateSettings()
				end,
				order = 100
			},
			maxLinesSysMsg = {
				type = "range", width = "double", min = 1, max = 3, step = 1,
				name = "Number of visible system message lines",
				desc = "Sets the number of visible system message lines at once. System messages are the yellow messages on top of your screen informing you of completed quest objectives and similar.",
				disabled = function() return InCombatLockdown() end,
				hidden = function() return not self.db.profile.enabled end,
				get = function(info) return self.db.profile.maxLinesSysMsg end,
				set = function(info,val)
					if InCombatLockdown() then return end
					self.db.profile.maxLinesSysMsg = tonumber(val)
					self:UpdateSettings()
				end,
				order = 200
			}
		}
	}
end

ErrorsFrame.ResetToGameDefaults = function(self)
	self:SetMaxLines(3)

	self.SysMsgFrame:ClearAllPoints()
	self.SysMsgFrame:SetPoint("TOP", 0, -122)
end

ErrorsFrame.ResetToDefaults = function(self)
	self:SetMaxLines(self.db.profile.maxLines)

	self.SysMsgFrame:ClearAllPoints()
	self.SysMsgFrame:SetPoint("CENTER", 0, -180)

end

ErrorsFrame.OnEvent = function(self, event, ...)
	if (event == "SYSMSG") then
		local message, r, g, b = ...

		if (not message or message == "") then return end
		if (tryFlashExisting(self.SysMsgFrame, message)) then return end

		self.SysMsgFrame:AddMessage(message, r or 1, g or 1, b or 1, 1)

	elseif (event == "UI_ERROR_MESSAGE") then

		local messageType, message = ...
		if (type(messageType) == "string") then
			message = messageType
			messageType = nil
		end

		if (not message or message == "") then return end
		if (tryFlashExisting(self.ErrorsFrame, message)) then return end

		self.ErrorsFrame:AddMessage(message, 1, .1, .1, 1)

	elseif (event == "UI_INFO_MESSAGE") then 
		local messageType, message = ...
		if (type(messageType) == "string") then
			message = messageType
			messageType = nil
		end
	
		if (not message or message == "") then return end
		if (tryFlashExisting(self.SysMsgFrame, message)) then return end

		self.SysMsgFrame:AddMessage(message, 1, 1, 0, 1)
	end
end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling.
ErrorsFrame.UpdateSettings = function(self)
	self.SysMsgFrame:SetShown(self.db.profile.enabled)
	self:SetMaxLines(self.db.profile.maxLines)
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
ErrorsFrame.RefreshConfig = function(self)
	self:UpdateSettings()
end

ErrorsFrame.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("ErrorsFrame", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

end

ErrorsFrame.OnEnable = function(self)

	-- Remove only the spammy error event from the original frame.
	-- SYSMSG and UI_INFO_MESSAGE stay on it so other addons keep working.
	self.SysMsgFrame = UIErrorsFrame
	self.SysMsgFrame:UnregisterEvent("UI_ERROR_MESSAGE")
	self.SysMsgFrame:UnregisterEvent("UI_INFO_MESSAGE")
	self.SysMsgFrame:UnregisterEvent("SYSMSG")

	self.SysMsgFrame:SetMovable(true) -- needed for the next line
	self.SysMsgFrame:SetUserPlaced(false) -- disable saving in the on-disk frame cache, it messes with our system
	self.SysMsgFrame:SetMovable(false) -- disable it to prevent the cache from popping back up

	self.SysMsgFrame:ClearAllPoints()
	self.SysMsgFrame:SetPoint("TOP", 0, -122)

	-- Our dedicated error frame
	self.ErrorsFrame = CreateFrame("MessageFrame", "AZUI6_ErrorFrame", UIParent)
	self.ErrorsFrame:SetSize(512, 22) -- single line by default
	self.ErrorsFrame:SetPoint("CENTER", 0, -180)
	self.ErrorsFrame:SetInsertMode("TOP")
	self.ErrorsFrame:SetTimeVisible(2)
	self.ErrorsFrame:SetFadeDuration(.5)
	self.ErrorsFrame:SetFadePower(3)
	self.ErrorsFrame:SetFontObject(self.SysMsgFrame:GetFontObject())
	self.ErrorsFrame:SetJustifyH("CENTER")
	self.ErrorsFrame:SetFrameStrata("DIALOG")
	self.ErrorsFrame:SetFrameLevel(1)

	self.SysMsgFrame.__AddMessage = self.SysMsgFrame.AddMessage
	self.SysMsgFrame.AddMessage = addMessage

	self.ErrorsFrame.__AddMessage = self.ErrorsFrame.AddMessage
	self.ErrorsFrame.AddMessage = addMessage

	self:SetMaxLines(self.db.profile.maxLines)
	self:RegisterMovableFrameAnchor(self.SysMsgFrame, "info frame", "floater", AzeriteUI6_Positions_DB)
	self:RegisterMovableFrameAnchor(self.ErrorsFrame, "error frame", "floater", AzeriteUI6_Positions_DB)

	self:RegisterEvent("UI_ERROR_MESSAGE", "OnEvent")
	self:RegisterEvent("UI_INFO_MESSAGE", "OnEvent")
	self:RegisterEvent("SYSMSG", "OnEvent")

end

