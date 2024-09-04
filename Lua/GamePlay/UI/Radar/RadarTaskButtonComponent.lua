local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local I18N = require('I18N')
local KingdomMapUtils = require('KingdomMapUtils')
local EventConst = require('EventConst')
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local ObjectType = require("ObjectType")
local ReceiveRadarTaskRewardParameter = require("ReceiveRadarTaskRewardParameter")
local UIMediatorNames = require('UIMediatorNames')

---@class RadarTaskButtonData
---@field customData wds.RadarTask
---@field iconName string
---@field uiPos CS.UnityEngine.Vector3

---@class RadarTaskButtonComponent : BaseUIComponent
---@field callback fun()
local RadarTaskButtonComponent = class('RadarTaskButtonComponent', BaseUIComponent)

local QUALITY_COLOR = {"sp_city_bubble_base_green", "sp_city_bubble_base_blue", "sp_city_bubble_base_purple", "sp_city_bubble_base_orange"}
local QUALITY_COLOR_CYST = {"sp_radar_img_light_01", "sp_radar_img_light_02", "sp_radar_img_light_03", "sp_radar_img_light_04"}
local RADARTASK_TYPE = {
    normal = 1, -- 一般雷达任务
    elite = 2, -- 精英雷达任务
    creepNormal = 3, -- 菌毯雷达任务(未清除)
    creepUnlock = 4, -- 菌毯雷达任务(已清除)
}

function RadarTaskButtonComponent:ctor()

end

function RadarTaskButtonComponent:OnCreate()
    self.imgIconStatus = self:Image('p_icon_status')
    self.imgIconCyst = self:Image('p_icon_cyst')
    self.imgFrame = self:Image('p_frame')
    self.imgFrameCyst = self:Image('p_frame_cyst')
    self.btnRadarTask = self:Button('p_rotation', Delegate.GetOrCreate(self, self.OnBtnClicked))
    self.goRedDot = self:GameObject('p_reddot')
    self.goFrameSelect = self:GameObject('p_img_frame_select')
    self.goGroupMission = self:GameObject('p_group_mission')
    self.goPetReward = self:GameObject('p_group_pet')
    self.imgPerReward = self:Image('p_img_pet')
    self.imgMissionHead = self:Image('p_img_head')
    self.normalAnimTrigger = self:AnimTrigger('Trigger')
    self.eliteAnimTrigger = self:AnimTrigger('p_icon_status_1')
    self.gameObject = self:GameObject('')

    g_Game.EventManager:AddListener(EventConst.RADAR_TASK_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnRadarTaskStateChanged))
    g_Game.EventManager:AddListener(EventConst.RADAR_TASK_CLICKED, Delegate.GetOrCreate(self, self.OnRadarTaskClicked))
    g_Game.ServiceManager:AddResponseCallback(ReceiveRadarTaskRewardParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnClaimReward))
end

function RadarTaskButtonComponent:OnOpened()
end

function RadarTaskButtonComponent:OnClose()
    self.isSelected = false
    self.radartasktype = RADARTASK_TYPE.normal
    g_Game.EventManager:RemoveListener(EventConst.RADAR_TASK_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnRadarTaskStateChanged))
    g_Game.EventManager:RemoveListener(EventConst.RADAR_TASK_CLICKED, Delegate.GetOrCreate(self, self.OnRadarTaskClicked))
    g_Game.ServiceManager:RemoveResponseCallback(ReceiveRadarTaskRewardParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnClaimReward))
end

---OnFeedData
---@param param RadarTaskButtonData
function RadarTaskButtonComponent:OnFeedData(param)
    if not param then
        return
    end

    self.uiPos = param.uiPos
    if param.iconName then
        self.iconName = param.iconName
    end
    self.isSelected = false
    self.isShake = false
    self:RefreshData(param.customData)
end

function RadarTaskButtonComponent:RefreshData(customData)
    self.customData = customData
    self:InitRadarTaskButton(self.customData)

    local cfg = ConfigRefer.RadarTask:Find(customData.RadarTaskId)
    if (cfg:IsManual() or cfg:IsElite()) and ModuleRefer.RadarModule:GetManualRadarTaskLock() then
        local targets = ModuleRefer.RadarModule:GetManualRadarTasks()
        local isFind = false
        for i = 1, #targets do
            if targets[i] == customData.RadarTaskId then
                isFind = true
                break
            end
        end
        self.btnRadarTask:SetVisible(not isFind)
    elseif ModuleRefer.RadarModule:GetRadarEventLock() then
        local id = ModuleRefer.RadarModule:GetSpecialTaskId()
        if id == customData.ID then
            self.btnRadarTask:SetVisible(false)
        else
            self.btnRadarTask:SetVisible(true)
        end
    else
        self.btnRadarTask:SetVisible(true)
    end
