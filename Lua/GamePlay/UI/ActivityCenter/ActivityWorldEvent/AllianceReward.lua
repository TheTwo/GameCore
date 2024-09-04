local BaseTableViewProCell = require('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local GrowthFundConst = require('GrowthFundConst')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local DBEntityPath = require('DBEntityPath')
local PlayerGetAutoRewardParameter = require('PlayerGetAutoRewardParameter')
local Utils = require('Utils')
local ColorConsts = require('ColorConsts')
local UIHelper = require('UIHelper')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local TimerUtility = require('TimerUtility')
local EventConst = require('EventConst')
local ReceiveAllianceExpeditionRewardParameter = require('ReceiveAllianceExpeditionRewardParameter')

---@class AllianceReward : BaseTableViewProCell
local AllianceReward = class('AllianceReward', BaseTableViewProCell)

local statusEnum = {normal = 1, canClaim = 2, claimed = 3}
function AllianceReward:OnCreate()
    self.transform = self:Transform('')
    self.rectTransform = self:RectTransform('')
    self.p_btn_reward = self:Button('p_btn_reward', Delegate.GetOrCreate(self, self.OnBtnClick))
    self.p_img_claim = self:GameObject('p_img_claim')
    self.p_icon_reward_n = self:GameObject('p_icon_reward_n')
    self.p_icon_reward_open = self:GameObject('p_icon_reward_open')
    self.p_text_reward_num = self:Text('p_text_reward_num')
    self.p_bubble = self:GameObject('p_bubble')
    self.p_img = self:Image('p_img')
    self.p_btn_bubble = self:Button('p_btn_bubble', Delegate.GetOrCreate(self, self.OnBubbleClick))
end

function AllianceReward:OnShow()
    -- g_Game.EventManager:AddListener(EventConst.WORLD_EVENT_CLICK_ALLIANCE_REWARD, Delegate.GetOrCreate(self, self.CheckBubble))
end

function AllianceReward:OnHide()
    -- g_Game.EventManager:RemoveListener(EventConst.WORLD_EVENT_CLICK_ALLIANCE_REWARD, Delegate.GetOrCreate(self, self.CheckBubble))
end

function AllianceReward:OnFeedData(param)
    self.param = param
    self.showBubble = false
    self.p_text_reward_num.text = param.num .. "%"
    self.transform.localPosition = CS.UnityEngine.Vector3(param.posX - self.rectTransform.rect.width, self.transform.localPosition.y, self.transform.localPosition.z)
    self:Refresh()
end

function AllianceReward:Refresh()
    local isClaimed = self.param.isClaimed
    local num = self.param.num
    local curValue = self.param.curValue
    local isClaimable = curValue >= num
    self.isClaimable = isClaimable

    if isClaimed then
        self.p_img_claim:SetVisible(false)
        self.p_icon_reward_n:SetVisible(false)
        self.p_icon_reward_open:SetVisible(true)
    elseif not isClaimable then
        self.p_img_claim:SetVisible(false)
        self.p_icon_reward_n:SetVisible(true)
        self.p_icon_reward_open:SetVisible(false)
    elseif isClaimable then
        self.p_img_claim:SetVisible(true)
        self.p_icon_reward_n:SetVisible(true)
        self.p_icon_reward_open:SetVisible(false)
    end
end

function AllianceReward:CheckBubble(param)
    -- if param.index ~= self.param.index then
    --     self.showBubble = false
    --     self.p_bubble:SetVisible(self.showBubble)
    -- end
end

function AllianceReward:OnBubbleClick()
    -- local param = {itemId = self.param.itemGroup.configCell:Id(), itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM, clickTransform = self.p_btn_bubble.transform}
    -- self.tipsRuntimeId = g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
end

function AllianceReward:OnBtnClick()
    if not self.param.isClaimed and self.isClaimable then
        local parameter = ReceiveAllianceExpeditionRewardParameter.new()
        parameter.args.EntityId = self.param.ExpeditionEntityId
        parameter.args.Progress = self.param.num

        parameter:SendOnceCallback(nil, nil, nil, function(_, isSuccess, _)
            if isSuccess then
                self.param.isClaimed = true
                self.isClaimable = false

                local items = {}
                local count = self.param.itemGroupConfig:ItemGroupInfoListLength()
                for i = 1, count do
                    local itemGroup = self.param.itemGroupConfig:ItemGroupInfoList(i)
                    table.insert(items, {id = itemGroup:Items(), count = itemGroup:Nums()})
                end
                g_Game.UIManager:Open(UIMediatorNames.UIRewardMediator, {itemInfo = items})

                self.p_img_claim:SetVisible(false)
                self.p_icon_reward_n:SetVisible(false)
                self.p_icon_reward_open:SetVisible(true)
            end
        end)
    else
        local itemPram = {}
        local items = {}
        local count = self.param.itemGroupConfig:ItemGroupInfoListLength()
        for i = 1, count do
            local itemGroup = self.param.itemGroupConfig:ItemGroupInfoList(i)
            table.insert(items, {itemId = itemGroup:Items(), itemCount = itemGroup:Nums()})
        end
        itemPram.listInfo = items
        itemPram.clickTrans = self.p_btn_reward.gameObject.transform
        g_Game.UIManager:Open(UIMediatorNames.GiftTipsUIMediator, itemPram)
    end
end

return AllianceReward
