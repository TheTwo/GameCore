---@scene scene_child_activity_league_boss
local BaseUIComponent = require("BaseUIComponent")
local ActivityAllianceBossConst = require("ActivityAllianceBossConst")
local ActivityAllianceBossRegisterStateHelper = require("ActivityAllianceBossRegisterStateHelper")
local AllianceModuleDefine = require("AllianceModuleDefine")
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local EventConst = require('EventConst')
local I18N = require('I18N')
local DBEntityPath = require('DBEntityPath')
local UIMediatorNames = require('UIMediatorNames')
local Utils = require('Utils')
local SlgTouchMenuHelper = require('SlgTouchMenuHelper')
local ItemTableMergeHelper = require('ItemTableMergeHelper')
local CommonConfirmPopupMediatorDefine = require('CommonConfirmPopupMediatorDefine')
local ConfigRefer = require('ConfigRefer')
local EnterSceneForPeerParameter = require('EnterSceneForPeerParameter')
local ActivityBehemothConst = require('ActivityBehemothConst')
local TimeFormatter = require('TimeFormatter')
local TimerUtility = require('TimerUtility')
local GuideUtils = require('GuideUtils')
---@class ActivityAllianceBossRegister : BaseUIComponent
local ActivityAllianceBossRegister = class('ActivityAllianceBossRegister', BaseUIComponent)

local I18N_KEY = ActivityAllianceBossConst.I18N_KEY
local STATE_I18N_KEY = ActivityAllianceBossRegisterStateHelper.STATE_I18N_KEY

local UI_UPDATE_MASK = {
    LEFT_GROUP = 1 << 0,
    TIME_GROUP = 1 << 1,
    REGISTER_BTN = 1 << 2,
    ALL = 0xFFFFFFFF,
}

function ActivityAllianceBossRegister:OnCreate()
    self.imgBoss = self:Image('p_img_monster')

    self.btnInfo = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnInfoClick))
    self.stextBtnInfo = self:Text('p_text_detail_btn', I18N_KEY.TITLE_INFO)

    self.btnRewardPreview = self:Button('p_btn_reward', Delegate.GetOrCreate(self, self.OnBtnRewardPreviewClick))
    self.stextBtnRewardPreview = self:Text('p_text_rewards', I18N_KEY.TITLE_REWARD)

    --- group left
    self.stextLabelBoss = self:Text('p_text_boss', I18N_KEY.LABEL_BOSS)
    self.textLv = self:Text('p_text_lv')
    self.textBossName = self:Text('p_text_boss_name')
    self.stextReward = self:Text('p_text_reward', I18N_KEY.LABEL_REWARD)
    self.tableReward = self:TableViewPro('p_table_reward')

    --- group right
    self.stextTitle = self:Text('p_text_title', I18N_KEY.TITLE)
    self.stextTitleDesc = self:Text('p_text_content_detail', I18N_KEY.TITLE_DESC)
    self.goBtn = self:GameObject('p_btn')
    self.textBtnHint = self:Text('p_text_hint')
    ---@see BistateButton
    self.luaBtnRegister = self:LuaObject('child_comp_btn_b')
    self.textHintCountDown = self:Text('p_text_stage')
    self.goCountDown = self:GameObject('child_activity_countdown')
    ---@see CommonActivityTimer
    self.luaCountDown = self:LuaObject('child_activity_countdown')
    self.textStage = self:Text('p_text_stage')

    self.goGroupStageBattle = self:GameObject('p_group_stage_battle')
    self.textBattleStage = self:Text('p_text_battle')
    self.textReason = self:Text('p_text_reason')

    self.isFirstOpen = true
    self.vxTrigger = self:AnimTrigger('vx_trigger')
end

function ActivityAllianceBossRegister:OnShow()
    if self.isFirstOpen then
        self.isFirstOpen = false
    else
        self.vxTrigger:FinishAll(CS.FpAnimation.CommonTriggerType.OnStart)
    end
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.OnBattleInfoChanged))
    self.luaBtnRegister:SetVisible(true)
end

