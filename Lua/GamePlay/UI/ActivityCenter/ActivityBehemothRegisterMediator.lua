local BaseUIMediator = require("BaseUIMediator")
local ActivityBehemothConst = require("ActivityBehemothConst")
local ActivityAllianceBossConst = require("ActivityAllianceBossConst")
local ActivityAllianceBossRegisterStateHelper = require("ActivityAllianceBossRegisterStateHelper")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local I18N = require("I18N")
local SlgTouchMenuHelper = require("SlgTouchMenuHelper")
local ItemTableMergeHelper = require("ItemTableMergeHelper")
local UIMediatorNames = require("UIMediatorNames")
local DBEntityPath = require("DBEntityPath")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local GuideUtils = require("GuideUtils")
local ConfigRefer = require("ConfigRefer")
---@class ActivityBehemothRegisterMediator : BaseUIMediator
local ActivityBehemothRegisterMediator = class("ActivityBehemothRegisterMediator", BaseUIMediator)

---@class ActivityBehemothRegisterMediatorParam
---@field title string

local I18N_KEY = ActivityAllianceBossConst.I18N_KEY

local UI_UPDATE_MASK = {
    LEFT_GROUP = 1 << 0,
    TIME_GROUP = 1 << 1,
    REGISTER_BTN = 1 << 2,
    TROOP_GROUP = 1 << 3,
    ALL = 0xFFFFFFFF,
}

local BTN_FUNCS = {
    Register = 1,
    Enter = 2,
    Disable_NotTime = 3,
    Disable_NotRegistered = 4,
}

function ActivityBehemothRegisterMediator:ctor()
    self.uiRole = 0
    self.uiState = 0
    self.battleId = ActivityBehemothConst.BATTLE_CFG_ID
    self.btnFunc = nil
end

function ActivityBehemothRegisterMediator:OnCreate()
    ---@see CommonBackButtonComponent
    self.luaBackBtn = self:LuaObject('child_common_btn_back')
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

    ---@see ActivityAllianceBossRegisterTroopSelect
    self.luaGroupTroop = self:LuaObject('p_group_troop')

    ---@see ActivityAllianceBossRegisterTimeChoose
    self.luaTimeRegisterGroup = self:LuaObject('p_group_time')

    self.goRegisteredGroup = self:GameObject('p_group_registered')
    self.textRegisteredLabel = self:Text('p_text_registered')
    self.textRegisteredNum = self:Text('p_text_registered_num')
    self.btnInfoRegistered = self:Button('p_btn_info_registered', Delegate.GetOrCreate(self, self.OnBtnRegisteredInfoClick))
end

---@param param ActivityBehemothRegisterMediatorParam
function ActivityBehemothRegisterMediator:OnOpened(param)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.OnBattleInfoChanged))
    self:UpdateUI(UI_UPDATE_MASK.ALL)
    self.luaBackBtn:FeedData(
        {title = I18N.Get("alliance_challengeactivity_title_name"),}
    )
    local requiredMemberCount = ConfigRefer.AllianceBattle:Find(self.battleId):RequiredMemberCount()
    self.textBtnHint.text = I18N.GetWithParams("alliance_behemoth_copy_die3", requiredMemberCount)
end

function ActivityBehemothRegisterMediator:OnClose()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.OnBattleInfoChanged))
end

function ActivityBehemothRegisterMediator:UpdateUI(mask)
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
    if mask & UI_UPDATE_MASK.TROOP_GROUP ~= 0 then
        self:UpdateTroopGroup()
    end
end

function ActivityBehemothRegisterMediator:UpdateLeftGroup()
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
        reward.showCount = false
        self.tableReward:AppendData(reward)
    end
end

function ActivityBehemothRegisterMediator:UpdateTimeGroup()
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
        self.luaCountDown:SetVisible(false)
        self.goGroupStageBattle:SetActive(false)
        self.textStage.text = ""
    end
end

