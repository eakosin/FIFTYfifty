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

ui = {}

--General value declarations
ui.fontSize = 40
ui.enemyHealth = 0
ui.score = 0
ui.playerHealth = 0
ui.leftGun = {damage = 0, probability = 0, highlight = 0}
ui.rightGun = {damage = 0, probability = 0, highlight = 0}
ui.pauseFrames = 0
ui.entries = {{name = "resume"}, {name = "menu"}}
ui.currentEntry = 1
ui.topEdge = 0
ui.bottomEdge = 1600
ui.state = "game"

function ui:load()
	--Load font
	self.font = love.graphics.newFont("fonts/teknobe.otf", self.fontSize * (love.window.getHeight() / 1080))
	self.font:setFilter("linear", "linear", 8)
	self.border = ui.fontSize * 0.25 * (love.window.getWidth() / 1920)
	--Find topEdge for shader blur
	self.topEdge = self.font:getHeight()
	--Load pause menu entries
	for entry = 1, #self.entries do
		self.entries[entry].image = love.graphics.newImage("images/"..self.entries[entry].name.."Button.png")
		self.entries[entry].scale = (love.window.getHeight() / 4) / self.entries[entry].image:getHeight()
		self.entries[entry].y = ((love.window.getHeight() / 4) * (entry - 1)) + ((love.window.getHeight() / 4))
		self.entries[entry].x = {unselected = love.window.getWidth() - (560 * self.entries[entry].scale),
								 selected   = love.window.getWidth() - (700 * self.entries[entry].scale),
								 hidden 	= love.window.getWidth() + (love.window.getWidth() * 0.05),
								 current    = love.window.getWidth() + (love.window.getWidth() * 0.05)}
	end
	--Load transparent black bar behind ui text
	self.back = love.graphics.newImage("images/uiback.png")
	--Nearest neighbor filtering due to single color image being stretched
	self.back:setFilter("nearest", "nearest", 8)
end

function ui:resize()
	self.font = love.graphics.newFont("fonts/teknobe.otf", self.fontSize * (love.window.getHeight() / 1080))
	self.font:setFilter("linear", "linear", 8)
	self.border = ui.fontSize * 0.25 * (love.window.getWidth() / 1920)
end

