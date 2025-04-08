-- LÖVE functions

local Callbacks = require("lib.callbacks")
local Launcher = require("lib.launcher")

-- All canvas stuff is for testing only
local canvas = love.graphics.newCanvas(320, 240)

local normalCallbacks

function love.load(_)
    love.mouse.setVisible(false)
    love.graphics.setDefaultFilter("nearest")

    normalCallbacks = Callbacks:getCurrent()
    Launcher:getGames()
end

function love.draw()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    if width == 1920 and height == 1080 then
        love.graphics.setCanvas(canvas)
        love.graphics.clear()

        Launcher:draw()

        love.graphics.setCanvas()
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(canvas, 240, 0, 0, 4.5, 4.5)
    else
        Launcher:draw()
    end
end

function love.keypressed(...)
    Launcher:keypressed(...)

    -- Keypress could have triggered launcher to launch a game
    local game = Launcher.launchedGame
    if game ~= nil then
        love.graphics.reset()
        Callbacks.default:apply()

        if not game:setup("main.lua") then
            -- TODO: handle error
            normalCallbacks:apply()
            return
        end

        -- Run the game's load function, with empty arguments list
        love.load({})

        -- Wrap love.quit to return to the launcher
        local gameQuit = love.quit
        function love.quit()
            if not (gameQuit and gameQuit()) then
                love.audio.stop() -- Some games don't stop audio themselves
                game:unset()
                normalCallbacks:apply()
                Launcher.launchedGame = nil
            end

            return true
        end
    end
end
