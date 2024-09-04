---@class ResourcePopDatum
---@field new fun():ResourcePopDatum
local ResourcePopDatum = class("ResourcePopDatum")

function ResourcePopDatum:ctor(icon, text, x, y)
    self.icon = icon
    self.text = text
    self.x = x
    self.y = y
end

return ResourcePopDatum