function ui:update()
	if(self.state == "game") then
		--Pass - values are updated in game.lua
	elseif(self.state == "pause") then
		--Pause screen input handling
		if((self.keyState.down or self.keyState.s or (self.joystick.axes[2] and self.joystick.axes[2] > 0.5) or self.joystick.buttons[2]) and (not self.inputLock.down)) then
			self.currentEntry = (((self.currentEntry) % #self.entries) + 1)
			self.inputLock:lock("down")
			self.audio.channels.sounds:push({name = "select"})
		end
		if((self.keyState.up or self.keyState.w or (self.joystick.axes[2] and self.joystick.axes[2] < -0.5) or self.joystick.buttons[1]) and (not self.inputLock.up)) then
			self.currentEntry = (((self.currentEntry - 2) % #self.entries) + 1)
			self.inputLock:lock("up")
			self.audio.channels.sounds:push({name = "select"})
		end
		--Process input from menu
		if((self.keyState["return"] or self.joystick.buttons[11]) and (not self.inputLock["return"])) then
			self.inputLock:lock("return")
			self.audio.channels.sounds:push({name = "enter"})
			self.state = "unpause"
		elseif((self.joystick.buttons[5] or self.joystick.buttons[12]) and (not self.inputLock["return"])) then
			self.currentEntry = 1
			self.audio.channels.sounds:push({name = "back"})
			self.state = "unpause"
		--Increment pause frames for fade in
		elseif(self.pauseFrames < 30) then
			self.pauseFrames = self.pauseFrames + 1
		end
		--Highlight menu options smoothly
		for entry = 1, #self.entries do
			if(entry == self.currentEntry and ((self.entries[entry].x.current > self.entries[entry].x.selected) or (self.entries[entry].x.current > self.entries[entry].x.selected))) then
				self.entries[entry].x.current = (self.entries[entry].x.current - math.floor((self.entries[entry].x.current - self.entries[entry].x.selected) / 4))
			elseif((self.entries[entry].x.current < self.entries[entry].x.unselected) or (self.entries[entry].x.current > self.entries[entry].x.unselected)) then
				self.entries[entry].x.current = (self.entries[entry].x.current + math.ceil((self.entries[entry].x.unselected - self.entries[entry].x.current) / 4))
			end
		end
	--Unpause state
	elseif(self.state == "unpause") then
		local allHidden = true
		--Smoothly hide menu entries
		for entry = 1, #self.entries do
			if(self.entries[entry].x.current < self.entries[entry].x.hidden) then
				self.entries[entry].x.current = (self.entries[entry].x.current + math.ceil((self.entries[entry].x.hidden - self.entries[entry].x.current) / 4))
				allHidden = false
			end
		end
		--Decrement pause frames for fade out
		if(self.pauseFrames > 0) then
			self.pauseFrames = self.pauseFrames - 1
		end
		--If all the menu options are hidden and the screen has faded to normal, continue playing
		if(allHidden and self.pauseFrames <= 0) then
			self.pauseFrames = 0
			if(self.currentEntry == 1) then
				self.state = "game"
				return "game"
			elseif(self.currentEntry == 2) then
				return "end"
			end
		end
	end
end

function ui:draw(alphaIn)
	alpha = alphaIn or 255
	love.graphics.setFont(self.font)
	--Calculate the edges of the ui text
	rightEdge = love.window.getWidth()
	self.bottomEdge = love.window.getHeight() - self.font:getHeight()
	--Draw the transparent black fill spanning the screen under the text
	love.graphics.draw(self.back, 0, 0, 0, love.window.getWidth() / self.back:getWidth(), self.font:getHeight() / self.back:getHeight())
	love.graphics.draw(self.back, 0, self.bottomEdge, 0, love.window.getWidth() / self.back:getWidth(), (self.font:getHeight() / self.back:getHeight()))
	love.graphics.setColor(225, 225, 225, alpha)
	--Draw text for ui
	love.graphics.printf(string.format("%.0f", tostring(self.enemyHealth)), self.border, 0, rightEdge * 0.5, "left")
	love.graphics.printf(string.format("%.0f", tostring(self.score)), rightEdge * 0.5, 0, (rightEdge * 0.5) - self.border, "right")
	love.graphics.printf(string.format("%.0f", tostring(self.playerHealth)), rightEdge * 0.33333, self.bottomEdge, rightEdge * 0.33333, "center")
	left = string.format("%06.2f%% - %.0f", tostring(self.leftGun.probability * 100.0), tostring(self.leftGun.damage))
	if(self.leftGun.highlight) then
		love.graphics.setColor(225, 225 - (self.leftGun.highlight * 7), 225 - (self.leftGun.highlight * 7), alpha)
	else
		love.graphics.setColor(225, 225, 225, alpha)
	end
	love.graphics.printf(left, self.border, self.bottomEdge, rightEdge * 0.33333, "left")
	right = string.format("%.0f - %06.2f%%", tostring(self.rightGun.damage), tostring(self.rightGun.probability * 100.0))
	if(self.rightGun.highlight) then
		love.graphics.setColor(225, 225 - (self.rightGun.highlight * 7), 225 - (self.rightGun.highlight * 7), alpha)
	else
		love.graphics.setColor(225, 225, 225, alpha)
	end
	love.graphics.printf(right, rightEdge * 0.66666, self.bottomEdge, (rightEdge * 0.33333) - self.border, "right")
	love.graphics.setColor(255, 255, 255, alpha)
end

function ui:drawMenu()
	--Draw all the menu entries
	for entry = 1, #self.entries do
		love.graphics.draw(self.entries[entry].image, self.entries[entry].x.current, self.entries[entry].y, 0, self.entries[entry].scale, self.entries[entry].scale)
	end
end