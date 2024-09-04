local KingdomConstant = require("KingdomConstant")
local MapSortingOrder = require("MapSortingOrder")
local CityConst = require("CityConst")

local Vector3 = CS.UnityEngine.Vector3

---@class PvPTileAssetCircleRangeBehavior
---@field scaleRoot CS.UnityEngine.Transform
---@field safeAreaMesh CS.UnityEngine.MeshRenderer
---@field effectAreaMesh CS.UnityEngine.MeshRenderer
local PvPTileAssetCircleRangeBehavior = class("PvPTileAssetCircleRangeBehavior")

function PvPTileAssetCircleRangeBehavior:Awake()
    self.scaleRoot.localPosition = Vector3.up * KingdomConstant.GroundVfxYOffset
    self.safeAreaMesh:SetVisible(false)
    self.effectAreaMesh:SetVisible(false)
end

---@param radius number
---@param staticMapData CS.Grid.StaticMapData
function PvPTileAssetCircleRangeBehavior:ShowRange(radius, staticMapData, isEffectRange)
    if not staticMapData then
        return
    end
    self.scaleRoot.localPosition = Vector3.up * KingdomConstant.GroundVfxYOffset
    self.scaleRoot.localScale = 2 * radius * staticMapData.UnitsPerTileX * Vector3.one 

    local mesh = isEffectRange and self.effectAreaMesh or self.safeAreaMesh
    mesh.sortingLayerID = 0
    mesh.sortingOrder = MapSortingOrder.Range
    mesh:SetVisible(true)
end

function PvPTileAssetCircleRangeBehavior:ShowCityRange(radius, isEffectRange)
    self.scaleRoot.localPosition = Vector3.up * CityConst.GroundVfxYOffset
    self.scaleRoot.localScale = radius * Vector3.one

    local mesh = isEffectRange and self.effectAreaMesh or self.safeAreaMesh
    mesh.sortingLayerID = 0
    mesh.sortingOrder = MapSortingOrder.Range
    mesh:SetVisible(true)
end

function PvPTileAssetCircleRangeBehavior:HideRange()
    self.safeAreaMesh:SetVisible(false)
    self.effectAreaMesh:SetVisible(false)
end

---@param x number
---@param z  number
---@param staticMapData CS.Grid.StaticMapData
function PvPTileAssetCircleRangeBehavior:SetOffset(x, z, staticMapData)
    self.scaleRoot.localPosition = Vector3(x * staticMapData.UnitsPerTileX, KingdomConstant.GroundVfxYOffset, z * staticMapData.UnitsPerTileZ)
end

return PvPTileAssetCircleRangeBehavior