local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local I18N = require('I18N')
local KingdomMapUtils = require('KingdomMapUtils')
local EventConst = require('EventConst')
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local WorldTrendDefine = require("WorldTrendDefine")
local DBEntityPath = require("DBEntityPath")
local ReceiveWorldStageRewardParameter = require("ReceiveWorldStageRewardParameter")
local UIMediatorNames = require('UIMediatorNames')
local UIHelper = require('UIHelper')

---@class WorldTrendGlobalBranch : BaseUIComponent
local WorldTrendGlobalBranch = class('WorldTrendGlobalBranch', BaseUIComponent)

---@class WorldTrendBranchParam
---@field stageID number

function WorldTrendGlobalBranch:OnCreate()
    self.textSubTitle = self:Text('p_text_global_branch_subtitle', I18N.Get("WorldStage_info_branch"))
    self.textGlobalBranchDesc = self:Text('p_text_global_branch')

    -- branch1
    self.textBranchDesc_1 = self:Text('p_text_answer_01')
    self.tableviewproBranchRewards_1 = self:TableViewPro('p_table_answer_rewards_01')
    self.goHot_1 = self:GameObject('p_icon_hot_01')
    self.goHotBase_1 = self:GameObject('p_hot_base_01')
    self.goHotter_1 = self:GameObject('p_icon_hotter_01')
    self.textHotNum_1 = self:Text('p_text_hot_01')
    self.goLose_1 = self:GameObject('p_icon_lose_01')
    self.textLose_1 = self:Text('p_text_lose_01', I18N.Get("WorldStage_kingdomtask_lose"))
    self.goWin_1 = self:GameObject('p_icon_win_01')
    self.textWin_1 = self:Text('p_text_win_01', I18N.Get("WorldStage_kingdomtask_win"))
    self.sliderProgress_1 = self:Slider('p_pb_01')
    self.btnBranch_1 = self:Button('p_answer_01', Delegate.GetOrCreate(self, self.OnClickBranch_1))
    self.btnIcon1 = self:Button('p_btn_reward_status_01', Delegate.GetOrCreate(self, self.OnClickIcon1))
    self.icon1 = self:Image("p_icon_01")
    self.iconBg1 = self:Image("p_base_lock_01")
    self.fill1 = self:Image('p_fill_01')
    -- branch2
    self.textBranchDesc_2 = self:Text('p_text_answer_02')
    self.tableviewproBranchRewards_2 = self:TableViewPro('p_table_answer_rewards_02')
    self.goHot_2 = self:GameObject('p_icon_hot_02')
    self.goHotBase_2 = self:GameObject('p_hot_base_02')
    self.goHotter_2 = self:GameObject('p_icon_hotter_02')
    self.textHotNum_2 = self:Text('p_text_hot_02')
    self.goLose_2 = self:GameObject('p_icon_lose_02')
    self.textLose_2 = self:Text('p_text_lose_02', I18N.Get("WorldStage_kingdomtask_lose"))
    self.goWin_2 = self:GameObject('p_icon_win_02')
    self.textWin_2 = self:Text('p_text_win_02', I18N.Get("WorldStage_kingdomtask_win"))
    self.sliderProgress_2 = self:Slider('p_pb_02')
    self.btnBranch_2 = self:Button('p_answer_02', Delegate.GetOrCreate(self, self.OnClickBranch_2))
    self.btnIcon2 = self:Button('p_btn_reward_status_02', Delegate.GetOrCreate(self, self.OnClickIcon2))
    self.icon2 = self:Image("p_icon_02")
    self.iconBg2 = self:Image("p_base_lock_02")
    self.fill2 = self:Image('p_fill_02')
end

function WorldTrendGlobalBranch:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Kingdom.WorldStage.VotingMap.MsgPath, Delegate.GetOrCreate(self, self.OnVoteChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Kingdom.WorldStage.HistoryStages.MsgPath, Delegate.GetOrCreate(self, self.OnStageStateChanged))
    g_Game.ServiceManager:AddResponseCallback(ReceiveWorldStageRewardParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnClaimReward))
