-- LÖVE functions

local Callbacks = require("lib.callbacks")
local Launcher = require("lib.launcher")

local normalCallbacks

function love.load(_)
    normalCallbacks = Callbacks:getCurrent()
    Launcher:getGames()
end

function love.draw()
    Launcher:draw()
end

function love.keypressed(...)
    Launcher:keypressed(...)

    -- Keypress could have triggered launcher to launch a game
    local game = Launcher.launchedGame
    if game ~= nil then
        Callbacks.default:apply()
        if not game:setup("main.lua") then
            -- TODO: handle error
            normalCallbacks:apply()
            return
        end

        if game.window.width and game.window.height then
            love.window.setMode(game.window.width, game.window.height)
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
