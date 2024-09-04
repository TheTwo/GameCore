local BaseActivityPack = require("BaseActivityPack")
---@class ActivityWorkerPack : BaseActivityPack
local ActivityWorkerPack = class("ActivityWorkerPack", BaseActivityPack)

function ActivityWorkerPack:PostInitGroupInfoParam()
    self.groupInfoParam.tagText = "+1"
end

return ActivityWorkerPack