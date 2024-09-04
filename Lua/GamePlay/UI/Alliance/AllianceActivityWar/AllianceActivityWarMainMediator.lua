--- scene:scene_league_war_main

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local DBEntityPath = require("DBEntityPath")
local OnChangeHelper = require("OnChangeHelper")
local ConfigRefer = require("ConfigRefer")
local TimeFormatter = require("TimeFormatter")
local UIMediatorNames = require("UIMediatorNames")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local ArtResourceUtils = require("ArtResourceUtils")
local FPXSDKBIDefine = require("FPXSDKBIDefine")
local UIHelper = require("UIHelper")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceActivityWarMainMediatorData
---@field battleId number
---@field backNoAni boolean

---@class AllianceActivityWarMainMediator:BaseUIMediator
---@field new fun():AllianceActivityWarMainMediator
---@field super BaseUIMediator
local AllianceActivityWarMainMediator = class('AllianceActivityWarMainMediator', BaseUIMediator)

function AllianceActivityWarMainMediator:ctor()
    BaseUIMediator.ctor(self)
    self._battleId = nil
    ---@type AllianceBattleConfigCell
    self._battleConfig = nil
    ---@type wds.AllianceActivityBattleInfo
    self._battleData = nil
    ---@type table<number, CS.UnityEngine.GameObject[] | CS.UnityEngine.Transform[]>
    self._statusVisibleControl = {}
    self._chooseDifficulty = nil
    self._backNoAni = false
end

function AllianceActivityWarMainMediator:OnCreate(param)

    ---@type CommonBackButtonComponent
    self._child_common_btn_back = self:LuaObject("child_common_btn_back")
    self._p_boss = self:GameObject("p_boss")
    self._p_status_boss_n = self:GameObject("p_status_boss_n")
    self._p_text_blood = self:Text("p_text_blood", "alliance_battle_hud25")
    self._p_text_blood_num = self:Text("p_text_blood_num")
    ---@type CommonTimer
    self._child_time = self:LuaObject("child_time")
    self._p_status_boss_death = self:GameObject("p_status_boss_death")
    self._p_text_death = self:Text("p_text_death", "alliance_battle_hud13")
    self._p_img_monster = self:Image("p_img_monster")
    self._p_img_head_boss = self:Image("p_img_head_boss")
    self._p_text_content_detail = self:Text("p_text_content_detail")
    self._p_text_reward = self:Text("p_text_reward", "alliance_battle_hud5")
    self._p_table_reward = self:TableViewPro("p_table_reward")
    self._p_title = self:GameObject("p_title")
    self._p_text_choose = self:Text("p_text_choose", "alliance_battle_hud7")

    self._p_group_difficulty_go = self:GameObject("p_group_difficulty")
    ---@type AllianceActivityWarMainDifficultyChoose
    self._p_group_difficulty = self:LuaObject("p_group_difficulty")

    self._p_group_troop_go = self:GameObject("p_group_troop")
    ---@type AllianceActivityWarMainTroopSelection
    self._p_group_troop = self:LuaObject("p_group_troop")

    self._p_text_hint = self:Text("p_text_hint")
    self._p_detail = self:GameObject("p_detail")
    self._child_btn_detail = self:Button("child_btn_detail", Delegate.GetOrCreate(self, self.OnClickBtnDetail))
    self._p_text_detail = self:Text("p_text_detail", "alliance_battle_button2")

    self._p_btn = self:GameObject("p_btn")
    ---@type BistateButton
    self._child_comp_btn_b = self:LuaObject("child_comp_btn_b")

    self._p_btn_share = self:Button("p_btn_share", Delegate.GetOrCreate(self, self.OnClickShareBtn))

    self._statusVisibleControl[wds.AllianceActivityBattleStatus.AllianceBattleStatusClose] = {
        self._p_text_hint.gameObject,
        self._p_detail,
    }
    self._statusVisibleControl[wds.AllianceActivityBattleStatus.AllianceBattleStatusOpen] = {
        self._p_text_hint.gameObject,
        self._p_title,
        self._p_boss,
        self._p_group_difficulty_go,
        self._p_btn,
    }
    self._statusVisibleControl[wds.AllianceActivityBattleStatus.AllianceBattleStatusActivated] = {
        self._p_text_hint.gameObject,
        self._p_boss,
        self._p_group_difficulty_go,
        self._p_group_troop_go,
        self._p_btn,
        self._p_btn_share.gameObject,
    }
    self._statusVisibleControl[wds.AllianceActivityBattleStatus.AllianceBattleStatusBattling] = {
        self._p_boss,
        self._p_group_difficulty_go,
        self._p_group_troop_go,
        self._p_btn,
        self._p_btn_share.gameObject,
    }
    self._statusVisibleControl[wds.AllianceActivityBattleStatus.AllianceBattleStatusFinished] = {
        self._p_text_hint.gameObject,
        self._p_boss,
        self._p_detail,
    }
