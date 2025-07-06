-- Configuration

local utils = require("lib.utils")

function love.conf(t)
    t.title = "Foxglove"
    t.identity = t.title

    t.window.width = utils.screenWidth
    t.window.height = utils.screenHeight
end
