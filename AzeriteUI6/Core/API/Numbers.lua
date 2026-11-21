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

local rounding = Enum.NumericRuleFormatRounding.Up
local formats = {
	day = "%.0fd",
	hour = "%.0fh",
	minute = "%.0fm",
	seconds = "%.0f",
	haste = "|cffff8800%.0f|r",
	critical = "|cffff0000%.0f|r"
}

local countdownFormatter = C_StringUtil.CreateNumericRuleFormatter()
countdownFormatter:SetBreakpoints({
	{ threshold = 86400, 	format = formats.day, 		components = {{ div = 86400, 	rounding = rounding }} }, -- ≥ 1 day
	{ threshold = 3540, 	format = formats.hour, 		components = {{ div = 3600, 	rounding = rounding }} }, -- ≥ 1 hour
	{ threshold = 59, 		format = formats.minute, 	components = {{ div = 60, 		rounding = rounding }} }, -- ≥ 1 minute
	{ threshold = 5.5, 		format = formats.seconds, 	components = {{ div = 1, 		rounding = rounding }} }, -- ≥ 5 seconds → whole seconds
	{ threshold = .9, 		format = formats.haste, 	components = {{ div = 1, 		rounding = rounding }} }, -- ≥ 1 second → whole seconds
	{ threshold = .05, 		format = formats.critical, 	components = {{ div = .1, 		rounding = rounding }} }, -- < 1 second, tenths of a second
	{ threshold = 0, 		format = "" } 
})

ns.GetCountdownFormatter = function() return countdownFormatter end

local breakPoints = {
	breakpointData = {
		{ breakpoint = 1e12,	abbreviation = "b", significandDivisor = 1e11,	fractionDivisor = 10, abbreviationIsGlobal = false },
		{ breakpoint = 1e9,		abbreviation = "b", significandDivisor = 1e8,	fractionDivisor = 10, abbreviationIsGlobal = false },
		{ breakpoint = 1e6,		abbreviation = "m", significandDivisor = 1e5,	fractionDivisor = 10, abbreviationIsGlobal = false },
		{ breakpoint = 1e3,		abbreviation = "k", significandDivisor = 1e2,	fractionDivisor = 10, abbreviationIsGlobal = false },
	}
}

local zhCNBreakpoints = {
	breakpointData = {
		-- 亿 with no decimals (from 1000亿 upward)
		{
			breakpoint = 1e11,-- 1000亿
			abbreviation = "亿",
			significandDivisor = 1e8,
			fractionDivisor = 1,
			abbreviationIsGlobal = false
		},
		-- 亿 with 2 decimals
		{
			breakpoint = 1e8,
			abbreviation = "亿",
			significandDivisor = 1e6,
			fractionDivisor = 100,
			abbreviationIsGlobal = false
		},
		-- 万 with no decimals (from 1000万 upward)
		{
			breakpoint = 1e7,-- 1000万
			abbreviation = "万",
			significandDivisor = 1e4,
			fractionDivisor = 1,
			abbreviationIsGlobal = false
		},
		-- 万 with 2 decimals
		{
			breakpoint = 1e4,
			abbreviation = "万",
			significandDivisor = 100,
			fractionDivisor = 100,
			abbreviationIsGlobal = false
		}
	}
}

local gameLocale = GetLocale()

ns.AbbreviateNumbers = function(value)
	return AbbreviateNumbers(value, gameLocale == "zhCN" and zhCNBreakpoints or breakPoints)
end
