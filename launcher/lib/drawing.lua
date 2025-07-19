-- Drawing info and functions

local drawing = {
    -- VGA, should fit most games
    -- Can fit nHD within it as well if needed
    screenWidth = 640,
    screenHeight = 480,

    -- UI element sizes
    gapSize = 16,
    marginSize = 40,

    color = { -- TODO: make these colors configurable
        foreground = { 1, 1, 1 },
        background = { 0, 0, 0 },
        accent = { 1, 0, 1}
    },

    fontPath = "vendored/fonts/",
    fontFile = "m6x11plus.ttf",
    fontSize = 18,
    imagePath = "assets/images/"
}

--- Sets the color and font for drawing, loading the font if not loaded yet
function drawing:setup()
    if not self.font then
        self.font = love.graphics.newFont(
            self.fontPath .. self.fontFile,
            self.fontSize,
            "mono"
        )
    end

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