end

function RadarTaskButtonComponent:ShowBubble()
    self.btnRadarTask:SetVisible(true)
    self.gameObject:SetActive(true)
end

function RadarTaskButtonComponent:InitRadarTaskButton(customData)
    self.ID = customData.ID
    self.entityID = customData.EntityId
    self.quality = customData.Quality
    self.radarTaskID = customData.RadarTaskId
    if customData.VanishTime then
        self.remainTime = customData.VanishTime.timeSeconds
    end
    self.type = customData.Type
    local radarTaskInfo = ConfigRefer.RadarTask:Find(customData.RadarTaskId)
    self.radarTaskInfo = radarTaskInfo
    if not radarTaskInfo then
        return
    end
    -- if radarTaskInfo:ObjectType() == ObjectType.SlgInteractor then
    --     local mineConf = ConfigRefer.Mine:Find(radarTaskInfo:ConfigIds(1))
    --     if not mineConf then
    --         return
    --     end
    --     if mineConf:MapInstanceId() > 0 then
    --         self.iconName = "sp_comp_icon_radar_se"
    --     else
    --         self.iconName = "sp_comp_icon_radar_collect"
    --     end
    -- elseif radarTaskInfo:ObjectType() == ObjectType.SlgCatchPet then
    --     self.iconName = "sp_comp_icon_radar_pet"
    -- elseif radarTaskInfo:ObjectType() == ObjectType.SlgMob then
    --     self.iconName = "sp_comp_icon_radar_monster"
    -- end
    self.iconName = radarTaskInfo:RadarTaskIcon()
    if self.customData.State == wds.RadarTaskState.RadarTaskState_CanReceiveReward then
        self.goRedDot:SetActive(true)
        if self.radartasktype == RADARTASK_TYPE.elite then
            self.eliteAnimTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
        else
            self.normalAnimTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
        end
    elseif self.radartasktype == RADARTASK_TYPE.creepNormal then
        self.normalAnimTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3)
    end

    self.imgFrameCyst.gameObject:SetActive(false)
    if self.radartasktype == RADARTASK_TYPE.creepNormal then
        g_Game.SpriteManager:LoadSprite("sp_comp_icon_radar_cyst", self.imgIconCyst)
        -- g_Game.SpriteManager:LoadSprite("sp_radar_farme_05", self.imgFrame)
        g_Game.SpriteManager:LoadSprite(QUALITY_COLOR[self.quality + 1], self.imgFrame)
        -- g_Game.SpriteManager:LoadSprite(QUALITY_COLOR_CYST[self.quality + 1], self.imgFrameCyst)
        self.imgIconCyst.gameObject:SetActive(true)
        self.imgIconStatus.gameObject:SetActive(false)
    elseif radarTaskInfo:IsSpecial() then
        if self.iconName == "" then
            local taskConfig = ConfigRefer.RadarTask:Find(self.radarTaskID)
            local itemGroupConfig = ConfigRefer.ItemGroup:Find(taskConfig:QualityExtReward(self.quality + 1))
            local itemGroup = itemGroupConfig:ItemGroupInfoList(1)
            self.iconName = ConfigRefer.Item:Find(itemGroup:Items()):Icon()
            self.gameObject.transform.localScale = CS.UnityEngine.Vector3.one * 1.3
        end
        g_Game.SpriteManager:LoadSprite(self.iconName, self.imgIconStatus)
        g_Game.SpriteManager:LoadSprite("sp_city_bubble_base_events", self.imgFrame)
        self.imgIconCyst.gameObject:SetActive(false)
        self.imgIconStatus.gameObject:SetActive(true)
    else
        g_Game.SpriteManager:LoadSprite(self.iconName, self.imgIconStatus)
        g_Game.SpriteManager:LoadSprite(QUALITY_COLOR[self.quality + 1], self.imgFrame)
        -- g_Game.SpriteManager:LoadSprite(QUALITY_COLOR_CYST[self.quality + 1], self.imgFrameCyst)
        self.imgIconCyst.gameObject:SetActive(false)
        self.imgIconStatus.gameObject:SetActive(true)
    end
    if not string.IsNullOrEmpty(radarTaskInfo:RadarTaskCitizenIcon()) then
        self.goGroupMission:SetActive(true)
        g_Game.SpriteManager:LoadSprite(radarTaskInfo:RadarTaskCitizenIcon(), self.imgMissionHead)
    else
        self.goGroupMission:SetActive(false)
    end

    if not string.IsNullOrEmpty(radarTaskInfo:RadarTaskRewardIcon()) then
        self.goPetReward:SetActive(true)
        g_Game.SpriteManager:LoadSprite(radarTaskInfo:RadarTaskRewardIcon(), self.imgPerReward)
    else
        self.goPetReward:SetActive(false)
    end

    if self.quality == 3 then
        self.normalAnimTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom5)
    else
        self.normalAnimTrigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom5)
    end

    if self:CheckIsMovingToRadarTask() then
        self:GoingToRadarTaskTarget()
    end
