local MapTileAssetUnit = require("MapTileAssetUnit")
local KingdomConstant = require("KingdomConstant")
local Layers = require("Layers")

---@class PvPTileAssetUnit : MapTileAssetUnit
---@field super MapTileAssetUnit
local PvPTileAssetUnit = class("PvPTileAssetUnit", MapTileAssetUnit)

function PvPTileAssetUnit:OnLodChanged(oldLod, newLod)
    -- 当拉高镜头时，可以直接切换显示模型，因为低Lod的数据比高Lod的数据全
    -- 当拉低镜头时，前端会重新请求可视范围内的数据，需要等待网络数据刷新显示模型，详见C#代码MapSystem.AddOrUpdateUnit
    -- 当切换到Lod0时，需要隐藏显示模型
    if oldLod < newLod or newLod == 0 or newLod == 1 or newLod == 2 then
        MapTileAssetUnit.OnLodChanged(self, oldLod, newLod)
    end
end

--雷达HUD图标 高lod销毁
function PvPTileAssetUnit:OnLodChangedHighLod(oldLod, newLod)
    if oldLod < newLod or newLod<= 3 then
        MapTileAssetUnit.OnLodChanged(self, oldLod, newLod)
    end
end

function PvPTileAssetUnit:OnConstructionSetup()
    local asset = self:GetAsset()
    if asset then
        asset:SetLayerRecursive(Layers.Tile)
    end
end

return PvPTileAssetUnit