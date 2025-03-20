-- Configuration

-- Store configuration in a table, so it can be accessed by requiring this file
local conf = {
    title = "Foxglove",
    window = {
        -- QVGA for now
        width = 320,
        height = 240
    }
}

function love.conf(t)
    require("foxglove.utils").tableMerge(t, conf)
end

return conf
