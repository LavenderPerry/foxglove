-- Handles installing games

local drawing = require("lib.drawing")
local path = require("lib.path")

--local isDir

local isMod = false
local currentGame
local itemPath
local itemFile

local installer = {}

--function installer.setItem(newItem, newIsDir)
--    isDir = newIsDir
--    if isDir then
--        itemPath = newItem
--    else
--        itemFile = newItem
--        itemPath = itemFile:getFilename()
--    end
--end

function installer.init(game, newPath, newFile)
    currentGame = game
    itemPath = newPath
    itemFile = newFile
end

function installer.draw()
    if not itemPath then return end

    love.graphics.setColor(drawing.color.background)
    local padding = drawing.marginSize * 2
    local sizeDiff = padding * 2
    local promptWidth = drawing.screenWidth - sizeDiff

    love.graphics.rectangle(
        "fill",
        padding, padding,
        promptWidth, drawing.screenHeight - sizeDiff
    )
    love.graphics.setColor(drawing.color.foreground)

    local contentPadding = padding + drawing.marginSize
    local textOffset = drawing.font:getHeight() + drawing.gapSize
    local itemPathY = contentPadding + textOffset

    drawing.printCenter("Is this a game or a mod?", contentPadding)
    drawing.printCenter(itemPath, itemPathY)

    local doubleText = textOffset * 2
    local noteY = itemPathY + doubleText
    drawing.printCenter(
        string.format(
            "Mods will be installed for the currently selected game (%s)",
            currentGame and currentGame.title or "none"
        )
    )

    local contentWidth = promptWidth - padding
    local halfScreen = contentWidth / 2
    local buttonWidth = halfScreen - drawing.gapSize / 2
    local buttonY = noteY + doubleText
    love.graphics.setColor(drawing.color[isMod and "foreground" or "accent"])
    love.graphics.rectangle(
        "line",
        contentPadding, buttonY,
        buttonWidth, textOffset
    )
    local button2X = contentPadding + halfScreen
    love.graphics.setColor(drawing.color[isMod and "accent" or "foreground"])
    love.graphics.rectangle(
        "line",
        button2X, buttonY,
        buttonWidth, textOffset
    )
    love.graphics.setColor(drawing.color.foreground)
    local textY = buttonY + (textOffset - drawing.font:getHeight()) / 2
    local opt = "Game"
    love.graphics.print(
        opt,
        contentPadding + (buttonWidth - drawing.font:getWidth(opt)) / 2,
        textY
    )
    opt = "Mod"
    love.graphics.print(
        opt,
        button2X + (buttonWidth - drawing.font:getWidth(opt)) / 2,
        textY
    )
end

function installer.keypressed(key)
    if not itemPath then return true end -- true -> run launcher keypressed

    if key == "up" or key == "down" then
        itemPath = nil
        itemFile = nil
        return
    end

    if key == "left" or key == "right" then
        isMod = not isMod
        return
    end

    if key == "space" then
        local copyTo = path.join(
            isMod and currentGame.active_mods or currentGame.dir,
            itemPath:match("[^/]*$")
        )
        if itemFile then
            itemFile:open("r")
            love.filesystem.write(copyTo, itemFile:read())
            itemFile = nil
        else
            local function copyDir(dir, dest)
                love.filesystem.createDirectory(dest)
                for _, child in ipairs(love.filesystem.getDirectoryItems(dir)) do
                    local curitem = path.join(dir, child)
                    local curdest = path.join(dest, child)
                    if love.filesystem.getInfo(curitem, "directory") then
                        copyDir(curitem, curdest)
                    else
                        love.filesystem.write(
                            curdest,
                            love.filesystem.read(curitem)
                        )
                    end
                end
            end
            copyDir(itemPath, copyTo)
        end
        itemPath = nil
    end
end

return installer