end

function AllianceActivityWarMainMediator:OnShow(param)
    self:SetupEvents(true)
end

---@param param AllianceActivityWarMainMediatorData
function AllianceActivityWarMainMediator:OnOpened(param)
    self._battleId = param and param.battleId
    self._backNoAni = param and param.backNoAni or false
    self._battleData = ModuleRefer.AllianceModule:GetMyAllianceActivityBattleById(self._battleId)
    self:SetupComponents()
    self:RefreshUI()
end

function AllianceActivityWarMainMediator:OnHide(param)
    self:SetupEvents(false)
end

function AllianceActivityWarMainMediator:SetupEvents(add)
    if add then
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.OnBattleDataChanged))
    else
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.OnBattleDataChanged))
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    end
end

function AllianceActivityWarMainMediator:OnClickBtnActiveOrStart()
    if self._battleData.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusOpen then
        ModuleRefer.AllianceModule:ActivateAllianceActivityBattle(self._child_comp_btn_b:Transform(""), self._battleId, self._chooseDifficulty - 1)
    elseif self._battleData.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusActivated then
        local memberCount = table.nums(self._battleData.Members)
        if memberCount < self._battleConfig:RequiredMemberCount() then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("alliance_battle_toast2", tostring(self._battleConfig:RequiredMemberCount())))
        else
            ---@type CommonConfirmPopupMediatorParameter
            local confirmPopupData = {}
            confirmPopupData.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
            confirmPopupData.content = I18N.Get("alliance_battle_confirm")
            confirmPopupData.confirmLabel = I18N.Get("confirm")
            confirmPopupData.cancelLabel = I18N.Get("cancle")
            confirmPopupData.context = self._battleId
            confirmPopupData.onConfirm = function(context)
                local mask1 = ModuleRefer.ServerPushNoticeModule:RemoveAllowMask(wrpc.PushNoticeType.PushNoticeType_AllianceActivityBattleStart)
                local mask2 = ModuleRefer.ServerPushNoticeModule:RemoveAllowMask(wrpc.PushNoticeType.PushNoticeType_AllianceActivityBattleActivated)
                ModuleRefer.AllianceModule:StartAllianceActivityBattle(self._child_comp_btn_b:Transform(""), context, function(cmd, isSuccess, rsp)
                    if isSuccess then
                        local battleData = ModuleRefer.AllianceModule:GetAllianceActivityBattleData(self._battleId)
                        if battleData then
                            local keyMap = FPXSDKBIDefine.ExtraKey.alliance_battle
                            local extraDic = {}
                            extraDic[keyMap.battle_member_num] = memberCount
                            extraDic[keyMap.map_instance_id] = ModuleRefer.AllianceModule:GetBattleInstanceId(self._battleId)
                            extraDic[keyMap.alliance_create_date] = nil
                            local _, inAllianceMemberCount = ModuleRefer.AllianceModule:GetMyAllianceOnlineMemberCount()
                            extraDic[keyMap.alliance_member_num] = inAllianceMemberCount
                            ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.alliance_battle, extraDic)
                        end
                        local isInBattle = self._battleData.Members[ModuleRefer.PlayerModule:GetPlayer().Owner.FacebookID] and true or false
                        if isInBattle then
                            ModuleRefer.AllianceModule:EnterAllianceActivityBattleScene(self._child_comp_btn_b:Transform(""), self._battleId, function(_, cmdSuccess, _)
                                if cmdSuccess then
                                    self:CloseSelf()
                                end
                            end)
                        end
                    else
                        if mask1 then
                            ModuleRefer.ServerPushNoticeModule:AddAllowMask(wrpc.PushNoticeType.PushNoticeType_AllianceActivityBattleStart)
                        end
                        if mask2 then
                            ModuleRefer.ServerPushNoticeModule:AddAllowMask(wrpc.PushNoticeType.PushNoticeType_AllianceActivityBattleActivated)
                        end
                    end
                end)
                return true
            end
            g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, confirmPopupData)
        end
    elseif self._battleData.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusBattling then
        ModuleRefer.AllianceModule:EnterAllianceActivityBattleScene(self._child_comp_btn_b:Transform(""), self._battleId, function(cmd, isSuccess, rsp)
            if isSuccess then
                self:CloseSelf()
            end
        end)
    end
