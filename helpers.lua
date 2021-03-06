-- FIFTYfifty - Space shooter using a probability mechanic.
-- Copyright (C) 2014  Evan A. Kosin

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

function string:split(pattern)
	local originalString = self
	local splitstring = {}
	while(originalString) do
		left, right = originalString:find(pattern)
		if((not left) or (not right)) then
			splitstring[#splitstring+1], originalString = originalString, nil
		else
			splitstring[#splitstring+1], originalString  = originalString:sub(0,(left-1)), originalString:sub(right+1)
		end
	end
	return splitstring
end

--Faster if only a single split is required.
function string:divide(pattern)
	left, right = self:find(pattern)
	return self:sub(0,(left-1)), self:sub(right+1)
end

debugLog = {}
debugLog.text = ""

function debugLog:clear()
	file = io.open("./debugLog.txt", "w")
	file:write("")
	file:close()
end

function debugLog:append(text,terminator)
	local text = text or ""
	local terminator = terminator or "\n"
	self.text = self.text..tostring(text)..tostring(terminator)
end

function debugLog:commit()
	if(self.text ~= "") then
		file = io.open("./debugLog.txt", "a")
		file:write(tostring(self.text).."\n")
		file:close()
		self.text = ""
	end
end

helpers = {}

function helpers.keys(tblin)
	local keys = {}
	for key, value in pairs(tblin) do
		keys[#keys+1] = key
	end
	return keys
end

function helpers.round(value)
	if(value > 0) then
		return math.floor(value + 0.5)
	elseif(value < 0) then
		return math.ceil(value - 0.5)
	else
		return 0
	end
end

function helpers.int(value)
	if(value > 0) then
		return math.floor(value)
	elseif(value < 0) then
		return math.ceil(value)
	else
		return 0
	end
end

function helpers.odd(value,up)
	if(value > 0) then
		value = math.floor(value)
	elseif(value < 0) then
		value = math.ceil(value)
	end
	if(value == 0) then
		return ((up and 1) or -1)
	elseif(math.fmod(value,2) == 0) then
		return value + (((up and 1) or -1) * (value / math.abs(value)))
	else
		return value
	end
end

function helpers.even(value,up)
	if(value > 0) then
		value = math.floor(value)
	elseif(value < 0) then
		value = math.ceil(value)
	else
		value = 0
	end
	if(math.fmod(value,2) ~= 0) then
		return value + (((up and 1) or -1) * (value / math.abs(value)))
	else
		return value
	end
end

function helpers.clamp(value,lower,upper)
	if(value < lower) then
		return lower
	elseif(value > upper) then
		return upper
	else
		return value
	end
end

function helpers.cleanPrecision(value)
	if(math.abs(value - math.floor(value)) > 0.95) then
		return math.floor(value) + 1
	elseif(math.abs(value - math.floor(value)) < 0.05) then
		return math.floor(value) - 1
	else
		return value
	end
end

weighting = {}

--[[
Best with a value between 0.0 and 1.0.
Value from -1.0 to 1.0 will use dual slopes.
power - controls the knee size.
scale - scales the output via multiplication.
shift - shifts the weighting curve
]]--
function weighting.exp(x,power,scale,width,shifth,shiftv)
	power = power or 3
	scale = scale or 100
	width = width or 1
	shifth = shifth or 0
	shiftv = shiftv or 0
	return (((math.abs(((x * (1 / width)) + (shifth / scale)) ^ power)) * scale) + shiftv)
end

function weighting.invExp(x,power,scale,width,shifth,shiftv)
	power = power or 3
	scale = scale or 100
	width = width or 1
	shifth = shifth or 0
	shiftv = shiftv or 0
	return ((((-math.abs(((x * (1 / width)) + (shifth / scale)) ^ power)) + 1) * scale) + shiftv)
end

function weighting.oddExp(x,power,scale,width,shifth,shiftv)
	power = helpers.odd(power,true) or 3
	scale = scale or 100
	width = width or 1
	shifth = shifth or 0
	shiftv = shiftv or 0
	return (((((x * (1 / width)) + (shifth / scale)) ^ power) * (scale / 2)) + (scale / 2) + shiftv)
end

function weighting.circular(x,power,scale,width,shifth,shiftv)
	power = power or 2
	scale = scale or 100
	width = width or 1
	shifth = shifth or 0
	shiftv = shiftv or 0
	return ((((1 - math.abs(((x * (1 / width)) + (shifth / scale))^power))^0.5) * scale) + shiftv)
end