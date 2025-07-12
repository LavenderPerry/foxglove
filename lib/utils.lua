-- Utilities used in other places

local utils = {
    -- VGA, should fit most games
    -- Can fit nHD within it as well if needed
    screenWidth = 640,
    screenHeight = 480
}

-- Function that does nothing, used for callbacks and monkey patching
function utils.dummyFunc(...) end

return utils
