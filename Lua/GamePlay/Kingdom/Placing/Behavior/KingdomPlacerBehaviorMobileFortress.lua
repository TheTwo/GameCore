local KingdomPlacerBehavior = require("KingdomPlacerBehavior")
local KingdomPlacerBehaviorBuilding = require("KingdomPlacerBehaviorBuilding")
local FlexibleMapBuildingType = require("FlexibleMapBuildingType")

---@class KingdomPlacerBehaviorMobileFortress : KingdomPlacerBehavior
---@field context  KingdomPlacerContextBuilding
local KingdomPlacerBehaviorMobileFortress = class("KingdomPlacerBehaviorMobileFortress", KingdomPlacerBehavior)

function KingdomPlacerBehaviorMobileFortress:OnPlacing()
    if self.context.buildingConfig:Type() == FlexibleMapBuildingType.MobileFortress then
        local message = require("BuildMobileFortressParameter").new()
        message.args.ConfID = self.context.buildingConfig:Id()
        message.args.Pos = wds.Vector3F.New(self.context.coord.X, self.context.coord.Y, 0)
        message:SendWithFullScreenLock()
    end
end

return KingdomPlacerBehaviorMobileFortress