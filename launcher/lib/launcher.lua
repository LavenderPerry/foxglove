-- Main launcher menu

local drawing = require("lib.drawing")
local Game = require("lib.game")

local gameSize = 128
local gameX = drawing.marginSize
local gameY = (drawing.screenHeight - gameSize) / 2
local gamesPerScreen = 4
local games
local gamesCanvas

local selectGap = drawing.gapSize / 2
local selectY = gameY - selectGap
local selectSize = gameSize + drawing.gapSize
local selectIdx = 1

local settingsIcon = drawing.loadImage("settings.png")
local settingsWidth, settingsHeight = settingsIcon:getDimensions()
local settingsY = drawing.marginSize + selectGap
local settingsX = drawing.screenWidth - settingsY - settingsWidth

local selectedSettings = true
local selectedGame = 1

local launcher = {}

--- Gets and stores the games, draws them to a canvas
--- Must be called before launcher:draw()
function launcher:setup()
    games = love.filesystem.getDirectoryItems(Game.dir)
    if #games == 0 then return end

    selectedSettings = false
    gamesCanvas = love.graphics.newCanvas(
        #games * selectSize,
        gameSize
    )
    love.graphics.setCanvas(gamesCanvas)
    for i, gameName in ipairs(games) do
        local game = Game:new(gameName)
        games[i] = game
        love.graphics.draw(
            game.launcherIcon,
            selectSize * (i - 1), 0,
            0,
            gameSize / game.launcherIcon:getWidth(),
            gameSize / game.launcherIcon:getHeight()
        )
    end
    love.graphics.setCanvas()
end

--- Draw callback
function launcher:draw()
    drawing:setup()

    -- TODO: more icons like this
    love.graphics.draw(settingsIcon, settingsX, settingsY)

    -- Draw the games (or indicate no games)
    if #games > 0 then
        love.graphics.draw(gamesCanvas, gameX, gameY)
    else
        local text = "No games"
        love.graphics.print(
            text,
            (drawing.screenWidth - drawing.font:getWidth(text)) / 2,
            (drawing.screenHeight - drawing.font:getHeight()) / 2
        )
    end

    -- Draw the selection indicator
    love.graphics.setColor(drawing.color.accent)
    if selectedSettings then
        love.graphics.rectangle(
            "line",
            settingsX - selectGap, settingsY - selectGap,
            settingsWidth + drawing.gapSize, settingsHeight + drawing.gapSize
        )
    else
        local offset = drawing.marginSize - selectGap
        local selectX = offset + selectSize * (selectIdx - 1)
        love.graphics.rectangle(
            "line",
            selectX, selectY,
            selectSize, selectSize
        )
        love.graphics.printf(
            games[selectedGame].title,
            selectX, gameY + selectSize,
            selectSize, "center"
        )
    end
end

--- Key pressed callback
--- @param key love.KeyConstant Character of the pressed key
function launcher:keypressed(key)
    if selectedSettings then
        if key == "space" then
            -- TODO: open settings
        else
            selectedSettings = false
        end
        return
    end

    if key == "up" or key == "down" then -- Select settings
        selectedSettings = true
        return
    end

    if key == "right" then -- Select next game
        if selectedGame < #games then
            selectedGame = selectedGame + 1
            if selectIdx < gamesPerScreen then
                selectIdx = selectIdx + 1
            else
                gameX = gameX - selectSize
            end
        end
        return
    end

    if key == "left" then -- Select previous game
        if selectedGame > 1 then
            selectedGame = selectedGame - 1
            if selectIdx > 1 then
                selectIdx = selectIdx - 1
            else
                gameX = gameX + selectSize
            end
        end
        return
    end

    if key == "space" then -- Launch the game (handled by main.lua)
        return games[selectedGame]
    end
end

return launcher
