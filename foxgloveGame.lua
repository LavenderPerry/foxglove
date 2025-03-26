-- Class for handling games

local ffi = require("ffi")

-- Standard values set for the launcher
local identity = love.filesystem.getIdentity()
local saveDirectory = love.filesystem.getSaveDirectory()
local source = love.filesystem.getSource()

-- Add PhysicsFS function to add to the search path for setGame
ffi.cdef("int PHYSFS_addToSearchPath(const char *newDir, int appendToPath);")

local foxgloveGame = {}

-- Creates a new game
-- Must specify t.filepath and t.title
--
-- @param t table The table to use
-- @return foxgloveGame
function foxgloveGame:new(t)
    if type(t) ~= "table" or not t.filepath or not t.title then
        error("Invalid argument. Need table with 'filepath' and 'title' set.")
        return
    end

    setmetatable(t, self)
    self.__index = self
    return t
end

-- Adds the game to the search path, sets the identity to the game,
-- and runs the specified file from the game
--
-- @param file string The file to run
-- @return boolean If setting up the game was successful or not
function foxgloveGame:setup(file)
    local gameFullPath = saveDirectory .. "/" .. self.filepath

    love.filesystem.setIdentity(self.identity or self.title)

    -- Failed setup if adding the game to search path failed
    if not ffi.C.PHYSFS_addToSearchPath(gameFullPath, 0) then
        return false
    end

    -- Failed setup if the specified game does not contain the specified file,
    -- and the file is instead found in this launcher's source
    --
    -- If the file does not exist anywhere,
    -- that will be caught by love.filesystem.load
    if love.filesystem.getRealDirectory(file) == source then
        return false
    end

    -- Failed setup if the file otherwise failed to load or run
    local chunk, errormsg = love.filesystem.load(file)
    if errormsg or not pcall(chunk) then
        return false
    end

    return true
end

-- Removes the game from the search path and resets the identity
-- Should be called after foxgloveGame:setup when done running the game
function foxgloveGame:unset()
    love.filesystem.setIdentity(identity)
    -- Removing from the search path is simply an unmount, no need for FFI here
    love.filesystem.unmount(self.filepath)
end

return foxgloveGame
