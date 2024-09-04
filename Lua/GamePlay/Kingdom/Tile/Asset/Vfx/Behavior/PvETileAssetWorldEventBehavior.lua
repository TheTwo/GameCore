local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local UIMediatorNames = require("UIMediatorNames")
local UIHelper = require('UIHelper')
local TimerUtility = require("TimerUtility")
local TimeFormatter = require("TimeFormatter")
local DBEntityType = require('DBEntityType')
local KingdomMapUtils = require("KingdomMapUtils")
local KingdomTouchInfoFactory = require('KingdomTouchInfoFactory')
local Utils = require("Utils")
local AddExpedition2RadarParameter = require("AddExpedition2RadarParameter")
local ProgressType = require("ProgressType")
local EventConst = require("EventConst")

---@class PvETileAssetWorldEventBehavior
---@field materialSetter CS.Lod.U2DWidgetMaterialSetter
---@field trigger CS.DragonReborn.LuaBehaviour
local PvETileAssetWorldEventBehavior = class("PvETileAssetWorldEventBehavior")

local QualitySprite =
{
    "sp_world_base_1",
    "sp_world_base_2",
    "sp_world_base_3",
    "sp_world_base_4",
}

local QUALITY_COLOR = {
    UIHelper.TryParseHtmlString("#519F0E"),
    UIHelper.TryParseHtmlString("#0E74FF"),
    UIHelper.TryParseHtmlString("#D81FF1"),
    UIHelper.TryParseHtmlString("#E37A00"),

}

function PvETileAssetWorldEventBehavior:Awake()
    if Utils.IsNotNull(self.timeText) then
        self.timeText:SetVisible(false)
    end
    if Utils.IsNotNull(self.trigger) then
        self.trigger.Instance:SetTrigger(Delegate.GetOrCreate(self, self.DoOnClick))
    end
end

function PvETileAssetWorldEventBehavior:OnEnable()
    if self.facingCamera then
        self.facingCamera.FacingCamera = KingdomMapUtils.GetBasicCamera().mainCamera
    end
    if not self.timer then
        self:OnTimer()
        self.timer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.OnTimer), 0.3, -1)
    end
end

function PvETileAssetWorldEventBehavior:OnDisable()
    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
end

function PvETileAssetWorldEventBehavior:InitEventByEntity(entity)
    self.entity = entity
    self.expeditionInfo = entity.ExpeditionInfo
    self.progress = self.expeditionInfo.PersonalProgress[ModuleRefer.PlayerModule:GetPlayer().ID] or 0
    self:RefreshExpeditionInfo(entity.ID)
end

function PvETileAssetWorldEventBehavior:RefreshExpeditionInfo(entityId)
    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
    if self.expeditionInfo.State == wds.ExpeditionState.ExpeditionNotice then
        self:RefreshNotice()
    elseif self.expeditionInfo.State == wds.ExpeditionState.ExpeditionActive then
        self:RefreshActive(entityId)
    end
end

