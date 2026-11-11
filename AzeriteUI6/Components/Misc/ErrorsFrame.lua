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

local ErrorsFrame = ns:NewModule("ErrorsFrame", nil, "LibMoreEvents-1.0")

local FLASH_DURATION = 0.2
local FLASH_STRENGTH = 0.4

local flashing = {}

local getTopFontString = function()
	local regions = { UIErrorsFrame:GetRegions() }
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

local flashFontString = function(fontString)
	if (not fontString) then return end

	local r, g, b = fontString:GetTextColor()
	if (not r) then return end

	flashing[fontString] = {
		start = GetTime(),
		originalR = r,
		originalG = g,
		originalB = b
	}

	if (not UIErrorsFrame:GetScript("OnUpdate")) then
		UIErrorsFrame:SetScript("OnUpdate", onFlashUpdate)
	end
end

local tryFlashExisting = function(message)
	if (not message or message == "") then return end

	local top = getTopFontString()
	if (top and top:GetText() == message) then
		flashFontString(top)
		return true
	end
end

local hookedAddMessage = function(self, message, r, g, b, a, messageType)
	if (tryFlashExisting(message)) then
		return
	end

	-- fall through to original
	if (ErrorsFrame.originalAddMessage) then
		ErrorsFrame.originalAddMessage(self, message, r, g, b, a, messageType)
	end
end

ErrorsFrame.OnEvent = function(self, event, ...)
	if (event == "SYSMSG") then
		local message, r, g, b = ...
		if (not message or message == "") then return end

		if (tryFlashExisting(message)) then return end

		UIErrorsFrame:AddMessage(message, r or 1, g or 1, b or 1, 1)

		return
	end

	-- UI_ERROR_MESSAGE / UI_INFO_MESSAGE
	local messageType, message = ...
	if (type(messageType) == "string") then
		message = messageType
		messageType = nil
	end

	if (not message or message == "") then return end

	if (tryFlashExisting(message)) then return end

	local r, g, b = 1, .1, .1
	if (event == "UI_INFO_MESSAGE") then
		r, g, b = 1, 1, 0
	end

	UIErrorsFrame:AddMessage(message, r, g, b, 1)
end

ErrorsFrame.OnEnable = function(self)

	UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
	UIErrorsFrame:UnregisterEvent("UI_INFO_MESSAGE")
	UIErrorsFrame:UnregisterEvent("SYSMSG")

	self:RegisterEvent("UI_ERROR_MESSAGE", "OnEvent")
	self:RegisterEvent("UI_INFO_MESSAGE", "OnEvent")
	self:RegisterEvent("SYSMSG", "OnEvent")

	-- Hook AddMessage as a safety net for any direct calls
	if (not self.originalAddMessage) then
		self.originalAddMessage = UIErrorsFrame.AddMessage
		UIErrorsFrame.AddMessage = hookedAddMessage
	end
end
