local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local ModuleRefer = require("ModuleRefer")
local I18N = require('I18N')
local BuildingType = require('BuildingType')
local ConfigRefer = require('ConfigRefer')
local KingdomMapUtils = require('KingdomMapUtils')
local DBEntityPath = require('DBEntityPath')
local EventConst = require('EventConst')
local UIMediatorNames = require('UIMediatorNames')
local RadarScanParameter = require('RadarScanParameter')
local RadarLevelUpParameter = require('RadarLevelUpParameter')
local NpcServiceType = require('NpcServiceType')
local SceneType = require('SceneType')
local Utils = require('Utils')
local CityConst = require('CityConst')
local MapUtils = CS.Grid.MapUtils
local UIHelper = require('UIHelper')
local NotificationType = require('NotificationType')
local TimerUtility = require('TimerUtility')
local RadarTaskUtils = require('RadarTaskUtils')
local ObjectType = require('ObjectType')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local ArtResourceUtils = require('ArtResourceUtils')
local MathUtils = require('MathUtils')
local LuaReusedComponentPool = require('LuaReusedComponentPool')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local Ease = CS.DG.Tweening.Ease
local ProtocolId = require('ProtocolId')
local TimeFormatter = require("TimeFormatter")
local UIAsyncDataProvider = require("UIAsyncDataProvider")

---@class RadarMediator : BaseUIMediator
local RadarMediator = class('RadarMediator', BaseUIMediator)

---@class RadarMediatorParam
---@field isInCity boolean
---@field stack ZoomToWithFocusStackStatus
---@field enterSelectBubbleType number
---@field mustSelectTarget boolean

function RadarMediator:OnCreate()
    self.transform = self:Transform('')
    self.compChildCommonBack = self:LuaObject('child_common_btn_back')
    self.goImgSelectIntel = self:GameObject('p_img_select_intel')
    self.goImgSelectMonster = self:GameObject('p_img_select_monster')
    self.goImgSelectResoures = self:GameObject('p_img_select_resoures')
    self.goImgSelectPet = self:GameObject('p_img_select_pet')
    self.goImgSelectTown = self:GameObject('p_img_select_town')

    self.btnEnergy = self:Button('p_btn_energy', Delegate.GetOrCreate(self, self.OnBtnEnergyClicked))
    self.textNumber = self:Text('p_text_number')
    self.btnRadarUpgrade = self:Button('p_btn_radar_upgrade', Delegate.GetOrCreate(self, self.OnBtnRadarUpgradeClicked))
    self.textLv = self:Text('p_text_lv')
    self.p_text_lv_0 = self:Text('p_text_lv_0', "Lvl.")
    self.goIconUpgrade = self:GameObject('p_icon_upgrade')
    self.goMax = self:GameObject('p_max')
    self.textMax = self:Text('p_text_max', I18N.Get("leida_manji"))

    self.goImgSelectSe = self:GameObject('p_img_select_se')
    self.goImgSelectEvent = self:GameObject('p_img_select_event')
    self.goImgSelectMonsterCity = self:GameObject('p_img_select_monster_city')
    self.goImgSelectCity = self:GameObject('p_img_select_city')

    self.textRadar = self:Text('p_text_radar', I18N.Get("radar_level_num"))

    self.textLevel = self:Text('p_text_level', I18N.Get("leida_dangqiandengji"))

    self.goScrollLvContent = self:GameObject('p_scroll_lv_content')
    self.goItemLv = self:GameObject('p_item_lv')
    self.btnAll = self:Button('p_btn_all', Delegate.GetOrCreate(self, self.OnBtnAllClicked))
    self.goSelectAll = self:GameObject('p_select_all')
    self.textAllSelect = self:Text('p_text_all_select', I18N.Get("leida_all"))
    self.textAll = self:Text('p_text_all', I18N.Get("leida_all"))
    self.goGroupSelect = self:GameObject('p_group_select')

    -- Left Group
    self.textInfo = self:Text('p_text_info', I18N.Get("Radar_info_intelligence"))
    self.textSearch = self:Text('p_text_search', I18N.Get("Radar_info_search"))
    self.goImgSelectInfo = self:GameObject('p_img_select_info')
    self.btnSelectInfo = self:Button('p_btn_info', Delegate.GetOrCreate(self, self.OnBtnInfoClicked))

    self.textEventTitle = self:Text('p_title_event', I18N.Get("bw_info_radarsystem_1"))

    -- TopRight Group
    self.btnAddEnergy = self:Button('p_btn_add', Delegate.GetOrCreate(self, self.OnBtnAddEnergyClicked))
    self.goQuantity = self:GameObject('p_quantity')
    self.textInfoQuantity = self:Text('p_text_quantity', I18N.Get("Radar_info_amount"))
    self.textInfoQuantityNum = self:Text('p_text_quantity_num')
    self.textRefreshTime = self:Text('p_text_refresh', I18N.Get("Radar_info_refresh"))
    self.timeComp = self:LuaObject('child_time')

    self.compExploreFog = self:LuaObject('p_explor_fog')
    self.goExploreFog = self:GameObject('p_explor_fog')
    -- BottomRight Group
    self.textInfoProgress = self:Text('p_text_info_progress')
    self.infoProgressSlider = self:BindComponent("p_progress_info", typeof(CS.UnityEngine.UI.Slider))

    -- Empty Group
    self.goEmpty = self:GameObject('p_info_empty')
    self.btnEmptyGuide = self:Button('p_btn_empty_guide', Delegate.GetOrCreate(self, self.OnBtnEmptyGuideClicked))
    self.textEmptyGuide = self:Text('p_text_guide', I18N.Get("village_btn_confirm_proxy"))
    self.goBase = self:GameObject('base')
    self.textEmpty = self:Text('p_text_empty', I18N.Get("Radar_tips_finish"))
    self.timeCompEmpty = self:LuaBaseComponent('child_time_1')
    self.btnEmptyPos = self:Button('p_btn_empty', Delegate.GetOrCreate(self, self.OnBtnEmptyPosClicked))
    self.goBubbleBtnParent = self:GameObject('p_btn_empty')
    self.goBubbleBtnBase = self:GameObject('node_eff')

    self.goRadarTaskItem = self:LuaBaseComponent('p_bubble_radar_info')
    self.goWorldEventItem = self:LuaBaseComponent('p_bubble_fake_world_events')
    self.rectRadarTaskItem = self:RectTransform('p_bubble_radar_info')
    self.rectWorldEventItem = self:RectTransform('p_bubble_fake_world_events')

    -- DetailInfo
    self.goGroupInfo = self:GameObject('p_group_info')
    self.luagoGroupInfo = self:LuaObject('p_group_info')

    -- VX
    self.animBaseTrigger = self:AnimTrigger("vx_trigger")
    self.infoProgressTrigger = self:AnimTrigger("Trigger_progress")
    self.upgradeTrigger = self:AnimTrigger("trigger_upgrade")

    self.selectCity = {self.goImgSelectSe, self.goImgSelectEvent, self.goImgSelectMonsterCity, self.goImgSelectCity}
    self.selects = {self.goImgSelectIntel, self.goImgSelectMonster, self.goImgSelectResoures, self.goImgSelectPet, self.goImgSelectTown, self.goImgSelectInfo}

    self.p_btn_quantity = self:Button('p_btn_quantity', Delegate.GetOrCreate(self, self.OnBtnNextRefresh))
    self.btnEvent = self:Button('p_btn_event', Delegate.GetOrCreate(self, self.OnBtnClickEggDetail))

    self.p_text_new_pet = self:Text('p_text_new_pet', 'village_newpet_after_occupied')
    self.p_img_pet = self:Image('p_img_pet')
    self.p_base_frame = self:Image('p_base_frame')

    -- 背景图
    self.bg = self:GameObject('bg')
    self.bg_outside = self:GameObject('bg_outside')

    self.p_info_progress = self:GameObject('p_info_progress')

    -- 新增雷达追踪
    self.p_icon = self:Image('p_icon')
    self.p_text_status = self:Text('p_text_status', 'radartrack_info_to_track')
    self.p_btn_goto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnBtnClickGotoTrace))
    self.child_reddot_default = self:LuaObject('child_reddot_default')
    self.p_group_popup = self:GameObject('p_group_popup')
    ---@type RadarPetTraceIconComp
    self.popup_1 = self:LuaObject("popup_1")
    self.popup_2 = self:LuaObject("popup_2")
    self.popup_3 = self:LuaObject("popup_3")
    self.tracingPets = {self.popup_1, self.popup_2, self.popup_3}
    self.p_text_trace_time = self:Text('p_text_trace_time')
    self.p_trace_status = self:StatusRecordParent('p_trace_status')
    self.trigger_trace = self:BindComponent("trigger_trace", typeof(CS.FpAnimation.FpAnimationCommonTrigger))
    self.tracePetProgressVfx = self:BindComponent('p_layout_progress', typeof(CS.FpAnimation.FpAnimationCommonTrigger))

    ---@type RadarPetTrackProgressComp
    self.p_point = self:LuaBaseComponent('p_point')
    self.p_layout_progress = self:Transform('p_layout_progress')
    self.pool_p_point = LuaReusedComponentPool.new(self.p_point, self.p_layout_progress)

    -- 新增世界事件
    self.group_world_event = self:GameObject('group_world_event')
    self.p_btn_event_1 = self:Button('p_btn_event_1', Delegate.GetOrCreate(self, self.OnBtnClickUseWorldEventItem1))
    self.p_btn_event_2 = self:Button('p_btn_event_2', Delegate.GetOrCreate(self, self.OnBtnClickUseWorldEventItem2))
    self.p_text_event_quantity_1 = self:Text('p_text_event_quantity_1')
    self.p_text_event_quantity_2 = self:Text('p_text_event_quantity_2')
    self.p_text_summon = self:Text('p_text_summon', 'alliance_activity_pet_01')

    -- 新增圈层
    self.p_btn_landform = self:Button('p_btn_landform', Delegate.GetOrCreate(self, self.OnBtnClickLandform))
    self.p_text_landform = self:Text('p_text_landform', 'radartrack_info_land_information')

    -- 新增主堡图片
    self.p_icon_home = self:Image('p_icon_home')
    if self.goQuantity then
        self.goQuantity:SetVisible(false)
    end

    self.p_text_radar_lvl = self:Text('p_text_radar_lvl', 'bw_info_radarsystem_8')

    self.p_tip_time = self:GameObject("p_tip_time")
    self.p_text_trace_quantity = self:Text("p_text_trace_quantity")
    self.p_text_trace_time = self:Text("p_text_trace_time")
