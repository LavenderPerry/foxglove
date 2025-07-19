-- Configuration

local drawing = require("lib.drawing")

function love.conf(t)
    t.title = "Foxglove"
    t.identity = t.title

    t.window.width = drawing.screenWidth
    t.window.height = drawing.screenHeight
end