function ActivityBehemothRegisterMediator:UpdateRegisterBtn()
    if self.uiState == ActivityAllianceBossConst.BATTLE_STATE.PREVIEW then
        g_Logger:ErrorChannel("ActivityBehemothRegisterMediator", "预告阶段不应进入此界面")
    elseif self.uiState == ActivityAllianceBossConst.BATTLE_STATE.REGISTER then
        if ActivityAllianceBossRegisterStateHelper.GetChosenTimeTemplateId(self.battleId) == 0 then
            self.luaBtnRegister:SetVisible(true)
            ---@type BistateButtonParameter
            local data = {}
            data.buttonText = I18N.Get("alliance_behemoth_challenge_state6")
            data.onClick = Delegate.GetOrCreate(self, self.OnBtnRegisterClick)
            self.luaBtnRegister:FeedData(data)
            self.luaBtnRegister:SetEnabled(true)
            self.btnFunc = BTN_FUNCS.Register
        else
            self.luaBtnRegister:SetVisible(true)
            ---@type BistateButtonParameter
            local data = {}
            data.disableButtonText = I18N.Get("alliance_challengeactivity_button_enter")
            data.disableClick = Delegate.GetOrCreate(self, self.OnBtnRegisterDisableClick)
            self.luaBtnRegister:FeedData(data)
            self.luaBtnRegister:SetEnabled(false)
            self.btnFunc = BTN_FUNCS.Disable_NotTime
        end
    elseif self.uiState == ActivityAllianceBossConst.BATTLE_STATE.WAITING then
        if ActivityAllianceBossRegisterStateHelper.IsRegisteredTroop(self.battleId) then
            self.luaBtnRegister:SetVisible(true)
            ---@type BistateButtonParameter
            local data = {}
            data.disableButtonText = I18N.Get("alliance_challengeactivity_button_enter")
            data.disableClick = Delegate.GetOrCreate(self, self.OnBtnRegisterDisableClick)
            self.luaBtnRegister:FeedData(data)
            self.luaBtnRegister:SetEnabled(false)
            self.btnFunc = BTN_FUNCS.Disable_NotTime
        else
            self.luaBtnRegister:SetVisible(false)
            self.textReason.text = I18N.Get("alliance_behemoth_challenge_state7")
        end
    elseif self.uiState == ActivityAllianceBossConst.BATTLE_STATE.BATTLE then
        if ActivityAllianceBossRegisterStateHelper.IsRegisteredTroop(self.battleId) then
            self.luaBtnRegister:SetVisible(true)
            ---@type BistateButtonParameter
            local data = {}
            data.buttonText = I18N.Get("alliance_challengeactivity_button_enter")
            data.onClick = Delegate.GetOrCreate(self, self.OnBtnRegisterClick)
            self.luaBtnRegister:FeedData(data)
            self.luaBtnRegister:SetEnabled(true)
            self.btnFunc = BTN_FUNCS.Enter
        else
            self.luaBtnRegister:SetVisible(false)
            self.textReason.text = I18N.Get("alliance_behemoth_challenge_state7")
        end
    elseif self.uiState == ActivityAllianceBossConst.BATTLE_STATE.END then
        self.luaBtnRegister:SetVisible(false)
        self.textReason.text = I18N.Get("leaderActivity_notice_end")
    end
end