end

function AllianceActivityWarMainMediator:OnClickBtnDisabledActiveOrStart()
    if self._battleData.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusOpen then

    elseif self._battleData.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusActivated then
        local memberCount = table.nums(self._battleData.Members)
        if memberCount < self._battleConfig:RequiredMemberCount() then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("alliance_battle_toast2", tostring(self._battleConfig:RequiredMemberCount())))
        end
    elseif self._battleData.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusBattling then

    end
end

function AllianceActivityWarMainMediator:OnClickBtnDetail()

end

function AllianceActivityWarMainMediator:OnClickShareBtn()

end

function AllianceActivityWarMainMediator:RefreshUI()
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local closeTime = self._battleData.CloseTime.Seconds
    local openTime = self._battleData.OpenTime.Seconds
    local isOn = true--nowTime > openTime and nowTime < closeTime
    local s = self._battleData.Status
    local statusEnum = wds.AllianceActivityBattleStatus
    self._child_time:RecycleTimer()
    if s == statusEnum.AllianceBattleStatusOpen and isOn then
        self:SetupUIStatus(s)
        self:RefreshStatusOpen()
    elseif s == statusEnum.AllianceBattleStatusActivated and isOn then
        self:SetupUIStatus(s)
        self:RefreshStatusActivated()
    elseif s == statusEnum.AllianceBattleStatusBattling and isOn then
        self:SetupUIStatus(s)
        self:RefreshStatusBattling()
    elseif s == statusEnum.AllianceBattleStatusFinished then
        self:SetupUIStatus(s)
        self:RefreshStatusFinished()
    else
        self:SetupUIStatus(statusEnum.AllianceBattleStatusClose)
        self:RefreshStatusClose()
    end
end

function AllianceActivityWarMainMediator:SetupUIStatus(toStatus)
    for status, list in pairs(self._statusVisibleControl) do
        if status ~= toStatus then
            for _, v in pairs(list) do
                v:SetVisible(false)
            end
        end
    end
    for status, list in pairs(self._statusVisibleControl) do
        if status == toStatus then
            for _, v in pairs(list) do
                v:SetVisible(true)
            end
            break
        end
    end
end

---@param entity wds.Alliance
---@param changedData table
function AllianceActivityWarMainMediator:OnBattleDataChanged(entity, changedData)
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return
    end
    if ModuleRefer.AllianceModule:GetAllianceId() ~= entity.ID then
        return
    end
    if not changedData[self._battleId] then
        return
    end
    self._battleData = ModuleRefer.AllianceModule:GetMyAllianceActivityBattleById(self._battleId)
    self:RefreshUI()
end

function AllianceActivityWarMainMediator:OnLeaveAlliance(allianceId)
    self:CloseSelf()
end

