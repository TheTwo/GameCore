local BaseTableViewProCell = require ('BaseTableViewProCell')
local I18N = require('I18N')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local StarRewardHuntingParameter = require('StarRewardHuntingParameter')
local EventConst = require('EventConst')
---@class HuntingStarRewardCell : BaseTableViewProCell
local HuntingStarRewardCell = class('HuntingMonsterCell', BaseTableViewProCell)

local REWARD_STATUS = {
    NOT_AVAILABLE = 0,
    AVAILABLE = 1,
    FINISHED = 2,
    FIRST_NOT_AVAILABLE = 3,
}

function HuntingStarRewardCell:OnCreate()
    self.textReward = self:Text('p_text_rewards', 'alliance_tec_huode')
    self.textStarNum = self:Text('p_text_star_num')
    self.tableReward = self:TableViewPro('p_table')

    self.btnClaim = self:Button('p_btn_claim', Delegate.GetOrCreate(self, self.OnBtnClaimClicked))
    self.textBtnClaim = self:Text('p_text', 'activity_signin_btn_active')
    self.textLock = self:Text('p_text_lock', 'UI_Title_UpdateLock')
    self.imgIconClaimed = self:Image('p_icon_claimed')

    self.btnGoto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnBtnGotoClicked))
    self.textGoto = self:Text('p_text_goto', 'alliance_bj_qianwang')

    self.btnStatusCtrler = {
        [REWARD_STATUS.NOT_AVAILABLE] = self.textLock.gameObject,
        [REWARD_STATUS.FIRST_NOT_AVAILABLE] = self.btnGoto.gameObject,
        [REWARD_STATUS.AVAILABLE] = self.btnClaim.gameObject,
        [REWARD_STATUS.FINISHED] = self.imgIconClaimed.gameObject,
    }
end

function HuntingStarRewardCell:OnFeedData(param)
    if not param then
        return
    end
    self.starRewardId = param.starRewardId
    self.starNum = param.starNum
    self.rewardList = param.rewardList
    self.isFirstNotAvailable = param.isFirstNotAvailable

    self.canClaim = ModuleRefer.HuntingModule:GetCurStarNum() >= self.starNum
    self.isClaimed = ModuleRefer.HuntingModule:IsStarRewardClaimed(self.starRewardId)

    self.status = REWARD_STATUS.NOT_AVAILABLE
    if self.isFirstNotAvailable then
        self.status = REWARD_STATUS.FIRST_NOT_AVAILABLE
    elseif self.canClaim then
        if self.isClaimed then
            self.status = REWARD_STATUS.FINISHED
        else
            self.status = REWARD_STATUS.AVAILABLE
        end
    end

    for status, go in pairs(self.btnStatusCtrler) do
        go:SetActive(status == self.status)
    end

    self.textStarNum.text = self.starNum
    self.tableReward:Clear()
    for _, reward in ipairs(self.rewardList) do
        self.tableReward:AppendData(reward)
    end
end

function HuntingStarRewardCell:OnBtnClaimClicked()
    local msg = StarRewardHuntingParameter.new()
    msg.args.HuntingStarRewardCfgIds:AddRange({self.starRewardId})
    msg:Send(self.btnClaim.transform)
end

function HuntingStarRewardCell:OnBtnGotoClicked()
    g_Game.EventManager:TriggerEvent(EventConst.HUNTING_GOTO_CURRENT_LEVEL)
    self:GetParentBaseUIMediator():CloseSelf()
end

return HuntingStarRewardCell