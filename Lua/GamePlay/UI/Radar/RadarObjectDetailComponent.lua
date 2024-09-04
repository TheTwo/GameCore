local TimeFormatter = require ('TimeFormatter')
local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local ProgressType = require('ProgressType')
local KingdomMapUtils = require('KingdomMapUtils')
local UIMediatorNames = require('UIMediatorNames')
local GuideFingerUtil = require("GuideFingerUtil")
local DBEntityType = require("DBEntityType")
local TimerUtility = require("TimerUtility")
local ObjectType = require("ObjectType")
local ColorConsts = require("ColorConsts")

---@class RadarObjectDetailComponent : BaseUIComponent
local RadarObjectDetailComponent = class('RadarObjectDetailComponent', BaseUIComponent)

---@class RadarObjectDetailParam
---@field ID number
---@field entityID number
---@field radarTaskID number
---@field taskState wds.RadarTaskState
---@field quality number
---@field vanishTime google.protobuf.Timestamp
---@field worldPos wds.Vector3F
---@field expeditionInfo wrpc.RadarScanResultExpedition
---@field type number
---@field entityType number
---@field isAlliance boolean

local QUALITY_NAME = {
    'leida_putong',
    'leida_gaoji',
    'leida_xiyou',
    'leida_chuanshuo',
}
local QUALITY_COLOR = {
    UIHelper.TryParseHtmlString(ColorConsts.quality_green),
    UIHelper.TryParseHtmlString(ColorConsts.quality_blue),
    UIHelper.TryParseHtmlString(ColorConsts.quality_purple),
    UIHelper.TryParseHtmlString(ColorConsts.quality_orange),
}
local WORLD_EVENT_COLOR = UIHelper.TryParseHtmlString("#FF4777")

local OBJECT_TYPE = {
    RadarTask = 0,
    WorldEvent = 1,
    MistTask = 2,
    CreepNormalTask = 3,
    CreepUnlockTask = 4,
}

function RadarObjectDetailComponent:OnCreate()
    --name
    self.textName = self:Text('p_text_name')

    --info
    self.goGroupQuality = self:GameObject('group_quality')
    self.textGroupQuality = self:Text('p_text_quality', I18N.Get("Radar_tips_quality"))
    self.textGroupQualityVal = self:Text('p_text_quality_1')
    self.goGroupType = self:GameObject('p_group_type')
    self.textGroupType = self:Text('p_text_type', I18N.Get("Radar_tips_type"))
    self.textGroupTypeVal = self:Text('p_text_type_1')
    self.goGroupLv = self:GameObject('group_lv')
    self.textGroupLv = self:Text('p_text_lv_info', I18N.Get("Radar_tips_level"))
    self.textGroupLvVal = self:Text('p_text_lv_info_1')
    self.goGroupTime = self:GameObject('group_time')
    -- self.textGroupTime = self:Text('p_text_time', I18N.Get("Radar_tips_timeleft"))
    self.textGroupTimeVal = self:Text('p_text_time')
    self.goClueReward = self:GameObject('group_reward')
    self.textClueReward = self:Text('p_text_reward_quantity', I18N.Get("clue_value_reward"))
    self.textClueRewardVal = self:Text('p_text_reward_1')
    self.textContent = self:Text('p_text_content')
    self.goLandform = self:GameObject('group_landform')
    self.textLandformTitle = self:Text('p_text_title_landform', I18N.Get("bw_info_radartask_land"))
    -- self.textLandformName = self:Text('p_text_landform')

    self.goEvent = self:GameObject('p_event')
    self.textEvent = self:Text('p_text_event', I18N.Get("Radar_tips_multiplayerevent"))
    self.goTime = self:GameObject('p_time')
    self.textTime = self:Text('p_text_time_1')
    self.btnLandform = self:Button('group_landform', Delegate.GetOrCreate(self, self.OnBtnLandformClicked))
    self.imgLandform = self:Image('p_img_landform')
    self.textLandform = self:Text('p_text_landform')

    --reward
    self.textReward = self:Text('p_text_reward', I18N.Get("Radar_tips_Rewards"))
    self.tableviewproReward = self:TableViewPro('p_table_reward')
    self.goReward = self:GameObject('p_table_reward')
    self.goGroupHint = self:GameObject('p_group_hint')

    --btn
    self.goProgress = self:GameObject('p_progress')
    self.textProgress = self:Text('p_text_progress')
    self.textProgressNum = self:Text('p_text_progress_num')
    self.btnGoto = self:Button('p_comp_btn_goto', Delegate.GetOrCreate(self,self.OnBtnGotoClicked))
    self.textGoto = self:Text('p_text', I18N.Get("Radar_btn_goto"))
    self.textGoingto = self:Text('p_text_doing', I18N.Get("Radar_tips_marching"))
    self.btnClaim = self:Button('p_comp_btn_claim', Delegate.GetOrCreate(self,self.OnBtnClaimClicked))
    self.textClaim = self:Text('p_text_claim', I18N.Get("Radar_btn_claim"))

    self.goGroupHint:SetVisible(false)
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.SecondUpdate))

