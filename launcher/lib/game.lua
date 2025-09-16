-- Class for handling games

local path = require("lib.path")
local drawing = require("lib.drawing")

--- @class Game
--- @field title string
--- @field filename string
local Game = {
    dir = "Games",
    iconDir = "Icons",
    modDir = "Mods",
    launcherIcon = drawing.loadImage("gameIconFallback.png") -- Default
}

--- Creates a new game
---
--- @param filename string The filename of the game
--- @return Game
function Game:new(filename)
    local res = {
        title = filename:match("^([^%.]+)"),
        filename = filename
    }
    res.active_mods = path.join(self.modDir, self.title, "active")

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
    local mods = love.filesystem.getDirectoryItems(self.active_mods)
    for i, mod in ipairs(mods) do
        mods[i] = path.full(mod_dir, mod)
    end

    love.event.restart({
        foxglove_launch_game = path.full(self.dir, self.filename),
        foxglove_mods = mods,
        foxglove_replace_restartval = true
    })
end

return Game