function PvETileAssetWorldEventBehavior:RefreshActive(entityId)
    local eventId = self.expeditionInfo.Tid
    self.eventId = eventId
    local eventCfg = ConfigRefer.WorldExpeditionTemplate:Find(eventId)
    if not eventCfg then
        return
    end
    self:SetNoticeUIShow(false)
    self.lvText.text = eventCfg:Level()
    self.progressImage.fillAmount = math.clamp(self.progress / eventCfg:MaxProgress(), 0, 1)
    self.finishTime = self.expeditionInfo.ActivateEndTime
    
    --特殊处理 大嘴鸟 小事件
    if ModuleRefer.WorldEventModule:IsExpeditionUseItem(self.expeditionInfo.Tid) then
        local cfgId = ModuleRefer.WorldEventModule:GetPersonalOwnAllianceExpedition()
        local activityId = ConfigRefer.AllianceActivityExpedition:Find(cfgId):DisplayTime()
        local startT,endT = ModuleRefer.WorldEventModule:GetActivityCountDown(activityId)
        self.finishTime = endT
    end

    if self.finishTime == 0 then
        local allianceExpeditionsInfo = ModuleRefer.WorldEventModule:GetAllianceActivityExpeditionByExpeditionID(self.expeditionInfo.Tid)
        if allianceExpeditionsInfo then
            local allianceCfg = ConfigRefer.AllianceActivityExpedition:Find(allianceExpeditionsInfo.ConfigId)
            local startT, endT = ModuleRefer.WorldEventModule:GetActivityCountDown(allianceCfg:Activities(1))
            self.finishTime = endT
        end
    end

    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local isShowTime = self.finishTime and self.finishTime > curTime
    if isShowTime then
        self.timeText:SetVisible(true)
        self:OnTimer()
        self.timer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.OnTimer), 0.3, -1)
    else
        self.timeText:SetVisible(false)
    end
    eventCfg:SpecialQuality()
    local icon = ModuleRefer.WorldEventModule:GetWorldEventIconByEntity(self.entity)
    if not string.IsNullOrEmpty(icon) then
        g_Game.SpriteManager:LoadSprite(icon, self.icon)
    else
        g_Game.SpriteManager:LoadSprite("sp_comp_icon_worldevent_map", self.icon)
    end
    -- local radarInfo = ModuleRefer.RadarModule:GetRadarInfo()
    -- self.quality = (radarInfo.ExpeditionQuality[self.expeditionInfo.ID] or {}).QualityType or 0
    self.entityId = self.expeditionInfo.ID
    -- if entityId then
    --     self.entityId = entityId
    --     self.quality = (radarInfo.ExpeditionQuality[entityId] or {}).QualityType or 0
    -- end

    local iconBase = ModuleRefer.WorldEventModule:GetWorldEventLodIconBaseByEntity(self.entity)
    if not string.IsNullOrEmpty(iconBase) then
        g_Game.SpriteManager:LoadSprite(iconBase, self.frame)
    end
    -- if self.quality and self.quality >= 0 then
    --     local qualityIndex = math.clamp(self.quality + 1, 1, #QualitySprite)
    --     local qualitySprite = QualitySprite[qualityIndex]
    --     g_Game.SpriteManager:LoadSprite(qualitySprite, self.frame)
    -- else
    --     local parameter = AddExpedition2RadarParameter.new()
    --     parameter.args.ExpeditionInstanceId = self.eventId
    --     parameter.args.ExpeditionEntityId = self.entityId
    --     parameter:Send()
    -- end
end

function PvETileAssetWorldEventBehavior:RefreshNotice()
    local eventId = self.expeditionInfo.Tid
    self.eventId = eventId
    local eventCfg = ConfigRefer.WorldExpeditionTemplate:Find(eventId)
    if not eventCfg then
        return
    end
    self.progressImage.fillAmount = 0
    self:SetNoticeUIShow(true)
    -- self.openText.text = I18N.Get("relocate_info_open_after")
    self.openText.gameObject:SetActive(false)

    self.finishTime = self.expeditionInfo.ActivateEndTime
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local isShowTime = self.finishTime and self.finishTime > curTime
    if isShowTime then
        self.timeOpenText:SetVisible(true)
        self:OnTimer()
        self.timer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.OnTimer), 0.3, -1)
    else
        self.timeOpenText:SetVisible(false)
    end
    local icon = ModuleRefer.WorldEventModule:GetWorldEventIconByEntity(self.entity)
    if not string.IsNullOrEmpty(icon) then
        g_Game.SpriteManager:LoadSprite(icon, self.icon)
    else
        g_Game.SpriteManager:LoadSprite("sp_comp_icon_worldevent_map", self.icon)
    end
    local iconBase = ModuleRefer.WorldEventModule:GetWorldEventIconBaseByEntity(self.entity)
    if not string.IsNullOrEmpty(iconBase) then
        g_Game.SpriteManager:LoadSprite(iconBase, self.frame)
    end
    -- local radarInfo = ModuleRefer.RadarModule:GetRadarInfo()
    -- self.quality = (radarInfo.ExpeditionQuality[self.expeditionInfo.ID] or {}).QualityType or 0
    -- self.entityId = self.expeditionInfo.ID
    -- if self.quality and self.quality >= 0 then
    --     local qualityIndex = math.clamp(self.quality + 1, 1, #QualitySprite)
    --     local qualitySprite = QualitySprite[qualityIndex]
    --     g_Game.SpriteManager:LoadSprite(qualitySprite, self.frame)
    -- else
    --     local parameter = AddExpedition2RadarParameter.new()
    --     parameter.args.ExpeditionInstanceId = self.eventId
    --     parameter.args.ExpeditionEntityId = self.entityId
    --     parameter:Send()
    -- end
end

function PvETileAssetWorldEventBehavior:SetNoticeUIShow(isShow)
    self.lv:SetActive(not isShow)
    self.timeText:SetVisible(not isShow)

    self.openTime:SetActive(isShow)
end

---@param expeditionInfo wds.ExpeditionInfo
function PvETileAssetWorldEventBehavior:InitEvent(expeditionInfo)
    local entity = g_Game.DatabaseManager:GetEntity(expeditionInfo.ID, DBEntityType.Expedition)
    if not entity then
        self:GetAsset().transform.gameObject:SetActive(false)
        return
    end
    self.entity = entity
    self:InitEventByEntity(entity)
end

---@param expeditionInfo wrpc.RadarScanResultExpedition
function PvETileAssetWorldEventBehavior:InitEventSkipEntity(expeditionInfo)
    self.expeditionInfo = expeditionInfo
    self.progress = self.expeditionInfo.PersonalProgress
    self:RefreshExpeditionInfo()
end

function PvETileAssetWorldEventBehavior:OnTimer()
    if not self.finishTime then
        return
    end
    local lastTime = self.finishTime - g_Game.ServerTime:GetServerTimestampInSeconds()
    if lastTime > 0 then
        if lastTime >= TimeFormatter.OneHourSeconds then
            if self.expeditionInfo.State == wds.ExpeditionState.ExpeditionNotice then
                local paramStr = math.floor(lastTime / TimeFormatter.OneHourSeconds) .. I18N.Get("h")
                self.timeOpenText.text = I18N.GetWithParams("WorldExpedition_info_Open_after", paramStr)
            elseif self.expeditionInfo.State == wds.ExpeditionState.ExpeditionActive then
                self.timeText.text = math.floor(lastTime / TimeFormatter.OneHourSeconds) .. I18N.Get("h")
            end
        else
            if self.expeditionInfo.State == wds.ExpeditionState.ExpeditionNotice then
                self.timeOpenText.text = I18N.GetWithParams("WorldExpedition_info_Open_after", TimeFormatter.SimpleFormatTimeWithoutHour(lastTime))
            elseif self.expeditionInfo.State == wds.ExpeditionState.ExpeditionActive then
                self.timeText.text = TimeFormatter.SimpleFormatTimeWithoutHour(lastTime)
            end
        end
    else
        self.timeText:SetVisible(false)
        if self.timer then
            TimerUtility.StopAndRecycle(self.timer)
            self.timer = nil
        end
    end
end

function PvETileAssetWorldEventBehavior:DoOnClick()
    if self.expeditionInfo then
        local joinExpeditions = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerExpeditions.JoinExpeditions
        for _, info in pairs(joinExpeditions) do
            if info.ExpeditionInstanceTid == self.eventId then
                self.progress = info.PersonalProgress
            end
        end
        local uiDatum = KingdomTouchInfoFactory.CreateExpedition(self.expeditionInfo.Tid, self.facingCamera.transform.position, self.progress, self.quality)
        g_Game.UIManager:Open(UIMediatorNames.TouchMenuUIMediator, uiDatum)
        g_Game.EventManager:TriggerEvent(EventConst.MAP_CLICK_WORLD_EVENT)
    end
end


function PvETileAssetWorldEventBehavior:ChangeRangeQuality()
    local radarInfo = ModuleRefer.RadarModule:GetRadarInfo()
    self.quality = (radarInfo.ExpeditionQuality[self.entityId] or {}).QualityType or 0
    if self.quality and self.quality >= 0 then
        local qualityIndex = math.clamp(self.quality + 1, 1, #QualitySprite)
        local qualitySprite = QualitySprite[qualityIndex]
        g_Game.SpriteManager:LoadSprite(qualitySprite, self.frame)
    end
end



return PvETileAssetWorldEventBehavior