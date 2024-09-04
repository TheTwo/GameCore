local CommonTileAssetSlgBubble = require("CommonTileAssetSlgBubble")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local TileHighLightMap = require("TileHighLightMap")
local ManualResourceConst = require("ManualResourceConst")

---@class PlayerTileAssetSlgInteractorHUD : CommonTileAssetSlgBubble
local PlayerTileAssetSlgInteractorHUD = class("PlayerTileAssetSlgInteractorHUD", CommonTileAssetSlgBubble)

function PlayerTileAssetSlgInteractorHUD:GetLodPrefabName(lod)
    if self:CheckLod(lod) then
        return ManualResourceConst.ui3d_bubble_radar
    end
    return string.Empty
end

function PlayerTileAssetSlgInteractorHUD:CanShow()
    local seEnterData = self:GetData()
    self.IsRadarTaskEntity = seEnterData and ModuleRefer.RadarModule:IsRadarTaskEntity(seEnterData.ID)
    return seEnterData and ModuleRefer.MapSlgInteractorModule:IsCanCombat(seEnterData.ID) or self.IsRadarTaskEntity
end

function PlayerTileAssetSlgInteractorHUD:GetIcon()
    if self.IsRadarTaskEntity then
        local entity = self:GetData()
        if not entity then
            return string.Empty
        end
        local radarTaskId = ModuleRefer.RadarModule:GetRadarTaskId(entity.ID)
        local configInfo = ConfigRefer.RadarTask:Find(radarTaskId)
        if configInfo then
            return configInfo:RadarTaskIcon()
        end
        local conf = self:GetConfigData()
        if not conf then
            return string.Empty
        end
        if conf:MapInstanceId() > 0 then
            return "sp_comp_icon_radar_se"
        else
            return "sp_comp_icon_radar_collect"
        end
    end
    return "sp_climbtower_icon_bubble"
end

function PlayerTileAssetSlgInteractorHUD:GetQuality()
    if self.IsRadarTaskEntity then
        local entity = self:GetData()
        if not entity then
            return 0
        end
        return ModuleRefer.RadarModule:GetRadarTaskQuality(entity.ID)
    end
    return 0
end

function PlayerTileAssetSlgInteractorHUD:OnIconClick()
    ---@type wds.SeEnter
    local seEnterData = self:GetData()
    local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(seEnterData.Position)
    local scene = KingdomMapUtils.GetKingdomScene()
    local tile = KingdomMapUtils.RetrieveMap(tileX, tileZ)
    KingdomTouchInfoFactory.CreateDataFromKingdom(tile, scene:GetLod())

    TileHighLightMap.ShowTileHighlight(tile)
end

function PlayerTileAssetSlgInteractorHUD:GetCustomData()
    ---@type wds.SeEnter
    local seEnterData = self:GetData()
    local ObjectType = require("ObjectType")
    local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(seEnterData.Position)
    local param = {isRadarTaskBubble = true, type = ObjectType.SeEnter, X = tileX, Y = tileZ}
    return param
end

function PlayerTileAssetSlgInteractorHUD:CustomBubbleLogic()
    if self.IsRadarTaskEntity then
        local entity = self:GetData()
        if not entity then
            return
        end
        local radarTaskId = ModuleRefer.RadarModule:GetRadarTaskId(entity.ID)
        local configInfo = ConfigRefer.RadarTask:Find(radarTaskId)
        if configInfo then
            local behavior = self:GetAsset():GetLuaBehaviour("PvETileAsseRadarBubbleBehavior").Instance
            if not behavior then
                return
            end
            if not string.IsNullOrEmpty(configInfo:RadarTaskRewardIcon()) then
                behavior:SetPetRewardActive(true)
                behavior:SetPetRewardIcon(configInfo:RadarTaskRewardIcon())
            else
                behavior:SetPetRewardActive(false)
            end
            if not string.IsNullOrEmpty(configInfo:RadarTaskCitizenIcon()) then
                behavior:SetCitizenTaskActive(true)
                behavior:SetCitizenTaskIcon(configInfo:RadarTaskCitizenIcon())
            else
                behavior:SetCitizenTaskActive(false)
            end
        end
    end
end

return PlayerTileAssetSlgInteractorHUD