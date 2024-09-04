local FurOverviewProcessState = require("FurOverviewProcessState")
---@class FurOverviewProcessStateNone:FurOverviewProcessState
---@field new fun():FurOverviewProcessStateNone
local FurOverviewProcessStateNone = class("FurOverviewProcessStateNone", FurOverviewProcessState)

function FurOverviewProcessStateNone:Enter()
    
end

function FurOverviewProcessStateNone:Exit()
    
end

return FurOverviewProcessStateNone