local Vector3 = CS.UnityEngine.Vector3

---@class RadarTaskBoardData
---@field new fun():RadarTaskBoardData
local RadarTaskBoardData = class("RadarTaskBoardData")

function RadarTaskBoardData:ctor()
    self.arrowPos = Vector3.zero
    self.result = false
    self.row = 0
    self.col = 0
    ---@type BubbleUIPosCacheData
    self.cacheData = nil
    self.isCacheData = false
    self.needUpdateCacheData = false
end

return RadarTaskBoardData