local FurOverviewProcessState = require("FurOverviewProcessState")
---@class FurOverviewProcessStateFree:FurOverviewProcessState
---@field new fun():FurOverviewProcessStateFree
local FurOverviewProcessStateFree = class("FurOverviewProcessStateFree", FurOverviewProcessState)

function FurOverviewProcessStateFree:Enter()
    self.data.cell._statusRecord:ApplyStatusRecord(0)
end

function FurOverviewProcessStateFree:Exit()
    
end

return FurOverviewProcessStateFree