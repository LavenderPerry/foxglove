-- Handling LÖVE callbacks

local Callbacks = {
    -- List of all callbacks used in the framework
    -- See https://www.love2d.org/wiki/love#Callbacks
    names = {
        -- General
        "draw", "errorhandler", "load", "lowmemory",
        "quit", "run", "threaderror", "update",

        -- Window
        "directorydropped", "displayrotated", "filedropped",
        "focus", "mousefocus", "resize", "visible",

        -- Keyboard
        "keypressed", "keyreleased", "textedited", "textinput",

        -- Mouse
        "mousemoved", "mousepressed", "mousereleased", "wheelmoved",

        -- Joystick
        "gamepadaxis", "gamepadpressed", "gamepadreleased",
        "joystickadded", "joystickaxis", "joystickhat",
        "joystickpressed", "joystickreleased", "joystickremoved",

        -- Touch
        "touchmoved", "touchpressed", "touchreleased"
    }
}

-- Creates a Callbacks object from a table of callbacks
--
-- @param t table The table to use
-- @return Callbacks
function Callbacks:new(t)
    t = t or {}
    setmetatable(t, self)
    self.__index = self
    return t
end

-- Returns the current callbacks in a table
--
-- @return Callbacks
function Callbacks:getCurrent()
    local res = self:new()
    for _, name in ipairs(self.names) do
        res[name] = love[name]
    end
    return res
end

-- Puts the callbacks into the love table, to apply them
function Callbacks:apply()
    for name, func in pairs(self) do
        love[name] = func
    end
end

-- Default callbacks
-- This file must be required before any callbacks are changed for this to work
Callbacks.default = Callbacks:getCurrent()

return Callbacks
