---@class UIRewardResourceItemData
---@field new fun(datum, uiMediator, delay):UIRewardResourceItemData
local UIRewardResourceItemData = class("UIRewardResourceItemData")

---@param uiMediator UIRewardResourceMediator
---@param datum ResourcePopDatum|RoomScorePopDatum
function UIRewardResourceItemData:ctor(datum, uiMediator, delay)
    self.datum = datum
    self.uiMediator = uiMediator
    self.delay = delay
end

function UIRewardResourceItemData:SetFixedViewportPos(x, y)
    self.fixedViewportPos = true
    self.viewport = CS.UnityEngine.Vector3(x, y, 0)
end

---@param pos CS.UnityEngine.Vector3
function UIRewardResourceItemData:SetFixedWorldPos(pos)
    self.fixedWorldPos = true
    self.worldPos = pos
end

return UIRewardResourceItemData