function AllianceActivityWarMainMediator:SetupComponents()
    self._p_table_reward:Clear()
    local configId = self._battleData.CfgId
    local config = ConfigRefer.AllianceBattle:Find(configId)
    self._battleConfig = config
    self._battleConfig_RequiredMemberCount = config:RequiredMemberCount()
    if UNITY_DEBUG then
        if ModuleRefer.SlgModule.DebugMode then
            self._battleConfig_RequiredMemberCount = 1
        end
    end
    g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(config:BossPortrait()), self._p_img_monster)
    g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(config:BossIcon()), self._p_img_head_boss)
    ---@type CommonBackButtonData
    local exitBtnData = {}
    exitBtnData.title = I18N.Get(config:LangKey())
    exitBtnData.onClose = Delegate.GetOrCreate(self, self.OnClickBackBtn)
    self._child_common_btn_back:FeedData(exitBtnData)
    self._p_text_content_detail.text = I18N.Get(config:LangDesc())
    local rewards = ConfigRefer.ItemGroup:Find(config:Rewards())
    if rewards then
        for i = 1, rewards:ItemGroupInfoListLength() do
            local item = rewards:ItemGroupInfoList(i)
            self._p_table_reward:AppendData(item)
        end
    end
    ---@type AllianceActivityWarMainDifficultyChooseData
    local dropDownData = {}
    self._chooseDifficulty = self._battleData.ActivatedInstanceIndex + 1
    local difficultyCount = self._battleConfig:InstanceLength()
    dropDownData.index = self._chooseDifficulty
    dropDownData.chooseList = {}
    dropDownData.chooseList[1] = {
        isLocked = false,
        title = I18N.Get("alliance_battle_difficulty1"),
        content = I18N.GetWithParams("alliance_battle_difficulty4", "10", "60"),
    }
    --if difficultyCount > 1 then
        dropDownData.chooseList[2] = {
        isLocked = true,
        title = I18N.Get("alliance_battle_difficulty2"),
        content = I18N.GetWithParams("alliance_battle_difficulty4", "10", "60"),
    }
    --end
    --if difficultyCount > 2 then
        dropDownData.chooseList[3] = {
            isLocked = true,
            title = I18N.Get("alliance_battle_difficulty3"),
            content = I18N.GetWithParams("alliance_battle_difficulty4", "10", "60"),
        }
    --end
    dropDownData.onChoose = Delegate.GetOrCreate(self, self.OnChooseDifficultyIndex)
    self._p_group_difficulty:FeedData(dropDownData)

    ---@type BistateButtonParameter
    local btnData = {}

    btnData.buttonText = I18N.Get("alliance_battle_button1")
    btnData.onClick = Delegate.GetOrCreate(self, self.OnClickBtnActiveOrStart)
    btnData.disableClick = Delegate.GetOrCreate(self, self.OnClickBtnDisabledActiveOrStart)
    self._child_comp_btn_b:FeedData(btnData)
end

function AllianceActivityWarMainMediator:RefreshStatusClose()
    local battleData = self._battleData
    local isAllianceLeader = ModuleRefer.AllianceModule:IsAllianceLeader()
    self._p_group_difficulty_go:SetVisible(false)
    ---@type CommonTimerData
    local timerData = {}
    timerData.needTimer = true
    timerData.endTime = battleData.CloseTime.Seconds
    timerData.overrideTimeFormat = TimeFormatter.SimpleFormatTimeWithDay
    self._child_time:FeedData(timerData)
    self._p_status_boss_n:SetVisible(true)
    self._p_status_boss_death:SetVisible(false)
    UIHelper.SetGray(self._p_img_head_boss.gameObject, false)
    UIHelper.SetGray(self._p_img_monster.gameObject, false)
    self._p_text_blood_num.text = "100%"
    local challengeCount = self._battleConfig:ChallengeCount()
    local hasLeftCount = challengeCount <= 0 or challengeCount > battleData.AlreadyChallengeTimes
    self._p_text_hint.text = string.Empty
    self._child_comp_btn_b:SetButtonText(I18N.Get("alliance_battle_button1"))
    self._child_comp_btn_b:SetEnabled(isAllianceLeader and hasLeftCount)
    self._child_comp_btn_b:SetVisible(true)
    self._p_group_difficulty:SetAllowChange(isAllianceLeader)
end

function AllianceActivityWarMainMediator:RefreshStatusOpen()
    local battleData = self._battleData
    local isAllianceLeader = ModuleRefer.AllianceModule:IsAllianceLeader()
    self._p_group_difficulty_go:SetVisible(isAllianceLeader)
    self._p_title:SetVisible(isAllianceLeader)
    ---@type CommonTimerData
    local timerData = {}
    timerData.needTimer = true
    timerData.endTime = battleData.CloseTime.Seconds
    timerData.overrideTimeFormat = TimeFormatter.SimpleFormatTimeWithDay
    self._child_time:FeedData(timerData)
    self._p_status_boss_n:SetVisible(true)
    self._p_status_boss_death:SetVisible(false)
    UIHelper.SetGray(self._p_img_head_boss.gameObject, false)
    UIHelper.SetGray(self._p_img_monster.gameObject, false)
    self._p_text_blood_num.text = "100%"
    local challengeCount = self._battleConfig:ChallengeCount()
    local hasLeftCount = challengeCount <= 0 or challengeCount > battleData.AlreadyChallengeTimes
    local leftCount = math.max(0, challengeCount - battleData.AlreadyChallengeTimes)
    self._p_text_hint.text = isAllianceLeader and I18N.GetWithParams("alliance_battle_hud8", challengeCount <= 0 and "999+" or tostring(leftCount)) or I18N.Get("alliance_battle_hud6")
    self._child_comp_btn_b:SetButtonText(I18N.Get("alliance_battle_button1"))
    self._child_comp_btn_b:SetEnabled(isAllianceLeader and hasLeftCount)
    self._child_comp_btn_b:SetVisible(true)
    self._p_group_difficulty:SetAllowChange(isAllianceLeader)