end

function RadarObjectDetailComponent:OnOpened(param)
end


function RadarObjectDetailComponent:OnClose(param)
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecondUpdate))
    if self.timer then
        self.timer:Stop()
        self.timer = nil
    end
end

---@param param RadarObjectDetailParam
function RadarObjectDetailComponent:RefreshGroupInfo(param)
    self.goGroupQuality:SetActive(false)
    self.goGroupType:SetActive(false)
    self.goGroupLv:SetActive(false)
    self.goClueReward:SetActive(false)
    -- self.goLandform:SetActive(false)
    self.goProgress:SetActive(false)
    self.finishTime = 0
    self.type = OBJECT_TYPE.RadarTask
    if param.type then
        self.type = param.type
    end
    self.ID = param.ID
    self.entityID = param.entityID
    self.entityType = param.entityType
    self.radarTaskID = param.radarTaskID
    self.taskState = param.taskState
    self.quality = param.quality
    if param.vanishTime then
        self.finishTime = param.vanishTime.timeSeconds
    end
    self.worldPos = param.worldPos
    if self.type == OBJECT_TYPE.WorldEvent and param.expeditionInfo then
        self.isWorldEventBubble = true
        self.expeditionInfo = param.expeditionInfo
        self.entityID = param.expeditionInfo.EntityID
        self.progress = param.expeditionInfo.PersonalProgress
        self.quality = param.expeditionInfo.Quality
        self.eventID = param.expeditionInfo.CfgId
        self.finishTime = param.expeditionInfo.ActivateEndTime
        self.isAlliance = param.isAlliance
        
        --特殊处理 大嘴鸟 小事件
        if ModuleRefer.WorldEventModule:IsExpeditionUseItem(param.expeditionInfo.CfgId) then
            local cfgId = ModuleRefer.WorldEventModule:GetPersonalOwnAllianceExpedition()
            local activityId = ConfigRefer.AllianceActivityExpedition:Find(cfgId):DisplayTime()
            local startT,endT = ModuleRefer.WorldEventModule:GetActivityCountDown(activityId)
            self.finishTime = endT
        end
    end

    self.tableviewproReward:Clear()
    self.textReward.gameObject:SetActive(true)
    self.textReward.text = I18N.Get("Radar_tips_Rewards")
    self.goReward:SetActive(true)
    self.textName.color = QUALITY_COLOR[self.quality + 1]
    if self.type == OBJECT_TYPE.WorldEvent then
        -- self.goGroupLv:SetActive(true)
        -- self.goGroupType:SetActive(true)

        local eventCfg = ConfigRefer.WorldExpeditionTemplate:Find(self.eventID)
        self.worldEventLv = eventCfg:Level()
        self.expeditionType = eventCfg:ProgressType()
        if self.isAlliance and self.expeditionType == ProgressType.Alliance then
            self.textName.text = I18N.Get(eventCfg:Name())
            self.textName.color = WORLD_EVENT_COLOR
            self.textContent.text = I18N.Get(eventCfg:Des())
            self.textGroupQualityVal.text = I18N.Get(QUALITY_NAME[self.quality + 1])
            self.textGroupQualityVal.color = QUALITY_COLOR[self.quality + 1]
            local isBigEvent = ModuleRefer.WorldEventModule:IsAllianceBigWorldEvent(self.eventID)
            if isBigEvent then
                self.textGroupTypeVal.text = I18N.Get("bw_info_radartask_event_name1")
            else
                self.textGroupTypeVal.text = I18N.Get("bw_info_radartask_event_name2")
            end

            --这个state字段只有联盟事件才会有, 个人事件不会有
            if self.expeditionInfo.State and self.expeditionInfo.State == wds.ExpeditionState.ExpeditionNotice then
                self.textGoingto.text = I18N.Get("bw_info_worldtask_allianceaccept")
                self.textGoingto:SetVisible(true)
            else
                self.textGoingto:SetVisible(false)
                if self.progress and self.progress > 0 then
                    self.goProgress:SetActive(true)
                    self.textProgress.text = I18N.Get("bw_info_radartask_event_progress")
                    local percent = math.clamp(self.progress / eventCfg:MaxProgress(), 0, 1)
                    self.textProgressNum.text = percent * 100 .. "%"
                end
            end
            self.btnGoto.gameObject:SetActive(true)
            self.btnClaim.gameObject:SetActive(false)
            self.textReward.text = I18N.Get("bw_info_radartask_event_reward")
            self:ShowAllianceWorldEventReward(eventCfg)
        else
            local taskConfig = ConfigRefer.RadarTask:Find(self.radarTaskID)
            if not taskConfig then
                return
            end
            self.textName.text = I18N.Get(taskConfig:Name())
            self.textContent.text = I18N.Get(taskConfig:Des())
            if self.expeditionType == ProgressType.Personal then
                self.textGroupTypeVal.text = I18N.Get("Radar_tips_personalevent")
            elseif self.expeditionType == ProgressType.Whole then
                self.textGroupTypeVal.text = I18N.Get("Radar_tips_multiplayerevent")
            end
            self.textGroupLvVal.text = self.worldEventLv
            self.textGroupQualityVal.text = I18N.Get(QUALITY_NAME[self.quality + 1])
            self.textGroupQualityVal.color = QUALITY_COLOR[self.quality + 1]
    
            if self.taskState == wds.RadarTaskState.RadarTaskState_CanReceiveReward then
                self.btnGoto.gameObject:SetActive(false)
                self.btnClaim.gameObject:SetActive(true)
                self.goProgress:SetActive(true)
                self.textProgress.text = I18N.Get("WorldExpedition_info_completed_progress")
                self.textProgressNum.text = "100%"
            else
                if self.progress and self.progress > 0 then
                    self.goProgress:SetActive(true)
                    self.textProgress.text = I18N.Get("WorldExpedition_info_completed_progress")
                    local percent = math.clamp(self.progress / eventCfg:MaxProgress(), 0, 1)
                    self.textProgressNum.text = percent * 100 .. "%"
                end
                self.btnGoto.gameObject:SetActive(true)
                self.btnClaim.gameObject:SetActive(false)
            end
    
            local itemGroupConfig = ConfigRefer.ItemGroup:Find(taskConfig:QualityExtReward(self.quality + 1))
            if itemGroupConfig then
                local additionRewardLength = itemGroupConfig:AdditionRuleLength()

                if additionRewardLength > 0 then
                    for k = 1, additionRewardLength do
                        local additionReward = itemGroupConfig:AdditionRule(k)
                        local additionRewardCfg = ConfigRefer.ItemGroupAdditionReward:Find(additionReward)
                        for i = 1, additionRewardCfg:RewardsLength() do
                        local info = additionRewardCfg:Rewards(i)
                        local activity = info:RelatedActivity()
                        local isOpen = ModuleRefer.ActivityCenterModule:IsActivityTemplateOpen(activity)
                            if isOpen then
                                local itemGroup = ConfigRefer.ItemGroup:Find(info:FixedReward())
                                for j = 1, itemGroup:ItemGroupInfoListLength() do
                                    local itemGroup = itemGroup:ItemGroupInfoList(j)
                                    self.tableviewproReward:AppendData({configCell = ConfigRefer.Item:Find(itemGroup:Items()), count = itemGroup:Nums(), showTips = true})
                                end
                            end
                        end
                    end
                end
                for i = 1, itemGroupConfig:ItemGroupInfoListLength() do
                    local itemGroup = itemGroupConfig:ItemGroupInfoList(i)
                    self.tableviewproReward:AppendData({configCell = ConfigRefer.Item:Find(itemGroup:Items()), count = itemGroup:Nums(), showTips = true})
                end
            end
        end
    else
        local taskConfig = ConfigRefer.RadarTask:Find(self.radarTaskID)
        if not taskConfig then
            return
        end
        
        if self.type == OBJECT_TYPE.CreepNormalTask then
            self.textName.text = I18N.Get("creep_tips_taskname")
            self.textContent.text = I18N.Get("creep_info_task_des")
            self.goClueReward:SetActive(false)
            self.textGroupQualityVal.text = I18N.Get("???")
            self.finishTime = -1
            self.textReward.gameObject:SetActive(false)
            self.goReward:SetActive(false)
        elseif self.type == OBJECT_TYPE.CreepUnlockTask then
            local configID = ModuleRefer.RadarModule:GetCreepConfigIDByEntityID(self.entityID)
            local crerpConfig = ConfigRefer.SlgCreepTumor:Find(configID)
            if crerpConfig then
                self.textName.text = I18N.Get(crerpConfig:TransformName())
                self.textContent.text = I18N.Get(crerpConfig:TransformDesc())
            end
            -- self.goClueReward:SetActive(true)
            self.textClueRewardVal.text = taskConfig:RewardClue()
            self.textGroupQualityVal.text = I18N.Get(QUALITY_NAME[self.quality + 1])
            self.textGroupQualityVal.color = QUALITY_COLOR[self.quality + 1]
            self.finishTime = -1
        else
            self.textName.text = I18N.Get(taskConfig:Name())
            self.textContent.text = I18N.Get(taskConfig:Des())
            -- self.goClueReward:SetActive(true)
            self.textClueRewardVal.text = taskConfig:RewardClue()
            self.textGroupQualityVal.text = I18N.Get(QUALITY_NAME[self.quality + 1])
            self.textGroupQualityVal.color = QUALITY_COLOR[self.quality + 1]
        end

        local itemGroupConfig = ConfigRefer.ItemGroup:Find(taskConfig:QualityExtReward(self.quality + 1))
        if itemGroupConfig then
            local additionRewardLength = itemGroupConfig:AdditionRuleLength()
                if additionRewardLength > 0 then
                    for k = 1, additionRewardLength do
                        local additionReward = itemGroupConfig:AdditionRule(k)
                        local additionRewardCfg = ConfigRefer.ItemGroupAdditionReward:Find(additionReward)
                        for i = 1, additionRewardCfg:RewardsLength() do
                        local info = additionRewardCfg:Rewards(i)
                        local activity = info:RelatedActivity()
                        local isOpen = ModuleRefer.ActivityCenterModule:IsActivityTemplateOpen(activity)
                            if isOpen then
                                local itemGroup = ConfigRefer.ItemGroup:Find(info:FixedReward())
                                for j = 1, itemGroup:ItemGroupInfoListLength() do
                                    local itemGroup = itemGroup:ItemGroupInfoList(j)
                                    self.tableviewproReward:AppendData({configCell = ConfigRefer.Item:Find(itemGroup:Items()), count = itemGroup:Nums(), showTips = true})
                                end
                            end
                        end
                    end
                end
            for i = 1, itemGroupConfig:ItemGroupInfoListLength() do
                local itemGroup = itemGroupConfig:ItemGroupInfoList(i)
                self.tableviewproReward:AppendData({configCell = ConfigRefer.Item:Find(itemGroup:Items()), count = itemGroup:Nums(), showTips = true})
            end
        end

        if self.taskState == wds.RadarTaskState.RadarTaskState_CanReceiveReward then
            --可领奖
            self.btnGoto.gameObject:SetActive(false)
            self.btnClaim.gameObject:SetActive(true)
            self:SetClaimBtnEnable(true)
        elseif self.taskState == wds.RadarTaskState.RadarTaskState_Received then
            --GOTO
            self.btnGoto.gameObject:SetActive(true)
            self.btnClaim.gameObject:SetActive(false)
        end
        --判断是否行军中
        if self:CheckIsMovingToRadarTask() then
            self.btnGoto.gameObject:SetActive(false)
            self.btnClaim.gameObject:SetActive(false)
            self.textGoingto.gameObject:SetActive(true)
            self.textGoingto.text = I18N.Get("Radar_tips_marching")
        end
    end
    self:CheckNeedShowLandform()

    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local remainTime = self.finishTime - curTime
    --剩余时间大于24小时也视为永久事件，不显示时间
    if remainTime < 0 or remainTime > 86400 then
        remainTime = 0
    end
    self.goTime:SetActive(remainTime > 0 and self.taskState ~= wds.RadarTaskState.RadarTaskState_CanReceiveReward and 
        (self.type ~= OBJECT_TYPE.CreepNormalTask or self.type ~= OBJECT_TYPE.CreepUnlockTask))
    --永久事件不显示时间
    if self.finishTime <= 0 or self.taskState == wds.RadarTaskState.RadarTaskState_CanReceiveReward then
        return
    end
    if remainTime >= TimeFormatter.OneHourSeconds then
        self.textTime.text = math.floor(remainTime / TimeFormatter.OneHourSeconds) .. I18N.Get("h")
        self.canRefresh = false
    elseif remainTime <= 0 then
        self.canRefresh = false
        -- g_Game.EventManager:TriggerEvent(EventConst.REFRESH_RADAR_TASK)
    else
        self.textTime.text = TimeFormatter.SimpleFormatTimeWithoutHour(remainTime)
        self.canRefresh = true
    end
