---@class TouchMenuMainBtnGroupData
---@field new fun():TouchMenuMainBtnGroupData
local TouchMenuMainBtnGroupData = class("TouchMenuMainBtnGroupData")

---@vararg TouchMenuMainBtnDatum
function TouchMenuMainBtnGroupData:ctor(...)
    self.data = {...}
    self.count = #self.data
end

return TouchMenuMainBtnGroupData