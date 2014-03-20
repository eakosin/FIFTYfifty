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
require("menu")
require("game")

debugLog:clear()

--Global Variables
state = "load"
screenshot = false

--Global Tables
canvas = {}
font = {}
audio = {thread = {}, channels = {}}
parameters = {maxScore = 0,
			  shaderSetting = 3,
			  music = 10,
			  sounds = 10}

--First layer input handling	
inputLock = {}
function inputLock:lock(input)
	if(self[input]) then
		return false
	end
	self[input] = true
	return true
end
function inputLock:unlock(input)
	self[input] = false
end
keyState = {}
function love.keypressed(key)
	keyState[key] = true
end
function love.keyreleased(key)
	keyState[key] = nil
	if(key == "w") then
		inputLock:unlock("up")
	elseif(key == "s") then
		inputLock:unlock("down")
	elseif(key == "a") then
		inputLock:unlock("left")
	elseif(key == "d") then
		inputLock:unlock("right")
	end
	inputLock:unlock(key)
end
joystick = {buttons = {}, axes = {}}
function love.joystickpressed(joystickIn, button)
	joystick.buttons[button] = joystickIn
	--debugLog:append("Button : "..tostring(button).."\n")
end
function love.joystickreleased(joystickIn, button)
	if(button == 1) then
		inputLock:unlock("up")
	elseif(button == 2) then
		inputLock:unlock("down")
	elseif(button == 3) then
		inputLock:unlock("left")
	elseif(button == 4) then
		inputLock:unlock("right")
	elseif(button == 5 or button == 11 or button == 12) then
		inputLock:unlock("return")
	end
	joystick.buttons[button] = nil
end
function love.joystickaxis(joystickIn, axis, value)
	joystick.axes[axis] = value
	--debugLog:append("Axis "..tostring(axis)..": "..tostring(value).."\n")
	if((value > -0.25 and value < 0.25) and axis == 2) then
		inputLock:unlock("up")
		inputLock:unlock("down")
	elseif((value > -0.25 and value < 0.25) and axis == 1) then
		inputLock:unlock("left")
		inputLock:unlock("right")
	end
end

function love.resize(width, height)
	menu:resize()
	game:resize()
end

--Check for compatability
function compatibilityCheck()
	compatibilityFail = false
	line = 0
	if(not love.graphics.isSupported("canvas")) then
		love.graphics.print("Canvases(FBO) not support on this graphics card.", 16, 16 + line)
		line = line + 16
		compatibilityFail = true
	end
	if(not love.graphics.isSupported("npot")) then
		love.graphics.print("Non power-of-two canvases not supported on this graphics card.", 16, 16 + line)
		line = line + 16
		compatibilityFail = true
	end
	if(compatibilityFail) then
		love.graphics.present()
		while(not (love.keyboard.isDown("escape") or love.keyboard.isDown("return"))) do
			love.event.pump()
			love.timer.sleep(0.01)
			--Pause until escape is pressed
		end
		love.event.quit()
	end
end

