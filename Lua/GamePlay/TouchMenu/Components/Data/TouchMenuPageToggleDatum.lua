---@class TouchMenuPageToggleDatum
---@field new fun():TouchMenuPageToggleDatum
local TouchMenuPageToggleDatum = class("TouchMenuPageToggleDatum")

---@param pageData TouchMenuPageDatum
function TouchMenuPageToggleDatum:ctor(pageData)
    self.pageData = pageData
end

return TouchMenuPageToggleDatum