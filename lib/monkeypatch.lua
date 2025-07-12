-- Monkey patches the LÖVE framework to work with the launcher

local utils = require("lib.utils")

-- love.graphics

local prevSetCanvas = love.graphics.setCanvas
function love.graphics.setCanvas(canvas, mipmap)
    if mipmap then return prevSetCanvas(canvas, mipmap) end
    if canvas then return prevSetCanvas(canvas) end

    -- TODO: set to wrapper canvas if there is an active game
    return prevSetCanvas() -- temporary
end

-- love.window
-- This deals with the fact that there is no real window system
-- A game's "window" is just the entire screen,
-- so window manipulation functions should not do any of their usual behavior

function love.window.close()
    -- TODO: return to the launcher screen, but keep the game running
    -- This error is temporary
    error("Closing the window is not supported by Foxglove!", 2)
end

love.window.maximize = utils.dummyFunc

-- Minimizing is the same thing as closing on this console
love.window.minimize = love.window.close

-- Game is always fullscreen
function love.window.setFullscreen(fullscreen, fstype)
    -- TODO: different behavior depending on values of fullscreen and fstype?
    return fullscreen
end

-- TODO: save whatever dimensions were specified and scale the game using that

local prevSetMode = love.window.setMode
function love.window.setMode(width, height, settings)
    if type(settings) == "table" then
        settings.fullscreen = nil
        settings.minwidth = nil
        settings.minheight = nil
    end
    prevSetMode(utils.screenWidth, utils.screenHeight, settings)
end

local prevUpdateMode = love.window.updateMode
function love.window.updateMode(width, height, settings)
    if type(settings) == "table" then
        settings.fullscreen = nil
        settings.minwidth = nil
        settings.minheight = nil
    end
    prevUpdateMode(utils.screenWidth, utils.screenHeight, settings)
end

-- TODO: restrict access games have to os functions, such as os.exit()
--       os.exit() should quit the game if a game is running instead