function love.load()
	compatibilityCheck()
	
	love.graphics.setBackgroundColor(26,26,27,255)
	love.graphics.clear()
	love.graphics.present()
	
	--Read in configuration file
	file = io.open("./config.ini", "r")
	if(file) then
		local text = file:read()
		while(text) do
			key, value = text:divide("|")
			debugLog:append("Key: "..tostring(key).." Value: "..tostring(value).."\n")
			parameters[key] = tonumber(value)
			text = file:read()
		end
		file:close()
	end
	
	love.graphics.setBackgroundColor(52,52,53,255)
	love.graphics.clear()
	love.graphics.present()
	
	--Prepare rendering canvases
	local screenWidth, screenHeight = love.window.getDesktopDimensions(1)
	love.graphics.setDefaultFilter("linear", "linear", 8)
	canvas.diffuse = love.graphics.newCanvas()
	love.graphics.setDefaultFilter("linear", "linear", 8)
	canvas.primary = love.graphics.newCanvas()
	
	love.graphics.setBackgroundColor(78,78,80,255)
	love.graphics.clear()
	love.graphics.present()
	
	--Create and initialize audio thread
	audio.thread = love.thread.newThread("audio.lua")
	audio.channels.thread = love.thread.getChannel("thread")
	audio.channels.music = love.thread.getChannel("music")
	audio.channels.sounds = love.thread.getChannel("sounds")
	audio.channels.feedback = love.thread.getChannel("feedback")
	audio.thread:start()
	
	love.graphics.setBackgroundColor(104,105,107,255)
	love.graphics.clear()
	love.graphics.present()
	
	--Set menu global references and load menu content
	menu.keyState = keyState
	menu.inputLock = inputLock
	menu.joystick = joystick
	menu.audio = audio
	menu:load()
	
	love.graphics.setBackgroundColor(130,131,134,255)
	love.graphics.clear()
	love.graphics.present()
	
	--Set game global references and load game content
	game.keyState = keyState
	game.inputLock = inputLock
	game.joystick = joystick
	game.audio = audio
	game:load()
	
	love.graphics.setBackgroundColor(156,157,161,255)
	love.graphics.clear()
	love.graphics.present()
	
	--Wait for audio thread and set volume from config file value
	while(not audio.channels.feedback:pop()) do end
	audio.channels.thread:push({name = "setVolume", musicVolume = ((parameters.music - 1) / 10), soundsVolume = ((parameters.sounds - 1) / 10)})
	
	love.graphics.setBackgroundColor(183,185,189,255)
	love.graphics.clear()
	love.graphics.present()
	
	state = "startMenu"
end

timeStart = 0
frame = 0

function love.update(dt)
	timeStart = love.timer.getTime()
	love.event.pump()
	
	--Quit exit
	if(keyState.escape) then
		love.event.quit()
	end
	
	--Screenshot key
	if(keyState["\\"] and (not inputLock["\\"])) then
		inputLock:lock("\\")
		screenshot = true
	end
	
	--Handle global state
	--Menu start state
	if(state == "startMenu") then
		audio.channels.music:push({name = "startMenu"})
		menu.maxScore.score = parameters.maxScore
		menu.options[1].value = parameters.music + 1
		menu.options[2].value = parameters.sounds + 1
		menu.options[3].value = parameters.shaderSetting
		state = "menu"
	--Menu state
	elseif(state == "menu") then
		feedback = menu:update()
		--Move to game state and configure game from menu settings
		if(feedback == "game") then
			state = "game"
			parameters.music = menu.options[1].value - 1
			parameters.sounds = menu.options[2].value - 1
			parameters.shaderSetting = menu.options[3].value
			game.shaderSetting = parameters.shaderSetting
			game.maxScore = parameters.maxScore
			game:reset()
		--Quit from menu
		elseif(feedback == "quit") then
			parameters.music = menu.options[1].value - 1
			parameters.sounds = menu.options[2].value - 1
			parameters.shaderSetting = menu.options[3].value
			love.event.quit()
		end
	--Game state
	elseif(state == "game") then
		feedback = game:update(dt)
		--Move back to the menu
		if(feedback == "end") then
			parameters.maxScore = game.maxScore
			state = "startMenu"
		end
	end
	--debugLog:commit()
end

--Draw scene
function love.draw()
	love.graphics.setCanvas(canvas.diffuse)
	
	love.graphics.setBackgroundColor(183,185,189,255)
	love.graphics.clear()
	
	if(state == "menu") then
		menu:draw()
	elseif(state == "game") then
		game:draw()
	end
	
	love.graphics.setCanvas(canvas.primary)
	love.graphics.origin()
	love.graphics.draw(canvas.diffuse,0,0,0,1,1)
	love.graphics.setCanvas()
	love.graphics.draw(canvas.primary)
	
	--Save a screenshot if \ is pressed
	if(screenshot) then
		screenshot = false
		canvas.diffuse:getImageData():encode("screenshot"..tostring(os.time())..".png")
	end
