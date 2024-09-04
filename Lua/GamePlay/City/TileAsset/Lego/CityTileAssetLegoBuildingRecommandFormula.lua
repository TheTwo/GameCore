local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetLegoBuildingRecommandFormula:CityTileAsset
---@field new fun(legoBuilding, buffCfg, lvCfg, complete):CityTileAssetLegoBuildingRecommandFormula
local CityTileAssetLegoBuildingRecommandFormula = class("CityTileAssetLegoBuildingRecommandFormula", CityTileAsset)
local Utils = require("Utils")
local ManualResourceConst = require("ManualResourceConst")

---@param legoBuilding CityLegoBuilding
---@param buffCfg RoomTagBuffConfigCell
---@param lvCfg CityFurnitureLevelConfigCell
---@param complete boolean
function CityTileAssetLegoBuildingRecommandFormula:ctor(legoBuilding, buffCfg, lvCfg, complete)
    CityTileAsset.ctor(self)
    self.isUI = true
    self.legoBuilding = legoBuilding
    self.buffCfg = buffCfg
    self.lvCfg = lvCfg
    self.complete = complete
end

function CityTileAssetLegoBuildingRecommandFormula:GetPrefabName()
    return ManualResourceConst.ui3d_bubble_room_formula
end

function CityTileAssetLegoBuildingRecommandFormula:OnAssetLoaded(go, userdata, handle)
    if Utils.IsNull(go) then return end

    self.go = go
    ---@type CityLegoRecommendFormulaBubble
    self.formula = go:GetLuaBehaviour("CityLegoRecommendFormulaBubble").Instance
    self.formula:Reset()
    self.formula:UpdatePreview(self.legoBuilding, self.buffCfg, self.lvCfg, self.complete)
end

function CityTileAssetLegoBuildingRecommandFormula:OnAssetUnload(go, fade)
    self.formula = nil
    self.go = nil
end

return CityTileAssetLegoBuildingRecommandFormula