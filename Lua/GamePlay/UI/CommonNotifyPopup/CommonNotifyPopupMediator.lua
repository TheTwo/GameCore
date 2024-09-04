--- scene:scene_tips_top

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local TimerUtility = require("TimerUtility")
local FpAnimTriggerEvent = require("FpAnimTriggerEvent")
local BaseUIMediator = require("BaseUIMediator")
local ToastFuncType = require("ToastFuncType")
local UIHelper = require("UIHelper")
local I18N = require("I18N")
local AllianceModuleDefine = require("AllianceModuleDefine")
local ModuleRefer = require('ModuleRefer')
local UIMediatorNames = require("UIMediatorNames")

---@class AllianceRecruitTopToastParameter
---@field infos wrpc.AllianceBriefInfo[]
---@field index number
---@field allianceDetailFunc fun()
---@field allianceJoinFunc fun(lockable:CS.UnityEngine.Transform)

---@class CommonNotifyPopupMediatorParameter
---@field icon string
---@field title string
---@field content string
---@field textBlood string
---@field acceptAction fun(context:any)
---@field context any
---@field btnText string
---@field progress number
---@field reward {icon:string, countStr:string, showPlus:boolean, onClick:fun()}[]
---@field funcType number @ToastFuncType
---@field fromServer boolean
---@field endTime number
---@field allianceInfo AllianceRecruitTopToastParameter

---@class CommonNotifyPopupMediator:BaseUIMediator
---@field new fun():CommonNotifyPopupMediator
---@field super BaseUIMediator
local CommonNotifyPopupMediator = class('CommonNotifyPopupMediator', BaseUIMediator)

function CommonNotifyPopupMediator:OnCreate(param)
    self._mask = self:GameObject("mask")
    self._p_img_head_boss = self:Image("p_img_head_boss")
    self._p_base_text= self:GameObject("base_text")
    self._p_text_blood = self:Text("p_text_blood")
    self._p_text_title = self:Text("p_text_title")
    self._p_text_info = self:Text("p_text_info")
    self._p_group_reward = self:GameObject("p_group_reward")
    self._p_text_reward = self:Text("p_text_reward", "world_jiangli")
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.OnClickBtnClose))
    self._p_comp_btn_boss = self:Button("p_comp_btn_boss", Delegate.GetOrCreate(self, self.OnClickAccept))
    self._p_text = self:Text("p_text")
    self._p_progress = self:Slider("p_progress")
    self._p_aniTrigger = self:AnimTrigger('vx_trigger')
    self._p_world_event = self:Image("p_world_event")
    self._p_group_league_recruit_language = self:GameObject("p_group_league_recruit_language")
    self._p_text_language = self:Text("p_text_language")
    self._p_btn_league_recruit = self:GameObject("p_btn_league_recruit")
    self._child_comp_btn_a_m_u2 = self:Button("child_comp_btn_a_m_u2", Delegate.GetOrCreate(self, self.OnClickAllianceDetail))
    self._p_text_league_detail = self:Text("p_text_league_detail", "alliance_recommend_banner_look")
    self._child_comp_btn_b_m_u2 = self:Button("child_comp_btn_b_m_u2", Delegate.GetOrCreate(self, self.OnClickAllianceJoin))
    self._p_text_league_join = self:Text("p_text_league_join", "alliance_recommend_banner_join")
    self._p_league_recruit = self:GameObject("p_league_recruit")
    self._child_league_logo = self:LuaObject("child_league_logo")
    self._p_text_name_league = self:Text("p_text_name_league")
    self._p_text_info_league = self:Text("p_text_info_league")
    self._p_btn_close_2 = self:Button("p_btn_close_2", Delegate.GetOrCreate(self, self.OnClickBtnClose))
    self._p_group_1 = self:GameObject("p_group_1")
    self._p_group_2 = self:GameObject("p_group_2")
    ---@type {go:CS.UnityEngine.GameObject, res:CommonResourceBtn}[]
    self._p_rewardItems = {}
    for i = 1, 3 do
        self._p_rewardItems[i] = {
            go = self:GameObject("p_reward_" .. i),
            res = self:LuaObject("child_resource_" .. i)
        }
    end
    self._p_progress.gameObject:SetActive(false)
    self.toastList = {}