end

function AllianceActivityWarMainMediator:RefreshStatusActivated()
    local battleData = self._battleData
    local isAllianceLeader = ModuleRefer.AllianceModule:IsAllianceLeader()
    self._p_group_difficulty:SetAllowChange(isAllianceLeader)
    ---@type CommonTimerData
    local timerData = {}
    timerData.needTimer = true
    timerData.endTime = battleData.CloseTime.Seconds
    timerData.overrideTimeFormat = TimeFormatter.SimpleFormatTimeWithDay
    self._child_time:FeedData(timerData)
    self._p_status_boss_n:SetVisible(true)
    self._p_status_boss_death:SetVisible(false)
    UIHelper.SetGray(self._p_img_head_boss.gameObject, false)
    UIHelper.SetGray(self._p_img_monster.gameObject, false)
    self._p_text_blood_num.text = "100%"
    local challengeCount = self._battleConfig:ChallengeCount()
    local leftCount = math.max(0, challengeCount - battleData.AlreadyChallengeTimes)
    self._p_text_hint.text = isAllianceLeader and I18N.GetWithParams("alliance_battle_hud8", challengeCount <= 0 and "999+" or tostring(leftCount))  or I18N.Get("alliance_battle_hud11")
    local memberCount = table.nums(battleData.Members)
    self._child_comp_btn_b:SetEnabled(memberCount >= self._battleConfig:RequiredMemberCount())
    self._child_comp_btn_b:SetButtonText(I18N.Get("alliance_battle_button5"))
    self._child_comp_btn_b:SetVisible(isAllianceLeader)
    self._p_group_troop:FeedData(self._battleData)
end

function AllianceActivityWarMainMediator:RefreshStatusBattling()
    local battleData = self._battleData
    self._p_group_difficulty:SetAllowChange(false)
    ---@type CommonTimerData
    local timerData = {}
    timerData.needTimer = true
    timerData.endTime = battleData.CloseTime.Seconds
    timerData.overrideTimeFormat = TimeFormatter.SimpleFormatTimeWithDay
    self._child_time:FeedData(timerData)
    self._p_status_boss_n:SetVisible(true)
    self._p_status_boss_death:SetVisible(false)
    UIHelper.SetGray(self._p_img_head_boss.gameObject, false)
    UIHelper.SetGray(self._p_img_monster.gameObject, false)
    self._p_text_blood_num.text = "100%"
    self._p_group_troop:FeedData(battleData)
    local inBattle = battleData.Members[ModuleRefer.PlayerModule:GetPlayer().Owner.FacebookID] and true or false
    self._child_comp_btn_b:SetEnabled(true)
    self._child_comp_btn_b:SetButtonText(I18N.Get("alliance_battle_button6"))
    self._child_comp_btn_b:SetVisible(inBattle)
end

function AllianceActivityWarMainMediator:RefreshStatusFinished()
    self._p_status_boss_n:SetVisible(false)
    self._p_status_boss_death:SetVisible(true)
    UIHelper.SetGray(self._p_img_head_boss.gameObject, true)
    UIHelper.SetGray(self._p_img_monster.gameObject, true)
    self._p_text_blood_num.text = "0%"
    self._p_text_hint.text = I18N.Get("alliance_battle_hud12")
    self._child_comp_btn_b:SetVisible(false)
end

function AllianceActivityWarMainMediator:OnChooseDifficultyIndex(index)
    self._chooseDifficulty = index
end

function AllianceActivityWarMainMediator:OnClickBackBtn()
    self:BackToPrevious(nil, self._backNoAni, self._backNoAni)
end

return AllianceActivityWarMainMediator