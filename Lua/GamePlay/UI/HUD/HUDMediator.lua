local Delegate = require("Delegate")
local HUDConst = require("HUDConst")
local BaseUIMediator = require("BaseUIMediator")
local EventConst = require('EventConst')
local ModuleRefer = require('ModuleRefer')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local HUDMediatorPartDefine = require("HUDMediatorPartDefine")
local Utils = require("Utils")
local TimelineGameEventDefine = require("TimelineGameEventDefine")
local HUDLogicPartDefine = require("HUDLogicPartDefine")
local UIMediatorNames = require("UIMediatorNames")
local DBEntityPath = require('DBEntityPath')
local KingdomConstant = require('KingdomConstant')
local KingdomMapUtils = require('KingdomMapUtils')
local TimerUtility = require('TimerUtility')

---@class HUDMediator:BaseUIMediator
---@field new fun():HUDMediator
---@field super BaseUIMediator
---@field visibleStates table
local HUDMediator = class('HUDMediator', BaseUIMediator)
local forceFastfoward = false

function HUDMediator:ctor()
    BaseUIMediator.ctor(self)
    self._timeLineOperatePart = nil
end

function HUDMediator:OnCreate(param)
    self.param = param
    self.logicDic = {}
    self.logicDic[HUDLogicPartDefine.playInfoComp] = self:LuaObject("child_hud_player_info")
    self.logicDic[HUDLogicPartDefine.communityComp] = self:LuaObject("child_hud_community")
    self.logicDic[HUDLogicPartDefine.mapComp] = self:LuaObject("child_hud_map_function")
    self.logicDic[HUDLogicPartDefine.taskComp] = self:LuaObject("child_hud_group_mission")
    -- self.logicDic[HUDLogicPartDefine.buildComp] = self:LuaObject("child_hud_build")
    -- self.logicDic[HUDLogicPartDefine.scienceComp] = self:LuaObject("child_hud_science")
    self.logicDic[HUDLogicPartDefine.resourceComp] = self:LuaObject("child_hud_resources")
    self.logicDic[HUDLogicPartDefine.activityComp] = self:LuaObject("child_hud_activity")
    self.logicDic[HUDLogicPartDefine.bottomComp] = self:LuaObject("child_hud_bottomright")
    self.logicDic[HUDLogicPartDefine.popNoticeComp] = self:LuaObject("child_hud_pop_notice")
    self.logicDic[HUDLogicPartDefine.residentComp] = self:LuaObject("child_hud_resident")
    self.logicDic[HUDLogicPartDefine.troopComp] = self:LuaObject("child_hud_troop_list")
    self.logicDic[HUDLogicPartDefine.injuredComp] = self:LuaObject("child_hud_injured")
    self.logicDic[HUDLogicPartDefine.explorerFog] = self:LuaObject("child_hud_lod_explor_fog")
    self.logicDic[HUDLogicPartDefine.lodHint] = self:LuaObject("child_hud_lod_hint")
    self.logicDic[HUDLogicPartDefine.bossInfoComp] = self:LuaObject("p_boss_battle_Info")
    self.logicDic[HUDLogicPartDefine.bossDmgRankComp] = self:LuaObject("child_league_battle_rank")
    self.logicDic[HUDLogicPartDefine.worldEventComp] = self:LuaObject("p_group_world_events")
    self.logicDic[HUDLogicPartDefine.activityNoticeComp] = self:LuaObject("child_hud_activity_event")
    self.logicDic[HUDLogicPartDefine.utcClock] = self:LuaObject("p_btn_time")

    ---@type table<HUDMediatorPartDefine, CS.UnityEngine.CanvasGroup>
    self.partDic = {}
    local mainTrans = self.CSComponent.transform:Find("main")
    local canvasGroupType = typeof(CS.UnityEngine.CanvasGroup)
    self.mainCanvasGroup = self:BindComponent("main", canvasGroupType)
    self.partDic[HUDMediatorPartDefine.topLeft] = mainTrans:Find("topleft"):GetComponent(canvasGroupType)
    self.partDic[HUDMediatorPartDefine.bottomLeft] = mainTrans:Find("bottomleft"):GetComponent(canvasGroupType)
    self.partDic[HUDMediatorPartDefine.left] = mainTrans:Find("left"):GetComponent(canvasGroupType)
    self.partDic[HUDMediatorPartDefine.topRight] = mainTrans:Find("topright"):GetComponent(canvasGroupType)
    self.partDic[HUDMediatorPartDefine.bottomRight] = mainTrans:Find("bottomright"):GetComponent(canvasGroupType)
    self.partDic[HUDMediatorPartDefine.top] = mainTrans:Find("top"):GetComponent(canvasGroupType)
    self.partDic[HUDMediatorPartDefine.right] = mainTrans:Find("right"):GetComponent(canvasGroupType)
    self.partDic[HUDMediatorPartDefine.base_top] = mainTrans:Find("base_top"):GetComponent(canvasGroupType)
    self.partDic[HUDMediatorPartDefine.bossInfo] = mainTrans:Find("p_group_behemoth"):GetComponent(canvasGroupType)
    self.partDic[HUDMediatorPartDefine.fullscreen] = self.CSComponent.transform:Find("fullscreen"):GetComponent(canvasGroupType)

    self.visibleStates = {}
    self.aniTrigger = self:AnimTrigger('vx_trigger')
    self.bottomRight = self:GameObject("bottomright")
    self.threeBtns = self:GameObject("btns")
    self.dog = self:GameObject("child_hud_explorer_map")
    self.bottomLeft = self:GameObject("bottomleft")
    self.task = self:GameObject("child_hud_group_mission")

    self.p_world_events_normal = self:GameObject("p_world_events_normal")
    self.p_world_events_boss = self:GameObject("p_world_events_boss")
    self.p_group_world_events = self:GameObject("p_group_world_events")
    self.isWorldEventBoss = false

    --迷雾宝箱

    self.child_hud_mist_box = self:GameObject('child_hud_mist_box')
    self.p_text_set = self:Text('p_text_set','bw_mistevent_info_discover')
    self.p_btn_goto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnClickBoxGoto))
    self.p_text_goto = self:Text('p_text_goto','bw_mistevent_btn_goto')
    self.child_btn_close = self:Button('child_btn_close', Delegate.GetOrCreate(self, self.OnClickBoxClose))
    self.mist_box_trigger = self:BindComponent("mist_box_trigger", typeof(CS.FpAnimation.FpAnimationCommonTrigger))

    self.rewardBoxButton = self:Button("p_btn_se_rewards", Delegate.GetOrCreate(self, self.OnOpenRewardBoxPopup))

    ---@type HudLandformSwitchPanel
    self.landformPanel = self:LuaObject("p_landform_switch")
    self.landformPanel:SetVisible(false)

    --防止p_group_behemoth被UE隐藏导致巨兽HUD显示不出来
    self.partDic[HUDMediatorPartDefine.bossInfo]:SetVisible(true)
    self:ShowHidePartChanged(HUDMediatorPartDefine.bossInfo, false)

    --防止fullscreen被UE隐藏导致被攻击特效显示不出来
    self.partDic[HUDMediatorPartDefine.fullscreen]:SetVisible(true)
    self:ShowHidePartChanged(HUDMediatorPartDefine.fullscreen, true)
