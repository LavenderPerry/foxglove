-- LÖVE functions

local ffi = require("ffi")

local gameDir = "Games"
local games = {}
local selectedGame = 1

local identity = love.filesystem.getIdentity()
local source = love.filesystem.getSource()

local defaultKeypressed = love.keypressed

-- Add PhysicsFS function to add to the search path for launching games
ffi.cdef("int PHYSFS_addToSearchPath(const char *newDir, int appendToPath);")

-- Removes the specified game from the search path and resets the identity
-- Should be called after setupGame with the same game passed to setupGame
--
-- @param game table The game that was setup earlier
local function unsetGame(game)
    love.filesystem.setIdentity(identity)
    -- Removing from the search path is simply an unmount, no need for FFI here
    love.filesystem.unmount(game.filepath)
end

-- Adds the specified game to the search path, sets the identity to the game,
-- and runs the specified file from the game
--
-- If the setup fails, unsetGame will be called for you
--
-- @param game table The game to setup
-- @param file string The file to run
-- @return boolean If the setup was successful
local function setupGame(game, file)
    local gameFullPath =
        love.filesystem.getSaveDirectory() .. "/" .. game.filepath

    love.filesystem.setIdentity(game.identity or game.title)

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
        unsetGame(game)
        return false
    end

    -- Failed setup if loading or running the file otherwise fails
    local filefunc, err = love.filesystem.load(file)
    if err or not pcall(filefunc) then
        unsetGame(game)
        return false
    end

    -- Success
    return true
end

function love.load()
    love.filesystem.createDirectory(gameDir)
    local prevConf = love.conf

    -- Get the list of games
    for _, filename in ipairs(love.filesystem.getDirectoryItems(gameDir)) do
        -- Create the default info/config table
        local game = {
            title = filename,
            filepath = gameDir .. "/" .. filename
        }

        -- Get the rest of the config
        love.conf = nil
        if setupGame(game, "conf.lua") then
            pcall(love.conf, game)
            unsetGame(game)
        end

        -- Finally, add the game to the games list
        table.insert(games, game)
    end

    love.conf = prevConf
end

-- Draws text centered horizontally in the window
--
-- @param text string The text to draw
-- @param y number The y-value to draw at (multiplied by font line height)
local function drawCenteredText(text, y)
    local font = love.graphics.getFont()

    love.graphics.print(
        text,
        (love.graphics.getWidth() - font:getWidth(text)) / 2,
        font:getHeight() * y
    )
end

-- TODO: actually good UI
function love.draw()
    love.graphics.setColor(1, 1, 1)

    -- Handle case when no games
    if #games == 0 then
        drawCenteredText("No games", 2)
        return
    end

    -- Print out all games
    for i, game in ipairs(games) do
        drawCenteredText(game.title, i * 3 - 1)
    end

    -- Rectangle around selected game
    local lineHeight = love.graphics.getFont():getHeight()
    love.graphics.rectangle(
        "line",
        lineHeight, lineHeight * (selectedGame * 3 - 2),
        love.graphics.getWidth() - lineHeight * 2, lineHeight * 3
    )
end

-- For now, this assumes keyboard with arrow key and space controls
-- Change as needed for the actual console
-- Also look into love.gamepadpressed and love.gamepadreleased
function love.keypressed(key)
    if key == "down" then -- Select next game
        selectedGame = selectedGame + 1
        if selectedGame > #games then
            selectedGame = 1
        end
        return
    end

    if key == "up" then -- Select previous game
        selectedGame = selectedGame - 1
        if selectedGame < 1 then
            selectedGame = #games
        end
        return
    end

    if key == "space" then -- Launch selected game
        local game = games[selectedGame]
        -- Run the actual game
        -- TODO: wrap around the game more to allow for better compatability
        if setupGame(game, "main.lua") then
            love.keypressed = defaultKeypressed
            love.load()
        end
        return
    end
end

-- TODO: if quit in a game, call the game's love.quit and return to the launcher
--function love.quit()
--    -- Unmount the mounted games
--    for _, game in ipairs(games) do
--        love.filesystem.unmount(game.path.file)
--    end
--end
