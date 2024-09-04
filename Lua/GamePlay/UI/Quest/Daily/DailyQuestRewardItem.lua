local BaseUIComponent = require("BaseUIComponent")
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local Utils = require('Utils')
local ConfigRefer = require('ConfigRefer')
local UIHelper = require('UIHelper')
local TimerUtility = require('TimerUtility')
local DailyTaskReceiveProgressRewardParameter = require('DailyTaskReceiveProgressRewardParameter')
---@class DailyQuestRewardItem : BaseUIComponent
local DailyQuestRewardItem = class("DailyQuestRewardItem", BaseUIComponent)

function DailyQuestRewardItem:OnCreate()
    self.btnGift = self:Button('p_btn_gift', Delegate.GetOrCreate(self, self.OnBtnGiftClicked))
    self.imgIconGift = self:Image('icon_gift')
    self.textGift = self:Text('p_text_gift')
	self.animation = self:BindComponent("p_cell_group", typeof(CS.UnityEngine.Animation))

    self.goBubble = self:GameObject("p_bubble")
    self.imgImg = self:Image('p_item')
    if Utils.IsNotNull(self.goBubble) then
        self.goBubble:SetActive(false)
    end
end

function DailyQuestRewardItem:OnOpened()
    self.goLoop = self:GameObject('vx_novice_circle_n')
    self.goGet = self:GameObject('vx_common_explode')
    self.goLoop:SetActive(false)
    self.goGet:SetActive(false)
end

function DailyQuestRewardItem:OnBtnGiftClicked()
    if self.isEnough and not self.isGot then
        TimerUtility.DelayExecute(function()
            local parameter = DailyTaskReceiveProgressRewardParameter.new()
            parameter.args.Progress = self.cfg:Progress(self.index)
            parameter:Send() end, 0.3)
        if Utils.IsNotNull(self.animation) then
            self.goGet:SetActive(true)
            self.goLoop:SetActive(false)
            self.animation:Play("anim_vx_ui_mission_item_gift_respond")
        end
    else
        local reward = self.cfg:ProgressRewards(self.index)
        local items = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(reward)
        local rewardLists = {{titleText = I18N.Get("daily_info_reward")}}
        for _, item in ipairs(items) do
            rewardLists[#rewardLists + 1] = {itemId = item.configCell:Id(), itemCount = item.count}
        end
        local giftTipsParam = {listInfo = rewardLists, clickTrans = self.btnGift.transform}
        g_Game.UIManager:Open("GiftTipsUIMediator", giftTipsParam)
    end
end

function DailyQuestRewardItem:PlayShowAnim()
	self.animation:Play("anim_vx_ui_misson_item_gift_in")
end

function DailyQuestRewardItem:PlayInitAnim()
	self.animation:Play("anim_vx_ui_misson_item_gift_null")
end

function DailyQuestRewardItem:OnFeedData(data)
    if not data then
        return
    end
    self.data = data
    self:RefreshData()
end

function DailyQuestRewardItem:RefreshData()
    local data = self.data
    self.goLoop:SetActive(false)
    self.goGet:SetActive(false)

    self.index = data.index
    self.cfg = data.cfg
    local score = self.cfg:Progress(self.index)
    local curScore = ModuleRefer.QuestModule.Daily:GetCurScore()
    self.textGift.text = score
    self.isEnough = curScore >= score
    self.isGot = ModuleRefer.QuestModule.Daily:CheckIsGotReward(score)
    if self.isGot then
        g_Game.SpriteManager:LoadSprite(self.cfg:UnlockedIcons(self.index), self.imgIconGift)
    else
        g_Game.SpriteManager:LoadSprite(self.cfg:LockedIcons(self.index), self.imgIconGift)
    end
    if self.isEnough and not self.isGot then
       if Utils.IsNotNull(self.animation) then
            self.animation:Play("anim_vx_ui_misson_item_gift_loop")
            self.goLoop:SetActive(true)
        end
    end
    if Utils.IsNotNull(self.goBubble) then
        local itemId = ConfigRefer.DailyTaskConst:BoxExtra()
        if self.index == 5 and itemId and itemId > 0 then
            self.goBubble:SetActive(true)
            local itemCell = ConfigRefer.Item:Find(itemId)
            local icon = UIHelper.GetFitItemIcon(self.imgImg, itemCell)
            g_Game.SpriteManager:LoadSprite(icon, self.imgImg)
        end
    end
end



return DailyQuestRewardItem