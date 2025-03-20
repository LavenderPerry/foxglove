-- LÖVE functions

local conf = require("conf")
local utils = require("foxglove.utils")

local gameDir = "Games"
local games = {}
local gameNamesDisplay = "No games found"

function love.load()
    love.filesystem.createDirectory(gameDir)

    -- Get list of games and game names
    local prevConf = love.conf
    local gameNames = {}
    for _, filename in ipairs(love.filesystem.getDirectoryItems(gameDir)) do
        -- Create the default info/config table
        local gameInfo = utils.tableMerge({}, conf, { title = filename })

        -- Mount the game data
        local filepath = gameDir .. "/" .. filename
        local mountpath = filename .. "-gamedata"
        local success = love.filesystem.mount(filepath, mountpath)

        if success then
            -- Get game config
            love.conf = nil
            local filefunc, err = love.filesystem.load(mountpath .. "/conf.lua")
            if not err then
                -- Add game to require paths,
                -- in case the game's conf.lua tries to require stuff
                local prevReq, prevCReq = utils.prependToRequirePaths(mountpath)

                -- The file defines love.conf, which then mutates gameInfo
                if pcall(filefunc) then
                    pcall(love.conf, gameInfo)
                end

                -- Reset require paths
                love.filesystem.setRequirePath(prevReq)
                love.filesystem.setCRequirePath(prevCReq)
            end

            gameInfo.path = { file = filepath, mounted = mountpath }
            table.insert(games, gameInfo)
            table.insert(gameNames, gameInfo.title)
        end
    end

    if #gameNames > 0 then
        gameNamesDisplay = table.concat(gameNames, "\n")
    end

    love.conf = prevConf
end

-- TODO: actually good UI
function love.draw()
    -- Print each game name
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
        gameNamesDisplay,
        0, 20,
        conf.window.width,
        "center"
    )
end

-- TODO: if quit in a game, call the game's love.quit and return to the launcher
function love.quit()
    -- Unmount the mounted games
    for _, game in ipairs(games) do
        love.filesystem.unmount(game.path.file)
    end
end
