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

--This is the audio thread. Audio events are passed to it through channels
--and it can respond back through the feedback channel.
require("love.audio")
require("love.sound")
require("love.filesystem")
require("love.timer")

--Create the audio table and set state
local audio = {}
audio.running = true
audio.state = "load"

--Parameters for controlling audio
audio.fadeVolume = 0.0
audio.pitch = 1.0
audio.fadeSteps = 0
audio.fadeTime = 0
audio.currenStep = 0
audio.spinSteps = 0

--Channels for communication with audio thread
audio.channels = {}
audio.channels.thread = love.thread.getChannel("thread")
audio.channels.music = love.thread.getChannel("music")
audio.channels.sounds = love.thread.getChannel("sounds")
audio.channels.feedback = love.thread.getChannel("feedback")

--Tables for each part of the audio thread
audio.thread = {}
audio.music = {volume = 1.0}
audio.sounds = {volume = 1.0}

--List of music and sounds to load
audio.music.list = {"menu", "menuLoop", "end", "endLoop", "game", "gameLoop"}
audio.music.sources = {}
audio.sounds.list = {select = 0.0,
					 enter = 0.0,
					 back = 0.0,
					 enemyShot = 0.5,
					 playerExplosion = 0.0,
					 enemyExplosion = 0.25,
					 laser = 0.0,
					 fail = 0.0,
					 hit = 0.0,
					 cycleLeft = 0.40,
					 cycleRight = 0.40}
audio.sounds.data = {}
audio.sounds.sources = {buffer = {}, size = 1, current = 1}

--Preload audio data
for index, name in pairs(audio.music.list) do
	audio.music.sources[name] = love.audio.newSource("music/"..name..".ogg", "static")
end

for name, _ in pairs(audio.sounds.list) do
	audio.sounds.data[name] = love.sound.newSoundData("sounds/"..name..".ogg")
end

--Notify the main thread that all audio has been pre-loaded
audio.channels.feedback:push(true)

--Stop all currently playing music
function stopMusic()
	audio.music.sources["menu"]:stop()
	audio.music.sources["menuLoop"]:stop()
	audio.music.sources["end"]:stop()
	audio.music.sources["endLoop"]:stop()
	audio.music.sources["game"]:stop()
	audio.music.sources["gameLoop"]:stop()
end

--Clamp value
function clamp(value,lower,upper)
	if(value < lower) then
		return lower
	elseif(value > upper) then
		return upper
	else
		return value
	end
end

