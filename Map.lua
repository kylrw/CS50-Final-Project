--[[
    Author : Kyler Witvoet

    Final Project for CS50 2020
    
    Contains all the tile data and necessary code for rendering the tile map to the screen.
]]

Map = Class{}

TILE_EMPTY = 1
TILE_SAND = 2
SAND_STONE = 3

-- bush tile
BUSH = 4
-- cloud tiles
CLOUD_LEFT = 5
CLOUD_RIGHT = 6
-- scrap tile
SCRAP = 7
-- cactus/pillar tiles
CACTUS_TOP = 8
CACTUS_BOTTOM = 12
-- rune tiles
RUNE_DEAD = 9
RUNE_ACTIVATE = 10
-- spike tiles
SPIKE = 30
USED_SPIKE = 31
-- spawn portal tile
DEAD_PORTAL = 32
-- cracked sand stone tile
CRACKED_SAND_STONE = 34
-- hanging object tile
HANGER = 35

-- timer for portal animation
local timer = 0
-- whether or not portal animation is going up or down
local portalDown = false
-- whether or not portal is active
local activePortal = false

-- variable to determine the map type
mapType = 1

local SCROLL_SPEED = 62

function Map:init()

    -- grabs the png image containing all the sprites
    self.spritesheet = love.graphics.newImage('graphics/spritesheet.png')

    -- divides the image into quads
    self.sprites = generateQuads(self.spritesheet, 32, 32)

    -- specifies the width and height of each tile in pixels
    self.tileWidth = 32
    self.tileHeight = 32

    -- specifies the width and height of the map
    self.mapWidth = 60
    self.mapHeight = 120

    -- table to hold the tile map
    self.tiles = {}

    -- width and height of the map in pixels
    self.mapPixelWidth = self.mapWidth * self.tileWidth
    self.mapPixelHeight = self.mapHeight * self.tileWidth

    -- camera's location
    self.camX = 0
    self.camY = 0

    -- defines player
    self.player = Player(self)
    self.active_runes = 0
    self.runes = 0

    -- holds the music
    self.music = love.audio.newSource('sounds/music.wav', 'static')
    self.portal_open = love.audio.newSource('sounds/portal_open.wav', 'static')

    -- procedurally generates the tile map
    self:procGen()

    -- begins playing the music
    self.music:setLooping(true)
    self.music:setVolume(0.2)
    self.music:play()
end

-- returns whether or not a given tile is a collidable
function Map:collides(tile)
    -- table of collidable tiles
    local collidables = {
        TILE_SAND, SAND_STONE, CRACKED_SAND_STONE, CACTUS_BOTTOM, CACTUS_TOP, RUNE_DEAD, RUNE_ACTIVATE
    }
    -- iterate and return true if our tile type matches
    for _, v in ipairs(collidables) do
        if tile.id == v then
            return true
        end
    end

    return false
end

-- function to update map related objects
function Map:update(dt)

    -- updates camera bounds
    self.camX = math.max(0,
        math.min(self.player.x - VIRTUAL_WIDTH / 2,
            math.min(self.mapPixelWidth - VIRTUAL_WIDTH - 32, self.player.x)))
    self.camY = math.floor(self.player.y - VIRTUAL_HEIGHT / 2) 
    -- updates player model
    self.player:update(dt)
    -- updates portal animation 
    -- texture depends on if its active or not
    if activePortal == true then
        if RUNE_ACTIVATE == 10 then
            self:updatePortal({16,21,22})
        else
            self:updatePortal({23,24,29})
        end
    else
        self:updatePortal({13,14,15})
    end
end

-- updates the portal animation
function Map:updatePortal(frames)

    timer = timer + 1
    -- gets the current frame of the portal
    local currentFrame = self:getTile(portalX,portalY - 1)
    -- updates after a interval of 30
    if timer > 30 then
        -- resets the timer
        timer = 0
        -- updates to portal based on current frame
        -- and if its going down or up
        if currentFrame == frames[1] then
            self:setTile(portalX,portalY - 1,frames[2])
            self:setTile(portalX,portalY,frames[2] + 4)
            portalDown = false
        elseif currentFrame == frames[2] then
            if portalDown == true then
                self:setTile(portalX,portalY - 1,frames[1])
                self:setTile(portalX,portalY,frames[1] + 4)
            else
                self:setTile(portalX,portalY - 1,frames[3])
                self:setTile(portalX,portalY,frames[3] + 4)
            end
        else 
            self:setTile(portalX,portalY - 1,frames[2])
            self:setTile(portalX,portalY,frames[2] + 4)
            portalDown = true
        end
    end
