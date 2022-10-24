
--[[
    Author : Kyler Witvoet

    Final Project for CS50 2020

    Seperates the inputted image (atlas) into quads/tiles of the specified height and width
]]--

function generateQuads(atlas, tilewidth, tileheight)
    -- returns the width and height of the inputted image
    local spriteWidth = atlas:getWidth() / tilewidth
    local spriteHeight = atlas:getHeight() / tileheight

    -- creates a variable to count how many quads there are
    local spritecounter = 1

    -- creates a table to hold the quads
    local quads = {}
    
    -- iterates through the image a grabs tiles/quads based on the specified width and height
    for y = 0, spriteHeight - 1 do
        for x = 0, spriteWidth - 1 do

            quads[spritecounter] = 
                love.graphics.newQuad(x * tilewidth, y * tileheight, tilewidth, 
                tileheight, atlas:getDimensions())
            spritecounter = spritecounter + 1

        end
    end

    -- returns a table of quads
    return quads
end