-- Getting games from online

local https = require("https")
local lom = require("lxp.lom")
local utf8 = require("utf8")

local drawing = require("lib.drawing")
local screen = require("lib.screen")
local Listing = require("lib.listing")

local gameHeight = drawing.font:getHeight() + drawing.gapSize
local gameListArea = drawing.screenHeight - drawing.doubleMargin
local gamesPerColumn = math.floor(gameListArea / gameHeight)
local columnsPerScreen = 3
local gameListStart = drawing.doubleMargin + drawing.selectGap
local columnWidth = math.floor(drawing.screenWidth / 3.25)
local gameTruncateAt = math.floor(
    (columnWidth - drawing.gapSize) / drawing.font:getWidth("W")
)
local columnAmount
local lastColumnRows

local games_url = "https://itch.io/games/tag-love2d.xml"
local games_cache = "onlineCache.xml"
local games_headers

local research_needed = false
local query

local search_stack = {}
local canvas_stack = {}
local curr_search
local curr_canvas

local selectOffsetX = drawing.marginSize - drawing.selectGap
local selectOffsetY = gameListStart - drawing.selectGap
local selectRow
local selectColumn
local screenSelectColumn
local canvasX

-- Loads the browser headers to avoid getting 403'd or 400'd
-- Must be called before getGames()
local function getBrowserHeaders()
    games_headers = {}
    for line in love.filesystem.lines("assets/browser_headers.txt") do
        local delim_start, delim_end = string.find(line, ": ", 1, true)
        local key = string.sub(line, 1, delim_start - 1)
        local val = string.sub(line, delim_end + 1)
        games_headers[key] = val
    end
end

local function resetSelection()
    selectRow = 1
    selectColumn = 1
    screenSelectColumn = 1
    canvasX = drawing.marginSize

    columnAmount = math.ceil(#curr_search / gamesPerColumn)
    lastColumnRows = #curr_search % gamesPerColumn
    if lastColumnRows == 0 then lastColumnRows = gamesPerColumn end
end

local function pushGames(games)
    if #games == 0 then
        curr_search = nil
        curr_canvas = nil
        search_stack[#search_stack + 1] = 0
        canvas_stack[#canvas_stack + 1] = 0
        return
    end

    curr_search = games
    search_stack[#search_stack + 1] = curr_search

    resetSelection()

    curr_canvas = love.graphics.newCanvas(
        columnAmount * columnWidth, gameListArea
    )
    canvas_stack[#canvas_stack + 1] = curr_canvas

    love.graphics.setCanvas(curr_canvas)

    for i, game in ipairs(games) do
        love.graphics.print(
            string.sub(game.title, 1, gameTruncateAt),
            columnWidth * math.floor((i - 1) / gamesPerColumn),
            gameHeight * ((i - 1) % gamesPerColumn)
        )
    end

    love.graphics.setCanvas()
end

local function popGames()
    search_stack[#search_stack] = nil
    canvas_stack[#canvas_stack] = nil
    curr_search = search_stack[#search_stack]
    curr_canvas = canvas_stack[#canvas_stack]

    resetSelection()
end

local function loadXmlToGames(xml)
    search_stack = {}
    canvas_stack = {}

    local games = {}
    local gamesList = lom.parse(xml)[1]
    for i = 3, #gamesList do
        local object = {}
        for _, element in ipairs(gamesList[i]) do
            object[element.tag] = element[1]
        end
        games[#games + 1] = Listing:new(
            object.plainTitle,
            object.guid
        )
    end

    pushGames(games)
end

local function updateGames()
	love.filesystem.write(games_cache, "uwu")
    if games_headers == nil then getBrowserHeaders() end

    local code, body = https.request(games_url, { headers = games_headers })
    if code ~= 200 then
		print(body)
        print(string.format("ERROR: %s responded with %d", games_url, code or 0))
        return
    end

    loadXmlToGames(body)
    love.filesystem.write(games_cache, body)
end

local function selectPrevColumn()
    if selectColumn < 2 then
        selectRow = 1
        return
    end

    selectColumn = selectColumn - 1
    if screenSelectColumn > 1 then
        screenSelectColumn = screenSelectColumn - 1
    else
        canvasX = canvasX + columnWidth
    end
end

local function selectNextColumn()
    if selectColumn >= columnAmount then
        selectRow = lastColumnRows
        return
    end

    selectColumn = selectColumn + 1
    if selectRow > lastColumnRows and selectColumn >= columnAmount then
        selectRow = lastColumnRows
    end
    if screenSelectColumn < columnsPerScreen then
        screenSelectColumn = screenSelectColumn + 1
    else
        canvasX = canvasX - columnWidth
    end
end

local online = {}

-- Gets the online games
function online.setup()
    local cachedXml = love.filesystem.read(games_cache)
    if cachedXml then
        loadXmlToGames(cachedXml)
    else
        updateGames()
    end
end

function online.draw()
    drawing.printCenter(query or "type to search...", drawing.marginSize)
    if curr_search == nil then
        drawing.printCenter("no games found")
        return
    end

    love.graphics.draw(curr_canvas, canvasX, gameListStart)

    love.graphics.setColor(drawing.color.accent)
    love.graphics.rectangle(
        "line",
        columnWidth * (screenSelectColumn - 1) + selectOffsetX,
        gameHeight * (selectRow - 1) + selectOffsetY,
        columnWidth, gameHeight
    )
    love.graphics.setColor(drawing.color.foreground)
end

function online.keypressed(key)
    if key == "backspace" then
        if query then
            local byteoffset = utf8.offset(query, -1)
            if byteoffset then
                query = string.sub(query, 1, byteoffset - 1)
                popGames()
            else
                query = nil
            end
        end
        return
    end


    if key == "escape" then
        curr_search = search_stack[1]
        curr_canvas = canvas_stack[1]
        search_stack = {curr_search}
        canvas_stack = {curr_canvas}

        resetSelection()

        if query then
            query = nil
        else
            screen:set("launcher")
        end

        return
    end

    if curr_search == nil then return end

    if key == "left"  then return selectPrevColumn() end
    if key == "right" then return selectNextColumn() end

    if key == "up" then
        if selectRow > 1 then
            selectRow = selectRow - 1
        else
            selectRow = gamesPerColumn
            selectPrevColumn()
        end
        return
    end

    if key == "down" then
        if selectRow < lastColumnRows or
           selectColumn < columnAmount and selectRow < gamesPerColumn then
            selectRow = selectRow + 1
        else
            selectRow = 1
            selectNextColumn()
        end
        return
    end

    if key == "return" then
        local selectedGame = (selectColumn - 1) * gamesPerColumn + selectRow
        love.system.openURL(curr_search[selectedGame].url)
    end
end

function online.textinput(txt)
    if curr_search == nil then return end

    query = query and (query .. txt) or txt

    local search_res = {}
    for _, game in ipairs(curr_search) do
        if game:match(query) then
            search_res[#search_res + 1] = game
        end
    end

    pushGames(search_res)
end

return online
