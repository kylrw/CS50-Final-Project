--[[
    Author : Kyler Witvoet

    Final Project for CS50 2020

    Contains all data and code for the player.
]]

Player = Class{}

local MOVE_SPEED = 160
local JUMP_VELOCITY = 700
local GRAVITY = 30

function Player:init(map)
    -- defines the height and width of the player image
    self.width = 32
    self.height = 40

    -- defines the starting position of the player
    self.x = map.tileWidth * 10
    self.y = map.tileHeight * (map.mapHeight / 3 - 1) - self.height

    -- holds the players current velocities
    self.dx = 0
    self.dy = 0

    -- offset from top left to center for sprite flipping
    self.xOffset = self.width / 2
    self.yOffset = self.height / 2

    -- reference to map
    self.map = map

    -- grabs the png image from files
    self.texture = love.graphics.newImage('graphics/guy.png')

    -- generates quads from the png
    self.frames = generateQuads(self.texture, 32, 40)

    -- defines the state of the player
    self.state = 'idle'

    -- defines the directions the player is facing
    self.direction = 'right'

    -- holds the current frame of animation
    self.currentFrame = nil

    -- ensures the dead/portal animation lasts a while
    self.deadTime = 0
    self.pTime = 0

    -- table for sound effects
    self.sounds = {
        ['jump'] = love.audio.newSource('sounds/jump.wav', 'static'),
        ['hit'] = love.audio.newSource('sounds/hit.wav', 'static'),
        ['die'] = love.audio.newSource('sounds/die.wav', 'static')
    }

    -- table to hold different animations
    self.animations = {
        ['idle'] = Animation {
            texture = self.texture,
            frames = {
                self.frames[1],self.frames[9]
            },
            interval = 1
        },
        ['walking'] = Animation {
            texture = self.texture,
            frames = {
                self.frames[2], self.frames[3], self.frames[4]
            },
            interval = 0.15
        },
        ['jumping'] = Animation {
            texture = self.texture,
            frames = {
                self.frames[5]
            },
            interval = 1
        },
        ['dead'] = Animation {
            texture = self.texture,
            frames = {
                self.frames[6]
            },
            interval = 1
        },
        ['Bportal'] = Animation {
            texture = self.texture,
            frames = {
                self.frames[7]
            },
            interval = 1
        },
        ['Rportal'] = Animation {
            texture = self.texture,
            frames = {
                self.frames[8]
            },
            interval = 1
        }
    }
    -- set default animation
    self.animation = self.animations['idle']
    -- creates table of behaviors or states
    -- takes keyboard input to move character and animate
    self.behaviors = {
        ['idle'] = function(dt)
            -- player movement
            if love.keyboard.wasPressed('space') then
                self.dy = -JUMP_VELOCITY
                self.state = 'jumping'
                self.animation = self.animations['jumping']
                self.sounds['jump']:play()
            elseif love.keyboard.isDown('left') then
                self.dx = -MOVE_SPEED
                self.state = 'walking'
                self.animation = self.animations['walking']
                self.direction = 'left'
            elseif love.keyboard.isDown('right') then
                self.dx = MOVE_SPEED
                self.state = 'walking'
                self.animation = self.animations['walking']
                self.direction = 'right'
            else
                self.dx = 0
            end
        end,
        ['walking'] = function(dt)
            -- player movement
            -- if no movement we switch back to idle state
            if love.keyboard.wasPressed('space') then
                self.dy = -JUMP_VELOCITY
                self.state = 'jumping'
                self.animation = self.animations['jumping']
                self.sounds['jump']:play()
            elseif love.keyboard.isDown('left') then
                self.dx = -MOVE_SPEED
                self.direction = 'left'
            elseif love.keyboard.isDown('right') then
                self.dx =  MOVE_SPEED
                self.direction = 'right'
            else
                self.dx = 0
                self.state = 'idle'
                self.animation = self.animations['idle']
            end

            -- check for collisions moving left and right
            self:checkRightCollision()
            self:checkLeftCollision()

            -- check if there's a tile directly beneath us
            if not self.map:collides(self.map:tileAt(self.x, self.y + self.height)) and
                not self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then
                
                -- if so, reset velocity and position and change state
                self.state = 'jumping'
                self.animation = self.animations['jumping']
            end
        end,
        ['jumping'] = function(dt)
            
            if love.keyboard.isDown('left') then
                self.direction = 'left'
                self.dx = -MOVE_SPEED
            elseif love.keyboard.isDown('right') then
                self.direction = 'right'
                self.dx = MOVE_SPEED
            end

            self.dy = self.dy + GRAVITY

            -- check if there's a tile directly beneath us
            if self.map:collides(self.map:tileAt(self.x, self.y + self.height)) or
                self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then
                
                -- if so, reset velocity and position and change state
                self.dy = 0
                self.state = 'idle'
                self.animation = self.animations['idle']
                self.y = (self.map:tileAt(self.x, self.y + self.height).y - 1) * self.map.tileHeight - self.height
            end

            -- check for collisions moving left and right
            self:checkRightCollision()
            self:checkLeftCollision()
        end,
        ['dead'] = function(dt)
            -- if the player has died on a spike
            self.animation = self.animations['dead']
            self.dx = 0
            self.dy = 0
            -- timer for the amount of time dead before respawning
            self.deadTime = self.deadTime + 1
        end,
        ['portal'] = function(dt)
            -- changes the colour of the player when entering the portal
            -- based on the colour of the runes
            if RUNE_ACTIVATE == 10 then
                self.animation = self.animations['Bportal']
            else
                self.animation = self.animations['Rportal']
            end
            self.dx = 0
            self.dy = 0

            self.pTime = self.pTime + 1
        end
    }