function ActivityBehemothRegisterMediator:UpdateTroopGroup()
    local battleData = ActivityAllianceBossRegisterStateHelper.GetBattleData(self.battleId)
    ---@type ActivityAllianceBossRegisterTroopSelectParam
    local data = {}
    data.battleData = battleData
    data.uiState = self.uiState
    data.uiRole = self.uiRole
    self.luaGroupTroop:FeedData(data)

    ---@type ActivityAllianceBossRegisterTimeChooseParam
    local timeData = {}
    timeData.battleId = self.battleId
    timeData.uiRole = self.uiRole
    timeData.uiState = self.uiState
    timeData.battleData = battleData
    self.luaTimeRegisterGroup:FeedData(timeData)

    if self.uiState == ActivityAllianceBossConst.BATTLE_STATE.PREVIEW then
        self.luaGroupTroop:SetVisible(false)
    elseif self.uiState == ActivityAllianceBossConst.BATTLE_STATE.REGISTER then
        if ActivityAllianceBossRegisterStateHelper.GetChosenTimeTemplateId(self.battleId) == 0 then
            self.luaGroupTroop:SetVisible(false)
            self.luaTimeRegisterGroup:SetVisible(false)
        else
            self.luaGroupTroop:SetVisible(true)
            self.luaTimeRegisterGroup:SetVisible(true)
        end
    elseif self.uiState == ActivityAllianceBossConst.BATTLE_STATE.WAITING then
        self.luaTimeRegisterGroup:SetVisible(true)
        if ActivityAllianceBossRegisterStateHelper.IsRegisteredTroop(self.battleId) then
            self.luaGroupTroop:SetVisible(true)
            self.goRegisteredGroup:SetActive(false)
        else
            self.luaGroupTroop:SetVisible(false)
            self.goRegisteredGroup:SetActive(true)
            self.textRegisteredNum.text = ModuleRefer.ActivityBehemothModule:GetBattleRegisteredNum(self.battleId)
        end
    elseif self.uiState == ActivityAllianceBossConst.BATTLE_STATE.BATTLE then
        self.luaTimeRegisterGroup:SetVisible(false)
        if ActivityAllianceBossRegisterStateHelper.IsRegisteredTroop(self.battleId) then
            self.luaGroupTroop:SetVisible(true)
            self.goRegisteredGroup:SetActive(false)
        else
            self.luaGroupTroop:SetVisible(false)
            self.goRegisteredGroup:SetActive(true)
            self.textRegisteredNum.text = ModuleRefer.ActivityBehemothModule:GetBattleRegisteredNum(self.battleId)
        end
    else
        self.luaGroupTroop:SetVisible(false)
        self.luaTimeRegisterGroup:SetVisible(false)
        self.goRegisteredGroup:SetActive(false)
    end
end

function ActivityBehemothRegisterMediator:OnBtnInfoClick()
    GuideUtils.GotoByGuide(5291)
end

function ActivityBehemothRegisterMediator:OnBtnRewardPreviewClick()
    g_Game.UIManager:Open(UIMediatorNames.ActivityAllianceBossRegisterRewardPreviewMediator, {})
end

function ActivityBehemothRegisterMediator:OnBtnRegisterClick()
    local battleData = ActivityAllianceBossRegisterStateHelper.GetBattleData(self.battleId)
    if self.btnFunc == BTN_FUNCS.Register then
        ---@type ActivityAllianceBossRegisterTimeChooseParam
        local data = {}
        data.battleData = battleData
        data.uiState = self.uiState
        data.uiRole = self.uiRole
        data.battleId = self.battleId
        g_Game.UIManager:Open(UIMediatorNames.ActivityBehemothTimeChooseMediator, data)
    elseif self.btnFunc == BTN_FUNCS.Enter then
        ---@type CommonConfirmPopupMediatorParameter
        local commonConfirmParam = {}
        commonConfirmParam.title = I18N.Get(I18N_KEY.CONFIRM_TITLE)
        commonConfirmParam.content = I18N.Get("alliance_behemoth_challenge_state9")
        commonConfirmParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
        commonConfirmParam.onConfirm = function ()
            local transform = self.luaBtnRegister.CSComponent.gameObject.transform
            ModuleRefer.AllianceModule:EnterAllianceActivityBattleScene(transform, battleData.ID, function (_, isSuccess)
                self:CloseSelf()
            end)
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, commonConfirmParam)
    end
end

function ActivityBehemothRegisterMediator:OnBtnRegisterDisableClick()
    if self.btnFunc == BTN_FUNCS.Disable_NotTime then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_behemoth_challenge_state10"))
    end
end

function ActivityBehemothRegisterMediator:OnBattleInfoChanged()
    self:UpdateUI(UI_UPDATE_MASK.ALL ~ UI_UPDATE_MASK.LEFT_GROUP)
end

function ActivityBehemothRegisterMediator:OnTimerEnd()
    self:UpdateUI(UI_UPDATE_MASK.ALL ~ UI_UPDATE_MASK.LEFT_GROUP)
end

function ActivityBehemothRegisterMediator:OnBtnRegisteredInfoClick()
    ---@type ActivityAllianceBossTroopListMediatorParam
    local data = {}
    data.battleData = ActivityAllianceBossRegisterStateHelper.GetBattleData(self.battleId)
    data.uiState = self.uiState
    g_Game.UIManager:Open(UIMediatorNames.ActivityAllianceBossTroopListMediator, data)
end

return ActivityBehemothRegisterMediator