end

function WorldTrendGlobalBranch:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Kingdom.WorldStage.VotingMap.MsgPath, Delegate.GetOrCreate(self, self.OnVoteChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Kingdom.WorldStage.HistoryStages.MsgPath, Delegate.GetOrCreate(self, self.OnStageStateChanged))
    g_Game.ServiceManager:RemoveResponseCallback(ReceiveWorldStageRewardParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnClaimReward))
end

---@param param WorldTrendBranchParam
function WorldTrendGlobalBranch:OnFeedData(param)
    if not param then
        return
    end

    self.stage = param.stageID
    local config = ConfigRefer.WorldStage:Find(self.stage)
    if config then
        self.textGlobalBranchDesc.text = I18N.Get(config:BranchDesc())
    end
    self.branchID_1, self.branchID_2 = ModuleRefer.WorldTrendModule:GetGlobalBranchID(self.stage)
    local isHaveRewardState = ModuleRefer.WorldTrendModule:IsHaveRewardState(self.branchID_1, self.branchID_2)
    self.curStageState = ModuleRefer.WorldTrendModule:GetBranchState(self.stage, isHaveRewardState)
    self:InitBranch_1(self.branchID_1)
    self:InitBranch_2(self.branchID_2)
    self:BranchCompare()
    self:UpdateVoteProgress()
end

function WorldTrendGlobalBranch:InitBranch_1(branchID)
    local config = ConfigRefer.WorldStage:Find(branchID)
    if not config then
        return
    end
    self.textBranchDesc_1.text = I18N.Get(config:BranchChoiceDesc())
    self.branch1Vote = ModuleRefer.WorldTrendModule:GetBranchVoteNum(branchID)
    self.textHotNum_1.text = tostring(self.branch1Vote)
    self:InitBranchRewardOrEffect_1(config)
end

function WorldTrendGlobalBranch:InitBranch_2(branchID)
    local config = ConfigRefer.WorldStage:Find(branchID)
    if not config then
        return
    end
    self.textBranchDesc_2.text = I18N.Get(config:BranchChoiceDesc())
    self.branch2Vote = ModuleRefer.WorldTrendModule:GetBranchVoteNum(branchID)
    self.goHot_2:SetActive(true)
    self.textHotNum_2.text = tostring(self.branch2Vote)
    self:InitBranchRewardOrEffect_2(config)
end

-- 展示两个分支的对比结果
function WorldTrendGlobalBranch:BranchCompare()
    local result = false
    local isEquil = true
    if self.branch1Vote and self.branch2Vote then
        result = self.branch1Vote > self.branch2Vote
        isEquil = self.branch1Vote == self.branch2Vote
    end

    if self.curStageState ~= WorldTrendDefine.BRANCH_STATE.Voting and isEquil then
        local winBranch = ModuleRefer.WorldTrendModule:GetWinBranch(self.stage)
        result = winBranch == self.branchID_1
    end

    if self.curStageState == WorldTrendDefine.BRANCH_STATE.Voting then
        self.goHotBase_1:SetActive(true)
        self.goHot_1:SetActive(isEquil or not result)
        self.goHotter_1:SetActive(not isEquil and result)
        self.goLose_1:SetActive(false)
        self.goWin_1:SetActive(false)
        self.goHotBase_2:SetActive(true)
        self.goHot_2:SetActive(isEquil or result)
        self.goHotter_2:SetActive(not isEquil and not result)
        self.goLose_2:SetActive(false)
        self.goWin_2:SetActive(false)
        -- TODO ShowHotIcon
    elseif self.curStageState == WorldTrendDefine.BRANCH_STATE.CanReward then
        self.goHotBase_1:SetActive(result)
        self.goHot_1:SetActive(isEquil or not result)
        self.goHotter_1:SetActive(not isEquil and result)
        self.goLose_1:SetActive(not result)
        self.goWin_1:SetActive(false)
        self.goHotBase_2:SetActive(not result)
        self.goHot_2:SetActive(isEquil or result)
        self.goHotter_2:SetActive(not isEquil and not result)
        self.goLose_2:SetActive(result)
        self.goWin_2:SetActive(false)
        self.curRewardBranch = result and self.branchID_1 or self.branchID_2
    elseif self.curStageState == WorldTrendDefine.BRANCH_STATE.Rewarded then
        self.goHotBase_1:SetActive(false)
        self.goHot_1:SetActive(false)
        self.goHotter_1:SetActive(false)
        self.goLose_1:SetActive(not result)
        self.goWin_1:SetActive(result)
        self.goHotBase_2:SetActive(false)
        self.goHot_2:SetActive(false)
        self.goHotter_2:SetActive(false)
        self.goLose_2:SetActive(result)
        self.goWin_2:SetActive(not result)
    elseif self.curStageState == WorldTrendDefine.BRANCH_STATE.None then
        -- 第一次为none
        self.goHot_1:SetVisible(true)
        self.goHot_2:SetVisible(true)

        self.goHotter_1:SetVisible(false)
        self.goHotter_2:SetVisible(false)
    end