end

---@param param RadarMediatorParam
function RadarMediator:OnOpened(param)
    -- if not param then
    --     return
    -- end
    g_Game.SpriteManager:LoadSprite('sp_icon_building_base', self.p_icon_home)
    g_Game.EventManager:TriggerEvent(EventConst.CLEAR_SLG_SELECT)
    self.compChildCommonBack:FeedData({
        title = I18N.Get("leida_title"),
        onDetailBtnClick = function(trans)
            ---@type TextToastMediatorParameter
            local param = {}
            param.content = I18N.Get('popup_rule_radar')
            param.clickTransform = trans
            ModuleRefer.ToastModule:ShowTextToast(param)
        end,
        onClose = function()
            self:OnClickClose()
        end,
    })
    self.lvTexts = {}
    self.timerList = {}
    self.originIsInCity = param.isInCity
    -- self.cameraStack = param.stack

    local isCityRadar = ModuleRefer.RadarModule:IsCityRadar()
    self.bg:SetVisible(isCityRadar)
    self.bg_outside:SetVisible(not isCityRadar)

    self:ChangInCityState(param.isInCity)
    self:Refresh()
    self:InitRadarLevelInfo()
    self:RefreshLv()
    -- self:RefreshEggContent()
    -- self.basicCamera = KingdomMapUtils.GetBasicCamera()
    -- self.basicCamera.enablePinch = false
    self.curAngle = 0

    self:OnBtnInfoClicked(true)
    -- if ModuleRefer.RadarModule:CheckIsNeedFakeRadar() then
    --     ModuleRefer.RadarModule:LoadFakeRadar()
    -- end
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.Radar.MsgPath, Delegate.GetOrCreate(self, self.Refresh))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.Radar.RadarLevel.MsgPath, Delegate.GetOrCreate(self, self.RefreshLv))
    g_Game.EventManager:AddListener(EventConst.RADAR_HIDE_CLOSE_CAMERA, Delegate.GetOrCreate(self, self.ChangeState))
    g_Game.EventManager:AddListener(EventConst.RADAR_OPEN_GROUP_INFO, Delegate.GetOrCreate(self, self.OpenGroupInfo))
    -- g_Game.EventManager:AddListener(EventConst.RADAR_TASK_CLAIM_REWARD, Delegate.GetOrCreate(self, self.RefreshRadarProgress))
    g_Game.EventManager:AddListener(EventConst.RADAR_UPGRADE_PANEL_CLOSE, Delegate.GetOrCreate(self, self.CheckRefreshLock))
    g_Game.EventManager:AddListener(EventConst.RADAR_MANUAL_TASKS_READY, Delegate.GetOrCreate(self, self.PlayManualCreateTasksVfx))
    g_Game.EventManager:AddListener(EventConst.RADAR_TRACE_PET_START_TRACE, Delegate.GetOrCreate(self, self.CheckPetTraceStatus))
    g_Game.EventManager:TriggerEvent(EventConst.RADAR_MEDIATOR_OPENED)
    g_Game.ServiceManager:AddResponseCallback(RadarScanParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnGetEntities))
    g_Game.ServiceManager:AddResponseCallback(RadarLevelUpParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnRadarLevelUp))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.Radar.MapRadarTask.MsgPath, Delegate.GetOrCreate(self, self.RefreshRedDot))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.Radar.MapRadarTask.MsgPath, Delegate.GetOrCreate(self, self.OnRadarTaskChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerExpeditions.MsgPath, Delegate.GetOrCreate(self, self.RefreshRedDot))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.AllianceExpeditionActivatorUseRet, Delegate.GetOrCreate(self, self.OnUseItem))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceExpedition.Expeditions.MsgPath, Delegate.GetOrCreate(self, self.OnUseItem))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.SyncGetPet, Delegate.GetOrCreate(self, self.SyncGetPet))

    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    self.ignoreCamera = true
    self.groupOffsetX = 0
    self:RefreshRedDot()
    self.isListerRadarRefreshFilter = true

    if param.enterSelectBubbleType then
        local taskList = ModuleRefer.RadarModule.radarTaskBubbleList
        if taskList and table.nums(taskList) > 0 then
            local hasTarget = false
            for _, v in pairs(taskList) do
                local lua = v:GetComponent(typeof(CS.DragonReborn.UI.LuaBaseComponent)).Lua
                local info = lua:GetRadarTaskInfo()
                if info:ObjectType() == param.enterSelectBubbleType then
                    lua:OnBtnClicked()
                    hasTarget = true
                    return
                end
            end

            if not hasTarget and param.mustSelectTarget then
                local _, v = next(taskList)
                local lua = v:GetComponent(typeof(CS.DragonReborn.UI.LuaBaseComponent)).Lua
                lua:OnBtnClicked()
            end
        end
    end

    local mapRadarTask = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.Radar.MapRadarTask
    local progress = mapRadarTask.Clue
    self:TryShowManualCreate()
    self:CheckWorldEventOpen()
    self:CheckPetTraceStatus()

    if param.tracePetId then
        g_Game.UIManager:Open(UIMediatorNames.RadarPetTraceMediator, {tracePetId = param.tracePetId})
        return
    end

    if not self:IsHaveRadarTask() and self.curPetTraceTime > 0 then
        g_Game.UIManager:Open(UIMediatorNames.RadarPetTraceMediator)
    end
end

function RadarMediator:OnShow()
    self.lastProgress = nil
end