end

function HUDMediator:HideForNewbieScene()
    if KingdomMapUtils.IsNewbieState() then
        self.bottomRight:SetActive(false)
        self.threeBtns:SetActive(false)
        self.dog:SetActive(false)
        self.bottomLeft:SetActive(false)
        self.task:SetActive(false)
    end
end

function HUDMediator:OnShow(param)
    self.curScene = g_Game.SceneManager.current
    self.curScene:AddLodChangeListener(Delegate.GetOrCreate(self, self.OnLodChanged))
    g_Game.EventManager:AddListener(EventConst.HUD_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnCityStateChanged))
    g_Game.EventManager:AddListener(EventConst.HUD_PART_SHOW_HIDE_CHANGE, Delegate.GetOrCreate(self, self.ShowHidePartChanged))
    g_Game.EventManager:AddListener(EventConst.HUD_LOGIC_SHOW_HIDE_CHANGE, Delegate.GetOrCreate(self, self.ShowHideLogicChanged))
    g_Game.EventManager:AddListener(EventConst.STORY_TIMELINE_GAME_EVENT_START, Delegate.GetOrCreate(self, self.OnTimelineControlEventStart))
    g_Game.EventManager:AddListener(EventConst.STORY_TIMELINE_GAME_EVENT_END, Delegate.GetOrCreate(self, self.OnTimelineControlEventEnd))
    g_Game.EventManager:AddListener(EventConst.WORLD_EVENT_RECORD_UI_STATE_CHANGEED, Delegate.GetOrCreate(self, self.ChangeLeftUIState))
    g_Game.EventManager:AddListener(EventConst.MAP_FOCUS_BOSS_CHANGED, Delegate.GetOrCreate(self, self.OnMapFocusBossChanged))
    g_Game.EventManager:AddListener(EventConst.WORLD_EVENT_SHOW_HIDE, Delegate.GetOrCreate(self, self.SetWorldEventPanel))
    g_Game.EventManager:AddListener(EventConst.MIST_BOX_FOUND, Delegate.GetOrCreate(self, self.ShowMistBoxPanel))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.SystemEntry.OpenSystems.MsgPath, Delegate.GetOrCreate(self, self.OnOpenSystemsChanged))

    -- 初始化界面
    self:OnCityStateChanged(HUDConst.HUD_STATE.CITY)

    self:HideForNewbieScene()

    -- 初始化各个系统入口按钮状态
    self:InitSystemEntryeBtn()

    self:SetupRewardBoxes()

    ModuleRefer.LeaderboardModule:UpdateDailyRewardState()