end

function WorldTrendGlobalBranch:InitBranchRewardOrEffect_1(config)
    if config:BranchGuideDemoLength() > 0 then
        self.video1 = config:BranchGuideDemo(1)
    else
        self.video1 = nil
    end
    self.tips1 = I18N.Get(config:BranchResultDesc())
    g_Game.SpriteManager:LoadSprite(config:BranchResultsIcon(), self.icon1)

    local rewardList = ModuleRefer.QuestModule.GetItemGroupInfoById(config:Reward())
    if rewardList then
        -- 配置奖励就不显示影响
        self.tableviewproBranchRewards_1:Clear()
        for _, reward in ipairs(rewardList) do
            local data = {}
            data.configCell = ConfigRefer.Item:Find(reward:Items())
            data.count = reward:Nums()
            data.showTips = true
            self.tableviewproBranchRewards_1:AppendData(data)
        end
    else
        -- 配置奖励为空，显示影响
        local systemEntryConfig = ConfigRefer.SystemEntry:Find(config:UnlockSystems(1))
        if not systemEntryConfig then
            return
        end
    end
end

function WorldTrendGlobalBranch:InitBranchRewardOrEffect_2(config)
    if config:BranchGuideDemoLength() > 0 then
        self.video2 = config:BranchGuideDemo(1)
    else
        self.video2 = nil
    end
    self.tips2 = I18N.Get(config:BranchResultDesc())
    g_Game.SpriteManager:LoadSprite(config:BranchResultsIcon(), self.icon2)

    local rewardList = ModuleRefer.QuestModule.GetItemGroupInfoById(config:Reward())
    if rewardList then
        -- 配置奖励就不显示影响
        self.tableviewproBranchRewards_2:Clear()
        for _, reward in ipairs(rewardList) do
            local data = {}
            data.configCell = ConfigRefer.Item:Find(reward:Items())
            data.count = reward:Nums()
            data.showTips = true
            self.tableviewproBranchRewards_2:AppendData(data)
        end
    else
        -- 配置奖励为空，显示影响
        local systemEntryConfig = ConfigRefer.SystemEntry:Find(config:UnlockSystems(2))
        if not systemEntryConfig then
            return
        end
    end
end

function WorldTrendGlobalBranch:UpdateVoteProgress()
    local totalVote = self.branch1Vote + self.branch2Vote
    local branch1Percent = 0
    local branch2Percent = 0
    if totalVote > 0 then
        branch1Percent = self.branch1Vote / totalVote
        branch2Percent = self.branch2Vote / totalVote
    end
    self.sliderProgress_1.value = branch1Percent
    self.sliderProgress_2.value = branch2Percent

    if branch1Percent > branch2Percent then
        self.SetSliderColor(self.fill1, self.fill2, self.iconBg1, self.iconBg2)
    else
        self.SetSliderColor(self.fill2, self.fill1, self.iconBg2, self.iconBg1)
    end
end

