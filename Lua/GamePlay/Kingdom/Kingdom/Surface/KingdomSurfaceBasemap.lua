local KingdomSurface = require("KingdomSurface")
local KingdomMapUtils = require("KingdomMapUtils")
local KingdomConstant = require("KingdomConstant")
local MapAssetNames = require("MapAssetNames")
local Layers = require("Layers")

local GameObjectCreateHelper = CS.DragonReborn.AssetTool.GameObjectCreateHelper
local LayerMask = CS.UnityEngine.LayerMask

---@class KingdomSurfaceBasemap : KingdomSurface
---@field helper CS.DragonReborn.AssetTool.GameObjectCreateHelper
---@field basemap CS.UnityEngine.GameObject
local KingdomSurfaceBasemap = class("KingdomSurfaceBasemap", KingdomSurface)

function KingdomSurfaceBasemap:ctor()
    self.helper = GameObjectCreateHelper.Create()
end

function KingdomSurfaceBasemap:OnLeaveMap()
    self:Leave()
end

function KingdomSurfaceBasemap:OnLodChanged(oldLod, newLod)
    local change = KingdomMapUtils.LodSwitched(oldLod, newLod, KingdomConstant.SymbolLod)
    if change > 0 then
        self:Enter()
    elseif change < 0 then
        self:Leave()
    end
end

function KingdomSurfaceBasemap:Enter()
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local mapSystem = KingdomMapUtils.GetMapSystem()
    local prefabName = MapAssetNames.GetBasemapName(staticMapData.Prefix)
    self.helper:CreateAsap(prefabName, mapSystem.Parent, function(go)
        go:SetLayerRecursive(Layers.SymbolMap)
        self.basemap = go
    end)
end

function KingdomSurfaceBasemap:Leave()
    self.helper:CancelAllCreate()
    GameObjectCreateHelper.DestroyGameObject(self.basemap)
    self.basemap = nil
end

return KingdomSurfaceBasemap