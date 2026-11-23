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

local LossOfControl = ns:NewModule("LossOfControl", nil, "LibMoreEvents-1.0", "LibMovableFrames-1.0", "AceHook-3.0")


-- Declare module defaults
local defaults = { profile = {
	enabled = true,
	--[[--

	--]]--
}}

LossOfControl.StyleLossOfControlFrame = function(self, frame)
	if (not frame) then return end

	-- Remove the red glow
	if (frame.RedLineTop) then
		frame.RedLineTop:SetAlpha(0)
		frame.RedLineTop:Hide()
	end
	if (frame.RedLineBottom) then
		frame.RedLineBottom:SetAlpha(0)
		frame.RedLineBottom:Hide()
	end

	-- Adjust black backdrop opacity (0.0–1.0). Default is 0.6.
	if (frame.blackBg) then
		frame.blackBg:SetAlpha(.25)	
	end

	-- Optional: tone down or hide the cooldown edge glow if present
	if (frame.Cooldown and frame.Cooldown.SetDrawEdge) then
		-- frame.Cooldown:SetDrawEdge(false) -- uncomment if you want the edge gone too
	end
end

LossOfControl.GetDefaults = function(self)
	return defaults
end

-- This is called by the options menu on settings changes,
-- and by the modules themselves on enabling.
LossOfControl.UpdateSettings = function(self)
end

-- This is called by the addon on full profile changes,
-- and should call a full settings update.
LossOfControl.RefreshConfig = function(self)
	self:UpdateSettings()
end

LossOfControl.OnInitialize = function(self)
	self.db = ns.db:RegisterNamespace("LossOfControl", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

LossOfControl.OnEnable = function(self)
	local frame = _G.LossOfControlFrame
	if (not frame) then return end

	-- Apply immediately and whenever it is shown / set up
	self:StyleLossOfControlFrame(frame)
	self:HookScript(frame, "OnShow", "StyleLossOfControlFrame")

	if (type(LossOfControlFrame_SetUpDisplay) == "function") then
		self:SecureHook("LossOfControlFrame_SetUpDisplay", "StyleLossOfControlFrame")
	end
end
