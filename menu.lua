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

menu = {}

--General value declarations
menu.background = {}
menu.title = {}
menu.window = {}
menu.scoreFontSize = 144
menu.optionFontSize = 72
menu.entries = {{name = "launch"}, {name = "options"}, {name = "help"}, {name = "quit"}}
menu.currentEntry = 1
menu.options = {{name = "music volume: ", value = 11, maxvalue = 11},
			    {name = "effect volume: ", value = 11, maxvalue = 11},
				{name = "shader settings: ", value = 3, maxvalue = 3, enum = {"simple", "medium", "complex"}},
				{name = "back", value = 1, maxvalue = 1, enum = {""}}}
menu.currentOption = 1
menu.maxScore = {score = 0}
menu.state = "start"

function menu:load()
	--Load fonts
	self.scoreFont = love.graphics.newFont("fonts/teknobe.otf", self.scoreFontSize * (love.window.getHeight() / 1080))
	self.scoreFont:setFilter("linear", "linear", 8)
	self.optionFont = love.graphics.newFont("fonts/teknobe.otf", self.optionFontSize * (love.window.getHeight() / 1080))
	self.optionFont:setFilter("linear", "linear", 8)
	--Configure score positioning relative to screen resolution
	self.maxScore.y = love.window.getHeight() - self.scoreFont:getHeight()
	self.maxScore.x = {visible = 0 + (self.scoreFontSize * (love.window.getWidth() / 1920) * 0.25),
					   hidden = -love.window.getWidth(),
					   current = -love.window.getWidth()}
	--Load title image and configure position and scale relative to screen resolution
	self.title.image = love.graphics.newImage("images/title.png")
	self.title.image:setFilter("linear", "linear", 8)
	self.title.scale = (love.window.getWidth() / self.title.image:getWidth()) * 0.6
	self.title.x 	 = {hidden = -(self.title.image:getWidth() * self.title.scale),
						visible = 0,
						current = -(self.title.image:getWidth() * self.title.scale)}
	--Load entry images and configure position and scale relative to screen resolution
	for entry = 1, #self.entries do
		self.entries[entry].image = love.graphics.newImage("images/"..self.entries[entry].name.."Button.png")
		self.entries[entry].image:setFilter("linear", "linear", 8)
		self.entries[entry].scale = (love.window.getHeight() / #self.entries) / self.entries[entry].image:getHeight()
		self.entries[entry].y = ((love.window.getHeight() / #self.entries) * (entry - 1) * 0.75) + ((love.window.getHeight() / #self.entries) * 0.75)
		self.entries[entry].x = {unselected = love.window.getWidth() - (560 * self.entries[entry].scale),
								 selected   = love.window.getWidth() - (700 * self.entries[entry].scale),
								 hidden 	= love.window.getWidth() + (love.window.getWidth() * 0.05),
								 current    = love.window.getWidth() + (love.window.getWidth() * 1.0 * entry)}
	end
	--Load window and help images and configure position and scale relative to screen resolution
	self.window.image = love.graphics.newImage("images/window.png")
	self.window.image:setFilter("linear", "linear", 8)
	self.window.help = love.graphics.newImage("images/help.png")
	self.window.help:setFilter("linear", "linear", 8)
	self.window.scale = (love.window.getHeight() / self.window.image:getHeight()) * 0.8
	self.window.x = ((love.window.getWidth() * 0.5) - (self.window.image:getWidth() * self.window.scale * 0.5))
	self.window.y = {visible = (love.window.getHeight() * 0.1),
					 hidden = love.window.getHeight(),
					 current = love.window.getHeight()}
	self.window.state = "help"
end

function menu:resize()
	
end

function menu:update()
	--Initialize
	if(self.state == "start") then
		self.currentEntry = 1
		self.audio.channels.thread:push({name = "setVolume", musicVolume = ((self.options[1].value - 1) / 10), soundsVolume = ((self.options[2].value - 1) / 10)})
		self.state = "main"
	--Main menu state
	elseif(self.state == "main") then
		--Change current entry
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
		--Do the necessary action for the current entry
		if((self.keyState["return"] or self.joystick.buttons[11]) and (not self.inputLock["return"])) then
			self.inputLock:lock("return")
			self.audio.channels.sounds:push({name = "enter"})
			--If first or last option, then move to leaving state
			if(self.currentEntry == 1 or self.currentEntry == 4) then
				self.audio.channels.music:push({name = "fadeOut", steps = 30, length = 0.5})
				self.state = "leaving"
			--Otherwise switch to window state
			else
				self.state = "window"
			end
		end
		--Highlight menu options smoothly
		for entry = 1, #self.entries do
			if(entry == self.currentEntry and (self.entries[entry].x.current > self.entries[entry].x.selected)) then
				self.entries[entry].x.current = (self.entries[entry].x.current - math.floor((self.entries[entry].x.current - self.entries[entry].x.selected) / 4))
			elseif((self.entries[entry].x.current < self.entries[entry].x.unselected) or (self.entries[entry].x.current > self.entries[entry].x.unselected)) then
				self.entries[entry].x.current = (self.entries[entry].x.current + math.ceil((self.entries[entry].x.unselected - self.entries[entry].x.current) / 4))
			end
		end
		--Slide title image in
		if(self.title.x.current < self.title.x.visible) then
			self.title.x.current = (self.title.x.current + math.ceil((self.title.x.visible - self.title.x.current) / 4))
		end
		--Slide high score in
		if(self.maxScore.x.current < self.maxScore.x.visible) then
			self.maxScore.x.current = (self.maxScore.x.current + math.ceil((self.maxScore.x.visible - self.maxScore.x.current) / 4))
		end
		--Slide window out
		if(self.window.y.current < self.window.y.hidden) then
			self.window.y.current = (self.window.y.current + math.ceil((self.window.y.hidden - self.window.y.current) / 4))
		end
	--Window state
	elseif(self.state == "window") then
		--Slide window in
		if(self.window.y.current > self.window.y.visible) then
			self.window.y.current = (self.window.y.current - math.floor((self.window.y.current - self.window.y.visible) / 4))
		end
		--Options entry
		if(self.currentEntry == 2) then
			self.window.state = "options"
			local volumeChange = false
			--Handle input in options state of window state
			if(self.joystick.buttons[12] and (not self.inputLock["return"])) then
				self.inputLock:lock("return")
				self.audio.channels.sounds:push({name = "back"})
				self.state = "main"
			end
			if((self.keyState["return"] or self.joystick.buttons[11]) and (not self.inputLock["return"]) and (self.currentOption == 4)) then
				self.inputLock:lock("return")
				self.audio.channels.sounds:push({name = "enter"})
				self.state = "main"
			end
			if((self.keyState.down or self.keyState.s or (self.joystick.axes[2] and self.joystick.axes[2] > 0.5) or self.joystick.buttons[2]) and (not self.inputLock.down)) then
				self.currentOption = (((self.currentOption) % #self.entries) + 1)
				self.inputLock:lock("down")
				self.audio.channels.sounds:push({name = "select"})
			end
			if((self.keyState.up or self.keyState.w or (self.joystick.axes[2] and self.joystick.axes[2] < -0.5) or self.joystick.buttons[1]) and (not self.inputLock.up)) then
				self.currentOption = (((self.currentOption - 2) % #self.entries) + 1)
				self.inputLock:lock("up")
				self.audio.channels.sounds:push({name = "select"})
			end
			if((self.keyState.right or self.keyState.d or (self.joystick.axes[1] and self.joystick.axes[1] > 0.5) or self.joystick.buttons[4]) and (not self.inputLock.right)) then
				self.options[self.currentOption].value = (((self.options[self.currentOption].value) % self.options[self.currentOption].maxvalue) + 1)
				self.inputLock:lock("right")
				self.audio.channels.sounds:push({name = "select"})
				volumeChange = true
			end
			if((self.keyState.left or self.keyState.a or (self.joystick.axes[1] and self.joystick.axes[1] < -0.5) or self.joystick.buttons[3]) and (not self.inputLock.left)) then
				self.options[self.currentOption].value = (((self.options[self.currentOption].value - 2) % self.options[self.currentOption].maxvalue) + 1)
				self.inputLock:lock("left")
				self.audio.channels.sounds:push({name = "select"})
				volumeChange = true
			end
			--If volume is changed in options, push the change to the audio thread for instant feedback
			if(volumeChange) then
				self.audio.channels.thread:push({name = "setVolume", musicVolume = ((self.options[1].value - 1) / 10), soundsVolume = ((self.options[2].value - 1) / 10)})
			end
		--Help entry
		elseif(self.currentEntry == 3) then
			self.window.state = "help"
			--Hide help if input is entered
			if((self.keyState["return"] or self.joystick.buttons[11] or self.joystick.buttons[12]) and (not self.inputLock["return"])) then
				self.inputLock:lock("return")
				if(self.joystick.buttons[12]) then
					self.audio.channels.sounds:push({name = "back"})
				else
					self.audio.channels.sounds:push({name = "enter"})
				end
				self.state = "main"
			end
		end
	--Leaving state for starting game or quitting application
	elseif(self.state == "leaving") then
		local allHidden = true
		--Slide buttons out of view
		for entry = 1, #self.entries do
			if(self.entries[entry].x.current < self.entries[entry].x.hidden) then
				self.entries[entry].x.current = (self.entries[entry].x.current + math.ceil((self.entries[entry].x.hidden - self.entries[entry].x.current) / 4))
				allHidden = false
			end
		end
		--Slide title out of view
		if(self.title.x.current > self.title.x.hidden) then
			self.title.x.current = (self.title.x.current - math.floor((self.title.x.current - self.title.x.hidden) / 4))
		end
		--Slide score out of view
		if(self.maxScore.x.current > self.maxScore.x.hidden) then
			self.maxScore.x.current = (self.maxScore.x.current - math.floor((self.maxScore.x.current - self.maxScore.x.hidden) / 4))
		end
		--If all entries are hidden then
		if(allHidden) then
			--Start the game and send feedback to main to change global state
			if(self.currentEntry == 1) then
				self.state = "start"
				self.audio.channels.music:push({name = "startGame"})
				return "game"
			--Send feedback to main to quit
			elseif(self.currentEntry == 4) then
				return "quit"
			end
		end
	end
end

function menu:draw()
	--Draw title image
	love.graphics.draw(self.title.image, self.title.x.current, 0, 0, self.title.scale, self.title.scale)
	--Draw each menu entry image
	for entry = 1, #self.entries do
		love.graphics.draw(self.entries[entry].image, self.entries[entry].x.current, self.entries[entry].y, 0, self.entries[entry].scale, self.entries[entry].scale)
	end
	--Draw the window
	love.graphics.draw(self.window.image, self.window.x, self.window.y.current, 0, self.window.scale, self.window.scale)
	--Draw the score
	love.graphics.setFont(self.scoreFont)
	love.graphics.setColor(90, 92, 98, 255)
	love.graphics.printf(string.format("%.0f", tostring(self.maxScore.score)), self.maxScore.x.current, self.maxScore.y, love.window.getWidth() * 0.80, "left")
	love.graphics.setColor(255, 255, 255, 255)
	--Draw the help content at window position of in help state
	if(self.window.state == "help") then
		love.graphics.draw(self.window.help, self.window.x, self.window.y.current, 0, self.window.scale, self.window.scale)
	--Draw the options content at window position if in option state
	elseif(self.window.state == "options") then
		love.graphics.setFont(self.optionFont)
		--Draw all the options
		for index = 1, #self.options do
			--Highlight current option with lighter color
			if(index == self.currentOption) then
				love.graphics.setColor(255, 255, 255, 255)
			else
				love.graphics.setColor(183, 185, 189, 255)
			end
			--If there are strings for the numerical values, use those
			if(self.options[index].enum) then
				love.graphics.printf(self.options[index].name..tostring(self.options[index].enum[self.options[index].value]), self.window.x + ((love.window.getHeight() / 1080) * 102), self.window.y.current + (self.optionFont:getHeight() * index * 2.023), self.window.image:getWidth() * self.window.scale, "left")
			--Otherwise use numbers
			else
				love.graphics.printf(self.options[index].name..tostring(self.options[index].value - 1), self.window.x + ((love.window.getHeight() / 1080) * 102), self.window.y.current + (self.optionFont:getHeight() * index * 2.023), self.window.image:getWidth() * self.window.scale, "left")
			end
		end
	end
	love.graphics.setColor(255, 255, 255, 255)
end