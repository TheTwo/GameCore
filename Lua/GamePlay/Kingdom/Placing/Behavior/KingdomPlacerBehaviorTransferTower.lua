local KingdomPlacerBehavior = require("KingdomPlacerBehavior")
local KingdomPlacerBehaviorBuilding = require("KingdomPlacerBehaviorBuilding")
local FlexibleMapBuildingType = require("FlexibleMapBuildingType")

---@class KingdomPlacerBehaviorTransferTower : KingdomPlacerBehavior
---@field context  KingdomPlacerContextBuilding
local KingdomPlacerBehaviorTransferTower = class("KingdomPlacerBehaviorTransferTower", KingdomPlacerBehavior)

function KingdomPlacerBehaviorTransferTower:OnPlacing()
    if self.context.buildingConfig:Type() == FlexibleMapBuildingType.TransferTower then
        local message = require("BuildTransferTowerParameter").new()
        message.args.TowerConfID = self.context.buildingConfig:Id()
        message.args.Pos = wds.Vector3F.New(self.context.coord.X, self.context.coord.Y, 0)
        message:SendWithFullScreenLock()
    end
end

return KingdomPlacerBehaviorTransferTower