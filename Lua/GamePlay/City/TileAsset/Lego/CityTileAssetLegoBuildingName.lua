local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetLegoBuildingName:CityTileAsset
---@field new fun():CityTileAssetLegoBuildingName
local CityTileAssetLegoBuildingName = class("CityTileAssetLegoBuildingName", CityTileAsset)
local Utils = require("Utils")
local I18N = require("I18N")
local ManualResourceConst = require("ManualResourceConst")

---@param legoBuilding CityLegoBuilding
function CityTileAssetLegoBuildingName:ctor(legoBuilding)
    CityTileAsset.ctor(self)
    self.legoBuilding = legoBuilding
end

function CityTileAssetLegoBuildingName:GetPrefabName()
    return ManualResourceConst.ui3d_name_city
end

function CityTileAssetLegoBuildingName:OnAssetLoaded(go, userdata, handle)
    if Utils.IsNull(go) then return end

    self.go = go
    local pos = self.legoBuilding:GetWorldCenter()
    local offset = self.legoBuilding.legoBluePrintCfg:BubbleHeightOffset() * self:GetCity().scale
    self.go.transform.position = pos + (CS.UnityEngine.Vector3.up * offset)

    ---@type CityLegoBuildingName
    local nameComp = go:GetLuaBehaviour("CityLegoBuildingName").Instance
    nameComp:SetName(I18N.Get(self.legoBuilding:GetNameI18N()))
end

function CityTileAssetLegoBuildingName:OnAssetUnload(go, fadeout)
    self.go = nil
end

return CityTileAssetLegoBuildingName