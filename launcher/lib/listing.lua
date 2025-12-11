-- Class for handling online listings

--- @class Listing
--- @field title string
--- @field url string
local Listing = {}

--- Creates a new listing
---
--- @param title string The title of the listing
--- @param url string The URL going to the listing
--- @return Listing
function Listing:new(title, url)
    local res = {
        title = title,
        url = url
    }

    setmetatable(res, self)
    self.__index = self

    return res
end

function Listing:match(query)
    return string.match(self.title, query)
end

return Listing
