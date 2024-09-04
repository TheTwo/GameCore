local KingdomPlacerBehavior = require("KingdomPlacerBehavior")
local KingdomPlacerBehaviorBuilding = require("KingdomPlacerBehaviorBuilding")
local FlexibleMapBuildingType = require("FlexibleMapBuildingType")

---@class KingdomPlacerBehaviorDefenseTower : KingdomPlacerBehavior
---@field context  KingdomPlacerContextBuilding
local KingdomPlacerBehaviorDefenseTower = class("KingdomPlacerBehaviorDefenseTower", KingdomPlacerBehavior)

function KingdomPlacerBehaviorDefenseTower:OnPlacing()
    if self.context.buildingConfig:Type() == FlexibleMapBuildingType.DefenseTower then
        local message = require("BuildDefenceTowerParameter").new()
        message.args.TowerConfID = self.context.buildingConfig:Id()
        message.args.Pos = wds.Vector3F.New(self.context.coord.X, self.context.coord.Y, 0)
        message:SendWithFullScreenLock()
    end
end

return KingdomPlacerBehaviorDefenseTower