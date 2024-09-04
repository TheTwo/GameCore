local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local NoviceConst = require('NoviceConst')
local UIHelper = require('UIHelper')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local NotificationType = require('NotificationType')
local TimerUtility = require('TimerUtility')
local DBEntityPath = require('DBEntityPath')
local OnChangeHelper = require('OnChangeHelper')
local ColorConsts = require('ColorConsts')
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
---@class NoviceTaskRewardCell : BaseTableViewProCell
local NoviceTaskRewardCell = class('NoviceTaskRewardCell', BaseTableViewProCell)

local MAX_HEIGHT = 800

local BubbleBase = {
    'sp_hero_item_circle_1',
    'sp_hero_item_circle_2',
    'sp_hero_item_circle_3',
    'sp_hero_item_circle_4',
    'sp_hero_item_circle_5',
}

local BubbleArrowColor = {
    UIHelper.TryParseHtmlString(ColorConsts.quality_white),
    UIHelper.TryParseHtmlString(ColorConsts.quality_green),
    UIHelper.TryParseHtmlString(ColorConsts.quality_blue),
    UIHelper.TryParseHtmlString(ColorConsts.quality_purple),
    UIHelper.TryParseHtmlString(ColorConsts.quality_orange),
}

local VxType = {
    Open = {
        [NoviceConst.RewardType.Normal] = CS.FpAnimation.CommonTriggerType.Custom3,
        [NoviceConst.RewardType.High] = CS.FpAnimation.CommonTriggerType.Custom4,
    },
    Finish = {
        [NoviceConst.RewardType.Normal] = CS.FpAnimation.CommonTriggerType.Custom1,
        [NoviceConst.RewardType.High] = CS.FpAnimation.CommonTriggerType.Custom2,
    },
}

function NoviceTaskRewardCell:OnCreate()
    self.root = self:GameObject('')
    self.selfRect = self:RectTransform('')
    self.btnRewardChest = self:Button('p_btn_reward', Delegate.GetOrCreate(self, self.OnBtnRewardChestClicked))
    self.textProgress = self:Text('p_text_reward_num')
    self.imgIconRewardN = self:Image('p_icon_reward_n')
    self.imgIconRewardOpen = self:Image('p_icon_reward_open')
    self.imgIconRewardHigh = self:Image('p_icon_reward_high')
    self.imgIconRewardHighOpen = self:Image('p_icon_reward_high_open')

    self.goBubble = self:GameObject('p_bubble')
    self.btnBubble = self:Button('p_btn_bubble', Delegate.GetOrCreate(self, self.OnBubbleClick))
    self.imgBubbleImg = self:Image('p_img')
    self.imgIconArrow = self:Image('p_icon_arrow')
    self.imgBase = self:Image('p_base')

    self.chestIconVisibleControl = {}
    self.chestIconVisibleControl[NoviceConst.RewardStatus.locked] = {
        self.imgIconRewardN.gameObject,
        self.imgIconRewardHigh.gameObject
    }
    self.chestIconVisibleControl[NoviceConst.RewardStatus.claimed] = {
        self.imgIconRewardOpen.gameObject,
        self.imgIconRewardHighOpen.gameObject
    }

    self.notifyNode = self:LuaObject('child_reddot_default')
    self.rewardAnimTrigger = self:BindComponent('trigger_reward', typeof(CS.FpAnimation.FpAnimationCommonTrigger))
    self.goVxCircles = {
        [NoviceConst.RewardType.Normal] = self:GameObject('vx_novice_circle_n'),
        [NoviceConst.RewardType.High] = self:GameObject('vx_novice_circle_high'),
    }
    self.goVxExplode = self:GameObject('vx_common_explode')
end

function NoviceTaskRewardCell:OnShow()
    for _, icons in pairs(self.chestIconVisibleControl) do
        for _, icon in ipairs(icons) do
            icon:SetActive(false)
        end
    end
end

function NoviceTaskRewardCell:OnHide()
end

