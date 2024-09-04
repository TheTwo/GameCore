local BaseTableViewProCell = require("BaseTableViewProCell")
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local DBEntityPath = require("DBEntityPath")
local TimeFormatter = require("TimeFormatter")
local GuideUtils = require("GuideUtils")
local LayoutRebuilder = CS.UnityEngine.UI.LayoutRebuilder
local UIMediatorNames = require("UIMediatorNames")
local ItemGroupHelper = require("ItemGroupHelper")
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")

local PetCollectionReward = class('PetCollectionReward', BaseTableViewProCell)

function PetCollectionReward:OnCreate()
    self.p_progress = self:Slider('p_progress')
    self.child_item_standard_s = self:LuaObject("child_item_standard_s")
    self.p_text_progress = self:Text('p_text_progress')
    self.p_text_progress_reach = self:Text('p_text_progress_reach')

    self.p_dot_n = self:GameObject('p_dot_n')
    self.p_dot_reach = self:GameObject('p_dot_reach')
end

function PetCollectionReward:OnShow()
end

function PetCollectionReward:OnHide()
end

function PetCollectionReward:OnFeedData(param)
    self.param = param
    self.p_text_progress.text = param:NeedPoint()
    self.p_text_progress_reach.text = param:NeedPoint()
    self:Refresh()
end

function PetCollectionReward:Refresh(IDs)
    -- 领奖刷新
    if IDs then
        for k, v in pairs(IDs) do
            if v == self.param.Index then
                self.param.isClaim = true
                self.param.canClaim = false
                break
            end
        end
    end

    local curPlayerProgress = ModuleRefer.PetCollectionModule:GetCollectionRewardCurrentProgress()

    self.canClaim = self.param.canClaim
    local needPoint = self.param:NeedPoint()

    if curPlayerProgress >= needPoint then
        self.p_progress.value = 1
        self.p_dot_n:SetVisible(false)
        self.p_dot_reach:SetVisible(true)
    else
        local progress = curPlayerProgress - self.param.lastNeedPoint
        self.p_progress.value = progress / needPoint
        self.p_dot_n:SetVisible(true)
        self.p_dot_reach:SetVisible(false)
    end

    self.rewardId = self.param:Id()
    local iconData = self.param.iconData
    self.itemId = iconData.configCell:Id()

    iconData.showCount = true
    iconData.received = self.param.isClaim
    iconData.claimable = self.canClaim
    iconData.onClick = Delegate.GetOrCreate(self, self.ClaimReward)
    self.child_item_standard_s:FeedData(iconData)
end

function PetCollectionReward:ClaimReward()
    if self.canClaim then
        g_Game.EventManager:TriggerEvent(EventConst.PET_COLLECTION_CLAIM_REWARDS)
    else
        local param = {itemId = self.itemId, itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM}
        self.tipsRuntimeId = g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
    end
end

return PetCollectionReward