end

function Map:tileAt(x, y)
    -- returns info on the tile in the specified coords
    return {
        x = math.floor(x / self.tileWidth) + 1,
        y = math.floor(y / self.tileHeight) + 1,
        id = self:getTile(math.floor(x / self.tileWidth) + 1, math.floor(y / self.tileHeight) + 1)
    }

end

-- writes the choosen tile to the tile table
function Map:setTile(x, y, tile_id)
    self.tiles[(y - 1) * self.mapWidth + x] = tile_id
end

-- returns the tile type from the choosen location
function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.mapWidth + x]
end

-- procedurally generates the map
function Map:procGen()
    self.portal_open:play()
    -- fills the map with empty tiles
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            self:setTile(x, y, TILE_EMPTY)
        end
    end
    -- fills the bottom two thirds of the map with sand
    for y = self.mapHeight / 3, self.mapHeight do
        for x = 1, self.mapWidth do
            self:setTile(x, y, TILE_SAND)
        end
    end
    -- randomly generates dunes and valleys
    local x = 1
    while x < self.mapWidth do
        local y = self.mapHeight / 3 - 1
        -- 5% chance to generate a valley 2 - 6 tiles long
        if math.random(20) == 1 then
            for i = 0, math.random(2,6) do
                self:setTile(x + i - 1, y,TILE_EMPTY)
                self:setTile(x + i, y + 1,TILE_EMPTY)
                self:setTile(x + i, y,TILE_EMPTY)
                self:setTile(x + i + 1, y,TILE_EMPTY)
            end
        -- 5% chance to generate a dune 2 - 6 tiles long
        elseif math.random(20) == 1 then
            for i = 0, math.random(2,6) do
                self:setTile(x + i, y,TILE_SAND)
                self:setTile(x + i, y + 1,TILE_SAND)
            end
        end
        x = x + 1

        -- randomly chooses what type of desert the map will be
        if mapType == 0 then
            self.spritesheet = love.graphics.newImage('graphics/spritesheet1.png')
            mapType = 1
        elseif mapType == 1 then
            self.spritesheet = love.graphics.newImage('graphics/spritesheet2.png')
            mapType = 2
        elseif mapType == 2 then
            self.spritesheet = love.graphics.newImage('graphics/spritesheet.png')
            mapType = 0
        end

    end

    -- procedurally generates the ingame objects
    -- ensures that atleast one rune spawns
    self:objGen()
    while self.runes == 0 do
        self:objGen()
    end
    -- procedurally generates the cave system
    self:caveGen()
    -- resets the player position every time the map is reset
    self.player.x = self.tileWidth * 10
    self.player.y = self.tileHeight * (self.mapHeight / 3 - 1) - self.player.height 
    -- adds the broken spawn portal to spawn location
    self:setTile(11,self.mapHeight / 3, TILE_SAND)
    self:setTile(11,self.mapHeight / 3 - 1, DEAD_PORTAL)
    self:setTile(11,self.mapHeight / 3 - 2, TILE_EMPTY)
    self:setTile(11,self.mapHeight / 3 - 3, TILE_EMPTY)
end 