function NoviceTaskRewardCell:OnFeedData(param)
    if not param then
        return
    end
    self.index = param.index
    self.score = param.score
    self.type = param.type
    self.rewardId = param.rewardId
    self.shouldPlayAnim = param.shouldPlayAnim
    self.textProgress.text = tostring(self.score)

    self.goVxExplode:SetActive(self.shouldPlayAnim)

    local uiCamera = g_Game.UIManager:GetUICamera()
    local y = self.root.transform.localPosition.y
    local z = self.root.transform.localPosition.z
    local x = param.pos - self.selfRect.rect.width / 2
    self.root.transform.localPosition = CS.UnityEngine.Vector3(x, y, z)

    --- set chest icon
    local isClaimed = ModuleRefer.NoviceModule:GetRewardOpenStatus(self.index)
    if self.shouldPlayAnim then
        self.rewardAnimTrigger:PlayAll(VxType.Open[self.type])
        self.status = NoviceConst.RewardStatus.claimed
    elseif isClaimed then
        self.status = NoviceConst.RewardStatus.claimed
    else
        self.status = NoviceConst.RewardStatus.locked
    end
    self:SetRewardIcon(self.status)

    --- set bubble image
    local rewardGroup = ConfigRefer.ItemGroup:Find(self.rewardId)
    local bubbleItemId = rewardGroup:ItemGroupInfoList(1):Items() -- 1：显示奖励道具列表中的第一项
    local bubbleItemIcon = ConfigRefer.Item:Find(bubbleItemId):Icon()
    local bubbleItemQuality = ConfigRefer.Item:Find(bubbleItemId):Quality()
    self.bubbleItemId = bubbleItemId
    g_Game.SpriteManager:LoadSprite(bubbleItemIcon, self.imgBubbleImg)

    --- set bubble color
    self.goBubble:SetActive(self.type == NoviceConst.RewardType.High and self.status == NoviceConst.RewardStatus.locked)
    self.imgIconArrow.color = BubbleArrowColor[bubbleItemQuality]
    g_Game.SpriteManager:LoadSprite(BubbleBase[bubbleItemQuality], self.imgBase)

    --- set notify
    local notifyNode = ModuleRefer.NotificationModule:GetDynamicNode(
        NoviceConst.NoviceNotificationNodeNames.NoviceReward .. self.index, NotificationType.NOVICE_REWARD)
    ModuleRefer.NotificationModule:AttachToGameObject(notifyNode, self.notifyNode.go, self.notifyNode.redDot)

    if ModuleRefer.NoviceModule:IsRewardCanClaim(self.index) and not ModuleRefer.NoviceModule:IsRewardOpened(self.index) then
        self.goVxCircles[self.type]:SetActive(true)
        TimerUtility.DelayExecuteInFrame(function()
            self.rewardAnimTrigger:PlayAll(VxType.Finish[self.type])
        end, 1)
    else
        self.goVxCircles[self.type]:SetActive(false)
    end
end

function NoviceTaskRewardCell:OnBtnRewardChestClicked()
    if self.status == NoviceConst.RewardStatus.locked then
        if ModuleRefer.NoviceModule:GetNoviceTaskScore() >= self.score then
            ModuleRefer.NoviceModule:ClaimNoviceTaskReward(self.index, self.btnRewardChest.transform)
        else
            local items = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(self.rewardId)
            local rewardLists = {{titleText = I18N.Get(NoviceConst.I18NKeys.REWARD_TITLE)}}
            for _, item in ipairs(items) do
                rewardLists[#rewardLists + 1] = {itemId = item.configCell:Id(), itemCount = item.count}
            end
            local giftTipsParam = {listInfo = rewardLists, clickTrans = self.btnRewardChest.gameObject.transform,
                maxHeight = MAX_HEIGHT, shouldAdapt = true}
            g_Game.UIManager:Open(UIMediatorNames.GiftTipsUIMediator, giftTipsParam)
        end
    end
end

function NoviceTaskRewardCell:SetRewardIcon(status)
    for ctrlStatus, icons in pairs(self.chestIconVisibleControl) do
        icons[self.type]:SetActive(ctrlStatus == status)
    end
end

function NoviceTaskRewardCell:OnBubbleClick()
    local param = {}
    param.itemId = self.bubbleItemId
    param.itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM
    g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
end

return NoviceTaskRewardCell