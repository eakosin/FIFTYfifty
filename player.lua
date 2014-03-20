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

player = {}

--General value declarations
player.scale = 1.0
player.x, player.y = 0, 0
player.dx = {current = 0, desired = 0}
player.dy = {current = 0, desired = 0}
player.speed = 160
player.acceleration = 10
--Fade is the animation steps for the laser fade.
player.laser = {left = {}, right = {}, fade = {0.3, 0.6, 0.9, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
												0.95, 0.9, 0.85, 0.8, 0.75, 0.7, 0.65, 0.6, 0.55, 0.5,
												0.45, 0.4, 0.35, 0.3, 0.25, 0.2, 0.15, 0.1, 0.05, 0.0}}
player.laser.left = {state = "idle", cycle = 0, probability = 1, damage = 100, frames = 0}
player.laser.right = {state = "idle", cycle = 0, probability = 1, damage = 100, frames = 0}
player.shield = {charging = false, probability = 1.0, reduction = .5}
player.health = 1000

function player:load()
	self.image = love.graphics.newImage("images/player3.png")
	self.image:setFilter("linear", "linear")
	self.image:setMipmapFilter("linear", 1)
	self.scale = (love.window.getHeight() / 8) / self.image:getHeight()
	self.laser.image = love.graphics.newImage("images/laser.png")
	self.laser.image:setFilter("linear", "nearest")
	self.laser.image:setMipmapFilter("linear", 0)
end

function player:resize()
	
end

function player:reset()
	self.x = (love.window.getWidth() * 0.5) - (self.image:getWidth() * self.scale * 0.5)
	self.y = (love.window.getHeight() * 0.95) - (self.image:getHeight() * self.scale)
	self.health = 1000
	self.dx.current, self.dx.desired = 0, 0
	self.dy.current, self.dy.desired = 0, 0
	self.laser.left.particle = nil
	self.laser.right.particle = nil
	self.laser.left.state = "idle"
	self.laser.left.cycle = 0
	self.laser.left.probability = 1
	self.laser.left.damage = 100
	self.laser.right.state = "idle"
	self.laser.right.cycle = 0
	self.laser.right.probability = 1
	self.laser.right.damage = 100
end

function player:checkCollision(object)
	return ((object.x > self.x) and (object.x < (self.x + (self.image:getWidth() * self.scale))) and
		(object.y > (self.y + (self.image:getWidth() * self.scale * 0.5))) and (object.y < (self.y + (self.image:getWidth() * self.scale))))
end

