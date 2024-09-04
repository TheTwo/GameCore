local KingdomMapUtils = require("KingdomMapUtils")
local ConfigRefer = require("ConfigRefer")
local ManualResourceConst = require("ManualResourceConst")

local PvPTileAssetUnit = require("PvPTileAssetUnit")

---@class PvPTileAssetBehemothEntryPointVFX:PvPTileAssetUnit
---@field new fun():PvPTileAssetBehemothEntryPointVFX
---@field super PvPTileAssetUnit
local PvPTileAssetBehemothEntryPointVFX = class('PvPTileAssetBehemothEntryPointVFX', PvPTileAssetUnit)

function PvPTileAssetBehemothEntryPointVFX:ctor()
    PvPTileAssetBehemothEntryPointVFX.super.ctor(self)
    self._offsetPosX = 0
    self._offsetPosY = 0
end

function PvPTileAssetBehemothEntryPointVFX:CanShow()
    ---@type wds.BehemothCage
    local entity = self:GetData()
    if not entity then
        return false
    end
    return true
end

function PvPTileAssetBehemothEntryPointVFX:GetLodPrefabName(lod)
    if not KingdomMapUtils.InMapNormalLod(lod) and not KingdomMapUtils.InMapLowLod(lod) then
        return string.Empty
    end
    if not self:CanShow() then
        return string.Empty
    end
    local entity = self:GetData()
    if not entity then
        return string.Empty
    end
    return ManualResourceConst.vfx_bigmap_behemoth_cage_entry_pos
end

function PvPTileAssetBehemothEntryPointVFX:CalculatePosition()
    local x, z = self:GetServerPosition()
    local staticMapData = self:GetStaticMapData()
    x = (x + self._offsetPosX) * staticMapData.UnitsPerTileX
    z = (z + self._offsetPosY) * staticMapData.UnitsPerTileZ
    local y = KingdomMapUtils.SampleHeight(x, z)
    return CS.UnityEngine.Vector3(x, y, z)
end

function PvPTileAssetBehemothEntryPointVFX:OnShow()
    ---@type wds.BehemothCage
    local entity = self:GetData()
    local config = ConfigRefer.BehemothCage:Find(ConfigRefer.FixedMapBuilding:Find(entity.BehemothCage.ConfigId):BehemothCageConfig())
    local dir = config:Dir()
    self._offsetPosX = dir:X()
    self._offsetPosY = dir:Y()
end

return PvPTileAssetBehemothEntryPointVFX