function RadarMediator:OnClose()
    self:ClearTimerList()
    self:StopTimer()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    ModuleRefer.KingdomTouchInfoModule:Hide()
    ModuleRefer.RadarModule:UnloadCityIcon()
    ModuleRefer.RadarModule:UnloadFakeRadar()
    ModuleRefer.RadarModule:SetRadarState(false)
    ModuleRefer.RadarModule:DestroyAllBubble()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.Radar.MsgPath, Delegate.GetOrCreate(self, self.Refresh))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.Radar.RadarLevel.MsgPath, Delegate.GetOrCreate(self, self.RefreshLv))
    g_Game.ServiceManager:RemoveResponseCallback(RadarScanParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnGetEntities))
    g_Game.ServiceManager:RemoveResponseCallback(RadarLevelUpParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnRadarLevelUp))
    g_Game.EventManager:RemoveListener(EventConst.RADAR_HIDE_CLOSE_CAMERA, Delegate.GetOrCreate(self, self.ChangeState))
    g_Game.EventManager:RemoveListener(EventConst.RADAR_OPEN_GROUP_INFO, Delegate.GetOrCreate(self, self.OpenGroupInfo))
    -- g_Game.EventManager:RemoveListener(EventConst.RADAR_TASK_CLAIM_REWARD, Delegate.GetOrCreate(self, self.RefreshRadarProgress))
    g_Game.EventManager:RemoveListener(EventConst.RADAR_UPGRADE_PANEL_CLOSE, Delegate.GetOrCreate(self, self.CheckRefreshLock))
    g_Game.EventManager:RemoveListener(EventConst.RADAR_MANUAL_TASKS_READY, Delegate.GetOrCreate(self, self.PlayManualCreateTasksVfx))
    g_Game.EventManager:RemoveListener(EventConst.RADAR_TRACE_PET_START_TRACE, Delegate.GetOrCreate(self, self.CheckPetTraceStatus))
    g_Game.EventManager:TriggerEvent(EventConst.RADAR_MEDIATOR_CLOSED)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.Radar.MapRadarTask.MsgPath, Delegate.GetOrCreate(self, self.RefreshRedDot))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.Radar.MapRadarTask.MsgPath, Delegate.GetOrCreate(self, self.OnRadarTaskChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerExpeditions.MsgPath, Delegate.GetOrCreate(self, self.RefreshRedDot))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.AllianceExpeditionActivatorUseRet, Delegate.GetOrCreate(self, self.OnUseItem))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceExpedition.Expeditions.MsgPath, Delegate.GetOrCreate(self, self.OnUseItem))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.SyncGetPet, Delegate.GetOrCreate(self, self.SyncGetPet))

    -- if self.basicCamera then
    --     self.basicCamera.enablePinch = true
    --     self.basicCamera.ignoreLimit = false
    -- end
    -- if self.IsInCity and ModuleRefer.CityModule.myCity then
    --     ModuleRefer.CityModule.myCity.stateMachine:ChangeState(CityConst.STATE_NORMAL)
    -- end
    self.lockProgressAnim = false
    RadarTaskUtils.ClearRadarTaskBtnPosBoard()
    ModuleRefer.RadarModule:SetRadarTaskLock(false)
    ModuleRefer.RadarModule:SetRadarEventLock(false)
    ModuleRefer.RadarModule:SetManualRadarTaskLock(false)
    ModuleRefer.RadarModule:ClearManualRadarTasks()
    ModuleRefer.RadarModule:ClearManualRadarTaskBubbles()
    ModuleRefer.RadarModule:RefreshRadarEntryReddot()
    g_Game.EventManager:TriggerEvent(EventConst.RADAR_SHOW_NEW_TASK, false)
end

function RadarMediator:OnClickClose()
    self.isListerRadarRefreshFilter = false
    if not self.IsInCity and self.originIsInCity then
        -- g_Game.SceneManager.current:ReturnMyCity()
    end
    if not self.ignoreCamera then
        if self.IsInCity == self.originIsInCity then
            -- self.cameraStack:back()
        else
            -- if self.IsInCity then
            --     self.basicCamera:ZoomToMinSize(0.2)
            -- else
            --     local size = ConfigRefer.ConstMain:ChooseCameraDistance()
            --     self.basicCamera:ZoomTo(size, 0.2)
            -- end
        end
    end
    self.animBaseTrigger:PlayAll(FpAnimTriggerEvent.Custom4, Delegate.GetOrCreate(self, self.BackToPrevious))
end

function RadarMediator:GetItemPos()
    -- return self.compExploreFog.p_btn_explor_fog.gameObject.transform.position
end

function RadarMediator:CloseCallBack()
    self:CloseSelf()
end

function RadarMediator:ChangInCityState(isInCity)
    self.IsInCity = isInCity
    -- if self.IsInCity then
    --     ModuleRefer.CityModule.myCity.stateMachine:ChangeState(CityConst.STATE_ENTER_RADAR)
    -- end
end

function RadarMediator:InitRedDot()
    if self.createRedDot then
        return
    end
    ModuleRefer.NotificationModule:GetOrCreateDynamicNode("RadarTaskInfo", NotificationType.RADAR_TASK_INFO)
    self.createRedDot = true
end

function RadarMediator:RefreshRedDot()
    if not self.createRedDot then
        self:InitRedDot()
    end
    local rewardCount = ModuleRefer.RadarModule:GetRadarTaskRewardCount()
    local canLevelUp = ModuleRefer.RadarModule:CheckIsCanUpgrade()

    local radarTaskInfo = ModuleRefer.NotificationModule:GetDynamicNode("RadarTaskInfo", NotificationType.RADAR_TASK_INFO)
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(radarTaskInfo, (canLevelUp or rewardCount) and 1 or 0)
end

function RadarMediator:Refresh()
    self:RefreshEnergy()
    -- self:RefreshLv()
    self:RefreshRadarTaskInfo()
end

function RadarMediator:ChangeState()
    -- self.ignoreCamera = true
end

function RadarMediator:OpenGroupInfo(param)
    self.goGroupInfo:SetVisible(true)
    self.luagoGroupInfo:RefreshGroupInfo(param)
    if param.groupOffsetX then
        if self.groupOffsetX == 0 or self.groupOffsetX < param.groupOffsetX then
            self:FixRadarTaskGroupPos(param.groupOffsetX)
        end
    end
end

function RadarMediator:InitRadarLevelInfo()
    self.curRadarLevel = ModuleRefer.RadarModule:GetRadarLv()
    self.oldRadarLevel = self.curRadarLevel

    self:RefreshItemProgress(true)
    self:RefreshRadarContents()
end

function RadarMediator:RefreshRadarContents()
    local cfg = ConfigRefer.ConstBigWorld
    local level = self.curRadarLevel
    self.goExploreFog:SetVisible(level >= cfg:UnlockMistSysRadarLevel()) -- 照明棒
    self.btnEnergy:SetVisible(level >= cfg:RadarDisplayEnergy()) -- 体力
    self.btnRadarUpgrade:SetVisible(level >= cfg:RadarDisplayLevelComponent()) -- 雷达等级组件
    self.p_info_progress:SetVisible(level >= cfg:RadarDisplayLevelComponent()) -- 雷达等级组件
    -- self.refreshComp:SetVisible(level >=cfg:RadarDisplayRefreshTime())   --刷新时间
end