end

function HUDMediator:OnHide(param)
    self.curScene:RemoveLodChangeListener(Delegate.GetOrCreate(self, self.OnLodChanged))
    g_Game.EventManager:RemoveListener(EventConst.STORY_TIMELINE_GAME_EVENT_START, Delegate.GetOrCreate(self, self.OnTimelineControlEventStart))
    g_Game.EventManager:RemoveListener(EventConst.STORY_TIMELINE_GAME_EVENT_END, Delegate.GetOrCreate(self, self.OnTimelineControlEventEnd))
    g_Game.EventManager:RemoveListener(EventConst.HUD_PART_SHOW_HIDE_CHANGE, Delegate.GetOrCreate(self, self.ShowHidePartChanged))
    g_Game.EventManager:RemoveListener(EventConst.HUD_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnCityStateChanged))
    g_Game.EventManager:RemoveListener(EventConst.HUD_LOGIC_SHOW_HIDE_CHANGE, Delegate.GetOrCreate(self, self.ShowHideLogicChanged))
    g_Game.EventManager:RemoveListener(EventConst.WORLD_EVENT_RECORD_UI_STATE_CHANGEED, Delegate.GetOrCreate(self, self.ChangeLeftUIState))
    g_Game.EventManager:RemoveListener(EventConst.MAP_FOCUS_BOSS_CHANGED, Delegate.GetOrCreate(self, self.OnMapFocusBossChanged))
    g_Game.EventManager:RemoveListener(EventConst.WORLD_EVENT_SHOW_HIDE, Delegate.GetOrCreate(self, self.SetWorldEventPanel))
    g_Game.EventManager:RemoveListener(EventConst.MIST_BOX_FOUND, Delegate.GetOrCreate(self, self.ShowMistBoxPanel))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.SystemEntry.OpenSystems.MsgPath, Delegate.GetOrCreate(self, self.OnOpenSystemsChanged))
    self.showWorldEvent = nil

    self:ShutdownRewardBoxes()

    self:OnClickBoxClose()
end

function HUDMediator:OnLodChanged(oldLod, newLod)
    if self.curLod and self.curLod == newLod then
        return
    end

    self.curLod = newLod
    if KingdomMapUtils.InSymbolMapLod(newLod) then
        self:OnCityStateChanged(HUDConst.HUD_STATE.HIGHT)
    else
        self:OnCityStateChanged(HUDConst.HUD_STATE.CITY)
    end

	self:RefreshrewardBoxButton()
    self:ChangeLod(newLod)
end

function HUDMediator:ChangeLod(newLod)
    if self.logicDic[HUDLogicPartDefine.mapComp] then
        self.logicDic[HUDLogicPartDefine.mapComp]:ChangeLod(newLod)
    end

end