end

function RadarObjectDetailComponent:SecondUpdate()
	self:RefresRemainTime()
end

function RadarObjectDetailComponent:SetClaimBtnEnable(enable)
    self.btnClaim.interactable = enable
end

function RadarObjectDetailComponent:RefresRemainTime()
    if not self.canRefresh then
        return
    end
	local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local remainTime = self.finishTime - curTime
    if remainTime >= TimeFormatter.OneHourSeconds then
        self.canRefresh = false
    elseif remainTime < 0 then
        remainTime = 0
        self.canRefresh = false
        -- g_Game.EventManager:TriggerEvent(EventConst.REFRESH_RADAR_TASK)
    else
        self.textGroupTimeVal.text = TimeFormatter.SimpleFormatTimeWithoutHour(remainTime)
        self.textTime.text = TimeFormatter.SimpleFormatTimeWithoutHour(remainTime)
    end
end


function RadarObjectDetailComponent:OnBtnGotoClicked(args)
    local cfg = ConfigRefer.RadarTask:Find(self.radarTaskID)
    if not cfg then
        if self.isWorldEventBubble then
            ModuleRefer.WorldEventModule:GotoUseItemExpedition()
            return
        else
            return
        end
    end
    --内城雷达
    if cfg:IsCityRadarTask() then
        local city = ModuleRefer.CityModule.myCity
        local element = city.elementManager:GetElementById(self.entityID)
        if element == nil then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("story_explore_7day_talk5_4"))
            return
        end
        local cityPos = city:GetWorldPositionFromCoord(element.x,element.y)
        local size = city.camera:GetMaxSize()
        local duration = ConfigRefer.ConstBigWorld:CityRadarCameraMoveDuration()
        city.camera:ForceGiveUpTween()
        city.camera:LookAt(cityPos, duration)
        city.camera:ZoomTo(size, duration)
        local offset = CS.UnityEngine.Vector3(0,150,0)

        TimerUtility.DelayExecute(function()
            GuideFingerUtil.ShowGuideFingerByWorldPos(cityPos, offset)
        end,duration)

        g_Game.UIManager:CloseAllByName(UIMediatorNames.RadarMediator)
        return
    end

    local radarMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.RadarMediator)
    if radarMediator then
        if radarMediator.IsInCity then
            -- radarMediator:ChangInCityState(false)
            -- radarMediator.basicCamera.ignoreLimit = false
            -- radarMediator.basicCamera.enablePinch = true
            local scene = g_Game.SceneManager.current
            local callback = function()
                self:RequestForConflictCoordCheck(self.entityType, self.entityID)
            end
            g_Game.UIManager:CloseAllByName(UIMediatorNames.RadarMediator)
            scene:LeaveCity(callback)
            return
        end
    end

    self:RequestForConflictCoordCheck(self.entityType, self.entityID)