function player:update(dt)
	--Movement Keys
	if(self.keyState.down or self.keyState.s or self.joystick.buttons[2]) then
		self.dy.desired = self.speed
	elseif(self.keyState.up or self.keyState.w or self.joystick.buttons[1]) then
		self.dy.desired = -self.speed
	elseif(self.joystick.axes[2] and ((self.joystick.axes[2] > 0.05) or (self.joystick.axes[2] < -0.05))) then
		self.dy.desired = self.speed * self.joystick.axes[2] * math.abs(self.joystick.axes[2])
	else
		self.dy.desired = 0
	end
	if(self.keyState.left or self.keyState.a or self.joystick.buttons[3]) then
		self.dx.desired = -self.speed
	elseif(self.keyState.right or self.keyState.d or self.joystick.buttons[4]) then
		self.dx.desired = self.speed
	elseif(self.joystick.axes[1] and ((self.joystick.axes[1] > 0.05) or (self.joystick.axes[1] < -0.05))) then
		self.dx.desired = self.speed * self.joystick.axes[1] * math.abs(self.joystick.axes[1])
	else
		self.dx.desired = 0
	end
	
	local direction = {n = (self.dy.desired < 0), s = (self.dy.desired > 0), w = (self.dx.desired < 0), e = (self.dx.desired > 0)}
	
	--Calculate acceleration
	if((self.dy.desired == 0) and not (self.dy.current == 0)) then
		self.dy.current = (self.dy.current - ((self.dy.current / math.abs(self.dy.current)) * self.acceleration))
	elseif(self.dy.desired > 0 and self.dy.current < self.dy.desired) then
		self.dy.current = helpers.clamp((self.dy.current + self.acceleration), -self.speed, self.speed)
	elseif(self.dy.desired < 0 and self.dy.current > self.dy.desired) then
		self.dy.current = helpers.clamp((self.dy.current - self.acceleration), -self.speed, self.speed)
	end
	if((self.dx.desired == 0) and not (self.dx.current == 0)) then
		self.dx.current = (self.dx.current - ((self.dx.current / math.abs(self.dx.current)) * self.acceleration))
	elseif(self.dx.desired > 0 and self.dx.current < self.dx.desired) then
		self.dx.current = helpers.clamp((self.dx.current + self.acceleration), -self.speed, self.speed)
	elseif(self.dx.desired < 0 and self.dx.current > self.dx.desired) then
		self.dx.current = helpers.clamp((self.dx.current - self.acceleration), -self.speed, self.speed)
	end
	
	self.x = self.x + ((self.dx.current / 10) * (love.window.getHeight() / 1080))
	self.y = self.y + ((self.dy.current / 10) * (love.window.getHeight() / 1080))
	
	--Stop movement at screen edges
	if( 
		(not (direction.w and 
			 (self.x < (love.window.getWidth() * 0.01))
			 )
		)
	and 
		(not (direction.e and
			 (self.x > ((love.window.getWidth() * 0.99) - (self.image:getWidth() * self.scale)) )
			 )
		) 
	) then --Pass
	else
		self.dx.current = 0
	end

	if( 
		(not (direction.n and 
			 (self.y < (love.window.getHeight() * 0.6))
			 )
		)
	and 
		(not (direction.s and
			 (self.y > ((love.window.getHeight() * 0.96) - (self.image:getHeight() * self.scale)) )
			 )
		) 
	) then --Pass
	else
		self.dy.current = 0
	end
	
	self.x = helpers.clamp(self.x, love.window.getWidth() * 0.01, (love.window.getWidth() * 0.99) - (self.image:getWidth() * self.scale))
	self.y = helpers.clamp(self.y, love.window.getHeight() * 0.6, (love.window.getHeight() * 0.96) - (self.image:getHeight() * self.scale))
	
	--Left laser state handling
	--Cycle charging if the laser button is held down and the laser is not in firing mode
	if((self.keyState.x or self.keyState.k or (self.joystick.axes[5] and (self.joystick.axes[5] > -0.9)) or self.joystick.buttons[9]) and (self.laser.left.state == "idle" or self.laser.left.state == "charging")) then
		self.laser.left.state = "charging"
		if(self.laser.left.cycle >= 29) then
			self.laser.left.damage = helpers.clamp(self.laser.left.damage * 2, 0, 1e15)
			self.laser.left.probability = helpers.clamp(self.laser.left.probability * 0.80, 0.0001, 1.1)
			self.laser.left.cycle = 0
			self.audio.channels.sounds:push({name = "cycleLeft", pitch = (1 + (0.25 * (1 - self.laser.left.probability)))})
		else
			self.laser.left.cycle = self.laser.left.cycle + 1
		end
	--If the state was charging but the buttons are not pressed, switch to firing mode
	elseif(self.laser.left.state == "charging") then
		self.laser.left.state = "firing"
	end
	--Test the probability and either switch to fired state or switch back to idle and reset values
	if(self.laser.left.state == "firing") then
		if(love.math.random() < self.laser.left.probability) then
			self.audio.channels.sounds:push({name = "laser"})
			self.laser.left.state = "fired"
			self.laser.left.frames = 0
		else
			self.audio.channels.sounds:push({name = "fail"})
			self.laser.left.particle = failParticle:createSystem(self.x + (160 * self.scale), self.y + (240 * self.scale))
			self.laser.left.state = "idle"
			self.laser.right.frames = 0
			self.laser.left.cycle = 0
			self.laser.left.probability = 1
			self.laser.left.damage = 100
		end
	end
	--If firing was successful, then set laser fade frame for 30 frames and switch to idle
	if(self.laser.left.state == "fired") then
		if(self.laser.left.frames < 30) then
			self.laser.left.frames = self.laser.left.frames + 1
		else
			self.laser.left.state = "idle"
			self.laser.left.frames = 0
			self.laser.left.cycle = 0
			self.laser.left.probability = 1
			self.laser.left.damage = 100
		end
	end
	
	--Right laser state handling
	--Cycle charging if the laser button is held down and the laser is not in firing mode
	if((self.keyState.c or self.keyState.l or (self.joystick.axes[6] and (self.joystick.axes[6] > -0.9)) or self.joystick.buttons[10]) and (self.laser.right.state == "idle" or self.laser.right.state == "charging")) then
		self.laser.right.state = "charging"
		if(self.laser.right.cycle >= 29) then
			self.laser.right.damage = helpers.clamp(self.laser.right.damage * 2, 0, 1e15)
			self.laser.right.probability = helpers.clamp(self.laser.right.probability * 0.80, 0.0001, 1.1)
			self.laser.right.cycle = 0
			self.audio.channels.sounds:push({name = "cycleRight", pitch = (1 + (0.25 * (1 - self.laser.right.probability)))})
		else
			self.laser.right.cycle = self.laser.right.cycle + 1
		end
	--If the state was charging but the buttons are not pressed, switch to firing mode
	elseif(self.laser.right.state == "charging") then
		self.laser.right.state = "firing"
	end
	--Test the probability and either switch to fired state or switch back to idle and reset values
	if(self.laser.right.state == "firing") then
		if(love.math.random() < self.laser.right.probability) then
			self.audio.channels.sounds:push({name = "laser"})
			self.laser.right.state = "fired"
			self.laser.right.frames = 0
		else
			self.audio.channels.sounds:push({name = "fail"})
			self.laser.right.particle = failParticle:createSystem(self.x + (284 * self.scale), self.y + (240 * self.scale))
			self.laser.right.state = "idle"
			self.laser.right.frames = 0
			self.laser.right.cycle = 0
			self.laser.right.probability = 1
			self.laser.right.damage = 100
		end
	end
	--If firing was successful, then set laser fade frame for 30 frames and switch to idle
	if(self.laser.right.state == "fired") then
		if(self.laser.right.frames < 30) then
			self.laser.right.frames = self.laser.right.frames + 1
		else
			self.laser.right.state = "idle"
			self.laser.right.frames = 0
			self.laser.right.cycle = 0
			self.laser.right.probability = 1
			self.laser.right.damage = 100
		end
	end
end

function player:draw(alphaIn)
	local alpha = alphaIn or 255
	--Draw Left Laser
	if(self.laser.left.state == "fired") then
		love.graphics.setColor(255, 255, 255, (255 * self.laser.fade[self.laser.left.frames]))
		love.graphics.draw(self.laser.image, self.x + (160 * self.scale), self.y + (240 * self.scale), 0, self.scale, -(love.window.getHeight() * 1.5) / self.laser.image:getHeight())
	end
	--Draw Right Laser
	if(self.laser.right.state == "fired") then
		love.graphics.setColor(255, 255, 255, (255 * self.laser.fade[self.laser.right.frames]))
		love.graphics.draw(self.laser.image, self.x + (284 * self.scale), self.y + (280 * self.scale), 0, self.scale, -(love.window.getHeight() * 1.5) / self.laser.image:getHeight())
	end
	love.graphics.setColor(255, 255, 255, alpha)
	love.graphics.draw(self.image, self.x, self.y - (self.dx.current * 0.09 * self.scale), 0, self.scale, self.scale, 0, 0, 0, (self.dx.current * 0.0015 * self.scale)) --Skew * 60 = y offset
end