function HUDMediator:OnTypeVisible(fastForward)
	fastForward = fastForward or forceFastfoward

    if not self.isVisible then
        if fastForward then
            self.aniTrigger:FinishAll(FpAnimTriggerEvent.OnClose)
            self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
            self.aniTrigger:FinishAll(FpAnimTriggerEvent.Custom1)
            self:OnAnimTriggerEnd()
        else
            self.aniTrigger:FinishAll(FpAnimTriggerEvent.OnClose)
            self.aniTrigger:ResetAll(FpAnimTriggerEvent.Custom1)
            self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom1, Delegate.GetOrCreate(self, self.OnAnimTriggerEnd))
        end
        self:UpdateTroopCompShowState()
    else
        self.aniTrigger:FinishAll(FpAnimTriggerEvent.OnClose)
        self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
        self.aniTrigger:FinishAll(FpAnimTriggerEvent.Custom1)
        self:OnAnimTriggerEnd()
        if Utils.IsNotNull(self.mainCanvasGroup) then
            self.mainCanvasGroup.alpha = 1
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.HUD_TYPE_VISIBLE)
end

function HUDMediator:GetVisible()
    return self.isVisible
end
  
function HUDMediator:OnAnimTriggerEnd()
    self.isVisible = true
    if self.logicDic[HUDLogicPartDefine.playInfoComp] then
        self.logicDic[HUDLogicPartDefine.playInfoComp]:RecrodPowerPos()
        self.logicDic[HUDLogicPartDefine.playInfoComp]:RecrodCorePos()
    end
    if self.logicDic[HUDLogicPartDefine.resourceComp] then
        self.logicDic[HUDLogicPartDefine.resourceComp]:RecordCoinPos()
        self.logicDic[HUDLogicPartDefine.resourceComp]:RecordMoneyPos()
        self.logicDic[HUDLogicPartDefine.resourceComp]:RecordResCellPos()
    end
    -- ModuleRefer.PetCollectionModule:ShowNextPopUpWindow()
end

function HUDMediator:OnTypeInvisible(fastForward)
	fastForward = fastForward or forceFastfoward
	
    if self.isVisible then
        self.aniTrigger:FinishAll(FpAnimTriggerEvent.Custom1)
        self.aniTrigger:ResetAll(FpAnimTriggerEvent.OnClose)
        self.aniTrigger:PlayAll(FpAnimTriggerEvent.OnClose)
        if fastForward then
            self.aniTrigger:FinishAll(FpAnimTriggerEvent.OnClose)
        end
    else
        self.aniTrigger:FinishAll(FpAnimTriggerEvent.Custom1)
        self.aniTrigger:PlayAll(FpAnimTriggerEvent.OnClose)
        self.aniTrigger:FinishAll(FpAnimTriggerEvent.OnClose)
    end
    self.isVisible = false
end

function HUDMediator:OnCityStateChanged(hudState)
    self:ResetHudDefaultCompState()
    self:ChangeCityCompState(hudState)
end

function HUDMediator:ChangeCityCompState(hudState)
    
    ---@type HUDMapFunctionComponent
    local mapComp = self.logicDic[HUDLogicPartDefine.mapComp]
    local playerInfoComp = self.logicDic[HUDLogicPartDefine.playInfoComp]
    if hudState == HUDConst.HUD_STATE.CITY then
        self:HideMistBoxPanel()
        local isCity = self.param and self.param.isCity and self.param.isCity()
        local isMyCity = self.param and self.param.isMyCity and self.param.isMyCity()
        if isCity then
            if isMyCity then
                local city = ModuleRefer.CityModule:GetMyCity()
                if not city or (not city:IsInSeBattleMode() and not city:IsInRecoverZoneEffectMode() and not city:IsInSingleSeExplorerMode()) then
                    self:OnMapFocusBossChanged(nil)
                end
                playerInfoComp:SwitchPlayerInfo(true)
                mapComp:Switch(true, true, false)
                self:ShowHideLogicChanged(HUDLogicPartDefine.inMyCity, false)
            else
                self:OnMapFocusBossChanged(nil)
                playerInfoComp:SwitchPlayerInfo(false)
                mapComp:Switch(true, false, false)
                self:ShowHideLogicChanged(HUDLogicPartDefine.inOtherCity, false)
            end
            self:ShowHideLogicChanged(HUDLogicPartDefine.worldEventComp, false)
            self.landformPanel:SetVisible(false)
        else
            self:OnMapFocusBossChanged(nil)
            playerInfoComp:SwitchPlayerInfo(true)
            mapComp:Switch(false, false, false)
            self.landformPanel:SetVisible(false)
            local worldEventMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.WorldEventRecordMediator)
            if worldEventMediator and worldEventMediator:IsShow() then
                self:ShowHideLogicChanged(HUDLogicPartDefine.worldEventRecordOnOutCity, false)
            else
                self:ShowHideLogicChanged(HUDLogicPartDefine.outCity, false)
                if self.showWorldEvent then
                    self:ShowHideLogicChanged(HUDLogicPartDefine.taskComp, false)
                    self:ShowHideLogicChanged(HUDLogicPartDefine.worldEventComp, true)
                end
            end
        end
    elseif hudState == HUDConst.HUD_STATE.HIGHT then
        self:OnMapFocusBossChanged(nil)
        mapComp:Switch(false, false, true)
        self:ShowHideLogicChanged(HUDLogicPartDefine.inHighLod, false)
        self.landformPanel:SetVisible(true)
    else
        self:OnMapFocusBossChanged(nil)
    end
	
