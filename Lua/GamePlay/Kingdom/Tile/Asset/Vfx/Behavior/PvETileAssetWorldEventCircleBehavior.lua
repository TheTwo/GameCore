local ConfigRefer = require("ConfigRefer")
local KingdomConstant = require("KingdomConstant")
local MapSortingOrder = require("MapSortingOrder")
local ModuleRefer = require('ModuleRefer')
local AreaShape = require("AreaShape")
local AddExpedition2RadarParameter = require('AddExpedition2RadarParameter')
local ExpeditionQualityType = require('ExpeditionQualityType')
local ProgressType = require('ProgressType')
local DBEntityType = require('DBEntityType')
local Vector3 = CS.UnityEngine.Vector3

---@class PvETileAssetWorldEventCircleBehavior
local PvETileAssetWorldEventCircleBehavior = class("PvETileAssetWorldEventCircleBehavior")

function PvETileAssetWorldEventCircleBehavior:Awake()
    -- self.scaleRoot.localPosition = Vector3.up * KingdomConstant.GroundVfxYOffset
    self.scaleRoot:SetVisible(false)
end

function PvETileAssetWorldEventCircleBehavior:ShowRange(expeditionInfo, staticMapData, entityId)
    if not expeditionInfo then
        return
    end
    self.eventId = expeditionInfo.Tid
    self.entityId = entityId
    self.entity = g_Game.DatabaseManager:GetEntity(self.entityId, DBEntityType.Expedition)
    local eventCfg = ConfigRefer.WorldExpeditionTemplate:Find(self.eventId)
    local x = eventCfg:RadiusA()
    local scaleX = x * staticMapData.UnitsPerTileX * 2
    if eventCfg:Shape() == AreaShape.Ellipse then
        local z = eventCfg:RadiusB()
        local scaleZ = z * staticMapData.UnitsPerTileZ * 2
        self.scaleRoot.localScale = Vector3(scaleX, scaleX, scaleZ)
        self.scaleRoot.eulerAngles = CS.UnityEngine.Vector3(0, math.radian2angle(0), 0)
    else
        self.scaleRoot.localScale = Vector3(scaleX, scaleX, scaleX)
    end
    self.circleColor = {self.green, self.blue, self.red, self.yellow}
    local quality = -1
    if eventCfg:ProgressType() == ProgressType.Personal then
        quality = ModuleRefer.RadarModule:GetRadarTaskQuality(self.entityId)
    else
        local radarInfo = ModuleRefer.RadarModule:GetRadarInfo()
        -- quality = (radarInfo.ExpeditionQuality[self.entityId] or {}).QualityType or 0
        quality = 3
    end
    if quality and quality >= 0 then
        if expeditionInfo.State ~= wds.ExpeditionState.ExpeditionNotice then
            for index, circle in ipairs(self.circleColor) do
                circle.gameObject:SetActive(index == quality + 1)
            end
        else
            for index, circle in ipairs(self.circleColor) do
                circle.gameObject:SetActive(false)
            end
        end
    else
        local parameter = AddExpedition2RadarParameter.new()
        parameter.args.ExpeditionInstanceId = self.eventId
        parameter.args.ExpeditionEntityId = self.entityId
        parameter:Send()
    end
    self.scaleRoot:SetVisible(true)
    self:SetColor()
end

function PvETileAssetWorldEventCircleBehavior:ChangeRangeQuality()
    -- local radarInfo = ModuleRefer.RadarModule:GetRadarInfo()
    -- local quality = (radarInfo.ExpeditionQuality[self.entityId] or {}).QualityType or 0
    -- for index, circle in ipairs(self.circleColor) do
    --     circle.gameObject:SetActive(index == quality + 1)
    -- end
    self:SetColor()
end
function PvETileAssetWorldEventCircleBehavior:SetColor()
    local isMine, isMulti, isAlliance, isBigEvent = ModuleRefer.WorldEventModule:CheckEventType(self.entity)
    local color = 1
    if isMine then
        color = 4
    elseif isMulti then
        color = 4
    elseif isAlliance then
        color = 3
    end

    if self.entity.ExpeditionInfo.Tid ==  ModuleRefer.WorldEventModule:GetUseItemId(1) then
        color = 3
    elseif self.entity.ExpeditionInfo.Tid == ModuleRefer.WorldEventModule:GetUseItemId(2) then
        color = 4
    end


    for index, circle in ipairs(self.circleColor) do
        circle.gameObject:SetActive(index == color)
    end
end
return PvETileAssetWorldEventCircleBehavior
