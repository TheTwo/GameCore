local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')
local I18N = require('I18N')
local KingdomMapUtils = require('KingdomMapUtils')
local EventConst = require('EventConst')
local ModuleRefer = require("ModuleRefer")
local ProgressType = require('ProgressType')
local ConfigRefer = require("ConfigRefer")
local DBEntityType = require("DBEntityType")
local ReceiveRadarTaskRewardParameter = require("ReceiveRadarTaskRewardParameter")
local GuideUtils = require('GuideUtils')

---@class WorldEventButtonData
---@field expeditionInfo wrpc.RadarScanResultExpedition
---@field radarTaskData wds.RadarTask
---@field iconName string
---@field uiPos CS.UnityEngine.Vector3
---@field isAlliance boolean

---@class WorldEventButtonComponent : BaseUIComponent
---@field callback fun()
local WorldEventButtonComponent = class('WorldEventButtonComponent', BaseUIComponent)

local QUALITY_COLOR = {
    "sp_radar_farme_event_01",
    "sp_radar_farme_event_02",
    "sp_radar_farme_event_03",
    "sp_radar_farme_event_04",
}

function WorldEventButtonComponent:ctor()

end

function WorldEventButtonComponent:OnCreate()
    self.imgIconStatus = self:Image('p_icon_status')
    self.imgFrame = self:Image('p_base')
    self.btnRadarTask = self:Button('p_rotation', Delegate.GetOrCreate(self, self.OnBtnClicked))
    self.goFrameSelect = self:GameObject('p_img_select')
    self.goLv = self:GameObject('p_progress_lv')
    self.imgProgress = self:Image('Fill')
    self.sliderProgress = self:BindComponent("p_progress_lv", typeof(CS.UnityEngine.UI.Slider))
    self.textProgress = self:Text('p_text_progress')
    self.goGroup = self:GameObject('p_group')
    self.goRedDot = self:GameObject('p_reddot')
    self.goLock = self:GameObject('p_group_lock')
    g_Game.EventManager:AddListener(EventConst.RADAR_TASK_STATE_CHANGED,Delegate.GetOrCreate(self,self.OnRadarTaskStateChanged))
    g_Game.EventManager:AddListener(EventConst.RADAR_TASK_CLICKED,Delegate.GetOrCreate(self,self.OnRadarTaskClicked))
    g_Game.ServiceManager:AddResponseCallback(ReceiveRadarTaskRewardParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnClaimReward))
end

function WorldEventButtonComponent:OnOpened()
end

function WorldEventButtonComponent:OnClose()
    self.isSelected = false
    g_Game.EventManager:RemoveListener(EventConst.RADAR_TASK_STATE_CHANGED,Delegate.GetOrCreate(self,self.OnRadarTaskStateChanged))
    g_Game.EventManager:RemoveListener(EventConst.RADAR_TASK_CLICKED,Delegate.GetOrCreate(self,self.OnRadarTaskClicked))
    g_Game.ServiceManager:RemoveResponseCallback(ReceiveRadarTaskRewardParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnClaimReward))
end

---OnFeedData
---@param param WorldEventButtonData
function WorldEventButtonComponent:OnFeedData(param)
    if not param then
        return
    end
    self.expeditionInfo = param.expeditionInfo
    self.radarTaskData = param.radarTaskData
    self.ID = param.radarTaskData.ID
    self.iconName = param.iconName
    self.uiPos = param.uiPos
    self.isAlliance = param.isAlliance
    self.isSelected = false
    self:OnSelected(self.isSelected)
    self:InitWorldEventButton(self.expeditionInfo)
end

function WorldEventButtonComponent:RefreshData(expeditionInfo, radarTaskData)
    self.expeditionInfo = expeditionInfo
    self.radarTaskData = radarTaskData
    self.ID = radarTaskData.ID
    self:InitWorldEventButton(self.expeditionInfo)
end

