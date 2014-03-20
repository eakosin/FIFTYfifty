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
require("player")
require("enemy")
require("shot")
require("ui")
require("particle")

--pi....
pi = 3.141592653

game = {}

--General value declarations
game.fontSize = 72
game.background = {}
game.mothership = {}
game.player = player
--Row positions
game.rs = 		{0.175,
				 0.175 + 0.14166666666666666666666666666667,
				 0.175 + (0.14166666666666666666666666666667 * 2),
				 0.175 + (0.14166666666666666666666666666667 * 3)}
--Enemy position grid as percentages of screen space
game.enemies = {
{{0.1, game.rs[1]}, {0.2, game.rs[1]}, {0.3, game.rs[1]}, {0.4, game.rs[1]}, {0.5, game.rs[1]}, {0.6, game.rs[1]}, {0.7, game.rs[1]}, {0.8, game.rs[1]}, {0.9, game.rs[1]}},
{{0.1, game.rs[2]}, {0.2, game.rs[2]}, {0.3, game.rs[2]}, {0.4, game.rs[2]}, {0.5, game.rs[2]}, {0.6, game.rs[2]}, {0.7, game.rs[2]}, {0.8, game.rs[2]}, {0.9, game.rs[2]}},
{{0.1, game.rs[3]}, {0.2, game.rs[3]}, {0.3, game.rs[3]}, {0.4, game.rs[3]}, {0.5, game.rs[3]}, {0.6, game.rs[3]}, {0.7, game.rs[3]}, {0.8, game.rs[3]}, {0.9, game.rs[3]}},
{{0.1, game.rs[4]}, {0.2, game.rs[4]}, {0.3, game.rs[4]}, {0.4, game.rs[4]}, {0.5, game.rs[4]}, {0.6, game.rs[4]}, {0.7, game.rs[4]}, {0.8, game.rs[4]}, {0.9, game.rs[4]}}
}
game.phase = 0
game.find = {x = 0, y = 0}
game.numenemies = 0
game.maxenemies = 14
game.enemyHealth = 1000
game.enemyDamage = 100
game.score = 0
game.maxScore = 0
game.frames = -1
game.shots = {}
game.state = "start"
game.shader = {}
game.shaderSetting = 3

function game:load()
	--Load fonts
	self.font = love.graphics.newFont("fonts/teknobe.otf", self.fontSize * (love.window.getHeight() / 1080))
	self.font:setFilter("linear", "linear", 8)
	self.border = ui.fontSize * 0.25 * (love.window.getWidth() / 1920)
	--Load and compile shaders
	self.shader[1] = love.graphics.newShader("simple.glsl")
	self.shader[2] = love.graphics.newShader("medium.glsl")
	self.shader[3] = love.graphics.newShader("complex.glsl")
	--Set screen size uniform for post processing shaders
	for index = 1, #self.shader do
		self.shader[index]:send("love_ScreenSize", {love.window.getWidth(), love.window.getHeight()})
	end
	--Set player global references and load player content
	self.player.keyState = self.keyState
	self.player.inputLock = self.inputLock
	self.player.joystick = self.joystick
	self.player.audio = self.audio
	self.player:load()
	--Load enemy content
	enemy:load()
	--Load shot content
	shot:load()
	--Set ui global references and load ui content
	ui.keyState = self.keyState
	ui.joystick = self.joystick
	ui.inputLock = self.inputLock
	ui.audio = self.audio
	ui:load()
	--Load particle content
	particle:load()
	playerParticle:load()
	shotParticle:load()
	laserParticle:load()
	failParticle:load()
	--Create a new framebuffer for postprocessing
	self.canvas = love.graphics.newCanvas()
end

function game:resize()

end

