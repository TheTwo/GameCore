local CityTileAssetLegoBuildingBlock = require("CityTileAssetLegoBuildingBlock")
---@class CityTileAssetLegoBuildingRoof:CityTileAssetLegoBuildingBlock
---@field new fun():CityTileAssetLegoBuildingRoof
local CityTileAssetLegoBuildingRoof = class("CityTileAssetLegoBuildingRoof", CityTileAssetLegoBuildingBlock)
local Utils = require("Utils")

---@param legoBuilding CityLegoBuilding
---@param legoRoof CityLegoRoof
function CityTileAssetLegoBuildingRoof:ctor(legoBuilding, legoRoof, indoor)
    CityTileAssetLegoBuildingBlock.ctor(self, legoBuilding, legoRoof, indoor)
    self.legoRoof = legoRoof
end

function CityTileAssetLegoBuildingRoof:OnAssetLoaded(go, userdata, handle)
    CityTileAssetLegoBuildingBlock.OnAssetLoaded(self, go, userdata, handle)

    local script = self.go:GetComponent(typeof(CS.PrefabCustomInfoHolder))
    if Utils.IsNotNull(script) then
        local neightMask = self.legoRoof:GetNeighborMask()
        script:ApplyNineGrid(neightMask)
    end
end

function CityTileAssetLegoBuildingRoof:GetPrefabName()
    if self:GetCity().roofHide then return string.Empty end

    return CityTileAssetLegoBuildingBlock.GetPrefabName(self)
end

function CityTileAssetLegoBuildingRoof:OnAssetUnload(go, fadeOut)
    CityTileAssetLegoBuildingBlock.OnAssetUnload(self, go, fadeOut)
end

function CityTileAssetLegoBuildingRoof:OnRoofStateChanged(hideRoof)
    if hideRoof then
        self:Hide()
    else
        self:Show()
    end
end

function CityTileAssetLegoBuildingRoof:GetType()
    return "屋顶"
end

return CityTileAssetLegoBuildingRoof