function WorldEventButtonComponent:InitWorldEventButton(expeditionInfo)
    self.quality = expeditionInfo.Quality
    self.entityID = expeditionInfo.EntityID
    self.eventId = expeditionInfo.CfgId
    self.progress = expeditionInfo.PersonalProgress
    local eventCfg = ConfigRefer.WorldExpeditionTemplate:Find(self.eventId)
    if not eventCfg then
        return
    end
    if not self.isAlliance and self.radarTaskData.State == wds.RadarTaskState.RadarTaskState_CanReceiveReward then
        self.goLv:SetActive(true)
        self.goRedDot:SetActive(true)
        self.sliderProgress.value = 1
        self.textProgress.text = "100%"
    else
        if self.progress and self.progress > 0 then
            self.goLv:SetActive(true)
            local percent = math.clamp(self.progress / eventCfg:MaxProgress(), 0, 1)
            self.sliderProgress.value = percent
            self.textProgress.text = percent * 100 .."%"
        else
            self.goLv:SetActive(false)
        end
    end
    if  eventCfg:ProgressType() == ProgressType.Whole and self.goGroup then
        self.goGroup:SetActive(true)
    end

    if self.isAlliance and self.expeditionInfo.State and self.expeditionInfo.State == wds.ExpeditionState.ExpeditionNotice then
        self.goLock:SetActive(true)
    else
        self.goLock:SetActive(false)
    end

    local iconBase = ModuleRefer.WorldEventModule:GetWorldEventIconBaseByConfigID(self.eventId)
    if not string.IsNullOrEmpty(iconBase) then
        g_Game.SpriteManager:LoadSprite(iconBase, self.imgFrame)
    end
    local icon = ModuleRefer.WorldEventModule:GetWorldEventIconByConfigID(self.eventId)
    if not string.IsNullOrEmpty(icon) then
        g_Game.SpriteManager:LoadSprite(icon, self.imgIconStatus)
    else
        g_Game.SpriteManager:LoadSprite("sp_comp_icon_worldevent", self.imgIconStatus)
    end
    if self:CheckIsMovingToRadarTask() then
        self:GoingToRadarTaskTarget()
    end
    self.goRedDot:SetActive( not self.isAlliance and self.radarTaskData.State == wds.RadarTaskState.RadarTaskState_CanReceiveReward)

    if  eventCfg:ProgressType() == ProgressType.Personal then
        GuideUtils.GotoByGuide(43)
    end
end

function WorldEventButtonComponent:OnRadarTaskClicked(ID)
   if ID ~= self.ID then
        self.isSelected = false
        self:OnSelected(self.isSelected)
   end
end

function WorldEventButtonComponent:OnRadarTaskStateChanged(isGoing)
   if isGoing then
        self:GoingToRadarTaskTarget()
   else
        self:NoneRadarTaskTarget()
   end
end

function WorldEventButtonComponent:GoingToRadarTaskTarget()
    self:ChangeImageAlpha(self.imgFrame, 0.3)
    self:ChangeImageAlpha(self.imgIconStatus, 0.3)
end

function WorldEventButtonComponent:NoneRadarTaskTarget()
    self:ChangeImageAlpha(self.imgFrame, 1)
    self:ChangeImageAlpha(self.imgIconStatus, 1)
end

function WorldEventButtonComponent:ChangeImageAlpha(image, alpha)
    local color = image.color
    color.a = alpha
    image.color = color
end

function WorldEventButtonComponent:CheckIsMovingToRadarTask()
    local troops = ModuleRefer.SlgModule:GetMyTroops() or {}
    for i, troop in ipairs(troops) do
        if troop.entityData and troop.entityData.MovePathInfo then
            local entityID = troop.entityData.MovePathInfo.TargetUID
            if self.expeditionInfo and entityID == self.expeditionInfo.EntityID and self.expeditionInfo.EntityID ~= 0 then
                 return true
            end
        end
    end
    return false
end

function WorldEventButtonComponent:IsCanAwardWorldEvent()
    local expeditions = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerExpeditions.CanReceiveRewardExpeditions or {}
    for id, expeditionInfo in pairs(expeditions) do
        if id ~= 0 and id == self.expeditionInfo.EntityID then
            return true
        end
    end
    return false
end

function WorldEventButtonComponent:OnSelected(isSelected)
    self.goFrameSelect:SetActive(isSelected)
end

function WorldEventButtonComponent:OnBtnClicked()
    if not self.isAlliance and self.radarTaskData.State == wds.RadarTaskState.RadarTaskState_CanReceiveReward then
        local parameter = ReceiveRadarTaskRewardParameter.new()
        parameter.args.RadarTaskCompId = self.radarTaskData.ID or 0
        parameter:Send()
        return
    end

    self.isSelected = true
    self:OnSelected(self.isSelected)
    ---@type RadarObjectDetailParam
    local param = {expeditionInfo = self.expeditionInfo, type = 1, ID = self.radarTaskData.ID,
     radarTaskID = self.radarTaskData.RadarTaskId, taskState = self.radarTaskData.State, entityType = self.radarTaskData.EntityType, entityID = self.radarTaskData.EntityId}
    param.isAlliance = self.isAlliance
    if self.uiPos then
        if self.uiPos.x > 260 then
            param.groupOffsetX = self.uiPos.x - 260
        else
            param.groupOffsetX = 0
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.RADAR_OPEN_GROUP_INFO, param)
    g_Game.EventManager:TriggerEvent(EventConst.RADAR_TASK_CLICKED, self.ID)
end

function WorldEventButtonComponent:Shake()
    -- self.normalAnimTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
end

function WorldEventButtonComponent:OnClaimReward(isSuccess, reply, rpc)
    if not isSuccess then
        return
    end
    if self.radarTaskData then
        return
    end
    g_Game.EventManager:TriggerEvent(EventConst.RADAR_TASK_CLAIM_REWARD)
end

return WorldEventButtonComponent