end

function RadarObjectDetailComponent:RequestForConflictCoordCheck(entityType, id)
    entityType, id = ModuleRefer.RadarModule:GetRadarTaskObjectTypeAndID(entityType, id)
    local parameter = require("RelocatePersonalEntityParameter").new()
    parameter.args.Id = id
    parameter.args.ObjectType = entityType

    if ModuleRefer.RadarModule:IsRadarTaskNeedRelocate(entityType, id) then
        parameter:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, success, response)
            ---@type wrpc.RelocatePersonalEntityResult
            local result = response.Result
            self.entityID = result.Id
            self.entityType = result.ObjectType
            ModuleRefer.MapUnitModule:AddRelocatedPlayerUnit(self.entityType, self.entityID)
            local taskInfo = ModuleRefer.RadarModule:GetRadarTaskInfoByID(self.ID)
            local x, z
            if taskInfo then
                x, z = KingdomMapUtils.ParseCoordinate(taskInfo.Pos.X, taskInfo.Pos.Y)
            else
                x, z  = KingdomMapUtils.ParseCoordinate(self.worldPos.X, self.worldPos.Y)
            end
            self:DoClick(x, z)
        end)
    else
        local x, z
        if self.type == OBJECT_TYPE.WorldEvent then
            x, z  = KingdomMapUtils.ParseCoordinate(self.expeditionInfo.X, self.expeditionInfo.Y)
        else
            x, z  = KingdomMapUtils.ParseCoordinate(self.worldPos.X, self.worldPos.Y)
        end
        self:DoClick(x, z)
    end
