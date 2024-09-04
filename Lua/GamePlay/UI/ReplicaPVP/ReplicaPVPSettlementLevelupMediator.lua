local BaseUIMediator = require("BaseUIMediator")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local TimerUtility = require("TimerUtility")

---@class ReplicaPVPSettlementLevelupMediatorParameter
---@field env SEEnvironment
---@field rewardInfo wrpc.LevelRewardInfo

---@class ReplicaPVPSettlementLevelupMediator:BaseUIMediator
---@field new fun():ReplicaPVPSettlementLevelupMediator
---@field super BaseUIMediator
local ReplicaPVPSettlementLevelupMediator = class('ReplicaPVPRankChangeMediator', BaseUIMediator)

local ANIM_DURATION = 3

function ReplicaPVPSettlementLevelupMediator:OnCreate(param)
    self.txtTitle = self:Text('p_text_title', 'se_pvp_battlemessage_levelup')

    self.imgRankIcon = self:Image('p_icon_level_old')
    self.imgRankIconNum = self:Image('p_icon_lv_num_old')
    self.txtRankName = self:Text('p_text_level_old')
    self.imgRankIconNew = self:Image('p_icon_level_new')
    self.imgRankIconNumNew = self:Image('p_icon_lv_num_new')
    self.txtRankNameNew = self:Text('p_text_level_new')
    self.sliderScores = self:Slider('p_progress_add')

    self.goReward = self:GameObject('p_reward')
    self.txtReward = self:Text('p_text_reward', 'se_pvp_battlemessage_reward')
    self.tableRewards = self:TableViewPro('p_table_reward')

    self.txtContinue = self:Text('p_text_continue', 'pet_se_result_memo')
    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnCloseClick))

    self.vxTrigger = self:AnimTrigger('trigger')
end

---@param param ReplicaPVPSettlementLevelupMediatorParameter
function ReplicaPVPSettlementLevelupMediator:OnOpened(param)
    self.param = param
    self.canClose = false
    self.txtContinue:SetVisible(false)

    self:RefreshUI()
    self.timer = TimerUtility.DelayExecute(function()
        self.canClose = true
        self.txtContinue:SetVisible(true)
    end, ANIM_DURATION)

    g_Game.SoundManager:Play("sfx_se_fight_upgrade")
end

function ReplicaPVPSettlementLevelupMediator:OnClose(param)
    self.param.env:QuitSE()

    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
end

function ReplicaPVPSettlementLevelupMediator:OnShow(param)
end

function ReplicaPVPSettlementLevelupMediator:OnHide(param)
end

function ReplicaPVPSettlementLevelupMediator:OnCloseClick()
    if self.canClose then
        self:CloseSelf()
    end
end

function ReplicaPVPSettlementLevelupMediator:RefreshUI()
    local oldTitle = self.param.rewardInfo.ReplicaPvpRewardInfo.OldTitle
    local oldTitleConfigCell = ConfigRefer.PvpTitleStage:Find(oldTitle)
    self:LoadSprite(oldTitleConfigCell:Icon(), self.imgRankIcon)
    if oldTitleConfigCell:LevelIcon() > 0 then
        self.imgRankIconNum:SetVisible(true)
        self:LoadSprite(oldTitleConfigCell:LevelIcon(), self.imgRankIconNum)
    else
        self.imgRankIconNum:SetVisible(false)
    end
    self.txtRankName.text = I18N.Get(oldTitleConfigCell:Name())

    local newTitle = self.param.rewardInfo.ReplicaPvpRewardInfo.NewTitle
    local newTitleConfigCell = ConfigRefer.PvpTitleStage:Find(newTitle)
    self:LoadSprite(newTitleConfigCell:Icon(), self.imgRankIconNew)
    if newTitleConfigCell:LevelIcon() > 0 then
        self.imgRankIconNumNew:SetVisible(true)
        self:LoadSprite(newTitleConfigCell:LevelIcon(), self.imgRankIconNumNew)
    else
        self.imgRankIconNumNew:SetVisible(false)
    end
    self.txtRankNameNew.text = I18N.Get(newTitleConfigCell:Name())

    local showRewards = self.param.rewardInfo.ReplicaPvpRewardInfo.IsGiveTitleReward
    self.goReward:SetVisible(showRewards)
    if showRewards then
        self.tableRewards:Clear()
        local itemGroupId = newTitleConfigCell:IMMDReward()
        local itemGroupConfigCell = ConfigRefer.ItemGroup:Find(itemGroupId)
        for i = 1 ,itemGroupConfigCell:ItemGroupInfoListLength() do
            local itemGroupInfo = itemGroupConfigCell:ItemGroupInfoList(i)
            self.tableRewards:AppendData(itemGroupInfo)
        end
    end

    self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)

    local newScore = self.param.rewardInfo.ReplicaPvpRewardInfo.Mine.NewScore
    local show, progress = ModuleRefer.ReplicaPVPModule:GetStageProgress(newScore)
    self.sliderScores:SetVisible(show)
    if show then
        self.sliderScores.value = 0
        self.sliderScores:DOValue(progress, ANIM_DURATION):OnComplete(function()
            self.canClose = true
            self.txtContinue:SetVisible(true)
        end)
    else
        self.canClose = true
        self.txtContinue:SetVisible(true)
    end
end

return ReplicaPVPSettlementLevelupMediator