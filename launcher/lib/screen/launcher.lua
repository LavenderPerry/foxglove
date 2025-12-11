-- Main launcher screen

local drawing = require("lib.drawing")
local screen = require("lib.screen")
local Game = require("lib.game")

local gameSize = 128
local gameX = drawing.marginSize
local gameY = (drawing.screenHeight - gameSize) / 2
local gamesPerScreen = 4
local games
local gamesCanvas

local selectY = gameY - drawing.selectGap
local selectSize = gameSize + drawing.gapSize
local selectIdx = 1

local onlineIcon = drawing.loadImage("online.png")
local onlineWidth, onlineHeight = onlineIcon:getDimensions()
local onlineY = drawing.marginSize + drawing.selectGap
local onlineX = drawing.screenWidth - onlineY - onlineWidth

local selectedOnline = true
local selectedGame = 1

local launcher = {}

--- Gets and stores the games, draws them to a canvas
--- Must be called before launcher.draw()
function launcher.setup()
    games = love.filesystem.getDirectoryItems(Game.dir)
    if #games == 0 then return end

    selectedOnline = false
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

--- Returns the selected game
function launcher.selectedGame()
    return games[selectIdx]
end

--- Draw callback
function launcher.draw()
    -- TODO: more icons like this
    love.graphics.draw(onlineIcon, onlineX, onlineY)

    -- Draw the games (or indicate no games)
    if #games > 0 then
        love.graphics.draw(gamesCanvas, gameX, gameY)
    else
        drawing.printCenter("No games")
    end

    -- Draw the selection indicator
    love.graphics.setColor(drawing.color.accent)
    if selectedOnline then
        love.graphics.rectangle(
            "line",
            onlineX - drawing.selectGap, onlineY - drawing.selectGap,
            onlineWidth + drawing.gapSize, onlineHeight + drawing.gapSize
        )
    else
        local offset = drawing.marginSize - drawing.selectGap
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
    love.graphics.setColor(drawing.color.foreground)
end

--- Key pressed callback
--- @param key love.KeyConstant Character of the pressed key
function launcher.keypressed(key)
    if selectedOnline then
        if key == "return" then
            screen:set("online")
        else
            selectedOnline = false
        end
        return
    end

    if key == "up" or key == "down" then -- Select online
        selectedOnline = true
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

    if key == "return" then -- Launch the game
        games[selectedGame]:launch()
    end
end

return launcher
