-- Class for handling games

local ffi = require("ffi")
local path = require("lib.path")
local drawing = require("lib.drawing")

-- Add PhysicsFS function to add to the search path for setGame
ffi.cdef("int PHYSFS_addToSearchPath(const char *newDir, int appendToPath);")

--- @class Game
--- @field title string
--- @field filepath string
--- @field fullpath string
--- @field identity string
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
        identity = filename,
        filepath = gamepath,
        fullpath = path.join(path.saveDirectory, gamepath),

        -- Tables that may be modified by love.conf
        -- See https://www.love2d.org/wiki/Config_Files
        audio = {},
        window = {},
        modules = {}
    }

    setmetatable(res, self)
    self.__index = self

    -- Get the game config
    local prevConf = love.conf
    love.conf = nil
    if res:setup("conf.lua") then
        pcall(love.conf, res)
    end

    -- Load the icon while the game is setup (to fallback on configured icon)
    local iconPath = path.join(self.iconDir, filename .. ".png")
    if path.exists(iconPath) then
        res.launcherIcon = love.graphics.newImage(iconPath)
    elseif res.icon ~= nil then
        res.launcherIcon = love.graphics.newImage(res.icon)
    end

    res:unset()
    love.conf = prevConf

    return res
end

--- Adds the game to the search path, sets the identity to the game,
--- and runs the specified file from the game
---
--- @param file string The file to run
--- @return boolean # If setting up the game was successful or not
function Game:setup(file)
    love.filesystem.setIdentity(self.identity or self.title)

    -- Failed setup if adding the game to search path failed
    if not ffi.C.PHYSFS_addToSearchPath(self.fullpath, 0) then
        return false
    end

    -- Failed setup if the specified game does not contain the specified file,
    -- and the file is instead found in this launcher's source
    --
    -- If the file does not exist anywhere,
    -- that will be caught by love.filesystem.load
    if love.filesystem.getRealDirectory(file) == path.source then
        return false
    end

    -- Failed setup if the file otherwise failed to load or run
    local chunk, errormsg = love.filesystem.load(file)
    if errormsg or not pcall(chunk) then
        return false
    end

    return true
end

--- Removes the game from the search path and resets the identity
--- Should be called after Game:setup when done running the game
function Game:unset()
    love.filesystem.setIdentity(path.identity)
    -- Removing from the search path is simply an unmount, no need for FFI here
    love.filesystem.unmount(self.filepath)
end

return Game
