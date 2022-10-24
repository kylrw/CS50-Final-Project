--[[
    Author : Kyler Witvoet

    Final Project for CS50 2020

    Animation Class
]]--

Animation = Class{}

function Animation:init(params)
    self.texture = params.texture
    -- frames for this animation
    self.frames = params.frames
    -- time in seconds each frame takes
    self.interval = params.interval or 0.05
    -- stores the amount of time that has passed
    self.timer = 0
    -- the current frame of animation
    self.currentFrame = 1
end

-- returns the current frame of the animation
function Animation:getCurrentFrame()
    return self.frames[self.currentFrame]
end

-- restarts the animation
function Animation:restart()
    self.timer = 0
    self.currentFrame = 1
end

function Animation:update(dt)
    -- adds delta time to the timer
    self.timer = self.timer + dt

    -- the number of frames in the table is only one do nothing
    while self.timer > self.interval do
        -- "restarts" the timer based on the current interval
        self.timer = self.timer - self.interval
        -- current frame equals the modulus of the current frame + 1 divided by the amount of frames + 1
        self.currentFrame = (self.currentFrame + 1) % (#self.frames + 1)
        -- there is no frame for 0 so set the current frame to 1
        if self.currentFrame == 0 then self.currentFrame = 1 end
    end
end