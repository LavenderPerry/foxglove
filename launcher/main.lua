-- LÖVE functions

-- TODO: the things changed via monkeypatching should be changed in the LÖVE fork instead
--require("lib.monkeypatch")

local launcher = require("lib.launcher")
local drawing = require("lib.drawing")

local normalCallbacks

function love.load(_)
    love.mouse.setVisible(false)
    love.graphics.setDefaultFilter("nearest")
    launcher.setup()
end

function love.draw()
    drawing:setup()

    -- TODO: handling for multiple screens
    launcher.draw()
end

love.keypressed = launcher.keypressed