while(audio.running) do
	--Pop thread event
	audio.thread.event = audio.channels.thread:pop()
	--Process thread event
	if(audio.thread.event) then
		--Kill the thread
		if(audio.thread.event.name == "kill") then
			audio.running = false
			love.audio.stop()
		--Stop all audio
		elseif(audio.thread.event.name == "stop") then
			love.audio.stop()
		--Set audio volumes and adjust menu song volume
		elseif(audio.thread.event.name == "setVolume") then
			audio.music.volume = audio.thread.event.musicVolume
			audio.sounds.volume = audio.thread.event.soundsVolume
			audio.music.sources["menu"]:setVolume(audio.music.volume)
			audio.music.sources["menuLoop"]:setVolume(audio.music.volume)
			for index = 1, audio.sounds.sources.size do
				if(audio.sounds.sources.buffer[index]) then
					audio.sounds.sources.buffer[index]:setVolume(audio.sounds.volume)
				end
			end
		--Get audio volumes
		elseif(audio.thread.event.name == "getVolume") then
			audio.channels.feedback:push({music = audio.music.volume, sounds = audio.sounds.volume})
		end
		audio.thread.event = nil
	end
	
	--Pop music event
	audio.music.event = audio.channels.music:pop()
	--Process music event
	if(audio.music.event) then
		--Start the appropriate song or fade music
		if(audio.music.event.name == "startMenu") then
			audio.state = "startMenu"
		elseif(audio.music.event.name == "startEnd") then
			audio.state = "startEnd"
		elseif(audio.music.event.name == "fadeEnd") then
			audio.state = "fadeEnd"
			audio.fadeVolume = audio.music.volume
		elseif(audio.music.event.name == "startGame") then
			audio.state = "startGame"
		elseif(audio.music.event.name == "fadeOut") then
			audio.state = "fadeOut"
			audio.fadeVolume = audio.music.volume
			audio.fadeSteps = audio.music.event.steps
			audio.currentStep = audio.fadeSteps
			audio.fadeTime = audio.music.event.length
		--Drop pitch and fade volume - sounds awful, even at 44.1khz steps to match sample rate
		elseif(audio.music.event.name == "spinDown") then
			audio.state = "spinDown"
			audio.pitch = 1.0
			audio.spinSteps = 88200
		end
		audio.music.event = nil
	end
	
	--Handle audio states
	--Start startMenu song
	if(audio.state == "startMenu") then
		stopMusic()
		audio.music.sources["menu"]:setVolume(audio.music.volume)
		audio.music.sources["menu"]:play()
		audio.state = "loopMenu"
	--Wait till startMenu song is done and start loopMenu
	elseif(audio.state == "loopMenu") then
		if(audio.music.sources["menu"]:isStopped()) then
			if(audio.music.sources["menuLoop"]:isStopped()) then
				audio.music.sources["menuLoop"]:setLooping(true)
				audio.music.sources["menuLoop"]:setVolume(audio.music.volume)
				audio.music.sources["menuLoop"]:play()
			end
		end
	--Start startEnd song
	elseif(audio.state == "startEnd") then
		stopMusic()
		audio.music.sources["end"]:setVolume(audio.music.volume)
		audio.music.sources["end"]:play()
		audio.state = "loopEnd"
	--Wait till startEnd song is done and start loopEnd
	elseif(audio.state == "loopEnd") then
		if(audio.music.sources["end"]:isStopped()) then
			if(audio.music.sources["endLoop"]:isStopped()) then
				audio.music.sources["endLoop"]:setLooping(true)
				audio.music.sources["endLoop"]:setVolume(audio.music.volume)
				audio.music.sources["endLoop"]:play()
			end
		end
	--Fade the end song out slowly over 2 seconds
	elseif(audio.state == "fadeEnd") then
		audio.fadeVolume = audio.fadeVolume - (audio.music.volume * (1 / 120))
		love.timer.sleep(1 / 60)
		audio.music.sources["endLoop"]:setVolume(audio.fadeVolume)
		audio.music.sources["end"]:setVolume(audio.fadeVolume)
	--Start startGame song
	elseif(audio.state == "startGame") then
		stopMusic()
		audio.music.sources["game"]:setVolume(audio.music.volume)
		audio.music.sources["game"]:play()
		audio.state = "loopGame"
	--Wait till startGame song is done and start loopGame
	elseif(audio.state == "loopGame") then
		if(audio.music.sources["game"]:isStopped()) then
			if(audio.music.sources["gameLoop"]:isStopped()) then
				audio.music.sources["gameLoop"]:setLooping(true)
				audio.music.sources["gameLoop"]:setVolume(audio.music.volume)
				audio.music.sources["gameLoop"]:play()
			end
		end
	--Fade out all songs in fadeSteps over fadeTime
	elseif(audio.state == "fadeOut") then
		if(audio.currentStep > 0) then
			audio.fadeVolume = audio.fadeVolume - (audio.music.volume / audio.fadeSteps)
			audio.currentStep = audio.currentStep - 1
			audio.music.sources["menu"]:setVolume(audio.fadeVolume)
			audio.music.sources["menuLoop"]:setVolume(audio.fadeVolume)
			audio.music.sources["end"]:setVolume(audio.fadeVolume)
			audio.music.sources["endLoop"]:setVolume(audio.fadeVolume)
			audio.music.sources["game"]:setVolume(audio.fadeVolume)
			audio.music.sources["gameLoop"]:setVolume(audio.fadeVolume)
		else
			stopMusic()
		end
		love.timer.sleep(audio.fadeTime / audio.fadeSteps)
	--Drop pitch and fade volume for songs - sounds awful
	elseif(audio.state == "spinDown") then
		if(audio.spinSteps > 0) then
			audio.fadeVolume = audio.fadeVolume - (audio.music.volume * (1 / 88200))
			audio.pitch = audio.pitch * 0.99996
			audio.spinSteps = audio.spinSteps - 1
			audio.music.sources["menu"]:setPitch(audio.pitch)
			audio.music.sources["menuLoop"]:setPitch(audio.pitch)
			audio.music.sources["end"]:setPitch(audio.pitch)
			audio.music.sources["endLoop"]:setPitch(audio.pitch)
			audio.music.sources["game"]:setPitch(audio.pitch)
			audio.music.sources["gameLoop"]:setPitch(audio.pitch)
			audio.music.sources["menu"]:setVolume(audio.fadeVolume)
			audio.music.sources["menuLoop"]:setVolume(audio.fadeVolume)
			audio.music.sources["end"]:setVolume(audio.fadeVolume)
			audio.music.sources["endLoop"]:setVolume(audio.fadeVolume)
			audio.music.sources["game"]:setVolume(audio.fadeVolume)
			audio.music.sources["gameLoop"]:setVolume(audio.fadeVolume)
		else
			stopMusic()
			audio.music.sources["menu"]:setPitch(1)
			audio.music.sources["menuLoop"]:setPitch(1)
			audio.music.sources["end"]:setPitch(1)
			audio.music.sources["endLoop"]:setPitch(1)
			audio.music.sources["game"]:setPitch(1)
			audio.music.sources["gameLoop"]:setPitch(1)
		end
		love.timer.sleep(1 / 88200)
	end
	
	--Pop sound event
	audio.sounds.event = audio.channels.sounds:pop()
	if(audio.sounds.event) then
		--Insert sound into sound buffer in first available slot or at end of buffer
		for index = 1, (audio.sounds.sources.size + 1) do
			if(audio.sounds.sources.buffer[index] == nil) then
				audio.sounds.sources.buffer[index] = love.audio.newSource(audio.sounds.data[audio.sounds.event.name])
				audio.sounds.sources.buffer[index]:setVolume(clamp(audio.sounds.volume - audio.sounds.list[audio.sounds.event.name], 0.0, 1.0))
				if(audio.sounds.event.pitch) then
					audio.sounds.sources.buffer[index]:setPitch(audio.sounds.event.pitch)
				end
				audio.sounds.sources.buffer[index]:play()
				if(index > audio.sounds.sources.size) then
					audio.sounds.sources.size = audio.sounds.sources.size + 1
				end
				break
			end
		end
		audio.sounds.event = nil
	end
	
	--Purge finished sounds
	audio.sounds.sources.current = (((audio.sounds.sources.current) % (audio.sounds.sources.size)) + 1)
	if(audio.sounds.sources.buffer[audio.sounds.sources.current] and audio.sounds.sources.buffer[audio.sounds.sources.current]:isStopped()) then
		audio.sounds.sources.buffer[audio.sounds.sources.current] = nil
	end
end