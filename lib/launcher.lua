-- Main launcher menu

local drawing = require("lib.drawing")
local Game = require("lib.launcher.game")

--- @class Launcher
local Launcher = {
    noGames = true, -- Is set to false if Launcher:loadGames() loads any games
    scrollable = false, -- Set to true if Launcher:loadGames() loads > 3 games
    settingsSelected = true,
    gameSelected = 1,

    settingsIcon = drawing.loadImage("settings.png"),
    selectIcon = drawing.loadImage("select.png")
}

--- @package
--- Iierator over each game currently on screen,
--- giving game, index (0-2) and index (total in list)
--- @return function
function Launcher:gamesOnscreen()
    local firstGameIdx = self.gameSelected > 2 and self.gameSelected - 2 or 1
    local i = -1
    return function()
        i = i + 1

        if i == 3 then return nil end

        local idx = firstGameIdx + i
        local game = self.games[idx]
        if game == nil then return nil end

        return self.games[idx], i, idx
    end
end

--- @package
--- Load the games currently on screen, if they are not already loaded
function Launcher:loadGamesOnscreen()
    for game, _, i in self:gamesOnscreen() do
        if type(game) == "string" then
            self.games[i] = Game:new(game)
        end
    end
end

--- Gets and stores the game filenames, loading the first three
--- Must be called before Launcher:draw()
function Launcher:getGames()
    self.games = love.filesystem.getDirectoryItems(Game.dir)

    if #self.games ~= 0 then
        self.noGames = false
        self.settingsSelected = false
        if #self.games > 3 then
            self.scrollable = true
            self.arrowIcon = drawing.loadImage("arrow.png")
        end

        self:loadGamesOnscreen()
    end
end

--- Draw callback
function Launcher:draw()
    drawing.setup()

    love.graphics.draw(self.settingsIcon, 272, 16)

    -- Draw the games (or indicate no games)
    if self.noGames then
        local text = "No games"
        love.graphics.print(
            text,
            (love.graphics.getWidth() - drawing.font:getWidth(text)) / 2, 148
        )
    else
        if self.scrollable then
            love.graphics.draw(self.arrowIcon,   8, 64)
            love.graphics.draw(self.arrowIcon, 312, 64, 0, -1, 1)
        end

        for game, i in self:gamesOnscreen() do
            local gameX = 32 + 96 * i
            love.graphics.draw(
                game.launcherIcon,
                gameX, 104,
                0,
                64 / game.launcherIcon:getWidth(),
                64 / game.launcherIcon:getHeight()
            )
            love.graphics.printf(game.title, gameX, 176, 64, "center")
        end
    end

    -- Draw the selection indicator
    love.graphics.setColor(drawing.color.accent)
    if self.settingsSelected then
        love.graphics.draw(self.selectIcon, 232, 20)
        love.graphics.rectangle("line", 270, 14, 36, 36)
    else
        local selectIdx = self.gameSelected > 2 and 2 or self.gameSelected - 1
        love.graphics.draw(self.selectIcon, 52 + 96 * selectIdx, 64)
        love.graphics.rectangle("line", 30 + 96 * selectIdx, 102, 68, 68)
    end
end

--- Key pressed callback
--- @param key love.KeyConstant Character of the pressed key
function Launcher:keypressed(key)
    if self.settingsSelected then
        if key == "space" then
            -- TODO: open settings
        else
            self.settingsSelected = false
        end
        return
    end

    if key == "up" or key == "down" then -- Select settings
        self.settingsSelected = true
        return
    end

    if key == "right" then -- Select next game
        self.gameSelected = self.gameSelected + 1
        if self.gameSelected > #self.games then
            self.gameSelected = 1
        end
        self:loadGamesOnscreen()
        return
    end

    if key == "left" then -- Select previous game
        self.gameSelected = self.gameSelected - 1
        if self.gameSelected < 1 then
            self.gameSelected = #self.games
        end
        self:loadGamesOnscreen()
        return
    end

    if key == "space" then -- Launch the game (handled by main.lua)
        self.launchedGame = self.games[self.gameSelected]
    end
end

Launcher:getGames()
return Launcher
