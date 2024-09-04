local PvPTileAssetUnit = require("PvPTileAssetUnit")
local KingdomMapUtils = require("KingdomMapUtils")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local ModuleRefer = require("ModuleRefer")
local DBEntityType = require("DBEntityType")
local ManualResourceConst = require("ManualResourceConst")

local One = CS.UnityEngine.Vector3.one

---@class PvPTileAssetProtectionShield : PvPTileAssetUnit
local PvPTileAssetProtectionShield = class("PvPTileAssetProtectionShield", PvPTileAssetUnit)

function PvPTileAssetProtectionShield:CanShow()
    ---@type wds.Village
    local entity = self:GetData()
    if not entity then
        return false
    end
    
    return self:IsEntityInProtection(entity)
end

function PvPTileAssetProtectionShield:GetLodPrefabName(lod)
    local entity = self:GetData()
    if not entity then
        return string.Empty
    end
    
    if not self:IsEntityInProtection(entity) then
        return string.Empty
    end

    if not KingdomMapUtils.CheckIsEnterOrHigherIconLodFixed(entity.MapBasics.ConfID, lod) then
        if entity.TypeHash == DBEntityType.CastleBrief then
            return ManualResourceConst.vfx_bigmap_city_platyer_LOOP
        else
            return ArtResourceUtils.GetItem(ArtResourceConsts.vfx_bigmap_city_hudun_LOOP)
        end
    end
    return string.Empty
end

function PvPTileAssetProtectionShield:GetPosition()
    return self:CalculateCenterPosition()
end

function PvPTileAssetProtectionShield:GetScale()
    local entity = self:GetData()
    if not entity then
        return One * ArtResourceUtils.GetScale(ArtResourceConsts.vfx_bigmap_city_hudun_LOOP)
    end
    local layout = ModuleRefer.MapBuildingLayoutModule:GetLayout(entity.MapBasics.LayoutCfgId)
    return One * math.max(layout.SizeX ,layout.SizeY)
end

function PvPTileAssetProtectionShield:OnShow()
    
end

function PvPTileAssetProtectionShield:OnHide()

end

function PvPTileAssetProtectionShield:IsEntityInProtection(entity)
    if not  entity then
        return false
    end

    if entity.TypeHash == DBEntityType.Village or entity.TypeHash == DBEntityType.Pass then
        return ModuleRefer.VillageModule:IsVillageInProtection(entity)
    else
        local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
        return entity.MapStates and entity.MapStates.StateWrapper and entity.MapStates.StateWrapper.ProtectionExpireTime > curTime
    end
end

function PvPTileAssetProtectionShield:OnConstructionUpdate()
end


return PvPTileAssetProtectionShield