end

function HUDMediator:ResetHudDefaultCompState()
    table.clear(self.visibleStates)
    for _, comp in pairs(self.logicDic) do
        -- comp:SetVisible(true)
        self.visibleStates[comp] = true
    end
end

function HUDMediator:ShowHideLogicChanged(partFlags, isShow)
    for part, comp in pairs(self.logicDic) do
        if (part & partFlags) ~= 0 then
            -- comp:SetVisible(isShow)
            self.visibleStates[comp] = isShow
        end
    end
    for comp, state in pairs(self.visibleStates) do
        comp:SetVisible(state)
    end
end

---@private
function HUDMediator:ShowHidePartChanged(partFlags, isShow, lastChanged)
    local changed = {}
    local alphaValue
    if isShow then
        alphaValue = 1
    else
        alphaValue = 0
    end
    for part, canvasGroup in pairs(self.partDic) do
        if Utils.IsNotNull(canvasGroup) then
            if (part & partFlags) ~= 0 and (not lastChanged or lastChanged[canvasGroup]) then
                canvasGroup.alpha = alphaValue
                canvasGroup.interactable = alphaValue > 0
                canvasGroup.blocksRaycasts = alphaValue > 0
                -- canvasGroup.gameObject:SetActive(alphaValue > 0)
                changed[canvasGroup] = true
            end
        end
    end
    return changed
end

function HUDMediator:OnTimelineControlEventStart(args)
    local city = ModuleRefer.CityModule:GetMyCity()
    if city and (city:IsInSeBattleMode() or city:IsInRecoverZoneEffectMode() or city:IsInSingleSeExplorerMode()) then
        return
    end
    if args[1] == TimelineGameEventDefine.HUD_HIDE_PART then
        local flag = args[2]
        if not flag then
            return
        end
        local part = HUDMediatorPartDefine[flag]
        if not part then
            return
        end
        self._timeLineOperatePart = self:ShowHidePartChanged(part, false)
    end
end

function HUDMediator:OnTimelineControlEventEnd(args)
    if args[1] == TimelineGameEventDefine.HUD_HIDE_PART then
        local flag = args[2]
        if not flag then
            return
        end
        local part = HUDMediatorPartDefine[flag]
        if not part then
            return
        end
        local lastChanged = self._timeLineOperatePart
        self._timeLineOperatePart = nil
        local city = ModuleRefer.CityModule:GetMyCity()
        if city and (city:IsInSeBattleMode() or city:IsInRecoverZoneEffectMode() or city:IsInSingleSeExplorerMode()) then
            return
        end
        self:ShowHidePartChanged(part, true, lastChanged)
    end
end

function HUDMediator:OnForceLayoutPart(partFlags)
    for part, canvasGroup in pairs(self.partDic) do
        if Utils.IsNotNull(canvasGroup) then
            if (part & partFlags) ~= 0 then
                local layout = part:GetComponent()
            end
        end
    end
end

function HUDMediator:GetTargetEventBtn(param)
    if self.logicDic[HUDLogicPartDefine.bottomComp] then
        return self.logicDic[HUDLogicPartDefine.bottomComp]:GetTargetEventBtn(param)
    end
end

