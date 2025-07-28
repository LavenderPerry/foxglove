-- LÖVE functions

require("lib.monkeypatch")

local Callbacks = require("lib.callbacks")
local Launcher = require("lib.launcher")
local drawing = require("lib.drawing")

local normalCallbacks

function love.load(_)
    love.mouse.setVisible(false)
    love.graphics.setDefaultFilter("nearest")

    normalCallbacks = Callbacks:getCurrent()
    Launcher:setup()
end

function love.draw()
    drawing:setup()

    -- TODO: handling for multiple screens
    Launcher:draw()
end

function love.keypressed(...)
    -- Keypress could have triggered launcher to launch a game
    local game = Launcher:keypressed(...)
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