-- procedurally generates the desert objects
function Map:objGen()
    -- keeps track of the amount of runes
    self.runes = 0
    self.active_runes = 0
    -- randomly chooses whether the runes are blue or red
    RUNE_ACTIVATE = math.random(10,11)
    
    -- iterate through every slot in the tile map
    local x = 1
    while x < self.mapWidth do
        -- y is the top level of sand
        for j = 1, self.mapHeight / 2 do
            if self:getTile(x,j) == TILE_SAND and self:getTile(x,j-1) == TILE_EMPTY then
                y = j
            end
        end

        -- 2% chance to generate a cloud
        -- ensures we are 2 tiles away from edge
        if x < self.mapWidth - 2 then
            if math.random(20) == 1 then
                -- chooses a random spawn height
                local cloudStart = math.random(self.mapHeight / 3 - 4)
                -- ensures we dont spawn a cloud on a other cloud
                if self:getTile(x, cloudStart) ~= CLOUD_LEFT or self:getTile(x, cloudStart) ~= CLOUD_RIGHT or
                    self:getTile(x + 1, cloudStart) ~= CLOUD_LEFT or self:getTile(x + 1, cloudStart) ~= CLOUD_RIGHT then

                    self:setTile(x, cloudStart, CLOUD_LEFT)
                    self:setTile(x + 1, cloudStart, CLOUD_RIGHT)
                end
            end
        end
        -- 5% chance to generate 2 tall object (cactus, pillar, tree thing)
        if math.random(20) == 1 then

            self:setTile(x, y - 2, CACTUS_TOP)
            self:setTile(x, y - 1, CACTUS_BOTTOM)
            x = x + 1

        -- 10% chance to generate a  1 tall plant (dead bush, small cactus, flower)
        elseif math.random(10) == 1 then

            self:setTile(x, y - 1, BUSH)
            x = x + 1

        -- 10% chance to spawn a scrap (pebble's, grass, bones)
        elseif math.random(10) == 1 then

            self:setTile(x, y - 1, SCRAP)
            x = x + 1          

        -- else
        elseif math.random(10) ~= 1 then

            -- generates a rune block
            if math.random(20) == 1 then
                self:setTile(x, self.mapHeight / 3 - math.random(4,6), RUNE_DEAD)
                self.runes = self.runes + 1
            end

            -- iterates to next line
            x = x + 1
        end
    end
end

-- procedurally generates the cave sysytem
function Map:caveGen()

    -- generates the enterance to the cave
    exists = false
    x = self.mapWidth / 2
    rand_depth = math.random(6,15)
    -- ensures that a cave does spawn
    while exists == false do
        if math.random(30) == 1 and x < self.mapWidth - rand_depth then
            -- ensures the mouth is not blocked off
            for y = self.mapHeight / 3, self.mapHeight / 3 - 4, -1 do
                for i = -1, 3 do
                    self:setTile(x + i,y,TILE_EMPTY)
                end
            end
            -- generates the stairway into the caves
            for y = self.mapHeight / 3, self.mapHeight / 3 + rand_depth do
                for i = 0, 3 do
                    self:setTile(x+i,y,TILE_EMPTY)
                end
                x = x - 1
                -- remembers the deepest cave coords
                cave_x = x + 3
                cave_y = y + 1
            end
            exists = true
        end
        -- generates a cave enterance in opposite direction
        if math.random(30) == 1 and x < self.mapWidth - rand_depth then
            -- ensures the mouth is not blocked off
            for y = self.mapHeight / 3, self.mapHeight / 3 - 4, -1 do
                for i = -1, 3 do
                    self:setTile(x + i,y,TILE_EMPTY)
                end
            end
            -- generates the stairway into the caves
            for y = self.mapHeight / 3, self.mapHeight / 3 + rand_depth do
                for i = 0, 3 do
                    self:setTile(x+i,y,TILE_EMPTY)
                end
                x = x - 1
                -- remembers the deepest cave coords
                cave_x = x + 3
                cave_y = y + 1
            end
            exists = true
        end
        -- if a cave doesnt spawn we reset x
        if x == self.mapWidth then
            x = self.mapWidth / 2
        end
        x = x + 1
    end

    -- generates more stairs and hallways
    self:hallway(cave_x,cave_y)
    self:stairway(cave_x,cave_y)
    self:hallway(cave_x,cave_y)
    self:stairway(cave_x,cave_y)
    self:hallway(cave_x,cave_y)
    self:stairway(cave_x,cave_y)


    -- generates portal room
    for x = cave_x, cave_x - 3, -1 do
        for y = cave_y, cave_y - 3, -1 do
            self:setTile(x,y,TILE_EMPTY)
        end
    end

    -- adds bricks any where in the caves that is beside an empty block
    for x = 0, self.mapWidth do
        for y = self.mapHeight / 3 + 3, self.mapHeight do
            if self:getTile(x,y) == TILE_SAND then
                if self:getTile(x+1,y) == TILE_EMPTY or self:getTile(x-1,y) == TILE_EMPTY or
                self:getTile(x,y+1) == TILE_EMPTY or self:getTile(x,y-1) == TILE_EMPTY then
                    -- 1 in 3 chance that cracked sand stone will spawn
                    if math.random(2) == 1 then
                        self:setTile(x,y,CRACKED_SAND_STONE)
                    else
                        self:setTile(x,y,SAND_STONE)
                    end
                end
            end
        end
    end

    -- adds bricks any where in the caves that is beside an empty block
    for x = 0, self.mapWidth do
        for y = self.mapHeight / 3 + 3, self.mapHeight do
            if self:getTile(x,y) == SAND_STONE or self:getTile(x,y) == CRACKED_SAND_STONE then
                if self:getTile(x,y+1) == TILE_EMPTY then
                    if math.random(10) == 1 then
                        self:setTile(x,y+1,HANGER)
                    end
                end
                if self:getTile(x,y-1) == TILE_EMPTY then
                    if math.random(10) == 1 then
                        self:setTile(x,y-1,SCRAP)
                    end
                end
            end
        end
    end

    -- ensures the edges of the map arent sand stone
    for y = self.mapHeight / 3, self.mapHeight do
        self:setTile(1,y,TILE_SAND)
        self:setTile(self.mapWidth - 1,y,TILE_SAND)
    end

    -- generates portal
    self:setTile(cave_x - 2, cave_y, 17)
    self:setTile(cave_x - 2, cave_y, 21)
    -- remembers portal coords
    portalX = cave_x - 2
    portalY = cave_y
    -- resets portal activation
    activePortal = false
end

-- generates a hallway
function Map:hallway(x,y) 
    -- ensures that a hallway does spawn
    exists = false
    local spike_count = 0
    while exists == false do 
        -- randomly chooses the length of the hallway
        rand_depth = math.random(8,30)
        -- randomly chooses the direction of the hallway
        if math.random(5) == 1 and cave_x + rand_depth  + 4 < self.mapWidth then
            for x = cave_x, cave_x + rand_depth do
                y = cave_y
                for i = 0, 3 do
                    self:setTile(x,y - i,TILE_EMPTY)
                end     

                -- remembers the deepest cave coord   
                cave_x = x - 2
                -- generates spikes every 4 tiles
                spike_count = spike_count + 1
                if spike_count == 4 then
                    self:setTile(x,y,SPIKE)
                    self:setTile(x,y + 1,SAND_STONE)
                    spike_count = 0
                end
            end
            exists = true
        elseif math.random(5) == 2 and cave_x - rand_depth - 4 > 0 then
            for x = cave_x, cave_x - rand_depth, -1 do
                y = cave_y
                for i = 0, 3 do
                    self:setTile(x,y - i,TILE_EMPTY)
                end

                -- remembers the deepest cave coord
                cave_x = x + 2
                -- generates spikes every 4 tiles
                spike_count = spike_count + 1
                if spike_count == 4 then
                    self:setTile(x,y,SPIKE)
                    self:setTile(x,y + 1,SAND_STONE)
                    spike_count = 0
                end
            end
            exists = true
        end
    end
end

-- generates stairways
function Map:stairway(x,y)

    rand_depth = math.random(6,12)
    -- ensures that a cave does spawn
    if math.random(1) == 1 and x < self.mapWidth - rand_depth - 4 then
        -- ensures stair enterance is clear
        self:setTile(x + 4,cave_y,TILE_EMPTY)

        -- generates the stairway in the caves
        for y = cave_y, cave_y + rand_depth do
            for i = 0, 3 do
                self:setTile(x+i,y,TILE_EMPTY)
            end

            x = x + 1
            cave_x = x - 2
            cave_y = y + 2
        end
    elseif math.random(1) == 0 and x > 0 then

        -- ensures stair enterance is clear
        self:setTile(x -1 ,cave_y,TILE_EMPTY)

        -- generates the stairway in the caves
        for y = cave_y, cave_y + rand_depth do
            for i = 0, 3 do
                self:setTile(x+i,y,TILE_EMPTY)
            end

            x = x - 1
            cave_x = x + 2
            cave_y = y + 2
        end
    end
end

-- renders the map
function Map:render()
    -- renders every tile in the tile map
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            local tile = self:getTile(x, y)
            if tile ~= TILE_EMPTY and tile ~= nil then
                love.graphics.draw(self.spritesheet, self.sprites[tile], 
                    (x - 1) * self.tileWidth, (y - 1) * self.tileHeight)
            end
        end
    end

    -- renders the player
    self.player:render()

    love.graphics.setColor(0, 0, 0, 1)
    -- shows how many runes the player has activated
    if self.active_runes ~= self.runes then
        love.graphics.print('RUNES ' .. tostring(self.runes),8 + self.camX,8 + self.camY - 128)
        love.graphics.print('ACTIVE RUNES ' .. tostring(self.active_runes),8 + self.camX,32 + self.camY - 128)
    else
        love.graphics.print('DONE',8 + self.camX,8 + self.camY - 128)
        if activePortal == false then
            self:setTile(portalX,portalY,24)
            self:setTile(portalX,portalY - 1,20)
        end
        activePortal = true
    end
end