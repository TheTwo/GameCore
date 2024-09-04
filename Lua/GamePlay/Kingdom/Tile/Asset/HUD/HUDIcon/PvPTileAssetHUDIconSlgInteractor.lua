local PvPTileAssetHUDIcon = require("PvPTileAssetHUDIcon")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")
local ModuleRefer = require("ModuleRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local ConfigRefer = require("ConfigRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local KingdomConstant = require("KingdomConstant")
local I18N = require("I18N")
local Utils = require("Utils")

---@class PvPTileAssetHUDIconSlgInteractor : PvPTileAssetHUDIcon
local PvPTileAssetHUDIconSlgInteractor = class("PvPTileAssetHUDIconSlgInteractor", PvPTileAssetHUDIcon)

function PvPTileAssetHUDIconSlgInteractor:OnRefresh(entity)
    if not entity then
        return
    end
    local icon = self:GetLod2Icon(entity.Interactor.ConfigID)
    self.behavior:SetIcon(icon)
    self.behavior:AdjustNameLevel()
    self.IsRadarTaskEntity = ModuleRefer.RadarModule:IsRadarTaskEntity(entity.ID)
    if self.IsRadarTaskEntity then
        self.behavior:SetIcon(self:GetLod2IconWithBase(entity.Interactor.ConfigID))
        self.behavior:SetIconBase(ModuleRefer.RadarModule:GetRadarTaskLodBase(entity.ID))
        self.behavior:ShowIconBase(true)
    else
        self.behavior:ShowIconBase(false)
    end
end

function PvPTileAssetHUDIconSlgInteractor:OnIconClick()
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return
    end

    -- local level = ModuleRefer.MapBuildingTroopModule:GetBuildingLevel(entity)
    local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(entity.MapBasics.BuildingPos)
    local touchData = KingdomTouchInfoFactory.CreateEntityHighLod(tileX, tileZ, self:GetName(entity.Interactor.ConfigID))
    ModuleRefer.KingdomTouchInfoModule:Show(touchData)
end

function PvPTileAssetHUDIconSlgInteractor:CheckLod(lod)
    return KingdomMapUtils.InMapNormalLod(lod) or KingdomMapUtils.InMapLowLod(lod)
end

function PvPTileAssetHUDIconSlgInteractor:DisplayIcon(lod)
    return KingdomMapUtils.InMapLowLod(lod)
end

function PvPTileAssetHUDIconSlgInteractor:DisplayText(lod)
    return KingdomMapUtils.InMapNormalLod(lod) or KingdomMapUtils.InMapLowLod(lod)
end

function PvPTileAssetHUDIconSlgInteractor:OnConstructionShutdown()
    if Utils.IsNotNull(self.behavior) then
        self.behavior:ShowIconBase(false)
    end
end

function PvPTileAssetHUDIconSlgInteractor:GetLod2Icon(configID)
    local mineConf = ConfigRefer.Mine:Find(configID)
    if not mineConf then
        return "sp_icon_missing_2"
    end
    if mineConf:MapInstanceId() > 0 then
        return "sp_icon_lod_se"
    else
        return "sp_icon_lod_collect"
    end
end

function PvPTileAssetHUDIconSlgInteractor:GetLod2IconWithBase(configID)
    local mineConf = ConfigRefer.Mine:Find(configID)
    if not mineConf then
        return "sp_icon_missing_2"
    end
    if mineConf:MapInstanceId() > 0 then
        return "sp_comp_icon_radar_se_1"
    else
        return "sp_comp_icon_radar_collect_1"
    end
end

function PvPTileAssetHUDIconSlgInteractor:GetName(configID)
    local mineConf = ConfigRefer.Mine:Find(configID)
    if not mineConf then
        return string.Empty
    end
    return I18N.Get(mineConf:Name())
end

function PvPTileAssetHUDIconSlgInteractor:CanShow()
    local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not entity then
        return false
    end
    --个人交互物只有自己能看到
    local isMine = entity.Owner.ExclusivePlayerId == ModuleRefer.PlayerModule:GetPlayer().ID
    local isMulti = entity.Owner.ExclusivePlayerId == 0
    return isMulti or isMine
end

return PvPTileAssetHUDIconSlgInteractor