end

---@param data CommonNotifyPopupMediatorParameter
function CommonNotifyPopupMediator:OnOpened(data)
    g_Game.EventManager:RemoveListener(EventConst.UI_EVENT_NOTIFY_POPUP_NEW, Delegate.GetOrCreate(self, self.OnNewToast))
    g_Game.EventManager:AddListener(EventConst.UI_EVENT_NOTIFY_POPUP_NEW, Delegate.GetOrCreate(self, self.OnNewToast))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_JOINED_WITH_DATA_READY, Delegate.GetOrCreate(self, self.OnJoinAlliance))
    self:PushToast(data)
    self:PopToast(true)
end

function CommonNotifyPopupMediator:OnClose()
    if self.progressTimer then
        TimerUtility.StopAndRecycle(self.progressTimer)
        self.progressTimer = nil
    end
    g_Game.EventManager:RemoveListener(EventConst.UI_EVENT_NOTIFY_POPUP_NEW, Delegate.GetOrCreate(self, self.OnNewToast))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_JOINED_WITH_DATA_READY, Delegate.GetOrCreate(self, self.OnJoinAlliance))
end

---@param data CommonNotifyPopupMediatorParameter
function CommonNotifyPopupMediator:OnNewToast(data)
    self:PushToast(data)
    self:PopToast()
end

---@param data CommonNotifyPopupMediatorParameter
function CommonNotifyPopupMediator:PushToast(data)
    table.insert(self.toastList, 1, data)
end

function CommonNotifyPopupMediator:PopToast(firstOpen)
    if #self.toastList == 0 then
        self:CloseSelf()
        if self._data and self._data.funcType == ToastFuncType.AllianceRecruitTop then
            if self._data.allianceInfo.index < #self._data.allianceInfo.infos then
                g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_FIND_NEXT_RECRUIT_TOP_INFO, self._data.allianceInfo.index + 1)
            end
        end
        return
    end
    if self.progressTimer then
        TimerUtility.StopAndRecycle(self.progressTimer)
        self.progressTimer = nil
    end
    if not firstOpen then
        self._p_aniTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
    end
    local toastInfo = self.toastList[1]
    self:ShowDetails(toastInfo)
    if toastInfo.fromServer and toastInfo.endTime then
        if toastInfo.endTime < g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() then
            table.remove(self.toastList, 1)
            self:PopToast()
            return
        end
        self.progressTimer = TimerUtility.StartFrameTimer(Delegate.GetOrCreate(self, self.OnProgress), 1, -1)
    end
end

---@param data CommonNotifyPopupMediatorParameter
function CommonNotifyPopupMediator:ShowDetails(data)
    self._data = data
    if data.funcType and data.funcType == ToastFuncType.AllianceRecruitTop then
        self:ShowAllianceInfo(data.allianceInfo)
        return
    else
        self:SetAllianceInfoVisable(false)
    end
    self._p_text_title.text = data.title
    if string.IsNullOrEmpty(data.content) then
        self._p_text_info:SetVisible(false)
    else
        self._p_text_info:SetVisible(true)
        self._p_text_info.text = data.content
    end
    self._p_text.text = data.btnText
    if string.IsNullOrEmpty(data.textBlood) then
        self._p_base_text:SetVisible(false)
        self._p_text_blood:SetVisible(false)
    else
        self._p_base_text:SetVisible(true)
        self._p_text_blood:SetVisible(true)
        self._p_text_blood.text = data.textBlood
    end
    if data.funcType and data.funcType == ToastFuncType.ExpeditionNotice then
        self._mask:SetActive(false)
        self._p_world_event:SetVisible(true)
        local isMine, isMulti, isAlliance, isBigEvent = ModuleRefer.WorldEventModule:CheckEventType(data.entity)
        local icon
        if isMine or isMulti then
            icon = "sp_comp_icon_worldevent"
        elseif isAlliance then
            if isBigEvent then
                icon = "sp_comp_icon_worldevent_league"
            else
                icon = "sp_comp_icon_worldevent_multi"
            end
        end
        g_Game.SpriteManager:LoadSprite(UIHelper.IconOrMissing(icon), self._p_world_event)
    else
        self._mask:SetActive(true)
        self._p_world_event:SetVisible(false)
        g_Game.SpriteManager:LoadSprite(UIHelper.IconOrMissing(data.icon), self._p_img_head_boss)
    end
    --self._p_progress.value = data.progress and math.clamp01(data.progress) or 0
    local isEmpty, count = table.IsNullOrEmpty(data.reward)
    if isEmpty then
        self._p_group_reward:SetVisible(false)
    else
        self._p_group_reward:SetVisible(true)
        for i = 3, (count + 1), -1 do
            self._p_rewardItems[i].go:SetVisible(false)
        end
        for i = 1, math.min(3, count) do
            self._p_rewardItems[i].go:SetVisible(true)
            ---@type CommonResourceBtnData
            local iconData = {}
            iconData.iconName = data.reward[i].icon
            iconData.isShowPlus = data.reward[i].showPlus
            iconData.content = data.reward[i].countStr
            iconData.onClick = data.reward[i].onClick
            self._p_rewardItems[i].res:FeedData(iconData)
        end
    end