end

-- updates character model
function Player:update(dt)

    self.animation:update(dt)
    self.behaviors[self.state](dt)
    self.currentFrame = self.animation:getCurrentFrame()

    -- apply velocity
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
    
    -- if we are jumping and collide with a block above us
    if self.dy < 0 then
        if self.map:collides(self.map:tileAt(self.x, self.y)) or
            self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y)) then
            -- reset y velocity
            self.dy = 0

            --plays hit sound
            self.sounds['hit']:play()

            -- activate rune block
            if self.map:tileAt(self.x, self.y).id == RUNE_DEAD then
                self.map:setTile(math.floor(self.x / self.map.tileWidth) + 1,
                    math.floor(self.y / self.map.tileHeight) + 1, RUNE_ACTIVATE)
                self.map.active_runes = self.map.active_runes + 1
            end
            if self.map:tileAt(self.x + self.width - 1, self.y).id == RUNE_DEAD then
                self.map:setTile(math.floor((self.x + self.width - 1) / self.map.tileWidth) + 1,
                    math.floor(self.y / self.map.tileHeight) + 1, RUNE_ACTIVATE)
                self.map.active_runes = self.map.active_runes + 1
            end
        end
    end

    -- checks if player has colided with a spike or a portal
    self:spikeCollision()
    self:portalCollision()

    -- if player enters the caves then reduce the gravity and the jump velocity
    if self.y > self.map.mapPixelHeight / 3 then
        JUMP_VELOCITY = 350
        GRAVITY = 15
    else
        JUMP_VELOCITY = 700
        GRAVITY = 30
    end
end

-- checks two tiles to our left to see if a collision occurred
function Player:checkLeftCollision()

    -- ensures the player cant leave the left screen boundary
    if self.x <= 0 then
        self.dx = 0
        self.x = 0
    end
    -- if we are moving left
    if self.dx < 0 then
        -- check if there's a tile to the left of player
        if self.map:collides(self.map:tileAt(self.x - 1, self.y)) or
            self.map:collides(self.map:tileAt(self.x - 1, self.y + self.height - 1)) then
            
            -- if so, reset velocity and position and change state
            self.dx = 0
            self.x = self.map:tileAt(self.x - 1, self.y).x * self.map.tileWidth
        end
    end
