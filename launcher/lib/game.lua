-- Class for handling games

local path = require("lib.path")
local drawing = require("lib.drawing")

--- @class Game
--- @field title string
--- @field filepath string
--- @field fullpath string
--- @field identity string | nil
local Game = {
    dir = "Games",
    iconDir = "Icons",
    launcherIcon = drawing.loadImage("gameIconFallback.png") -- Default
}

--- Creates a new game
---
--- @param filename string The filename of the game
--- @return Game
function Game:new(filename)
    local gamepath = path.join(self.dir, filename)

    local res = {
        title = filename,
        filepath = gamepath,
        fullpath = path.join(path.saveDirectory, gamepath),
    }

    setmetatable(res, self)
    self.__index = self

    -- Get the icon if it exists
    local iconPath = path.join(self.iconDir, res.title .. ".png")
    if path.exists(iconPath) then
        res.launcherIcon = love.graphics.newImage(iconPath)
    end

    return res
end

--- Launches the game by performing a restart with specific parameters
--- This only works on Foxglove's specific fork of LÖVE
function Game:launch()
    love.event.restart({
        foxglove_launch_game = self.fullpath,
        foxglove_replace_restartval = true
    })
end

return Game