end

function RadarTaskButtonComponent:OnSelected(isSelected)
    if self.goFrameSelect then
        self.goFrameSelect:SetActive(isSelected)
    end
end

function RadarTaskButtonComponent:OnRadarTaskStateChanged(isGoing)
    if isGoing then
        self:GoingToRadarTaskTarget()
    else
        self:NoneRadarTaskTarget()
    end
end

function RadarTaskButtonComponent:OnRadarTaskClicked(entityID)
    if entityID ~= self.ID then
        self.isSelected = false
        self:OnSelected(self.isSelected)
    end
end

function RadarTaskButtonComponent:GoingToRadarTaskTarget()
    self:ChangeImageAlpha(self.imgFrame, 0.3)
    self:ChangeImageAlpha(self.imgIconStatus, 0.3)
end

function RadarTaskButtonComponent:NoneRadarTaskTarget()
    self:ChangeImageAlpha(self.imgFrame, 1)
    self:ChangeImageAlpha(self.imgIconStatus, 1)
end

function RadarTaskButtonComponent:ChangeImageAlpha(image, alpha)
    local color = image.color
    color.a = alpha
    image.color = color
end

function RadarTaskButtonComponent:CheckIsMovingToRadarTask()
    local troops = ModuleRefer.SlgModule:GetMyTroops() or {}
    for i, troop in ipairs(troops) do
        if troop.entityData and troop.entityData.MovePathInfo then
            local entityID = troop.entityData.MovePathInfo.TargetUID
            if self.customData and entityID == self.customData.EntityId and self.customData.EntityId ~= 0 then
                return true
            end
        end
    end
    return false
end

function RadarTaskButtonComponent:SetRadarTaskType(type)
    self.radartasktype = type
end

function RadarTaskButtonComponent:SendClaim()
    local radarTaskCfg = ConfigRefer.RadarTask:Find(self.customData.RadarTaskId)
    local has, need = ModuleRefer.RadarModule:GetRadarItemNum()
    -- 点击后会升级雷达 差一个电子元件时上锁
    if has + 1 == need then
        ModuleRefer.RadarModule:SetRadarTaskLock(true)
    end
    -- 点击后会完成个人事件 进度值90+时上锁
    local mapRadarTask = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.Radar.MapRadarTask
    local progress = mapRadarTask.Clue
    local rewardClue = radarTaskCfg:RewardClue()
    if progress + rewardClue >= 100 then
        ModuleRefer.RadarModule:SetRadarEventLock(true)
    end
    local parameter = ReceiveRadarTaskRewardParameter.new()
    parameter.args.RadarTaskCompId = self.customData.ID or 0
    parameter:Send()
end

function RadarTaskButtonComponent:OnBtnClicked()
    if self.customData.State == wds.RadarTaskState.RadarTaskState_CanReceiveReward then
        local radarTaskCfg = ConfigRefer.RadarTask:Find(self.customData.RadarTaskId)
        -- 追踪生物弹窗
        local desc = radarTaskCfg:TracePetDesc()
        local image = radarTaskCfg:TracePetImage()
        if desc ~= "" and image > 0 then
            g_Game.UIManager:Open(UIMediatorNames.RadarFindTraceMediator, {
                desc = desc,
                image = image,
                closeCallback = function()
                    self:SendClaim()
                end,
            })
            return
        end
        self:SendClaim()
        return
    end

    self.isSelected = true
    self:OnSelected(self.isSelected)

    ---@type RadarObjectDetailParam
    local param = {
        ID = self.customData.ID,
        entityID = self.customData.EntityId,
        radarTaskID = self.customData.RadarTaskId,
        taskState = self.customData.State,
        quality = self.customData.Quality,
        vanishTime = self.customData.VanishTime,
        worldPos = self.customData.Pos,
        type = self.customData.Type,
        uiPos = self.uiPos,
        entityType = self.customData.EntityType,
    }
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

function RadarTaskButtonComponent:OnClaimReward(isSuccess, reply, rpc)
    if not isSuccess then
        return
    end
    if self.customData then
        return
    end
    g_Game.EventManager:TriggerEvent(EventConst.RADAR_TASK_CLAIM_REWARD)
end

function RadarTaskButtonComponent:Shake()
    if self.isShake then
        return
    end
    self.isShake = true
    self.normalAnimTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2, function()
        self.isShake = false
    end)
end

function RadarTaskButtonComponent:GetRadarTaskID()
    return self.customData.RadarTaskId
end

function RadarTaskButtonComponent:GetRadarTaskInfo()
    return self.radarTaskInfo
end

return RadarTaskButtonComponent