--Reset game state before new game
function game:reset()
	--Set number of frames for smooth transition from game to menu
	self.frames = 240
	--Set initial difficulty parameters
	self.enemyHealth = 1000
	self.enemyDamage = 100
	self.score = 0
	--Reset player state
	self.player:reset()
	--Set ui to use first entry
	ui.currentEntry = 1
	--Create particle table for damage to player effect
	self.particles = {current = 1, size = 3}
	--Load the background image suitable for each shader setting
	self.background.image = nil
	self.background.scale = 0.0
	if(self.shaderSetting == 1) then
		self.background.image = love.graphics.newImage("images/space1.jpg")
		self.background.image:setFilter("linear", "linear")
		self.background.scale = love.window.getWidth() / self.background.image:getWidth()
	elseif(self.shaderSetting == 2) then
		self.background.image = love.graphics.newImage("images/space2.jpg")
		self.background.image:setFilter("linear", "linear")
		self.background.scale = love.window.getWidth() / self.background.image:getWidth()
	elseif(self.shaderSetting == 3) then
		self.background.image = love.graphics.newImage("images/space3.jpg")
		self.background.image:setFilter("linear", "linear")
		self.background.scale = love.window.getWidth() / self.background.image:getWidth()
	end
	--Set background y for looping motion
	self.background.y = (-self.background.scale * self.background.image:getHeight()) + love.window.getHeight()
	--Clear player particle system for any consecutive games
	self.playerParticle = nil
end