function HUDMediator:GetCoinPos()
    if self.logicDic[HUDLogicPartDefine.resourceComp] then
        return self.logicDic[HUDLogicPartDefine.resourceComp]:GetCoinPos()
    end
end

function HUDMediator:GetCorePos()
    if self.logicDic[HUDLogicPartDefine.playInfoComp] then
        return self.logicDic[HUDLogicPartDefine.playInfoComp]:GetCorePos()
    end
end

function HUDMediator:GetPowerPos()
    if self.logicDic[HUDLogicPartDefine.playInfoComp] then
        return self.logicDic[HUDLogicPartDefine.playInfoComp]:GetPowerPos()
    end
end

function HUDMediator:GetMoneyPos()
    if self.logicDic[HUDLogicPartDefine.resourceComp] then
        return self.logicDic[HUDLogicPartDefine.resourceComp]:GetMoneyPos()
    end
end

function HUDMediator:GetResCellPos(index)
    if self.logicDic[HUDLogicPartDefine.resourceComp] then
        return self.logicDic[HUDLogicPartDefine.resourceComp]:GetResCellPos(index)
    end
end

function HUDMediator:GetHammerPos()
    if self.logicDic[HUDLogicPartDefine.mapComp] then
        return self.logicDic[HUDLogicPartDefine.mapComp]:GetHammerPos()
    end
end

function HUDMediator:ChangeLeftUIState(isShow)
    self:ShowHideLogicChanged(HUDLogicPartDefine.worldEventPanel, isShow)
end

function HUDMediator:InitSystemEntryeBtn()
    local ConfigRefer = require("ConfigRefer")
    for _, v in ConfigRefer.SystemEntry:ipairs() do
        if v:ButtonName() and string.len(v:ButtonName()) > 0 then
            -- local clickFunc = function()
            --     local I18N = require("I18N")
            --     local content = I18N.Get(v:LockedTips())
            --     ModuleRefer.ToastModule:AddJumpToast(content)
            -- end
            -- if v:LockedPerformance() == SystemEntryLockedPerformanceType.Locked then
            --     -- body
            -- end
            local btnGO = self:Button(v:ButtonName())
            ModuleRefer.NewFunctionUnlockModule:AddToNewFunctionList(v:Id(), btnGO)
        end
    end
end

function HUDMediator:UpdateTroopCompShowState()
    if self.logicDic[HUDLogicPartDefine.troopComp] then
        self.logicDic[HUDLogicPartDefine.troopComp]:UpdateShowState()
    end
end

function HUDMediator:OnOpenSystemsChanged(data, changed)
    if changed then
        self:UpdateTroopCompShowState()
    end
end

---@param boss TroopCtrl
---@return boolean
function HUDMediator.CheckBossIsMyAllianceAttackTarget(boss)
    ---@type BehemothTroopCtrl
    local cageBoss = boss
    if not cageBoss or not cageBoss.cageEntity or not ModuleRefer.AllianceModule:IsInAlliance() then
        return false
    end
    local warInfo = ModuleRefer.VillageModule:GetBehemothCageWarInfo(cageBoss.cageEntity, ModuleRefer.AllianceModule:GetAllianceId())
    if not warInfo then
        return false
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    return warInfo.EndTime > nowTime
end

---@param boss TroopCtrl
function HUDMediator:OnMapFocusBossChanged(boss)
    if HUDMediator.CheckBossIsMyAllianceAttackTarget(boss) then
        self:ShowHidePartChanged(HUDMediatorPartDefine.bossInfo, true)
        self:ShowHidePartChanged(HUDMediatorPartDefine.allTop | HUDMediatorPartDefine.left, false)
        self:ShowHideLogicChanged(HUDLogicPartDefine.bossInfoComp | HUDLogicPartDefine.bossDmgRankComp, true)
        self.logicDic[HUDLogicPartDefine.bossInfoComp]:FeedData({bossData = boss._data})
        self.logicDic[HUDLogicPartDefine.bossDmgRankComp]:FeedData({boss = boss})
    else
        self:ShowHideLogicChanged(HUDLogicPartDefine.bossInfoComp | HUDLogicPartDefine.bossDmgRankComp, false)
        self:ShowHidePartChanged(HUDMediatorPartDefine.bossInfo, false)
        self:ShowHidePartChanged(HUDMediatorPartDefine.allTop | HUDMediatorPartDefine.left, true)
    end