end

function RadarObjectDetailComponent:DoClick(x, z)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.RadarMediator)
    local camerMoveCallBack = nil
    local pos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(x,z, KingdomMapUtils.GetMapSystem())
    local offset
    if self.type == OBJECT_TYPE.WorldEvent then
        local mapBasic = self:GetRandomWorldEventMobPos()
        if mapBasic then
            local tempx, tempz  = KingdomMapUtils.ParseCoordinate(mapBasic.Position.X, mapBasic.Position.Y)
            pos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(tempx,tempz, KingdomMapUtils.GetMapSystem())
        end
    else
        offset = CS.UnityEngine.Vector3(0,200,0)
    end

    camerMoveCallBack = function()
        GuideFingerUtil.ShowGuideFingerByWorldPos(pos, offset)
        if not ModuleRefer.MapFogModule:IsFogUnlocked(x, z) then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("Radar_mist_condition"))
            return
        end
    end

    local myCityCoord = ModuleRefer.PlayerModule:GetCastle().MapBasics.Position
    local dis = (x - myCityCoord.X) ^ 2 + (z - myCityCoord.Y) ^ 2
    local size = ConfigRefer.ConstBigWorld:RadarGotoNormalCameraSize()
    if dis > ConfigRefer.ConstBigWorld:RadarGotoHighCameraSizeDis() then
        size = ConfigRefer.ConstBigWorld:RadarGotoHighCameraSize()
    end

    KingdomMapUtils.GetBasicCamera():ForceGiveUpTween()
    KingdomMapUtils.GetBasicCamera():ZoomTo(size, ConfigRefer.ConstBigWorld:RadarGotoZoomToSizeDuration(), function()
        KingdomMapUtils.GetBasicCamera():LookAt(pos, ConfigRefer.ConstBigWorld:RadarGotoLookAtPosDuration(), camerMoveCallBack)
    end)
