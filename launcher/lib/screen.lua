-- Screen management

local index = {}

local screen = {}

--- Sets the screen to the one specified by name
--- @param name string
function screen:set(name)
    if index[name] == nil then
        index[name] = require("lib.screen." .. name)
        index[name].setup()
    end
    self.current = index[name]
end

return screen