function game:update(dt)
	--Start state
	if(self.state == "start") then
		--Wait until transition is done
		if(self.frames > 0) then
			self.frames = self.frames - 1
		--Create initial enemies in grid and change to game state
		else
			for index = 2, 8 do
				self.enemies[2][index].enemy = enemy:new(self.enemies[2][index][1] * love.window.getWidth(), self.enemies[2][index][2] * love.window.getHeight(), self.enemyHealth, index * 10 + 80)
				self.enemies[3][index].enemy = enemy:new(self.enemies[3][index][1] * love.window.getWidth(), self.enemies[3][index][2] * love.window.getHeight(), self.enemyHealth, index * 10)
			end
			self.numenemies = 14
			self.phase = 0
			self.state = "game"
		end
	--Game state
	elseif(self.state == "game") then
		--Set phase for enemy motion
		self.phase = (self.phase + 1) % 120
		--Find unused slot
		if(self.find.x == 0 or self.find.y == 0) then
			tx, ty = love.math.random(1,#self.enemies[1]), love.math.random(1,#self.enemies)
			if(not self.enemies[ty][tx].enemy) then
				self.find.x, self.find.y = tx, ty
			end
		end
		--Populate screen with enemies when less than max
		if(self.numenemies < self.maxenemies) then
			if(not (self.find.x == 0 or self.find.y == 0)) then
				self.enemies[self.find.y][self.find.x].enemy = enemy:new(self.enemies[self.find.y][self.find.x][1] * love.window.getWidth(),
																		 self.enemies[self.find.y][self.find.x][2] * love.window.getHeight(),
																		 self.enemyHealth,
																		 -1,
																		 helpers.clamp((self.enemyHealth - 1000) * 0.001, 0, 90))
				self.find.x, self.find.y = 0, 0
				self.numenemies = self.numenemies + 1
			end
		end
		--Update player
		self.player:update(dt)
		--Update enemies
		for x = 1, #self.enemies[1] do
			for y = 1, #self.enemies do
				if(self.enemies[y][x].enemy) then
					self.enemies[y][x].enemy.offset = math.cos(((self.phase / 120) * 2 * pi) + ((pi * 0.5) * y) + ((pi * 0.125) * x)) * (138 * (love.window.getWidth() / 1920))
					self.enemies[y][x].enemy:update()
					-- if(self.player:checkCollision(self.enemies[y][x].enemy)) then
						-- self.player.health = self.player.health - 200
						-- self.enemies[y][x].enemy.health = self.enemies[y][x].enemy.health - 200
					-- end
				end
			end
		end
		--Check for laser hits
		if(self.player.laser.left.state == "fired") then
			for x = 1, #self.enemies[1] do
				for y = 1, #self.enemies do
					if(self.enemies[y][x].enemy) then
						--Combine math for laser position with math for enemy ship position
						if(not (self.enemies[y][x].enemy.state == "destroyed" or self.enemies[y][x].enemy.state == "created") and 
						   ((self.player.x + (160 * self.player.scale)) > (self.enemies[y][x].enemy.x + self.enemies[y][x].enemy.offset - (self.enemies[y][x].enemy.image:getWidth() * self.enemies[y][x].enemy.scale * 0.38))) and
						   ((self.player.x + (160 * self.player.scale)) < (self.enemies[y][x].enemy.x + self.enemies[y][x].enemy.offset + (self.enemies[y][x].enemy.image:getWidth() * self.enemies[y][x].enemy.scale * 0.38)))) then
							self.enemies[y][x].enemy.health = self.enemies[y][x].enemy.health - self.player.laser.left.damage
							if(self.enemies[y][x].enemy.maxDamage < self.player.laser.left.damage) then
								self.enemies[y][x].enemy.maxDamage = self.player.laser.left.damage
							end
							if(self.enemies[y][x].enemy.maxProbability > self.player.laser.left.probability) then
								self.enemies[y][x].enemy.maxProbability = self.player.laser.left.probability
							end
						end
					end
				end
			end
		end
		if(self.player.laser.right.state == "fired") then
			for x = 1, #self.enemies[1] do
				for y = 1, #self.enemies do
					if(self.enemies[y][x].enemy) then
						--Combine math for laser position with math for enemy ship position
						--Only check for enemies that are on screen and not already destroyed
						if(not (self.enemies[y][x].enemy.state == "destroyed" or self.enemies[y][x].enemy.state == "created") and 
						   ((self.player.x + (284 * self.player.scale)) > (self.enemies[y][x].enemy.x + self.enemies[y][x].enemy.offset - (self.enemies[y][x].enemy.image:getWidth() * self.enemies[y][x].enemy.scale * 0.38))) and
						   ((self.player.x + (284 * self.player.scale)) < (self.enemies[y][x].enemy.x + self.enemies[y][x].enemy.offset + (self.enemies[y][x].enemy.image:getWidth() * self.enemies[y][x].enemy.scale * 0.38)))) then
							self.enemies[y][x].enemy.health = self.enemies[y][x].enemy.health - self.player.laser.right.damage
							if(self.enemies[y][x].enemy.maxDamage < self.player.laser.right.damage) then
								self.enemies[y][x].enemy.maxDamage = self.player.laser.right.damage
							end
							if(self.enemies[y][x].enemy.maxProbability > self.player.laser.right.probability) then
								self.enemies[y][x].enemy.maxProbability = self.player.laser.right.probability
							end
						end
					end
				end
			end
		end
		--Check for destroyed enemies
		for x = 1, #self.enemies[1] do
			for y = 1, #self.enemies do
				if(self.enemies[y][x].enemy) then
					if(self.enemies[y][x].enemy.health <= 0) then
						self.enemies[y][x].enemy.state = "destroy"
						self.numenemies = self.numenemies - 1
						--Up difficulty based upon max damage done to enemy in one shot
						self.player.health = helpers.round(self.player.health + (self.enemies[y][x].enemy.maxDamage * (0.1 + (0.9 * (1 - self.enemies[y][x].enemy.maxProbability))) ) )
						self.enemyHealth = helpers.round(self.enemyHealth + (self.enemies[y][x].enemy.maxDamage * (0.05 + (0.45 * (1 - self.enemies[y][x].enemy.maxProbability))) ) )
						self.score = helpers.round(self.score + self.enemies[y][x].enemy.maxDamage)
						self.enemyDamage = helpers.round(self.enemyDamage + (self.enemies[y][x].enemy.maxDamage * (0.01 + (0.2 * (1 - self.enemies[y][x].enemy.maxProbability))) ) )
						self.enemies[y][x].particle = nil
						self.enemies[y][x].particle = particle:createSystem(self.enemies[y][x].enemy.x + self.enemies[y][x].enemy.offset, self.enemies[y][x].enemy.y - (self.enemies[y][x].enemy.image:getHeight() * self.enemies[y][x].enemy.scale * 0.5))
						self.audio.channels.sounds:push({name = "enemyExplosion"})
						self.enemies[y][x].enemy:update()
						self.enemies[y][x].enemy = nil
					end
				end
			end
		end
		--Check for firing enemies
		for x = 1, #self.enemies[1] do
			for y = 1, #self.enemies do
				if(self.enemies[y][x].enemy) then
					if(self.enemies[y][x].enemy.firing) then
						self.shots[#self.shots + 1] = shot:new((self.enemies[y][x].enemy.x + self.enemies[y][x].enemy.offset),
																((self.enemies[y][x].enemy.y) - (self.enemies[y][x].enemy.image:getHeight() * self.enemies[y][x].enemy.scale * 0.5)))
						self.audio.channels.sounds:push({name = "enemyShot"})
					end
				end
			end
		end
		--Update shots removing any shots that are offscreen or hit
		for index = 1, #self.shots do
			if(self.shots[index] and self.shots[index].y) then
				self.shots[index]:update()
				--Shot leaves the bottom of the screen
				if(self.shots[index].y > (love.window.getHeight() * 1.15)) then
					local removeIndex = index
					local newShots = {}
					for subindex = 1, #self.shots do
						if(subindex ~= index) then
							newShots[#newShots + 1] = self.shots[subindex]
						end
					end
					self.shots = newShots
				--Shot collides with player
				elseif(self.player:checkCollision(self.shots[index])) then
					self.player.health = self.player.health - self.enemyDamage
					self.audio.channels.sounds:push({name = "hit"})
					self.particles[self.particles.current] = shotParticle:createSystem(self.shots[index].x, self.shots[index].y)
					self.particles.current = (((self.particles.current) % self.particles.size) + 1)
					local removeIndex = index
					local newShots = {}
					for subindex = 1, #self.shots do
						if(subindex ~= index) then
							newShots[#newShots + 1] = self.shots[subindex]
						end
					end
					self.shots = newShots
				end
			end
		end
		--Update particle emitters
		for x = 1, #self.enemies[1] do
			for y = 1, #self.enemies do
				if(self.enemies[y][x].particle) then
					self.enemies[y][x].particle:update(dt)
				end
			end
		end
		for index = 1, self.particles.size do
			if(self.particles[index]) then
				self.particles[index]:update(dt)
			end
		end
		if(self.player.laser.left.particle) then
			self.player.laser.left.particle:update(dt)
		end
		if(self.player.laser.right.particle) then
			self.player.laser.right.particle:update(dt)
		end
		
		--Pause the game.
		if((self.keyState["return"] or self.joystick.buttons[5]) and (not self.inputLock["return"])) then
			self.inputLock:lock("return")
			self.audio.channels.sounds:push({name = "enter"})
			self.state = "pause"
			ui.state = "pause"
			ui.pauseFrames = 0
		end
		--End the game if the player has no health
		if(self.player.health <= 0) then
			self.player.health = 0
			self.state = "end"
			self.frames = 60
			self.audio.channels.music:push({name = "fadeOut", steps = 30, length = 0.5})
			self.audio.channels.sounds:push({name = "playerExplosion"})
		end
	--Pause state
	elseif(self.state == "pause") then
		--Update ui and wait for feedback
		feedback = ui:update()
		if(feedback == "game") then
			self.state = "game"
		elseif(feedback == "end") then
			self.audio.channels.music:push({name = "fadeOut", steps = 30, length = 0.5})
			self.audio.channels.sounds:push({name = "playerExplosion"})
			self.state = "end"
			self.frames = 60
		end
	--End state
	elseif(self.state == "end") then
		--Create explosion for player
		if(self.frames == 60) then
			self.playerParticle = playerParticle:createSystem(self.player.x + (self.player.image:getWidth() * self.player.scale * 0.5), self.player.y + (self.player.image:getHeight() * self.player.scale * 0.5))
			self.playerParticle:start()
		end
		--Start ending song
		if(self.frames == 30) then
			self.audio.channels.music:push({name = "startEnd"})
		end
		if(self.frames > 0) then
			self.frames = self.frames - 1
		--Fade out after button press
		elseif(self.keyState["return"] or self.joystick.buttons[11] or self.joystick.buttons[5]) then
			self.state = "fadeout"
			self.frames = 119
		end
	--Fade out state
	elseif(self.state == "fadeout") then
		--Fade end song out slowly
		if(self.frames >= 119) then
			self.audio.channels.music:push({name = "fadeEnd"})
		end
		--Clear enemies and enemy particle systems
		if(self.frames > 0) then
			self.frames = self.frames - 1
		else
			for x = 1, #self.enemies[1] do
				for y = 1, #self.enemies do
					self.enemies[y][x].enemy = nil
					self.enemies[y][x].particle = nil
				end
			end
			--Clear shots and particle systems
			self.shots = {}
			self.particles = {current = 1, size = 3}
			--Set max score
			self.maxScore = ((self.maxScore < self.score) and self.score) or self.maxScore
			self.state = "start"
			return "end"
		end
	end
	--Special handling of enemies, shots, particles, and lasers to maintain animation during end and fadeout
	if(self.state == "end" or self.state == "fadeout") then
		--Accelerate enemies offscreen
		for x = 1, #self.enemies[1] do
			for y = 1, #self.enemies do
				if(self.enemies[y][x].enemy) then
					self.enemies[y][x].enemy.y = self.enemies[y][x].enemy.y * 1.03
				end
			end
		end
		--Update shots
		for index = 1, #self.shots do
			if(self.shots[index] and self.shots[index].y) then
				self.shots[index]:update()
				if(self.shots[index].y > (love.window.getHeight() * 1.15)) then
					self.shots[index] = nil
				end
			end
		end
		--Update particles
		for x = 1, #self.enemies[1] do
			for y = 1, #self.enemies do
				if(self.enemies[y][x].particle) then
					self.enemies[y][x].particle:update(dt)
				end
			end
		end
		if(self.playerParticle) then
			self.playerParticle:update(dt)
		end
		if(self.player.laser.left.particle) then
			self.player.laser.left.particle:update(dt)
		end
		if(self.player.laser.right.particle) then
			self.player.laser.right.particle:update(dt)
		end
	end
	--Move and wrap background if not paused
	if(self.state == "start" or self.state == "game" or self.state == "end" or self.state == "fadeout") then
		if(self.background.y >= love.window.getHeight()) then
			self.background.y = (-self.background.scale * self.background.image:getHeight()) + love.window.getHeight()
		else
			self.background.y = self.background.y + 0.125
		end
	end
	--Configure UI values
	ui.enemyHealth = self.enemyHealth
	ui.score = self.score
	ui.playerHealth = self.player.health
	ui.leftGun = {damage = self.player.laser.left.damage, probability = self.player.laser.left.probability, highlight = self.player.laser.left.cycle}
	ui.rightGun = {damage = self.player.laser.right.damage, probability = self.player.laser.right.probability, highlight = self.player.laser.right.cycle}
end

function game:draw()
	--Choose current shader
	shader = self.shader[self.shaderSetting]
	--Set ui boundries to Gaussian blur behind
	if(self.shaderSetting > 1) then
		shader:send("uiBound", {ui.font:getHeight(), ui.bottomEdge})
	end
	--Fade intro
	if(self.state == "start") then
		--Fade from gray
		if(self.frames >= 180) then
			change = (((self.frames - 180)) / 60)
			love.graphics.setBackgroundColor(183 * change, 185 * change, 189 * change, 255)
			love.graphics.clear()
		--Fade in game
		else
			--This is similar to below code for rendering
			current = love.graphics.getCanvas()
			love.graphics.setCanvas(self.canvas)
			love.graphics.setBackgroundColor(0,0,0,255)
			love.graphics.clear()
			love.graphics.draw(self.background.image, 0, self.background.y, 0, self.background.scale, self.background.scale)
			self.player:draw()
			love.graphics.setCanvas(current)
			love.graphics.setShader(shader)
			shader:send("amount", 0)
			shader:send("fade", 0)
			love.graphics.setBackgroundColor(0,0,0,255)
			love.graphics.clear()
			love.graphics.setColor(255, 255, 255, (255 * ((180 - self.frames) / 180)))
			love.graphics.draw(self.canvas, 0, 0)
			love.graphics.setShader()
			ui:draw((255 * ((180 - self.frames) / 180)))
		end
	else
		--Grab the current framebuffer
		current = love.graphics.getCanvas()
		--Change to local framebuffer
		love.graphics.setCanvas(self.canvas)
		love.graphics.setColor(255, 255, 255, 255)
		--Draw background image twice, second time shifted by image height for seamless scrolling
		love.graphics.draw(self.background.image, 0, self.background.y, 0, self.background.scale, self.background.scale)
		love.graphics.draw(self.background.image, 0, (self.background.y - (self.background.scale * self.background.image:getHeight())), 0, self.background.scale, self.background.scale)
		--If the game is not over, draw the player
		--This hides the player during the end explosion
		if(self.state ~= "end" and self.state ~= "fadeout") then
			self.player:draw()
		end
		--Draw any shots that currently exist
		for index = 1, #self.shots do
			if(self.shots[index]) then
				self.shots[index]:draw()
			end
		end
		--Draw any enemies that currently exist
		for x = 1, #self.enemies[1] do
			for y = 1, #self.enemies do
				if(self.enemies[y][x].enemy) then
					self.enemies[y][x].enemy:draw()
				end
			end
		end
		--Change alpha blending to additive to enhance particle effects
		love.graphics.setBlendMode("additive")
		--Draw all active particle systems
		for x = 1, #self.enemies[1] do
			for y = 1, #self.enemies do
				if(self.enemies[y][x].particle) then
					love.graphics.draw(self.enemies[y][x].particle)
				end
			end
		end
		for index = 1, self.particles.size do
			if(self.particles[index]) then
				love.graphics.draw(self.particles[index])
			end
		end
		if(self.playerParticle) then
			love.graphics.draw(self.playerParticle)
		end
		if(self.player.laser.left.particle) then
			love.graphics.draw(self.player.laser.left.particle)
		end
		if(self.player.laser.right.particle) then
			love.graphics.draw(self.player.laser.right.particle)
		end
		--Set alpha blend mode back to alpha
		love.graphics.setBlendMode("alpha")
		--Restore the global framebuffer
		love.graphics.setCanvas(current)
		--Enable the postprocessing shader
		love.graphics.setShader(shader)
		--Change postprocessing parameters based upon state and current frame
		--Game state
		if(self.state == "game") then
			shader:send("amount", 0)
			shader:send("fade", 0)
			love.graphics.setColor(255, 255, 255, 255)
		--Pause state - Fade, arkening and blur
		elseif(self.state == "pause") then
			shader:send("amount", ui.pauseFrames)
			shader:send("fade", 0)
			love.graphics.setColor(255, 255, 255, 128 + (127 * ((30 - ui.pauseFrames) / 30)))
		--End state - Fade, darkening and blur
		elseif(self.state == "end") then
			if(self.frames > 30) then
				shader:send("amount", 30 - (self.frames - 30))
				love.graphics.setColor(255, 255, 255, 128 + (127 * ((self.frames - 30) / 30)))
			else
				shader:send("amount", 30)
				love.graphics.setColor(255, 255, 255, 128)
			end
			shader:send("fade", 0)
		--Fadeout state - Fade from darkened blur to menu gray
		elseif(self.state == "fadeout") then
			shader:send("amount", 120 - self.frames)
			shader:send("fade", 1)
			love.graphics.setColor(183, 185, 189, 128 + (127 * ((120 - self.frames) / 120)))
		end
		--Clear and draw using postprocessing shader the local framebuffer to the global framebuffer
		love.graphics.setBackgroundColor(0,0,0,255)
		love.graphics.clear()
		love.graphics.draw(self.canvas, 0, 0)
		--Switch to default shaders
		love.graphics.setShader()
		--If end or fadeout state, then show score, losing message, fade appropriately, and draw ui
		if(self.state == "end") then
			love.graphics.setFont(self.font)
			love.graphics.setColor(255, 64, 64, 255 * ((60 - self.frames) / 60))
			love.graphics.printf("Your luck has run out...", 0, (love.window.getHeight() / 2) - (self.font:getHeight()), love.window.getWidth(), "center")
			love.graphics.printf(tostring(self.score), 0, love.window.getHeight() / 2, love.window.getWidth(), "center")
			love.graphics.setColor(255, 255, 255, 255)
			ui:draw()
		elseif(self.state == "fadeout") then
			love.graphics.setFont(self.font)
			love.graphics.setColor(255, 64, 64, 255 * (self.frames / 120))
			love.graphics.printf("Your luck has run out...", 0, (love.window.getHeight() / 2) - (self.font:getHeight()), love.window.getWidth(), "center")
			love.graphics.printf(tostring(self.score), 0, love.window.getHeight() / 2, love.window.getWidth(), "center")
			ui:draw(255 * (self.frames / 120))
		else
			love.graphics.setColor(255, 255, 255, 255)
			ui:draw()
		end
		love.graphics.setColor(255, 255, 255, 255)
		--Draw the pause menu
		ui:drawMenu()
	end
end