end

function RadarObjectDetailComponent:OnBtnClaimClicked(args)
    self:SetClaimBtnEnable(false)
    self.timer = TimerUtility.DelayExecute(function()
        self:SetClaimBtnEnable(true)
    end, 0.5)
    -- local parameter = ReceiveRadarTaskRewardParameter.new()
    -- parameter.args.RadarTaskCompId = self.ID or 0
    -- parameter:Send()
end

function RadarObjectDetailComponent:GetRandomWorldEventMobPos()
    ---@type wds.MapMob
    local troops = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.MapMob)
    for _, troop in pairs(troops) do
        if troop.Owner.SpawnerId == self.entityID then
            return troop.MapBasics
        end
    end
end

function RadarObjectDetailComponent:CheckIsMovingToRadarTask()
    local troops = ModuleRefer.SlgModule:GetMyTroops() or {}
    for i, troop in ipairs(troops) do
        if troop.entityData and troop.entityData.MovePathInfo then
            local entityID = troop.entityData.MovePathInfo.TargetUID
            if self.entityID and entityID == self.entityID and self.entityID ~= 0 then
                 return true
            end
        end
    end
    return false
end

function RadarObjectDetailComponent:CheckNeedShowLandform()
    local x, z
    if self.type == OBJECT_TYPE.WorldEvent then
        x, z  = KingdomMapUtils.ParseCoordinate(self.expeditionInfo.X, self.expeditionInfo.Y)
    else
        x, z  = KingdomMapUtils.ParseCoordinate(self.worldPos.X, self.worldPos.Y)
    end
    local landCfgId = ModuleRefer.TerritoryModule:GetLandCfgIdAt(x, z)
    if landCfgId == nil or landCfgId == -1 then
        landCfgId = ModuleRefer.LandformModule:GetMyLandCfgId()
        -- self.goLandform:SetVisible(false)
        -- return
    end
    self.goLandform:SetVisible(true)
    self.selectLandCfgId = landCfgId
    local landCfgCell = ConfigRefer.Land:Find(landCfgId)
    if landCfgCell then
        g_Game.SpriteManager:LoadSprite(landCfgCell:Iconbg(), self.imgLandform)
        self.textLandform.text = I18N.Get(landCfgCell:Name())
    end
