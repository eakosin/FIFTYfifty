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

--General value declarations
enemy = {}
enemy.x, enemy.y = 0,0
enemy.offset = 0
enemy.health = 1000
enemy.maxDamage = 0
enemy.maxProbability = 1.0
enemy.state = "created"
enemy.pause = -1
enemy.nextshot = 0
enemy.firing = false

--Create a new enemy
function enemy:new(x, y, health, delay, shotDelay)
	new = {}
	setmetatable(new, self)
	self.__index = self
	new.x, new.desiredy, new.y = x, y, (-love.window.getHeight() * 0.26) - y
	new.health = health
	new.pause = delay or -1
	new.shotDelay = shotDelay or 0
	return new
end

function enemy:load()
	--Load enemy images and set scale relative to screen space
	self.image = love.graphics.newImage("images/enemy.png")
	self.image:setFilter("linear", "linear")
	self.image:setMipmapFilter("linear", 1)
	self.scale = (love.window.getHeight() / 8) / self.image:getHeight()
end

function enemy:resize()
	self.scale = (love.window.getHeight() / 8) / self.image:getHeight()
end

function enemy:update()
	--Created state
	if(self.state == "created") then
		--If no pause value is passed, then pick a random pause time
		if(self.pause == -1) then
			self.pause = love.math.random(30, 480)
		end
		--If not shot delay is passed, pick a random shot delay time
		if(self.nextshot == 0) then
			self.nextshot = self.pause + love.math.random(120 - self.shotDelay, 360 - (self.shotDelay * 3))
		end
		--After pause time is done, deaccelerate onto screen
		if(self.pause <= 0) then
			if(self.desiredy - self.y > 0) then
				self.y = self.y + (math.ceil((self.desiredy - self.y) * 0.5) * 0.0625)
			end
			--Change to active state when visible
			if(self.y > 0) then
				self.state = "active"
			end
		else
			self.pause = self.pause - 1
		end
	--Active state
	elseif(self.state == "active") then
		--If not in grid y position, deaccelerate to it
		if(self.desiredy - self.y > 0) then
			self.y = self.y + (math.ceil((self.desiredy - self.y) * 0.5) * 0.0625)
		end
	end
	--If destroyed, hide, else, fire at random.
	if(self.state == "destroyed") then
		self.firing = false
		self.x = -(self.x * love.window.getWidth())
		self.y = -(self.y * love.window.getHeight())
	else
		if(self.firing) then
			self.firing = false
		elseif(self.nextshot <= 0) then
			self.firing = true
			self.nextshot = love.math.random(120 - self.shotDelay, 360 - (self.shotDelay * 3))
		else
			self.nextshot = self.nextshot - 1
		end
	end
end

function enemy:draw()
	love.graphics.draw(self.image, self.x + self.offset, self.y, 0, self.scale, self.scale, (self.image:getHeight() * 0.5), (self.image:getHeight()), 0, 0)
end