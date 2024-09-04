local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetLegoBuildingExpireFormula:CityTileAsset
---@field new fun():CityTileAssetLegoBuildingExpireFormula
local CityTileAssetLegoBuildingExpireFormula = class("CityTileAssetLegoBuildingExpireFormula", CityTileAsset)
local Utils = require("Utils")
local ManualResourceConst = require("ManualResourceConst")

---@param legoBuilding CityLegoBuilding
---@param buffCfg RoomTagBuffConfigCell
function CityTileAssetLegoBuildingExpireFormula:ctor(legoBuilding, buffCfg)
    CityTileAsset.ctor(self)
    self.isUI = true
    self.legoBuilding = legoBuilding
    self.buffCfg = buffCfg
end

function CityTileAssetLegoBuildingExpireFormula:GetPrefabName()
    return ManualResourceConst.ui3d_bubble_room_formula
end

function CityTileAssetLegoBuildingExpireFormula:OnAssetLoaded(go, userdata, handle)
    if Utils.IsNull(go) then return end

    self.go = go
    ---@type CityLegoRecommendFormulaBubble
    self.formula = go:GetLuaBehaviour("CityLegoRecommendFormulaBubble").Instance
    self.formula:Reset()
    self.formula:UpdateExpire(self.legoBuilding, self.buffCfg)
end

function CityTileAssetLegoBuildingExpireFormula:OnAssetUnload(go, fade)
    self.formula = nil
    self.go = nil
end

return CityTileAssetLegoBuildingExpireFormula