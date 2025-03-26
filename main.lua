-- LÖVE functions

local foxgloveGame = require("foxgloveGame")
local ffi = require("ffi")

local gameDir = "Games"
local games = {}
local selectedGame = 1

local identity = love.filesystem.getIdentity()
local saveDirectory = love.filesystem.getSaveDirectory()
local source = love.filesystem.getSource()

local defaultKeypressed = love.keypressed

function love.load()
    love.filesystem.createDirectory(gameDir)
    local prevConf = love.conf

    -- Get the list of games
    for _, filename in ipairs(love.filesystem.getDirectoryItems(gameDir)) do
        -- Create the default game
        local game = foxgloveGame:new({
            title = filename,
            filepath = gameDir .. "/" .. filename
        })

        -- Get the rest of the config
        love.conf = nil
        if game:setup("conf.lua") then
            pcall(love.conf, game)
        end
        game:unset()

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
        if game:setup("main.lua") then
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
