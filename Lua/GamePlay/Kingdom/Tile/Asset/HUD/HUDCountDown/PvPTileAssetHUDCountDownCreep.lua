local PvPTileAssetHudCountDown = require("PvPTileAssetHudCountDown")
local TimeFormatter = require("TimeFormatter")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceUIConsts = require("ArtResourceUIConsts")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local MapHudTransformControl = require("MapHudTransformControl")
local KingdomMapUtils = require("KingdomMapUtils")


---@class PvPTileAssetHUDCountDownCreep : PvPTileAssetHudCountDown
local PvPTileAssetHUDCountDownCreep = class("PvPTileAssetHUDCountDownCreep", PvPTileAssetHudCountDown)

function PvPTileAssetHUDCountDownCreep:GetNormalIcon(entity)
    return "sp_icon_item_coin"
end

function PvPTileAssetHUDCountDownCreep:GetClaimIcon(entity)
    return ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_icon_item_creepcleaner)
end

function PvPTileAssetHUDCountDownCreep:UpdateProgress(entity)
    local serverTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    ---@type wds.SlgCreepTumorRemoverInfo
    local removerInfo = entity.RemoverInfo
    local progress = math.clamp01((serverTime - removerInfo.StartTime.Seconds) / (removerInfo.EndTime.Seconds - removerInfo.StartTime.Seconds))
    local timeStr = TimeFormatter.SimpleFormatTime(removerInfo.EndTime.Seconds - serverTime)
    return progress, timeStr
end

function PvPTileAssetHUDCountDownCreep:CanShowReward(entity)
    return ModuleRefer.KingdomConstructionModule:IsMyBuilding(entity.Owner)
end

function PvPTileAssetHUDCountDownCreep:OnClaimReward()
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return
    end
    
    ModuleRefer.MapCreepModule:ClaimFinishReward(entity.ID)
    self:SecondTick()--force refresh

end

return PvPTileAssetHUDCountDownCreep