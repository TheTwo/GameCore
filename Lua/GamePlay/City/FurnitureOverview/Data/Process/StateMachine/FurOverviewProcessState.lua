local State = require("State")
---@class FurOverviewProcessState:State
---@field new fun():FurOverviewProcessState
local FurOverviewProcessState = class("FurOverviewProcessState", State)

---@param data CityFurnitureOverviewUnitData_Process
function FurOverviewProcessState:ctor(data)
    self.data = data
end

return FurOverviewProcessState