end

-- checks two tiles to our right to see if a collision occurred
function Player:checkRightCollision()

    -- ensures the player can't leave the right screen boundary
    if self.x >= self.map.mapPixelWidth - (self.width * 2) then
        self.dx = 0
        self.x = self.map.mapPixelWidth - (self.width * 2)
    end
    -- if we are moving right
    if self.dx > 0 then
        -- check if there's a tile to the right of player
        if self.map:collides(self.map:tileAt(self.x + self.width, self.y)) or
            self.map:collides(self.map:tileAt(self.x + self.width, self.y + self.height - 1)) then
            
            -- if so, reset velocity and position and change state
            self.dx = 0
            self.x = (self.map:tileAt(self.x + self.width, self.y).x - 1) * self.map.tileWidth - self.width
        end
    end
end

-- checks whether player has collided with a spike
function Player:spikeCollision()
    -- if player has entered portal bounds
    if self.map:tileAt(self.x - 1, self.y + self.height - 1).id == SPIKE or self.map:tileAt(self.x + self.width - 1, self.y + self.height - 1).id == SPIKE or
    self.map:tileAt(self.x - 1, self.y + self.height - 1).id == USED_SPIKE or self.map:tileAt(self.x + self.width - 1, self.y + self.height - 1).id == USED_SPIKE then
        --sets state to dead and ensures the animation lasts a half second
        self.state = 'dead'

        -- updates spike to a "used spike"
        if self.map:tileAt(self.x - 1, self.y + self.height - 1).id == SPIKE then
            self.map:setTile(math.floor((self.x - 1 )/ self.map.tileWidth) + 1,
                    math.floor((self.y + self.height - 1) / self.map.tileHeight) + 1, USED_SPIKE)
        end
        if self.map:tileAt(self.x + self.width - 1, self.y + self.height - 1).id == SPIKE then
            self.map:setTile(math.floor((self.x + self.width - 1) / self.map.tileWidth) + 1,
                    math.floor((self.y + self.height - 1) / self.map.tileHeight) + 1, USED_SPIKE)
        end

        -- plays the death sound once
        local played = false
        if played == false then
            self.sounds['die']:play()
            played = true
        end

        -- makes sure that the dead state lasts a while
        if self.deadTime >= 50 then
            -- defines the starting position of the player
            played = false
            self.x = map.tileWidth * 10
            self.y = map.tileHeight * (map.mapHeight / 3 - 1) - self.height
            self.deadTime = 0
            self.state = 'idle'
        end
    end
end

-- checks whether player has collided with a portal
function Player:portalCollision()
    -- if player has entered blue or red portal bounds
    if self.map:tileAt(self.x + self.width, self.y).id == 26 or self.map:tileAt(self.x - 1, self.y).id == 26 or 
    self.map:tileAt(self.x - 1, self.y + self.height - 1).id == 26 or self.map:tileAt(self.x + self.width, self.y + self.height - 1).id == 26 or
    self.map:tileAt(self.x + self.width, self.y).id == 29 or self.map:tileAt(self.x - 1, self.y).id == 29 or 
    self.map:tileAt(self.x - 1, self.y + self.height - 1).id == 29 or self.map:tileAt(self.x + self.width, self.y + self.height - 1).id == 29 then
        --sets state to dead and ensures the animation lasts a half second
        self.state = 'portal'
        if self.pTime >= 50 then
            self.map:procGen()
            self.pTime = 0
            self.state = 'idle'
        end
    end
end

-- renders the player
function Player:render()
    -- scale factor
    local scaleX

    -- if the character need to face the opposite direction scale it by -1 which flips it
    if self.direction == 'right' then
        scaleX = 1
    elseif self.direction == 'left' then
        scaleX = -1
    end

    -- renders character model
    love.graphics.draw(self.texture, self.currentFrame, math.floor(self.x + self.xOffset),
        math.floor(self.y + self.yOffset), 0, scaleX, 1, self.xOffset, self.yOffset)
end