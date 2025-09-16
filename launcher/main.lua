-- LÖVE functions

local drawing = require("lib.drawing")
local launcher = require("lib.launcher")
local installer = require("lib.installer")

local droppedFile
local droppedPath

function love.load(_)
    love.mouse.setVisible(false)
    love.graphics.setDefaultFilter("nearest")
    launcher.setup()
end

function love.draw()
    drawing:setup()
    launcher.draw()
    installer.draw()
end

function love.filedropped(file)
    installer.init(launcher.selectedGame(), file:getFilename(), file)
end

function love.directorydropped(dir)
    installer.init(launcher.selectedGame(), dir)
end

function love.keypressed(key)
    return installer.keypressed(key) and launcher.keypressed(key)
end
