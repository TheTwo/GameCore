local BaseModule = require("BaseModule")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local RelocateCantPlaceReason = require("RelocateCantPlaceReason")
local I18N = require("I18N")

---@class RelocateModule : BaseModule
local RelocateModule = class("RelocateModule", BaseModule)

function RelocateModule:OnRegister()
    
end

function RelocateModule:OnRemove()
end


---@return number
function RelocateModule.CanRelocate(x, y, type)
    if type == wrpc.MoveCityType.MoveCityType_MoveToAllianceTerrain then
        if not ModuleRefer.AllianceModule:IsInAlliance() then
            return RelocateCantPlaceReason.AllianceLimit
        elseif ModuleRefer.InventoryModule:GetAmountByConfigId(ConfigRefer.ConstMain:AllianceRelocateItemID()) <= 0 then
            return RelocateCantPlaceReason.ItemLimit
        end
    end
    if type == wrpc.MoveCityType.MoveCityType_MoveToCurProvince then
        local districtId = ModuleRefer.PlayerModule:GetBornDistrictId()
        local curDistrictId = ModuleRefer.TerritoryModule:GetDistrictAt(x, y)
        local landId = ModuleRefer.TerritoryModule:GetLandCfgIdAt(x, y)
        local level = ConfigRefer.Land:Find(landId):UnlockCondMainCityLevel()
        local castleLevel = ModuleRefer.PlayerModule:StrongholdLevel()
        if castleLevel < level then
            return RelocateCantPlaceReason.CastleLevel
        end
        if curDistrictId ~= districtId then
            return RelocateCantPlaceReason.SlgBlockLimit
        end
        if not ModuleRefer.LandformModule:IsLandformSystemUnlockAt(x, y) then
            return RelocateCantPlaceReason.LandformLocked
        end
    end

    local serverTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    if serverTime < ModuleRefer.PlayerModule:GetCastle().BasicInfo.MoveCityTime.Seconds then
        return RelocateCantPlaceReason.InCD
    end

    if not ModuleRefer.MapFogModule:IsFogUnlocked(x, y) then
        return RelocateCantPlaceReason.MistLimit
    end

    if not ModuleRefer.KingdomPlacingModule:ValidateCoordinate(x, y) or 
    not ModuleRefer.KingdomPlacingModule:CheckTileValid() then
        return RelocateCantPlaceReason.PosLimit
    end
    
    local troops = ModuleRefer.SlgModule:GetMyTroops() or {}
    for i, troop in ipairs(troops) do
        if troop.entityData then
            return RelocateCantPlaceReason.TroopLimit
        end
    end

    return RelocateCantPlaceReason.OK
end

---@param reason number
function RelocateModule.CantRelocateToast(reason, tileX, tileZ)
    if reason == RelocateCantPlaceReason.InCD then
        return I18N.Get("relocate_toast_cd")
    elseif reason == RelocateCantPlaceReason.MistLimit then
        return I18N.Get("relocate_toast_mist")
    elseif reason == RelocateCantPlaceReason.AllianceLimit then
        return I18N.Get("relocate_toast_Union")
    elseif reason == RelocateCantPlaceReason.AllianceAreaLimit then
        return I18N.Get("relocate_toast_Unionterritory")
    elseif reason == RelocateCantPlaceReason.SlgBlockLimit then
        return I18N.Get("relocate_toast_province")
    elseif reason == RelocateCantPlaceReason.PosLimit then
        return I18N.Get("relocate_toast_crowded")
    elseif reason == RelocateCantPlaceReason.TroopLimit then
        return I18N.Get("relocate_toast_troop")
    elseif reason == RelocateCantPlaceReason.ItemLimit then
        return I18N.Get("relocate_toast_Insufficient")
    elseif reason == RelocateCantPlaceReason.LandformLocked then
        local landCfgId = ModuleRefer.TerritoryModule:GetLandCfgIdAt(tileX, tileZ)
        local landCfgCell = ConfigRefer.Land:Find(landCfgId)
        if not landCfgCell then
            g_Logger.Error('获取不到圈层信息,tileX %s tileZ %s landCfgId %s', tileX, tileZ, landCfgId)
            return nil
        end
        return ModuleRefer.LandformModule:GetUnlockWorldStageDesc(landCfgCell)
    elseif reason == RelocateCantPlaceReason.CastleLevel then
        local landCfgId = ModuleRefer.TerritoryModule:GetLandCfgIdAt(tileX, tileZ)
        local castleName =I18N.Get(ConfigRefer.CityFurnitureTypes:Find(ConfigRefer.CityConfig:MainFurnitureType()):Name())
        local level = ConfigRefer.Land:Find(landCfgId):UnlockCondMainCityLevel()
        return I18N.GetWithParams("toast_unlock_team_animal_slot",castleName, level)
    end
    return I18N.Get("relocate_info_relocation_failed")
end

return RelocateModule