function ActivityAllianceBossRegister:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.OnBattleInfoChanged))
    self.luaBtnRegister:SetVisible(false)
    if self.delayUpdateTimer then
        TimerUtility.StopAndRecycle(self.delayUpdateTimer)
        self.delayUpdateTimer = nil
    end
end

function ActivityAllianceBossRegister:OnFeedData(param)
    self.tabId = param.tabId
    self.battleId = ActivityBehemothConst.BATTLE_CFG_ID
    self.goBtn:SetActive(true)
    self:UpdateUI(UI_UPDATE_MASK.ALL)
end

function ActivityAllianceBossRegister:UpdateUI(mask)
    if not mask then
        mask = UI_UPDATE_MASK.ALL
    end
    self.uiRole = ActivityAllianceBossRegisterStateHelper.GetCurUIRole(self.battleId)
    self.uiState = ActivityAllianceBossRegisterStateHelper.GetCurUIState(self.battleId)
    if mask & UI_UPDATE_MASK.LEFT_GROUP ~= 0 then
        self:UpdateLeftGroup()
    end
    if mask & UI_UPDATE_MASK.TIME_GROUP ~= 0 then
        self:UpdateTimeGroup()
    end
    if mask & UI_UPDATE_MASK.REGISTER_BTN ~= 0 then
        self:UpdateRegisterBtn()
    end
end

function ActivityAllianceBossRegister:UpdateLeftGroup()
    local behemoth = ModuleRefer.AllianceModule.Behemoth:GetCurrentBindBehemoth()
    local deviceLv = ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceLevel()
    local behemothCfg = behemoth:GetRefKMonsterDataConfig(deviceLv)
    local name, icon, level, _, _, bodyPaint = SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfig(behemothCfg)
    self.textLv.text = level
    self.textBossName.text = name
    g_Game.SpriteManager:LoadSprite(bodyPaint, self.imgBoss)

    local rankRewards, dropRewards, observeRewards = SlgTouchMenuHelper.GetMobPreviewRewards(behemothCfg, true)
    ---@type ItemIconData[]
    local previewRewards = {}
    for _, reward in pairs(rankRewards) do
        table.insert(previewRewards, reward)
    end
    for _, reward in pairs(dropRewards) do
        table.insert(previewRewards, reward)
    end
    for _, reward in pairs(observeRewards) do
        table.insert(previewRewards, reward)
    end
    previewRewards = ItemTableMergeHelper.MergeItemDataByItemCfgId(previewRewards)
    self.tableReward:Clear()
    for _, reward in pairs(previewRewards) do
        reward.showCount = true
        self.tableReward:AppendData(reward)
    end
end

function ActivityAllianceBossRegister:UpdateTimeGroup()
    self.luaCountDown:SetVisible(self.uiState < ActivityAllianceBossConst.BATTLE_STATE.BATTLE)
    self.goGroupStageBattle:SetActive(self.uiState == ActivityAllianceBossConst.BATTLE_STATE.BATTLE)
    ---@type CommonActivityTimerParam
    local data = {}
    if self.uiState == ActivityAllianceBossConst.BATTLE_STATE.PREVIEW then
        data.activityTemplateId = ActivityAllianceBossRegisterStateHelper.GetPreviewTemplateId(self.battleId)
        data.callback = Delegate.GetOrCreate(self, self.OnTimerEnd)
        self.luaCountDown:FeedData(data)
        self.textStage.text = I18N.Get("alliance_behemoth_challenge_state2")
    elseif self.uiState == ActivityAllianceBossConst.BATTLE_STATE.REGISTER then
        data.activityTemplateId = ActivityAllianceBossRegisterStateHelper.GetRegisterTemplateId(self.battleId)
        data.callback = Delegate.GetOrCreate(self, self.OnTimerEnd)
        self.luaCountDown:FeedData(data)
        self.textStage.text = I18N.Get("alliance_behemoth_challenge_state3")
    elseif self.uiState == ActivityAllianceBossConst.BATTLE_STATE.WAITING then
        data.activityTemplateId = ActivityAllianceBossRegisterStateHelper.GetChosenTimeTemplateId(self.battleId)
        data.useActivityStartTime = true
        data.callback = Delegate.GetOrCreate(self, self.OnTimerEnd)
        self.luaCountDown:FeedData(data)
        self.textStage.text = I18N.Get("alliance_behemoth_challenge_state4")
    elseif self.uiState == ActivityAllianceBossConst.BATTLE_STATE.BATTLE then
        self.textStage.text = ""
        self.textBattleStage.text = I18N.Get("alliance_behemoth_challenge_state5")
    else
        self.textStage.text = ""
    end