end

---@param data AllianceRecruitTopToastParameter
function CommonNotifyPopupMediator:ShowAllianceInfo(data)
    local info = data.infos[data.index]
    if not info then
        g_Logger.ErrorChannel("CommonNotifyPopupMediator", "Alliance info is nil")
        return
    end
    self.allianceInfo = info
    self:SetAllianceInfoVisable(true)
    self._p_text_language.text = AllianceModuleDefine.GetConfigLangaugeStr(info.Language)
    self._p_text_name_league.text = string.format("[%s]%s", info.Abbr, info.Name)
    self._p_text_info_league.text = I18N.Get("alliance_recommend_banner")
    self._child_league_logo:FeedData(info.Flag)
end

function CommonNotifyPopupMediator:SetAllianceInfoVisable(show)
    self._p_group_reward:SetActive(not show)
    self._p_comp_btn_boss.gameObject:SetActive(not show)
    self._p_group_league_recruit_language:SetActive(show)
    self._p_league_recruit:SetActive(show)
    self._p_btn_league_recruit:SetActive(show)
    self._p_group_1:SetActive(not show)
    self._p_group_2:SetActive(show)
end

function CommonNotifyPopupMediator:OnProgress()
    local lastTime = self._data.endTime - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    --self._p_progress.value = math.clamp01(lastTime / self._data.duration)
    if lastTime < 0 then
        table.remove(self.toastList, 1)
        self:PopToast()
    end
end

function CommonNotifyPopupMediator:OnClickAccept()
    if self._data and self._data.acceptAction then
        self._data.acceptAction(self._data.context)
    end
    table.remove(self.toastList, 1)
    self:PopToast()
end

function CommonNotifyPopupMediator:OnClickAllianceDetail()
    if self._data and self._data.allianceInfo.allianceDetailFunc then
        self._data.allianceInfo.allianceDetailFunc()
    end
    table.remove(self.toastList, 1)
    self:PopToast()
end

function CommonNotifyPopupMediator:OnClickAllianceJoin()
    if self._data and self._data.allianceInfo.allianceJoinFunc then
        self._data.allianceInfo.allianceJoinFunc(self._child_comp_btn_b_m_u2.transform)
    end
    table.remove(self.toastList, 1)
    self:PopToast()
end

function CommonNotifyPopupMediator:OnClickBtnClose()
    table.remove(self.toastList, 1)
    self:PopToast()
end

function CommonNotifyPopupMediator:OnJoinAlliance()
    table.remove(self.toastList, 1)
    self:PopToast()
    ---@type AllianceMainMediatorParameter
    local openParameter = {
        showJoinAni = true
    }
    g_Game.UIManager:Open(UIMediatorNames.AllianceMainMediator, openParameter)
end

return CommonNotifyPopupMediator