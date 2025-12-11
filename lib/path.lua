-- Standard paths and functions to manipulate paths

local path = {
    identity = love.filesystem.getIdentity(),
    saveDirectory = love.filesystem.getSaveDirectory(),
    source = love.filesystem.getSource()
}

--- Joins strings together to create a path
--- @param ... string The components of the path
--- @return string # The resulting path
function path.join(...)
    return table.concat({ ... }, "/")
end

--- Constructs a path within the save directory
--- @param ... string The components of the path
--- @return string # The resulting path
function path.full(...)
    return path.join(path.saveDirectory, ...)
end

--- Checks if a file/directory/etc exists at the given path
--- This function is kind of useless and may be removed soon
--- @param p string The path to check
--- @return boolean # If the path exists
function path.exists(p)
    return love.filesystem.getInfo(p) ~= nil
end

return path