end

function ActivityAllianceBossRegister:UpdateRegisterBtn()
    self.textReason.text = ""
    if self.uiState == ActivityAllianceBossConst.BATTLE_STATE.PREVIEW then
        ---@type BistateButtonParameter
        local data = {}
        data.disableButtonText = I18N.Get("alliance_behemoth_challenge_state11")
        data.disableClick = Delegate.GetOrCreate(self, self.OnBtnRegisterDisableClick)
        self.luaBtnRegister:SetVisible(true)
        self.luaBtnRegister:FeedData(data)
        self.luaBtnRegister:SetEnabled(false)
    elseif self.uiState == ActivityAllianceBossConst.BATTLE_STATE.REGISTER then
        self.luaBtnRegister:SetVisible(true)
        self.luaBtnRegister:FeedData({
            buttonText = I18N.Get("alliance_behemoth_challenge_state11"),
            onClick = Delegate.GetOrCreate(self, self.OnBtnRegisterClick),
        })
        self.luaBtnRegister:SetEnabled(true)
    elseif self.uiState == ActivityAllianceBossConst.BATTLE_STATE.WAITING then
        if ActivityAllianceBossRegisterStateHelper.IsRegisteredTroop(self.battleId) then
            self.luaBtnRegister:SetVisible(true)
            self.luaBtnRegister:FeedData({
                buttonText = I18N.Get("alliance_behemoth_challenge_state11"),
                onClick = Delegate.GetOrCreate(self, self.OnBtnRegisterClick),
            })
            self.luaBtnRegister:SetEnabled(true)
        else
            self.luaBtnRegister:SetVisible(false)
            self.textReason.text = I18N.Get("alliance_behemoth_challenge_state7")
        end
    elseif self.uiState == ActivityAllianceBossConst.BATTLE_STATE.BATTLE then
        if ActivityAllianceBossRegisterStateHelper.IsRegisteredTroop(self.battleId) then
            self.luaBtnRegister:SetVisible(true)
            self.luaBtnRegister:FeedData({
                buttonText = I18N.Get("alliance_behemoth_challenge_state11"),
                onClick = Delegate.GetOrCreate(self, self.OnBtnRegisterClick),
            })
            self.luaBtnRegister:SetEnabled(true)
        else
            self.luaBtnRegister:SetVisible(false)
            self.textReason.text = I18N.Get("alliance_behemoth_challenge_state7")
        end
    else
        self.luaBtnRegister:SetVisible(false)
        self.textReason.text = I18N.Get("leaderActivity_notice_end")
    end
end

function ActivityAllianceBossRegister:OnBattleInfoChanged()
    self:UpdateUI(UI_UPDATE_MASK.ALL ~ UI_UPDATE_MASK.LEFT_GROUP)
end

function ActivityAllianceBossRegister:OnBtnRegisterClick()
    ---@type ActivityBehemothRegisterMediatorParam
    local data = {}
    data.title = ConfigRefer.ActivityCenterTabs:Find(self.tabId):TitleKey()
    g_Game.UIManager:Open(UIMediatorNames.ActivityBehemothRegisterMediator, data)
end

function ActivityAllianceBossRegister:OnBtnRegisterDisableClick()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_behemoth_challenge_state1"))
end

function ActivityAllianceBossRegister:OnBtnRewardPreviewClick()
    g_Game.UIManager:Open(UIMediatorNames.ActivityAllianceBossRegisterRewardPreviewMediator, {})
end

function ActivityAllianceBossRegister:OnBtnInfoClick()
    GuideUtils.GotoByGuide(5291)
end

function ActivityAllianceBossRegister:OnTimerEnd()
    self:UpdateUI(UI_UPDATE_MASK.ALL ~ UI_UPDATE_MASK.LEFT_GROUP)
end

return ActivityAllianceBossRegister