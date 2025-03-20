-- Misc. utilities used in this project

local utils = {}

-- Merges multiple tables together, taking subtables into account.
-- Subtables are copied to a different location in memory.
--
-- If any of the tables passed have duplicate keys
-- values from tables towards the end of the parameter list overwrite
-- values from tables towards the beginning of the parameter list.
-- The only exception is if both keys are tables, in which case
-- the final result for that key is this function applied to both the keys.
--
-- Be aware that this function modifies t1.
-- If you don't want t1 to be modified, pass a new blank table as t1.
--
-- @param t1 The first table to merge all other tables into
-- @param t2 A table to be merged
-- @param ... Other tables to be merged
-- @return t1 after merging all other tables into it
function utils.tableMerge(t1, t2, ...)
    if t2 == nil then
        return t1
    end

    for k, v in pairs(t2) do
        if type(v) == "table" then
            t1[k] = utils.tableMerge(type(t1[k]) == "table" and t1[k] or {}, v)
        else
            t1[k] = v
        end
    end

    return utils.tableMerge(t1, ...)
end

-- Prepend the given directory to the require paths
-- @param dir The directory to add
-- @return The previous require path and C require path, in that order
function utils.prependToRequirePaths(dir)
    local prevReq = love.filesystem.getRequirePath()
    local prevCReq = love.filesystem.getCRequirePath()

    love.filesystem.setRequirePath(
        dir .. "/?.lua;" ..
        dir .. "/?/init.lua;" ..
        prevReq
    )
    love.filesystem.setCRequirePath(dir .. "/??;" .. prevCReq)

    return prevReq, prevCReq
end

return utils
