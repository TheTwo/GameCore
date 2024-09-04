local KingdomSurface = require("KingdomSurface")
local GameObjectHandle = CS.DragonReborn.AssetTool.PooledGameObjectHandle
local PoolUsage = require("PoolUsage")
local KingdomMapUtils = require("KingdomMapUtils")
local KingdomConstant = require("KingdomConstant")
local ManualResourceConst = require("ManualResourceConst")
local MapAssetNames = require("MapAssetNames")

local Vector3 = CS.UnityEngine.Vector3
local Identity = CS.UnityEngine.Quaternion.identity
local One = CS.UnityEngine.Vector3.one
local LayerMask = CS.UnityEngine.LayerMask

---@class KingdomSurfaceHighland : KingdomSurface
---@field prefabName string
local KingdomSurfaceHighland = class("KingdomSurfaceHighland", KingdomSurface)

function KingdomSurfaceHighland:ctor()
    self.highland = GameObjectHandle(PoolUsage.Kingdom)
end

---@param go CS.UnityEngine.GameObject
local function OnSymbolLoaded(go, data)
    go.transform.position = data.mapSystem.GlobalOffset + Vector3(100130, 100, 103533)
    go:SetLayerRecursive(LayerMask.NameToLayer("SymbolMap"))
end

function KingdomSurfaceHighland:OnEnterMap()
    if not self.prefabName then
        self.prefabName = MapAssetNames.GetHighlandName(KingdomMapUtils.GetStaticMapData().Prefix)
    end
end

function KingdomSurfaceHighland:OnLeaveMap()
    self.highland:Delete()
    self.prefabName = nil
end

function KingdomSurfaceHighland:OnLodChanged(oldLod, newLod)
    if not KingdomMapUtils.IsMapState() then return end

    local newValid = KingdomMapUtils.InSymbolMapDetailLod(newLod)
    local oldValid = KingdomMapUtils.InSymbolMapDetailLod(oldLod)
    if newValid and not oldValid then
        self.highland:Create(self.prefabName , self.root, OnSymbolLoaded, self, math.maxinteger, true)
    elseif not newValid and oldValid then
        self.highland:Delete()
    end
end

return KingdomSurfaceHighland