local KingdomSurface = require("KingdomSurface")
local GameObjectHandle = CS.DragonReborn.AssetTool.PooledGameObjectHandle
local PoolUsage = require("PoolUsage")
local KingdomMapUtils = require("KingdomMapUtils")
local KingdomConstant = require("KingdomConstant")
local ManualResourceConst = require("ManualResourceConst")
local Utils = require("Utils")
local Layers = require("Layers")

local GameObjectCreateHelper = CS.DragonReborn.AssetTool.GameObjectCreateHelper
local Vector3 = CS.UnityEngine.Vector3
local Identity = CS.UnityEngine.Quaternion.identity
local One = CS.UnityEngine.Vector3.one
local LayerMask = CS.UnityEngine.LayerMask

---@class KingdomSurfaceOcean : KingdomSurface
---@field ocean CS.UnityEngine.GameObject
---@field oceanSymbol CS.UnityEngine.GameObject
local KingdomSurfaceOcean = class("KingdomSurfaceOcean", KingdomSurface)

function KingdomSurfaceOcean:ctor()
    self.helper = GameObjectCreateHelper.Create()
end

function KingdomSurfaceOcean:OnEnterMap()
    self:LoadOcean()
    self:ShowOcean()
    self:HideSymbolOcean()
end

function KingdomSurfaceOcean:OnLeaveMap()
    self:UnloadOcean()
end

function KingdomSurfaceOcean:OnLodChanged(oldLod, newLod)
    if not KingdomMapUtils.IsMapState() then return end

    if newLod >= KingdomConstant.SymbolLod and oldLod < KingdomConstant.SymbolLod then
        self:ShowSymbolOcean()
        self:HideOcean()
    elseif newLod < KingdomConstant.SymbolLod and oldLod >= KingdomConstant.SymbolLod then
        self:ShowOcean()
        self:HideSymbolOcean()
    end
end

function KingdomSurfaceOcean:LoadOcean()
    self.helper:CreateAsap(ManualResourceConst.HexGridPerimeter, self.root, function(go)
        go.transform.position = self.mapSystem.GlobalOffset
        go:SetLayerRecursive(Layers.MapTerrain)
        self.ocean = go
    end)
    self.helper:CreateAsap(ManualResourceConst.mdl_map_ocean_symbol, self.root, function(go)
        go.transform.position = self.mapSystem.GlobalOffset
        go:SetLayerRecursive(Layers.SymbolMap)
        self.oceanSymbol = go
    end)
end

function KingdomSurfaceOcean:UnloadOcean()
    self.helper:CancelAllCreate()
    if Utils.IsNotNull(self.ocean) then
        GameObjectCreateHelper.DestroyGameObject(self.ocean)
        self.ocean = nil
    end
    if Utils.IsNotNull(self.oceanSymbol) then
        GameObjectCreateHelper.DestroyGameObject(self.oceanSymbol)
        self.oceanSymbol = nil
    end
end

function KingdomSurfaceOcean:ShowOcean()
    if Utils.IsNotNull(self.ocean) then
        self.ocean:SetVisible(true)
    end
end

function KingdomSurfaceOcean:HideOcean()
    if Utils.IsNotNull(self.ocean) then
        self.ocean:SetVisible(false)
    end
end

function KingdomSurfaceOcean:ShowSymbolOcean()
    if Utils.IsNotNull(self.oceanSymbol) then
        self.oceanSymbol:SetVisible(true)
    end
end

function KingdomSurfaceOcean:HideSymbolOcean()
    if Utils.IsNotNull(self.oceanSymbol) then
        self.oceanSymbol:SetVisible(false)
    end
end

return KingdomSurfaceOcean