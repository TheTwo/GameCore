local KingdomPlacerContext = require("KingdomPlacerContext")
local KingdomMapUtils = require("KingdomMapUtils")

---@class KingdomPlacerContextBuilding : KingdomPlacerContext
---@field buildingConfig FlexibleMapBuildingConfigCell
local KingdomPlacerContextBuilding = class("KingdomPlacerContextBuilding", KingdomPlacerContext)

function KingdomPlacerContextBuilding:SetParameter(parameter)
    self.buildingConfig = parameter[1]
    self.coord = parameter[2]
    self.sizeX, self.sizeY = KingdomMapUtils.GetLayoutSize(self.buildingConfig:Layout())
end

return KingdomPlacerContextBuilding