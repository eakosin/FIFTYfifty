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

require("helpers")

shot = {}

--General value declarations
shot.x, shot.y = 0, 0
shot.scale = 0
shot.speed = 15

function shot:load()
	--Load the shot image and calculate scale relative to screen space
	self.image = love.graphics.newImage("images/shot2.png")
	self.image:setFilter("linear", "linear")
	self.image:setMipmapFilter("linear", 0)
	self.scale = ((love.window.getHeight() / 8) / self.image:getHeight()) * 0.75
end

--Create a new shot
function shot:new(x, y)
	new = {}
	setmetatable(new, self)
	self.__index = self
	new.x, new.y = x, y
	return new
end

function shot:update()
	--Update shot position relative to screen space
	self.y = self.y + (shot.speed * (love.window.getHeight() / 1080))
end

function shot:draw()
	--Draw the shot
	love.graphics.draw(self.image, self.x, self.y, 0, self.scale, self.scale, (self.image:getHeight() * 0.5), (self.image:getHeight() * 0.5), 0, 0)
end