--[[
    DESERT MAN
    Author : Kyler Witvoet

    Final Project for CS50 2020
]]


-- imports the push library and the class library
Class = require 'class'
push = require 'push'

-- imports the required classes
require 'Util'
require 'Map'
require 'Player'
require 'Animation'


-- defines the size of the application window
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720
-- defines the size of the virtual screen displayed in the window
VIRTUAL_WIDTH = 864
VIRTUAL_HEIGHT = 486 

-- variables for background
-- credit to "Cecihoney" for "desert background"
local background = love.graphics.newImage('graphics/background.png')
local background1 = love.graphics.newImage('graphics/background1.png')
local background2 = love.graphics.newImage('graphics/background2.png')
local clouds = love.graphics.newImage('graphics/clouds.png')
-- variable to keep track of background scrolling and looping
local cloudScroll = 0
local backgroundScroll = 0
local BACKGROUND_SCROLL_SPEED = 0
local CLOUD_SCROLL_SPEED = 20
local BACKGROUND_LOOPING_POINT = 960
scrolling = true
-- boolean on whether or not the game has "started"
local start = false

-- only runs once to load the game world
-- initializes all objects and date needed by program
function love.load()
    -- sets the random seed to the current time
    math.randomseed(os.time())
    -- makes zoomed in image clearer
    love.graphics.setDefaultFilter('nearest', 'nearest')
    -- an object to contain the map data
    map = Map()
    -- sets up the screen with a virtual resolution
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        vsync = false,
        resizable = true
    })
    -- sets the font to "Viking, Elder Runes" by "flansburg_design"
    font = love.graphics.newFont('fonts/viking_middle_runes.ttf', 25)
    love.graphics.setFont(font)

    love.window.setTitle('DESERT MAN')

    love.keyboard.keysPressed = {}
end

-- called when the window is resized
function love.resize(w, h)
    push:resize(w, h)
end

-- called whenever a key is pressed
function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'return' then
        start = true
    elseif key == 'r' then
        map:procGen()
    end

    love.keyboard.keysPressed[key] = true
end

-- returns if a key was pressed or not
function love.keyboard.wasPressed(key)
    return love.keyboard.keysPressed[key]
 end

-- updates the game world
function love.update(dt)

    -- background image scrolling
    if map.camX >= map.player.x + VIRTUAL_WIDTH / 2 then
        -- scrolls the background based on which key is pressed
        if love.keyboard.isDown('left') then
            BACKGROUND_SCROLL_SPEED = 30
        elseif love.keyboard.isDown('right') then
            BACKGROUND_SCROLL_SPEED = -30
        else
            BACKGROUND_SCROLL_SPEED = 0
        end
    else
        BACKGROUND_SCROLL_SPEED = 0
    end
    
    if scrolling == true then
        backgroundScroll = (backgroundScroll + BACKGROUND_SCROLL_SPEED * dt) % BACKGROUND_LOOPING_POINT
    end
    -- the clouds scroll automatically
    cloudScroll = (cloudScroll + CLOUD_SCROLL_SPEED * dt) % BACKGROUND_LOOPING_POINT
    -- updates the map
    map:update(dt)

    love.keyboard.keysPressed = {}

end

-- called each frame, renders data to the screen
function love.draw()
    -- begins drawing to the virtual screen
    push:apply('start')

    -- if the player hasn't hit enter yet then the game wont start
    if start == false then
        love.graphics.draw(background, -backgroundScroll, 0)
        love.graphics.draw(clouds, math.floor(-cloudScroll), 0)
        love.graphics.setColor(0,0,0,1)
        love.graphics.print('DESERT MAN',VIRTUAL_WIDTH / 4 + 32,VIRTUAL_HEIGHT / 2 - 20,0,3,3)
        love.graphics.print('PRESS ENTER TO START',VIRTUAL_WIDTH / 4 + 96,VIRTUAL_HEIGHT / 2 + 44)
    else 
        -- draws background image based on the current type of desert     
        love.graphics.translate(math.floor(-map.camX + 0.5), math.floor(-map.camY + 0.5 + 128))
        if mapType == 0 then
            love.graphics.draw(background, math.floor(-backgroundScroll), math.floor(map.camY - 128))
        elseif mapType == 1 then
            love.graphics.draw(background1, math.floor(-backgroundScroll), math.floor(map.camY - 128))
        elseif mapType == 2 then
            love.graphics.draw(background2, math.floor(-backgroundScroll), math.floor(map.camY - 128)) 
        end
        love.graphics.draw(clouds, math.floor(-cloudScroll), math.floor(map.camY - 128))    
        -- renders the map
        map:render()
    end

    -- ends drawing to the virtual screen
    push:apply('end')

end