end

function HUDMediator:SetWorldEventPanel(param)
    local isShow = param.isShow

    if self.showWorldEvent == true then
        if isShow == false then
            if self.worldEventEntityId and param.data and self.worldEventEntityId ~= param.data.entityId then
                return
            end
        else
            if self.worldEventEntityId == param.data.entityId then
                return
            end
        end
    end

    if self.isWorldEventBoss ~= param.isBoss then
        self.isWorldEventBoss = param.isBoss
        local parent = self.isWorldEventBoss and self.p_world_events_normal or self.p_world_events_boss
        self.p_group_world_events.transform:SetParent(parent.transform)
        self.p_group_world_events.transform.localPosition = CS.UnityEngine.Vector3.zero
    end

    if isShow then
        self.worldEventEntityId = param.data.entityId
    else
        self.worldEventEntityId = nil
    end

    self.showWorldEvent = isShow

    if param.isBoss then
        g_Game.EventManager:TriggerEvent(EventConst.HUD_HIDE_LAYOUT_BUTTONS, not isShow)
    end

    self:ShowHideLogicChanged(HUDLogicPartDefine.worldEventComp, isShow)
    ModuleRefer.WorldEventModule:SetShowToast(isShow)

    if isShow then
        self.logicDic[HUDLogicPartDefine.worldEventComp]:FeedData(param.data)
        self.task:SetVisible(false)
    else
        local lod = KingdomMapUtils.GetLOD()
        if lod < KingdomConstant.SymbolLod then
            self.task:SetVisible(true)
        end
    end
end


function HUDMediator:WriteBlackboard(key, value)
    if not self.blackboard then
        self.blackboard = {}
    end
    self.blackboard[key] = value
    g_Game.EventManager:TriggerEvent(EventConst.HUD_BLACKBOARD_CHANGED, self, key)
end

function HUDMediator:ReadBlackboard(key, clear)
    local ret = self.blackboard and self.blackboard[key]
    if self.blackboard and clear then
        self.blackboard[key] = nil
    end
    return ret
end

function HUDMediator:OnOpenRewardBoxPopup()
    g_Game.UIManager:Open(UIMediatorNames.UIRewardTipsMediator)
end

function HUDMediator:SetupRewardBoxes()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper3.PlayerRewardBox.MsgPath, Delegate.GetOrCreate(self, self.PlayerRewardBoxChanged))

    self:RefreshrewardBoxButton()
end

function HUDMediator:ShutdownRewardBoxes()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper3.PlayerRewardBox.MsgPath, Delegate.GetOrCreate(self, self.PlayerRewardBoxChanged))
end

function HUDMediator:RefreshrewardBoxButton()
	local inSymbolLod = KingdomMapUtils.InSymbolMapLod(self.curLod)
    local boxes = ModuleRefer.PlayerModule:GetRewardBoxes()
    local count = boxes:Count()
    local hasRewardBoxes = count > 0
    self.rewardBoxButton:SetVisible(hasRewardBoxes and not inSymbolLod)
end

function HUDMediator:PlayerRewardBoxChanged()
    self:RefreshrewardBoxButton()
end


function HUDMediator:ShowMistBoxPanel(param)
    self.child_hud_mist_box:SetVisible(true)
    self.mist_box_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    self.showMistFunc = param.func
    self:ClearMistBoxTimer()
    self.mistBoxDelayTimer = TimerUtility.DelayExecute(function()
        self:OnClickBoxClose()
    end, 4)
end

function HUDMediator:OnClickBoxGoto()
    if self.showMistFunc then
        self.showMistFunc()
    end
    self:OnClickBoxClose()
end

function HUDMediator:OnClickBoxClose()
    self.mist_box_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
    self.showMistFunc = nil
    self:ClearMistBoxTimer()
    self.mistBoxDelayTimer = TimerUtility.DelayExecute(function()
        self:HideMistBoxPanel()
    end, 1)
end

function HUDMediator:HideMistBoxPanel()
    self.child_hud_mist_box:SetVisible(false)
end

function HUDMediator:ClearMistBoxTimer()
    if self.mistBoxDelayTimer then
        TimerUtility.StopAndRecycle(self.mistBoxDelayTimer)
        self.mistBoxDelayTimer = nil
    end
end

return HUDMediator