function RadarMediator:RefreshLv(_, changedData)
    local needShowUpgrade = false
    if changedData then
        if self.curRadarLevel < changedData then
            self.curRadarLevel = changedData
            self.oldRadarLevel = self.curRadarLevel - 1
            needShowUpgrade = true
            local unlockMist = require("NewFunctionUnlockIdDefine").UnlockMist
            local unlocked = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(unlockMist)
            self.goExploreFog:SetActive(unlocked)
            if self.curRadarLevel == ConfigRefer.ConstBigWorld:UnlockMistSysRadarLevel() and unlocked then
                local GuideUtils = require('GuideUtils')
                GuideUtils.GotoByGuide(45)
            end

            -- 雷达升级的时机...
            g_Game.EventManager:TriggerEvent(EventConst.RADAR_LEVEL_UP)
        end
    end

    if needShowUpgrade then
        -- 1.5s后 刷新等级
        local timer = TimerUtility.DelayExecute(function()
            self:RefreshLv()
            self:RefreshRadarContents()
        end, 1.5)
        self.timerList[#self.timerList + 1] = timer

        -- 2s后,展示雷达升级界面
        local upgradeTimer = TimerUtility.DelayExecute(function()
            g_Game.UIManager:Open(UIMediatorNames.RadarUpgradeSuccMediator)
        end, 2)
        self.timerList[#self.timerList + 1] = upgradeTimer
        return
    end
    local isMax = ModuleRefer.RadarModule:CheckIsMax()
    self.goMax:SetActive(isMax)
    if isMax then
        self.textInfoProgress:SetVisible(false)
    end
    self.textLv.text = ModuleRefer.RadarModule:GetRadarLv()

    local unlockMist = require("NewFunctionUnlockIdDefine").UnlockMist
    local unlocked = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(unlockMist)
    self.goExploreFog:SetActive(unlocked)
end

-- 关闭雷达升级界面后
function RadarMediator:CheckRefreshLock()
    if self.curRadarLevel == ConfigRefer.ConstBigWorld:CityRadarToWorldRadarVfxLevel() then
        self.animBaseTrigger:PlayAll(FpAnimTriggerEvent.Custom7)
    end

    -- 0.5s后 时尝试刷新事件
    if ModuleRefer.RadarModule:GetRadarTaskLock() then
        local timer = TimerUtility.DelayExecute(function()
            -- 刷新任务
            ModuleRefer.RadarModule:SetRadarTaskLock(false)
            self:RefreshRadarTask(true, false)
        end, 0.5)
        self.timerList[#self.timerList + 1] = timer
    end
end

function RadarMediator:TryShowNewPet()
    local cfg = ConfigRefer.RadarLevel:Find(self.curRadarLevel)
    local petId = cfg:RadarNewPet()
    if petId and petId > 0 then
        local petCfg = ConfigRefer.Pet:Find(petId)
        g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(petCfg:Icon()), self.p_img_pet)
    end
end

function RadarMediator:TryShowManualCreate()
    -- local hasRewardTasks = ConfigRefer.RadarLevel:Find(self.curRadarLevel):RadarRewardTasksLength() > 0
    -- local radar = ModuleRefer.RadarModule:GetRadarInfo()
    -- local autoLevel = ConfigRefer.ConstMain:RadarLevelRewardAutoMaxLevel()
    -- local isOpen = self.curRadarLevel >= autoLevel
end

function RadarMediator:OnBtnClickManualCreateRadarTask()
    -- 不可连续点
    if ModuleRefer.RadarModule:GetManualRadarTaskLock() then
        return
    end

    -- 任务过多时阻拦
    local radarTaskNum = ModuleRefer.RadarModule:GetRadarTaskNum()
    if radarTaskNum > ConfigRefer.ConstBigWorld:RadarDisplayTaskNumLimit() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("radar_toast_too_many_tasks"))
        return
    end

    -- 上锁\标记将要出现的任务
    local radar = ModuleRefer.RadarModule:GetRadarInfo()
    ModuleRefer.RadarModule:SetManualRadarTaskLock(true)
    local cfg = ConfigRefer.RadarLevel:Find(radar.RaderRewardLevel + 1)
    for i = 1, cfg:RadarRewardTasksLength() do
        ModuleRefer.RadarModule:SetManualRadarTasks(cfg:RadarRewardTasks(i))
    end

    local params = require('RadarLevelRewardTasksParameter').new()
    params:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, suc, resp)
        if (suc) then

        end
    end)
end

