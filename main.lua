-- LÖVE functions

-- https://mrpudn.net/log/2024/04/06/using-luarocks-with-love/

LUA_VERSION = "5.1" -- LÖVE uses Luajit, which is compatible with 5.1

love.filesystem.setRequirePath(table.concat({
  love.filesystem.getRequirePath(),
  table.concat({ ";lua_modules/share/lua/", LUA_VERSION, "/?.lua" }),
  table.concat({ ";lua_modules/share/lua/", LUA_VERSION, "/?/init.lua" }),
  ";src/?.lua",
}))

love.filesystem.setCRequirePath(table.concat({
  love.filesystem.getCRequirePath(),
  table.concat({ ";lua_modules/lib/lua/", LUA_VERSION, "/??" }),
  ";lib/??",
}))

--

local drawing = require("lib.drawing")
local installer = require("lib.installer")
local screen = require("lib.screen")
local launcher

function love.load(_)
    love.mouse.setVisible(false)
    love.keyboard.setTextInput(true)
    love.graphics.setDefaultFilter("nearest")
    drawing:setup()
    screen:set("launcher")
	launcher = screen.current
end

function love.draw()
    screen.current.draw()
    installer.draw()
end

function love.filedropped(file)
    installer.init(launcher.selectedGame(), file:getFilename(), file)
end

function love.directorydropped(dir)
    installer.init(launcher.selectedGame(), dir)
end

function love.keypressed(key)
    return installer.keypressed(key) and screen.current.keypressed(key)
end

function love.textinput(text)
    if type(screen.current.textinput) == "function" then
        screen.current.textinput(text)
    end
end