end

--Quitting
function love.quit()
	--Exit cleanly
	if(not compatibilityFail) then
		audio.channels.thread:push({name = "kill"})
		audio.thread:wait()
		--Grab first error from the audio thread
		-- if(audio.thread:getError()) then
			-- debugLog:append("Audio Thread Error:\n"..audio.thread:getError())
		-- end
		--Write configuration parameters to config file
		file = io.open("./config.ini", "w")
		if(file) then
			for key, value in pairs(parameters) do
				file:write(tostring(key).."|"..tostring(value).."\n")
			end
			file:close()
		end
	end
	--debugLog:commit()
end

--The main loop
function love.run()

    if love.math then
        love.math.setRandomSeed(os.time())
    end

    if love.event then
        love.event.pump()
    end

    if love.load then love.load(arg) end

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end

    local dt = 0

    -- Main loop time.
    while true do
        -- Process events.
        if love.event then
            love.event.pump()
            for e,a,b,c,d in love.event.poll() do
                if e == "quit" then
                    if not love.quit or not love.quit() then
                        if love.audio then
                            love.audio.stop()
                        end
                        return
                    end
                end
                love.handlers[e](a,b,c,d)
            end
        end

        -- Update dt, as we'll be passing it to update
        if love.timer then
            love.timer.step()
            dt = love.timer.getDelta()
        end

        -- Call update and draw
        if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

        if love.window and love.graphics then
            love.graphics.clear()
            love.graphics.origin()
            if love.draw then love.draw() end
            love.graphics.present()
        end

        if love.timer then love.timer.sleep(0.001) end
    end

end

local function error_printer(msg, layer)
    print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end

function love.errhand(msg)
	-- if((not compatibilityFail) and audio.thread.getError()) then
		-- debugLog:append("Audio Thread Error:\n"..audio.thread:getError())
	-- end
	-- debugLog:commit()
	
    msg = tostring(msg)

    error_printer(msg, 2)

    if not love.window or not love.graphics or not love.event then
        return
    end

    if not love.graphics.isCreated() or not love.window.isCreated() then
        if not pcall(love.window.setMode, 800, 600) then
            return
        end
    end

    -- Reset state.
    if love.mouse then
        love.mouse.setVisible(true)
        love.mouse.setGrabbed(false)
    end
    if love.joystick then
        for i,v in ipairs(love.joystick.getJoysticks()) do
            v:setVibration() -- Stop all joystick vibrations.
        end
    end
    if love.audio then love.audio.stop() end
    love.graphics.reset()
    love.graphics.setBackgroundColor(89, 157, 220)
    local font = love.graphics.setNewFont(14)

    love.graphics.setColor(255, 255, 255, 255)

    local trace = debug.traceback()

    love.graphics.clear()
    love.graphics.origin()

    local err = {}

    table.insert(err, "Error\n")
    table.insert(err, msg.."\n\n")

    for l in string.gmatch(trace, "(.-)\n") do
        if not string.match(l, "boot.lua") then
            l = string.gsub(l, "stack traceback:", "Traceback\n")
            table.insert(err, l)
        end
    end

    local p = table.concat(err, "\n")

    p = string.gsub(p, "\t", "")
    p = string.gsub(p, "%[string \"(.-)\"%]", "%1")

    local function draw()
        love.graphics.clear()
        love.graphics.printf(p, 70, 70, love.graphics.getWidth() - 70)
        love.graphics.present()
    end

    while true do
        love.event.pump()

        for e, a, b, c in love.event.poll() do
            if e == "quit" then
                return
            end
            if e == "keypressed" and a == "escape" then
                return
            end
        end

        draw()

        if love.timer then
            love.timer.sleep(0.1)
        end
    end

end