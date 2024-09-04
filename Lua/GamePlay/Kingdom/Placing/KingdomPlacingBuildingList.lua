local DBEntityType = require("DBEntityType")

---@class KingdomPlacingBuildingList
local KingdomPlacingBuildingList = {
    DBEntityType.CastleBrief,
    DBEntityType.DefenceTower,
    DBEntityType.EnergyTower,
    DBEntityType.TransferTower,
    DBEntityType.ResourceField,
    DBEntityType.Village,
    DBEntityType.Pass,
    DBEntityType.CommonMapBuilding,
}

return KingdomPlacingBuildingList