function RadarMediator:PlayManualCreateTasksVfx()
    -- 2024/5/27 先播放左下角宠物头气泡的出现效果，再播放粒子打到屏幕中央的效果
    local timer = TimerUtility.DelayExecute(function()
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("radartrack_toast_finish_task"))
        self:PlaySingleManualCreateTasksVfx()
    end, 1)
    self.timerList[#self.timerList + 1] = timer
    -- self:TryShowManualCreate()
end

function RadarMediator:PlaySingleManualCreateTasksVfx()
    local bubble = ModuleRefer.RadarModule:GetManualRadarTaskBubble()
    if bubble == nil then
        -- 播完清零
        ModuleRefer.RadarModule:SetManualRadarTaskLock(false)
        ModuleRefer.RadarModule:ClearManualRadarTasks()
        ModuleRefer.RadarModule:ClearManualRadarTaskBubbles()

        return
    end
    local vfxHandle = CS.DragonReborn.VisualEffect.VisualEffectHandle()
    local flyDuration = 0.6
    vfxHandle:Create("vfx_radarmain_trail_01", "vfx_radarmain_trail_01", self.transform, function(success, obj, handle)
        if success then
            ---@type CS.UnityEngine.GameObject
            local go = handle.Effect.gameObject
            go.transform.position = self.p_text_status.transform.position
            local endPos = bubble.transform.position
            MathUtils.Paracurve(go.transform, go.transform.position, endPos, CS.UnityEngine.Vector3.right, 2.5, 8, flyDuration, Ease.OutQuad)

            local timer = TimerUtility.DelayExecute(function()
                self:PlaySingleManualCreateTasksVfx()
            end, 0.1)
            self.timerList[#self.timerList + 1] = timer

            local timer = TimerUtility.DelayExecute(function()
                bubble:SetActive(false)
                bubble:SetActive(true)
                local obj = bubble:GetComponent("LuaBaseComponent").Lua:ShowBubble()
            end, flyDuration)
            self.timerList[#self.timerList + 1] = timer

        end
    end)
end

--特殊任务完成飞左上特效
function RadarMediator:PlaySpecialTaskClaimVfx(uniqueId)
    local bubble = ModuleRefer.RadarModule:GetBubbleUIPosCache(uniqueId)
    if not bubble then return end
    local vfxHandle = CS.DragonReborn.VisualEffect.VisualEffectHandle()
    local flyDuration = 0.4
    vfxHandle:Create("vfx_radar_task_trail", "vfx_radar_task_trail", bubble.go.transform, function(success, obj, handle)
        if success then
            ---@type CS.UnityEngine.GameObject
            local go = handle.Effect.gameObject
            go.transform.localPosition = CS.UnityEngine.Vector3.zero
            local endPos = self.textInfoProgress.transform.position
            MathUtils.Paracurve(go.transform, go.transform.position, endPos, CS.UnityEngine.Vector3.right, 2.5, 8, flyDuration, Ease.OutQuad)

            local timer = TimerUtility.DelayExecute(function()
                self.upgradeTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
                self:RefreshItemProgress()
            end, flyDuration)
            self.timerList[#self.timerList + 1] = timer
        end
    end)
end

function RadarMediator:RefreshEnergy()
    local radarInfo = ModuleRefer.RadarModule:GetRadarInfo()
    local curEnery = radarInfo.PPPCur
    local maxEnergy = radarInfo.PPPMax
    if curEnery == 0 then
        self.textNumber.text = string.format('<color=#FF0000FF>%d</color>/%d', curEnery, maxEnergy)
    else
        self.textNumber.text = curEnery .. '/' .. maxEnergy
    end
end

function RadarMediator:RefreshRadarTaskInfo()
    local curLv = ModuleRefer.RadarModule:GetRadarLv()
    if curLv < ConfigRefer.ConstBigWorld:UnlockRemainTaskNumRadarLevel() then
        -- self.goQuantity:SetActive(false)
    else
        -- self.goQuantity:SetActive(true)
        local curCfg = ConfigRefer.RadarLevel:Find(curLv)
        local totalTask = 0
        for i = 1, curCfg:RadarTaskAnnulusTaskNumLength() do
            totalTask = totalTask + curCfg:RadarTaskAnnulusTaskNum(i)
        end
        local WaitRadarTaskInfo = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.Radar.MapRadarTask.WaitRadarTasks
        local waitTask = #WaitRadarTaskInfo
        -- self.textInfoQuantityNum.text = waitTask .. "/" .. totalTask
        self.textInfoQuantityNum.text = waitTask
    end

    local finishTime = self:GetNextRadarTaskRefreshTime()
    if self.timeComp then
        self.timeComp:FeedData({
            endTime = finishTime,
            needTimer = true,
            function()
                self:OnBtnInfoClicked()
            end,
        })
    end
end

function RadarMediator:GetNextRadarTaskRefreshTime()
    local serverTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local seconds = math.floor(serverTime % 86400)
    local finishTime = 0
    if seconds < 8 * 3600 then
        finishTime = serverTime - seconds + 8 * 3600
    elseif seconds < 16 * 3600 then
        finishTime = serverTime - seconds + 16 * 3600
    elseif seconds < 24 * 3600 then
        finishTime = serverTime - seconds + 24 * 3600
    end
    return finishTime
end

function RadarMediator:IsHaveRadarTask()
    local playerInfo = ModuleRefer.PlayerModule:GetPlayer()
    local radarTasks = playerInfo.PlayerWrapper2.Radar.MapRadarTask
    local recievedCount = 0
    -- 已接取的雷达任务
    for _, v in pairs(radarTasks.ReceivedTasks) do
        if v then
            recievedCount = recievedCount + 1
        end
    end
    -- 等待接取的雷达任务
    recievedCount = recievedCount + #radarTasks.WaitRadarTasks
    -- 已刷的世界事件
    local expeditionQuality = playerInfo.PlayerWrapper2.Radar.ExpeditionQuality
    if expeditionQuality then
        for entityID, info in pairs(expeditionQuality) do
            if info.QualityType > 0 then
                recievedCount = recievedCount + 1
            end
        end
    end
    -- 可领取的世界事件
    local expeditions = playerInfo.PlayerWrapper2.PlayerExpeditions.CanReceiveRewardExpeditions or {}
    for id, expeditionInfo in pairs(expeditions) do
        recievedCount = recievedCount + 1
    end

    local eliteTaskList = radarTasks.EliteTasks
    for _, taskData in pairs(eliteTaskList) do
        recievedCount = recievedCount + 1
    end

    local mistTaskList = radarTasks.MistTasks
    for _, taskData in pairs(mistTaskList) do
        if ModuleRefer.RadarModule:IsCanShowMistTask(taskData) then
            recievedCount = recievedCount + 1
        end
    end

    local allianceWorldEvent = ModuleRefer.WorldEventModule:GetPersonalOwnAllianceExpedition()
    if allianceWorldEvent then
        recievedCount = recievedCount + 1
    end

    if recievedCount == 0 then
        return false
    end
    return true
end

function RadarMediator:FixRadarTaskGroupPos(offsetX)
    if offsetX == 0 then
        if self.groupOffsetX ~= 0 then
            self.goBubbleBtnParent.transform:DOLocalMoveX(0, 0.2)
            self.goBubbleBtnBase.transform:DOLocalMoveX(0, 0.2)
            self.groupOffsetX = 0
        end
        return
    end
    self.isGroupInfoOffset = true
    self.goBubbleBtnParent.transform:DOLocalMoveX(-offsetX, 0.2)
    self.goBubbleBtnBase.transform:DOLocalMoveX(-offsetX, 0.2)
    self.groupOffsetX = offsetX
end

function RadarMediator:OnBtnBackClicked(args)
    self:BackToPrevious()
end

function RadarMediator:OnBtnInfoClicked(isFirst)
    isFirst = isFirst or false
    if isFirst then
        local curLevel = ModuleRefer.RadarModule:GetRadarLv()
        if curLevel == 1 and not ModuleRefer.RadarModule:GetFirstShow() then
            ModuleRefer.RadarModule:SetFirstShow(true)
            self.animBaseTrigger:PlayAll(FpAnimTriggerEvent.Custom8)
        else
            self.animBaseTrigger:PlayAll(FpAnimTriggerEvent.Custom3)
        end
    end
    self.animBaseTrigger:PlayAll(FpAnimTriggerEvent.Custom2)
    ModuleRefer.RadarModule:ClearLastRefreshRecord()
    self:RefreshRadarTask(false, true)

    local timer = TimerUtility.DelayExecute(function()
        self:DelayShowRadarTask()
    end, 0.2)
    self.timerList[#self.timerList + 1] = timer
end

function RadarMediator:ClearTimerList()
    if self.timerList then
        for i = 1, #self.timerList do
            self.timerList[i]:Stop()
        end
        self.timerList = {}
    end
end

function RadarMediator:OnRadarTaskChanged(entity, changedData)
    self:RefreshRadarTask(true, false, changedData)
    self:CheckWorldEventOpen()
end

function RadarMediator:OnUseItem()
    self:RefreshRadarTask(true, false)
    self:DelayShowRadarTask()
    self:CheckWorldEventOpen()
end

function RadarMediator:RefreshRadarTask(isActive, isClear, changedData)

    -- 雷达追踪第二阶段任务出现
    if changedData and changedData.PetTrackInfo and changedData.PetTrackInfo.SecondPhaseTasks and changedData.PetTrackInfo.SecondPhaseTasks.Add then
        ModuleRefer.RadarModule:SetManualRadarTaskLock(true)
    end

    local lock = ModuleRefer.RadarModule:GetManualRadarTaskLock()
    self.goGroupInfo:SetVisible(false)

    if changedData then
        self:ClearRadarTaskCacheData(changedData)

        if lock and changedData.EliteTasks and changedData.EliteTasks.Add then
            for k, v in pairs(changedData.EliteTasks.Add) do
                ModuleRefer.RadarModule:SetManualRadarTasks(v.RadarTaskId)
            end
        end
    end
    self.groupOffsetX = 0

    if self:IsHaveRadarTask() then
        self.goEmpty:SetActive(false)
        ModuleRefer.WorldEventModule:SetFilterType(wrpc.RadarEntityType.RadarEntityType_Expedition)
        ModuleRefer.RadarModule:LoadRadarTask(self.goBubbleBtnParent.transform, self.goRadarTaskItem, isActive, isClear)
        ModuleRefer.RadarModule:LoadWorldEvent(self.goBubbleBtnParent.transform, self.goWorldEventItem, false)
        ModuleRefer.RadarModule:LoadAllianceRadarTask(self.goBubbleBtnParent.transform, self.goWorldEventItem, isActive)
        ModuleRefer.KingdomTouchInfoModule:Hide()
    else
        local curT, maxT = ModuleRefer.RadarModule:GetRadarTrackingPetTimes()
        local isCityRadar = ModuleRefer.RadarModule:IsCityRadar()
        if isCityRadar and curT == 0 then
            -- self.btnEmptyGuide:SetVisible(false)
            self.goEmpty:SetActive(true)
            self.textEmpty.text = I18N.Get("radar_info_unrecovered_areas")
            self.textEmptyGuide.text = I18N.Get("bw_mistevent_btn_goto")
            self.timeCompEmpty:SetVisible(false)
            -- self.btnEmptyGuide:SetVisible(true)
        else
            self.btnEmptyGuide:SetVisible(false)
            --     self.textEmpty.text = I18N.Get("Radar_tips_finish")
            --     self.textEmptyGuide.text = I18N.Get("village_btn_confirm_proxy")
            --     self.timeCompEmpty:SetVisible(true)
            --     self.btnEmptyGuide:SetVisible(false)
            --     local finishTime = self:GetNextRadarTaskRefreshTime()
            --     self.timeCompEmpty:FeedData({
            --         endTime = finishTime,
            --         needTimer = true,
            --         function()
            --             self:OnBtnInfoClicked()
            --         end,
            --     })
        end
    end

    -- if lock and changedData and changedData.EliteTasks and changedData.EliteTasks.Add then
    --     g_Game.EventManager:TriggerEvent(EventConst.RADAR_MANUAL_TASKS_READY)
    -- end
end

function RadarMediator:ClearRadarTaskCacheData(changedData)
    if changedData then
        if changedData.ReceivedTasks and changedData.ReceivedTasks.Remove then
            local removeTable = changedData.ReceivedTasks.Remove
            for k, v in pairs(removeTable) do
                ModuleRefer.RadarModule:HideRadarTaskBtn(k)
            end
        end
        if changedData.EliteTasks and changedData.EliteTasks.Remove then
            local removeTable = changedData.EliteTasks.Remove
            local isSpecial = false
            for k, v in pairs(removeTable) do
                ModuleRefer.RadarModule:HideRadarTaskBtn(k)
                --特殊任务完成飞左上特效
                if ConfigRefer.RadarTask:Find(v.RadarTaskId):IsSpecial() then
                    isSpecial = true
                    self:PlaySpecialTaskClaimVfx(k)
                end
            end

            --普通任务完成飞左下特效
            if not isSpecial then
                self.tracePetProgressVfx:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
            end
            self:CheckPetTraceStatus(true)
        end
        if changedData.MistTasks and changedData.MistTasks.Remove then
            local removeTable = changedData.MistTasks.Remove
            for k, v in pairs(removeTable) do
                ModuleRefer.RadarModule:HideRadarTaskBtn(k)
            end
        end
    end
end

function RadarMediator:ShowInfoProgressAnim()
    self:OnBtnEmptyPosClicked()
    local mapRadarTask = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.Radar.MapRadarTask
    local progress = mapRadarTask.Clue

    -- 被重复调用了
    if self.lastProgress and self.lastProgress == progress then
        return
    end

    if self.eventProgress ~= progress then
        local isFull = progress < self.eventProgress
        if not self.lockProgressAnim then
            if isFull then
                self.lockProgressAnim = true
                self.lastProgress = nil
            else
                self.lastProgress = progress
            end

            self.eventProgressTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
            local timer = TimerUtility.DelayExecute(function()
                if isFull then
                    self.eventProgressTrigger:PlayAll(FpAnimTriggerEvent.Custom2, function()
                        self:TryShowManualCreate()
                    end)
                else
                    self.eventProgressTrigger:PlayAll(FpAnimTriggerEvent.Custom3)
                end
            end, 0.4)
            self.timerList[#self.timerList + 1] = timer

            local timer = TimerUtility.DelayExecute(function()
                self:RefreshEventProgress()
            end, 0.7)
            self.timerList[#self.timerList + 1] = timer
        end

    end

    self.infoProgressTrigger:PlayAll(FpAnimTriggerEvent.Custom1, function()
        self:RefreshItemProgress()
    end)
end

function RadarMediator:RefreshRadarProgress()
    self:RefreshItemProgress()
end

function RadarMediator:RefreshItemProgress(noAnim)
    local itemID = ModuleRefer.RadarModule:GetRadarUpgradeInfo(self.oldRadarLevel)
    local has, need = ModuleRefer.RadarModule:GetRadarItemNum(self.oldRadarLevel)
    if itemID == 0 and need == 0 then
        return
    end
    local itemConfig = ConfigRefer.Item:Find(itemID)
    if not itemConfig then
        return
    end
    local progress = has / need
    if self.infoProgressSlider.value == progress then
        return
    end

    if noAnim then
        -- self.textInfoProgress.text = string.format("%s:%d/%d", I18N.Get(itemConfig:NameKey()), has, need)
        self.textInfoProgress.text = string.format("%d/%d", has, need)
        self.infoProgressSlider.value = progress
        return
    end

    if self.oldRadarLevel == self.curRadarLevel then
        self.textInfoProgress.text = string.format("%d/%d", has, need)
        self.infoProgressSlider:DOValue(progress, 0.4)
    else
        self.infoProgressSlider:DOValue(1, 0.4)
        self.textInfoProgress.text = string.format("%d/%d", has, need)
        self.upgradeTrigger:PlayAll(FpAnimTriggerEvent.Custom1, function()
            self:TryShowNewPet()
        end)
        self.oldRadarLevel = self.curRadarLevel

        self:RefreshItemProgress()
    end
end

function RadarMediator:RefreshEggContent(showToast)
    local items = ModuleRefer.RadarModule:GetPetEggRewards()
    if items == nil or #items == 0 then
        return
    end
    local itemCfg = ConfigRefer.Item:Find(items[1].itemId)
    local icon = itemCfg:Icon()

    if showToast then
        local curLv = ModuleRefer.RadarModule:GetRadarLv()
        local radarTaskRandLibConfig = ConfigRefer.RadarTaskRandLib:Find(curLv)
        if not radarTaskRandLibConfig then
            g_Logger.Error("策划没配 ConfigRefer.RadarTaskRandLib" .. curLv)
        else
            local radarTaskConfig = ConfigRefer.RadarTask:Find(radarTaskRandLibConfig:EliteRadarTasks(1))
            if not radarTaskConfig then
                return
            end
            g_Game.UIManager:Open(UIMediatorNames.RadarToastInfoMediator, {content = I18N.Get(radarTaskConfig:Name()), icon = icon})
        end
    end
end

function RadarMediator:OnBtnAddEnergyClicked(args)
    local provider = require("EnergyGetMoreDataProvider").new()
    provider:SetItemList({ConfigRefer.ConstMain:AddenergyItemId()})
    g_Game.UIManager:Open(UIMediatorNames.UseResourceMediator, provider)
end

function RadarMediator:OnBtnNextRefresh(args)
    local totalTask = 0
    local curLevelCfg = ConfigRefer.RadarLevel:Find(self.curRadarLevel)
    for i = 1, curLevelCfg:RadarTaskAnnulusTaskNumLength() do
        totalTask = totalTask + curLevelCfg:RadarTaskAnnulusTaskNum(i)
    end
    ---@type TextToastMediatorParameter
    local param = {}
    param.timeText = I18N.Get("radar_info_time")
    param.timeStamp = self:GetNextRadarTaskRefreshTime()
    param.tailContent = ""
    param.content = I18N.GetWithParams('radar_info_time_content', totalTask)
    param.clickTransform = self.p_btn_quantity.gameObject.transform
    ModuleRefer.ToastModule:ShowTextToast(param)
end

function RadarMediator:OnBtnClickEggDetail()
    ---@type TextToastMediatorParameter
    -- local toastParameter = {}
    -- toastParameter.clickTransform = self.btnEvent.transform
    -- toastParameter.content = I18N.Get("Radar_tips_elite")
    -- ModuleRefer.ToastModule:ShowTextToast(toastParameter)

end

function RadarMediator:DelayShowRadarTask()
    local delayTime = 0
    local IntervalTime = 0
    local radarTaskList = ModuleRefer.RadarModule.radarTaskBubbleList
    local mistTaskList = ModuleRefer.RadarModule.mistTaskBubbleList
    local worldEventList = ModuleRefer.RadarModule.radarBubbleList
    local allianceWorldEventList = ModuleRefer.RadarModule.allianceBubbleList
    for k, v in pairs(radarTaskList) do
        if Utils.IsNotNull(v) and not v.activeSelf then
            IntervalTime = math.random(0, 15) / 100
            delayTime = delayTime + IntervalTime
            local timer = TimerUtility.DelayExecute(function()
                v:SetActive(true)
                ModuleRefer.RadarModule:AddUniqueId(k)
            end, delayTime)
            self.timerList[#self.timerList + 1] = timer
        end
    end
    for k, v in pairs(mistTaskList) do
        if Utils.IsNotNull(v) and not v.activeSelf then
            IntervalTime = math.random(5, 20) / 100
            delayTime = delayTime + IntervalTime
            local timer = TimerUtility.DelayExecute(function()
                v:SetActive(true)
                ModuleRefer.RadarModule:AddUniqueId(k)
            end, delayTime)
            self.timerList[#self.timerList + 1] = timer
        end
    end
    for k, v in pairs(worldEventList) do
        if Utils.IsNotNull(v) and not v.activeSelf then
            IntervalTime = math.random(5, 20) / 100
            delayTime = delayTime + IntervalTime
            local timer = TimerUtility.DelayExecute(function()
                v:SetActive(true)
                ModuleRefer.RadarModule:AddUniqueId(k)
            end, delayTime)
            self.timerList[#self.timerList + 1] = timer
        end
    end
    for k, v in pairs(allianceWorldEventList) do
        if Utils.IsNotNull(v) and not v.activeSelf then
            IntervalTime = math.random(5, 20) / 100
            delayTime = delayTime + IntervalTime
            local timer = TimerUtility.DelayExecute(function()
                v:SetActive(true)
                ModuleRefer.RadarModule:AddUniqueId(k)
            end, delayTime)
            self.timerList[#self.timerList + 1] = timer
        end
    end
end

function RadarMediator:OnBtnEmptyPosClicked()
    self.goGroupInfo:SetVisible(false)
    g_Game.EventManager:TriggerEvent(EventConst.RADAR_TASK_CLICKED)
    self.groupOffsetX = 0
    if self.isGroupInfoOffset then
        self.goBubbleBtnParent.transform:DOLocalMoveX(0, 0.2)
        self.goBubbleBtnBase.transform:DOLocalMoveX(0, 0.2)
        self.isGroupInfoOffset = false
    end
end

function RadarMediator:OnGetEntities(isSuccess, reply, rpc)
    if not isSuccess then
        return
    end
    local request = rpc.request
    local filterType = request.RadarEntityTypes[1]
    local result = reply.Result
    ModuleRefer.RadarModule:LoadBubbleByType(filterType, result, self.goBubbleBtnParent.transform, self.goWorldEventItem)
end

function RadarMediator:OnRadarLevelUp(isSuccess, reply, rpc)
    if not isSuccess then
        return
    end
    self:OnRadarTaskChanged()
end

function RadarMediator:OnBtnWildernessClicked(args)
    if ModuleRefer.RadarModule:CheckIsLockWorldRadar() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("kingdom_locked"))
        return
    end
    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    scene:LeaveCity()
end

function RadarMediator:OnBtnCityClicked(args)
    -- self.animBaseTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
    g_Game.SceneManager.current:ReturnMyCity()
end

function RadarMediator:OnBtnEnergyClicked(args)
    local radarInfo = ModuleRefer.RadarModule:GetRadarInfo()
    local curEnery = radarInfo.PPPCur
    local maxEnergy = radarInfo.PPPMax
    local isMax = curEnery >= maxEnergy
    if isMax then
        local text = I18N.GetWithParams("energy_tips_1", string.format("%d", ConfigRefer.ConstMain:PPPIncInterval() / 60))
        ModuleRefer.ToastModule:ShowTextToast({clickTransform = self.btnEnergy.transform, content = text})
    else
        local text = I18N.GetWithParams("energy_tips_1", string.format("%d", ConfigRefer.ConstMain:PPPIncInterval() / 60))
        ModuleRefer.ToastModule:ShowTextToast({clickTransform = self.btnEnergy.transform, content = text})
    end
end
function RadarMediator:OnBtnRadarUpgradeClicked(args)
    g_Game.UIManager:Open(UIMediatorNames.RadarPopupUpgradeMediator)
end

function RadarMediator:RefreshTextColor()
    for index, text in ipairs(self.lvTexts or {}) do
        if index == self.selectLv then
            text.text = UIHelper.GetSizeText(index, 48)
            text.color = CS.UnityEngine.Color(36 / 255, 38 / 255, 48 / 255, 1)
        else
            text.text = UIHelper.GetSizeText(index, 32)
            text.color = CS.UnityEngine.Color.white
        end
    end
end

function RadarMediator:RefreshLvItem()
    local lvCount = 0

    if lvCount <= 0 then
        self.goGroupTopLvup:SetActive(false)
        return
    end
    for i = 0, self.goScrollLvContent.transform.childCount - 1 do
        self.lvTexts = {}
        local transform = self.goScrollLvContent.transform:GetChild(i)
        local button = transform:GetComponent(typeof(CS.UnityEngine.UI.Button))
        if not Utils.IsNullOrEmpty(button) then
            button.onClick:RemoveAllListeners()
        end
        CS.UnityEngine.GameObject.Destroy(transform.gameObject)
    end
    local count = 0
    for lv = 1, lvCount do
        ---@type CS.UnityEngine.GameObject
        local lvItem = CS.UnityEngine.GameObject.Instantiate(self.goItemLv)
        lvItem.transform:SetParent(self.goScrollLvContent.transform)
        local lvItemText = lvItem:GetComponentInChildren(typeof(CS.UnityEngine.UI.Text))
        if (lvItemText) then
            lvItemText.text = lv
        end
        local callback = function()
            self.pageviewcontrollerScrollLv:ScrollToPage(lv - 1, false)
        end
        local button = lvItem:GetComponent(typeof(CS.UnityEngine.UI.Button))
        if not Utils.IsNullOrEmpty(button) then
            button.onClick:AddListener(callback)
        end
        self.lvTexts[#self.lvTexts + 1] = lvItemText
        lvItem.transform.localScale = CS.UnityEngine.Vector3.one
        lvItem:SetActive(true)
        count = count + 1
    end
    self.pageviewcontrollerScrollLv.pageCount = count
    self.pageviewcontrollerScrollLv:ScrollToPage(self.selectLv - 1 or 1, false)
    self:RefreshTextColor()
end

function RadarMediator:OnBtnAllClicked(args)
    self.isSelectAll = not self.isSelectAll
    if self.isSelectAll then
        ModuleRefer.RadarModule:RecordSelectLv(self.filterType, -1)
        for index, text in ipairs(self.lvTexts or {}) do
            text.text = UIHelper.GetSizeText(index, 32)
            text.color = CS.UnityEngine.Color.white
        end
    else
        ModuleRefer.RadarModule:RecordSelectLv(self.filterType, 1)
    end
    self.pageviewcontrollerScrollLv:ScrollToPage(0, false)
    ModuleRefer.KingdomTouchInfoModule:Hide()
end

function RadarMediator:OnBtnEmptyGuideClicked()
    local isCityRadar = ModuleRefer.RadarModule:IsCityRadar()
    if isCityRadar then
        local city = ModuleRefer.CityModule.myCity
        local zone = city.zoneManager:GetNextZone()
        if zone == nil then
            g_Logger.Error("区域全收复了")
            return
        end
        local pos = zone.config:RecoverPopPos()
        local cityPos = city:GetCenterWorldPositionFromCoord(pos:X(), pos:Y(), 1, 1)
        ---@type CS.UnityEngine.Vector3
        local viewPortPos = CS.UnityEngine.Vector3(0.45, 0.5, 0.0)
        city.camera:ForceGiveUpTween()
        city.camera:ZoomToWithFocusBySpeed(CityConst.CITY_RECOMMEND_CAMERA_SIZE, viewPortPos, cityPos)
        self:CloseSelf()
    else
        if ModuleRefer.MapFogModule.allUnlocked then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("mist_toast_nomist"))
            return
        end

        g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Dialog)
        g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Popup)
        local _scene = g_Game.SceneManager.current
        if _scene:GetName() == require('KingdomScene').Name then
            require("GuideUtils").GotoByGuide(5033)
        end
    end
end

function RadarMediator:Tick(delta)
    if not self.rotate_line then
        self.rotate_line = self:Transform('node_eff'):Find("vfx_radarmain_radar/ui_radar_main_vfx_radarmain_radar/mask/vfx_radarmain_radar/rotate")
        return
    end

    if self.rotate_line then
        -- 射线预制体 初始时有45度偏移值
        local angle = 360 - self.rotate_line.localEulerAngles.z + 45
        if angle > 360 then
            angle = angle - 360
        end
        self.curAngle = angle
    end

    for k, v in pairs(ModuleRefer.RadarModule.bubbleUIPosCache) do
        if Utils.IsNotNull(v.go) and v.go.activeSelf and v.luaGO and RadarTaskUtils.CheckAngleInRange(v.shakeAngle, self.curAngle) then
            v.luaGO:Shake(self.curAngle, v.shakeAngle)
        end
    end
end

function RadarMediator:CheckRadarMediatorOpen()
    local radarMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.RadarMediator)
    if radarMediator then
        return true
    end
    return false
end

function RadarMediator:GetTracingPets()
    local pets = ModuleRefer.RadarModule:GetRadarTracingPets()
    for i = 1, 3 do
        if self.trackStatus == 2 then
            self.tracingPets[i]:FeedData({cfgId = pets[i]})
        else
            if i <= #pets then
                -- self.tracingPets[i]:SetVisible(true)
                self.tracingPets[i]:FeedData({cfgId = pets[i]})
            end
        end
    end
end

function RadarMediator:CheckWorldEventOpen()
    local cfg = ConfigRefer.ConstBigWorld
    local level = self.curRadarLevel
    local canShow = level >= cfg:RadarDisplayWorldEvent()
    if not canShow then
        self.group_world_event:SetVisible(false) -- 雷达世界事件
        return
    end

    local isActivityOpen, item1, item2 = ModuleRefer.WorldEventModule:IsPersonalAllianceExpeditionOpen()
    self.group_world_event:SetVisible(isActivityOpen)
    self.count1 = 0
    self.count2 = 0
    if isActivityOpen then
        self.item1 = item1
        self.item2 = item2
        local itemCfg1 = ConfigRefer.Item:Find(item1)
        local itemCfg2 = ConfigRefer.Item:Find(item2)
        local uid1 = ModuleRefer.InventoryModule:GetUidByConfigId(item1)
        local uid2 = ModuleRefer.InventoryModule:GetUidByConfigId(item2)

        if uid1 then
            self.count1 = ModuleRefer.InventoryModule:GetItemInfoByUid(uid1).Count
        end
        if uid2 then
            self.count2 = ModuleRefer.InventoryModule:GetItemInfoByUid(uid2).Count
        end
    end
    self.p_text_event_quantity_1.text = "x" .. self.count1
    self.p_text_event_quantity_2.text = "x" .. self.count2
end

function RadarMediator:OnBtnClickUseWorldEventItem1()
    if self.count1 <= 0 then
        ---@type CommonItemDetailsParameter
        local param = {}
        param.clickTransform = self.p_btn_event_1.transform
        param.itemId = self.item1
        param.itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM
        g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
    else
        ModuleRefer.WorldEventModule:ValidateItemUse(self.item1, self.count1, nil, true)
    end
end

function RadarMediator:OnBtnClickUseWorldEventItem2()
    if self.count2 <= 0 then
        ---@type CommonItemDetailsParameter
        local param = {}
        param.clickTransform = self.p_btn_event_2.transform
        param.itemId = self.item2
        param.itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM
        g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
    else
        ModuleRefer.WorldEventModule:ValidateItemUse(self.item2, self.count2, nil, true)
    end
end

function RadarMediator:OnBtnClickLandform()
    g_Game.UIManager:Open(UIMediatorNames.LandformIntroUIMediator)
end

function RadarMediator:CheckPetTraceStatus(isDelay)
    if isDelay then
        local timer = TimerUtility.DelayExecute(function()
            self:DORefreshTracingTimes()
            self:DORefreshTracingState(true)
        end, 0.8)
        self.timerList[#self.timerList + 1] = timer

    else
        self:DORefreshTracingTimes()
        self:DORefreshTracingState()
    end
end

function RadarMediator:DORefreshTracingTimes()
    local status = ModuleRefer.RadarModule:GetRadarPetTraceState()
    local curT, maxT = ModuleRefer.RadarModule:GetRadarTrackingPetTimes()
    self.curPetTraceTime = curT
    if curT == 0 and status == 2 then
        self.p_text_trace_time.text = I18N.Get("radar_info_unrecovered_areas")
        self.p_tip_time:SetVisible(true)

        self.p_text_trace_quantity.text = I18N.GetWithParams("radartrack_info_tracking_times", curT, maxT)
        self.p_text_trace_time.text = I18N.GetWithParams("radartrack_info_restore", "00:00:00")
        self:SetCountDown()
        self:SetCountDownTimer()
    else
        self:StopTimer()
        self.p_text_trace_time.text = ""
        self.p_tip_time:SetVisible(false)
    end
end

function RadarMediator:DORefreshTracingState(isDelay)
    local status = ModuleRefer.RadarModule:GetRadarPetTraceState()
    self.trackStatus = status
    self.p_trace_status:SetState(status)
    if status == 0 then
        self.p_text_status.text = I18N.Get("radartrack_info_tracking")
        self.trigger_trace:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
        self.trigger_trace:ResetAll(CS.FpAnimation.CommonTriggerType.Custom2)
        self:RefreshTrackingProgress()
    elseif status == 1 then
        local pet = ConfigRefer.Pet:Find(ModuleRefer.RadarModule:GetRadarTrackingPet())
        self.p_text_status.text = I18N.GetWithParams("radartrack_info_tracked_to", I18N.Get(pet:Name()))
        self.trigger_trace:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
        if isDelay then
            self.trigger_trace:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
        else
            self.trigger_trace:ResetAll(CS.FpAnimation.CommonTriggerType.Custom2)
        end
    elseif status == 2 then
        self.trigger_trace:ResetAll(CS.FpAnimation.CommonTriggerType.Custom2)
        self.p_text_status.text = I18N.Get("radartrack_btn_track")
        if self.curPetTraceTime > 0 then
            self.trigger_trace:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
        else
            self.trigger_trace:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
        end
    end
    self:GetTracingPets()
    self:RefreshPetTraceReddot()
    local isCityRadar = ModuleRefer.RadarModule:IsCityRadar()
    self.p_btn_landform:SetVisible(not isCityRadar)
end

function RadarMediator:RefreshTrackingProgress()
    local pet = ModuleRefer.RadarModule:GetRadarTrackingPet()
    local radarTasks = ModuleRefer.RadarModule:GetRadarPetTrackingTasks()
    local count = 0
    for k, v in pairs(radarTasks) do
        if v then
            count = count + 1
        end
    end

    self.pool_p_point:HideAll()
    for k, v in pairs(radarTasks) do
        local itemMain = self.pool_p_point:GetItem().Lua
        local isFinish = false
        local isLast = false
        if count > 0 then
            isFinish = true
            count = count - 1
        end
        if isFinish and count == 0 then
            isLast = true
        end
        itemMain:FeedData({fill = isFinish, isLast = isLast})
    end
end

function RadarMediator:RefreshPetTraceReddot()
    if self.trackStatus == 0 then
        self.child_reddot_default:SetVisible(false)
    elseif self.trackStatus == 1 then
        self.child_reddot_default:SetVisible(false)
    elseif self.trackStatus == 2 then
        self.child_reddot_default:SetVisible(self.curPetTraceTime > 0)
    end
end

function RadarMediator:OnBtnClickGotoTrace()
    g_Game.UIManager:Open(UIMediatorNames.RadarPetTraceMediator)
end

function RadarMediator:SetCountDown()
    local curT, maxT = ModuleRefer.RadarModule:GetRadarTrackingPetTimes()
    local lastAddTime = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.Radar.LastAddTime.Seconds
    local cur = g_Game.ServerTime:GetServerTimestampInSeconds()
    -- local nextRefreshT = 8 * 60 * 60 -- 每八小时刷新一次
    -- local seconds = nextRefreshT + lastAddTime - cur
    local seconds = self:GetNextRadarTaskRefreshTime() - cur

    self.p_text_trace_quantity.text = I18N.GetWithParams("radartrack_info_tracking_times", curT, maxT)
    self.p_text_trace_time.text = I18N.GetWithParams("radartrack_info_restore", TimeFormatter.SimpleFormatTimeWithDayHourSeconds(seconds))
end

function RadarMediator:SetCountDownTimer()
    if not self.countdownTimer then
        self.countdownTimer = TimerUtility.IntervalRepeat(function()
            self:SetCountDown()
        end, 1, -1, true)
    end
end

function RadarMediator:StopTimer()
    if self.countdownTimer then
        TimerUtility.StopAndRecycle(self.countdownTimer)
        self.countdownTimer = nil
    end
end

---通过道具获得宠物
---@param isSuccess boolean
---@param data wrpc.SyncGetPetRequest
function RadarMediator:SyncGetPet(isSuccess, data)
    if isSuccess then
        local petView = data.PetView
        local reason = data.Reason
        if reason == wrpc.GetPetReason.GetPetReason_UseItem then
            -- 非首次获得的宠物在雷达界面中弹出来
            if data.PetView.TypeIndex ~= 1 then
                ---@type SEPetSettlementParam
                local param = {}
                param.petCompId = petView.CompId
                param.showAsGetPet = true
                -- local provider = UIAsyncDataProvider.new()
                -- local name = UIMediatorNames.SEPetSettlementMediator
                -- local check = UIAsyncDataProvider.CheckTypes.DoNotShowOnOtherMediator | UIAsyncDataProvider.CheckTypes.DoNotShowInCityZoneRecoverState
                -- local checkFailedStrategy
                -- if self._allowSyncPetPopUpQueue then
                --     checkFailedStrategy = UIAsyncDataProvider.StrategyOnCheckFailed.DelayToAnyTimeAvailable
                -- else
                --     checkFailedStrategy = UIAsyncDataProvider.StrategyOnCheckFailed.Cancel
                -- end
                -- provider:Init(name, nil, check, checkFailedStrategy, false, param)
                -- provider:SetOtherMediatorCheckType(0)
                -- provider:AddOtherMediatorBlackList(UIMediatorNames.SEPetSettlementMediator)
                -- provider:AddOtherMediatorBlackList(UIMediatorNames.CityHatchEggOpenUIMediator)
                -- provider:AddOtherMediatorBlackList(UIMediatorNames.StoryDialogUIMediator)
                -- provider:AddOtherMediatorBlackList(UIMediatorNames.StoryDialogChatUIMediator)
                -- provider:AddOtherMediatorBlackList(UIMediatorNames.StoryDialogRecordUIMediator)
                -- provider:AddOtherMediatorBlackList(UIMediatorNames.StoryDialogSkipPopupUIMediator)
                -- provider:AddOtherMediatorBlackList(UIMediatorNames.RadarMediator)

                --左上特效播完 再弹
                local timer = TimerUtility.DelayExecute(function()
                    g_Game.UIManager:Open(UIMediatorNames.SEPetSettlementMediator, param)
                end, 1)
                self.timerList[#self.timerList + 1] = timer
            end
        end
    end
end

return RadarMediator