end

function RadarObjectDetailComponent:ShowAllianceWorldEventReward(eventCfg)
    if not eventCfg then
        return
    end
    local items = {}

    local target = ModuleRefer.WorldEventModule:GetPersonalOwnAllianceExpedition()
    local allianceCfg = ConfigRefer.AllianceActivityExpedition:Find(target)
        for i = 1, allianceCfg:PreviewRewardItemIdsLength() do
            local item = ConfigRefer.Item:Find(allianceCfg:PreviewRewardItemIds(i))
            local id = item:Id()
            -- items[id] = 1
            table.insert(items,id)
        end
    
    -- for i = 1, eventCfg:PartProgressRewardLength() do
    --     local rewards = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(eventCfg:PartProgressReward(i):Reward()) or {}
    --     for k, v in ipairs(rewards) do
    --         local id = v.configCell:Id()
    --         if items[id] then
    --             items[id] = items[id] + v.count
    --         else
    --             items[id] = v.count
    --         end
    --     end
    -- end
    -- for i = 1, eventCfg:AlliancePartProgressRewardLength() do
    --     local rewards = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(eventCfg:AlliancePartProgressReward(i):Reward()) or {}
    --     for k, v in ipairs(rewards) do
    --         local id = v.configCell:Id()
    --         if items[id] then
    --             items[id] = items[id] + v.count
    --         else
    --             items[id] = v.count
    --         end
    --     end
    -- end
    for k, v in pairs(items) do
        local itemConfig = ConfigRefer.Item:Find(v)
        self.tableviewproReward:AppendData({configCell = itemConfig, showCount = false, showTips = true})
    end
end

function RadarObjectDetailComponent:OnBtnLandformClicked()
    --外城雷达未解锁时 屏蔽圈层跳转
    local isCityRadar = ModuleRefer.RadarModule:IsCityRadar()
    if isCityRadar then
        return
    end
    g_Game.UIManager:Open(UIMediatorNames.LandformIntroUIMediator)
end

return RadarObjectDetailComponent