function WorldTrendGlobalBranch.SetSliderColor(winnerFill, loserFill, winnerBg, loserBg)
    -- winnerSlider
    winnerFill.color = UIHelper.TryParseHtmlString("#9CBAF2")
    loserFill.color = UIHelper.TryParseHtmlString("#D9E1F1")

    g_Game.SpriteManager:LoadSprite("sp_world_trend_base_circle_03", loserBg)
    g_Game.SpriteManager:LoadSprite("sp_world_trend_base_circle_01", winnerBg)

end

function WorldTrendGlobalBranch:OnClickBranch_1()
    if self.curStageState == WorldTrendDefine.BRANCH_STATE.CanReward and self.curRewardBranch == self.branchID_1 then
        local parameter = ReceiveWorldStageRewardParameter.new()
        parameter.args.StageId = self.curRewardBranch
        parameter:Send()
    end
end

function WorldTrendGlobalBranch:OnClickBranch_2()
    if self.curStageState == WorldTrendDefine.BRANCH_STATE.CanReward and self.curRewardBranch == self.branchID_2 then
        local parameter = ReceiveWorldStageRewardParameter.new()
        parameter.args.StageId = self.curRewardBranch
        parameter:Send()
    end
end

function WorldTrendGlobalBranch:OnVoteChanged(_, changedTable)
    if not changedTable then
        return
    end
    local isChanged = false
    for k, v in pairs(changedTable) do
        if k == self.branchID_1 then
            self:UpdateVote_1(v)
            isChanged = true
        elseif k == self.branchID_2 then
            self:UpdateVote_2(v)
            isChanged = true
        end
    end
    if isChanged then
        self:BranchCompare()
        self:UpdateVoteProgress()
    end
end

function WorldTrendGlobalBranch:UpdateVote_1(num)
    if num > self.branch1Vote then
        self.branch1Vote = num
        self.textHotNum_1.text = tostring(self.branch1Vote)
    end
end

function WorldTrendGlobalBranch:UpdateVote_2(num)
    if num > self.branch2Vote then
        self.branch2Vote = num
        self.textHotNum_1.text = tostring(self.branch2Vote)
    end
end

function WorldTrendGlobalBranch:OnStageStateChanged(_, changedTable)
    if not changedTable or not changedTable.Add then
        return
    end
    local isChanged = false
    for k, v in pairs(changedTable.Add) do
        if v.Stage == self.stage and self.curStageState == WorldTrendDefine.BRANCH_STATE.Voting then
            self.curStageState = WorldTrendDefine.BRANCH_STATE.CanReward
            isChanged = true
        end
    end
    if isChanged then
        self:InitBranch_1(self.branchID_1)
        self:InitBranch_2(self.branchID_2)
        self:BranchCompare()
    end
end

function WorldTrendGlobalBranch:OnClaimReward(isSuccess, reply, rpc)
    if not isSuccess then
        return
    end
    self.curStageState = WorldTrendDefine.BRANCH_STATE.Rewarded
    self:BranchCompare()
    g_Game.EventManager:TriggerEvent(EventConst.WORLD_TREND_REWARD, self.stage)
end

function WorldTrendGlobalBranch:OnClickIcon1()
    local params = {}
    if self.video1 then
        params.pos = self.btnIcon1.gameObject.transform.position
        params.tips = self.tips1
        params.video = self.video1
        g_Game.UIManager:Open(UIMediatorNames.WorldTrendToastTextMediator, params)
    else
        params.clickTransform = self.btnIcon1.gameObject.transform
        params.content = I18N.Get(self.tips1)
        ModuleRefer.ToastModule:ShowTextToast(params)
    end
end

function WorldTrendGlobalBranch:OnClickIcon2()
    local params = {}
    if self.video2 then
        params.pos = self.btnIcon2.gameObject.transform.position
        params.tips = self.tips2
        params.video = self.video2
        g_Game.UIManager:Open(UIMediatorNames.WorldTrendToastTextMediator, params)
    else
        params.clickTransform = self.btnIcon2.gameObject.transform
        params.content = I18N.Get(self.tips2)
        ModuleRefer.ToastModule:ShowTextToast(params)
    end
end

return WorldTrendGlobalBranch
