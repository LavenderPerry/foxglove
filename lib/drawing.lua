-- Drawing info and functions

local drawing = {
    color = { -- TODO: make these colors configurable
        foreground = { 1, 1, 1 },
        background = { 0, 0, 0 },
        accent = { 1, 0, 1}
    },

    font = love.graphics.newFont("vendored/fonts/m6x11plus.ttf", 18, "mono"),
    imagePath = "assets/images/"
}

--- Sets the color and font for drawing
function drawing.setup()
    love.graphics.setColor(drawing.color.foreground)
    love.graphics.setFont(drawing.font)
end

--- Loads an image from the image path
--- @param filename string The filename of the image
--- @return love.Image
function drawing.loadImage(filename)
    return love.graphics.newImage(drawing.imagePath .. filename)
end

return drawing
