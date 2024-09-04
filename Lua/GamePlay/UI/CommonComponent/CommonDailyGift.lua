local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')
local CommonDailyGiftState = require('CommonDailyGiftState')
local UIHlper = require('UIHelper')

---@class CommonDailyGiftData
---@field state CommonDailyGiftState
---@field itemGroupId number    奖励预览
---@field customCloseIcon string
---@field customCloseText string
---@field customOpenIcon string
---@field customOpenText string
---@field onClickWhenClosed fun()
---@field onClickWhenOpened fun()

---@class CommonDailyGift : BaseUIComponent
local CommonDailyGift = class('CommonDailyGift', BaseUIComponent)

function CommonDailyGift:OnCreate()
    self.btnClosed = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnClosedClick))
    self.btnOpened = self:Button('p_btn_open', Delegate.GetOrCreate(self, self.OnOpenedClick))
    ---@type NotificationNode
    self.child_reddot_default = self:LuaObject('child_reddot_default')

    self.imgClosed = self:Image('p_icon_close')
    self.imgOpened = self:Image('p_icon_open')
    self.textGift = self:Text('p_text_gift')
    self.textClaimed = self:Text('p_text_claimed')

    self.vxTrigger = self:AnimTrigger('vx_trigger_open')
end

---@param data CommonDailyGiftData
function CommonDailyGift:OnFeedData(data)
    self.data = data
    self.btnClosed:SetVisible(data.state == CommonDailyGiftState.CanCliam)
    self.imgClosed:SetVisible(data.state == CommonDailyGiftState.CanCliam)
    self.textGift:SetVisible(data.state == CommonDailyGiftState.CanCliam)
    self.btnOpened:SetVisible(data.state == CommonDailyGiftState.HasCliamed)
    self.imgOpened:SetVisible(data.state == CommonDailyGiftState.HasCliamed)
    self.textClaimed:SetVisible(data.state == CommonDailyGiftState.HasCliamed)
    if not string.IsNullOrEmpty(data.customCloseIcon) then
        g_Game.SpriteManager:LoadSprite(data.customCloseIcon, self.imgClosed)
    end

    if not string.IsNullOrEmpty(data.customOpenIcon) then
        g_Game.SpriteManager:LoadSprite(data.customOpenIcon, self.imgOpened)
    end

    if self.textGift and data.customCloseText then
        self.textGift.text = data.customCloseText
    end

    if self.textClaimed and data.customOpenText then
        self.textClaimed.text = data.customOpenText
    end

    if data.state == CommonDailyGiftState.HasCliamed then
        self.vxTrigger:FinishAll(CS.FpAnimation.CommonTriggerType.OnEnable)
    end
end

function CommonDailyGift:OnClosedClick()
    if self.data.onClickWhenClosed then
        self.data.onClickWhenClosed()
    end
end

function CommonDailyGift:OnOpenedClick()
    if self.data.onClickWhenOpened then
        self.data.onClickWhenOpened()
    end

    if self.data.itemGroupId and self.data.itemGroupId > 0 then
        UIHlper.ShowRewardPreview(self.data.itemGroupId, self.btnOpened.transform)
    end
end

function CommonDailyGift:ChangeState(state)
    self.btnClosed:SetVisible(state == CommonDailyGiftState.CanCliam)
    self.imgClosed.gameObject:SetActive(state == CommonDailyGiftState.CanCliam)
    self.textGift.gameObject:SetActive(state == CommonDailyGiftState.CanCliam)
    self.btnOpened:SetVisible(state == CommonDailyGiftState.HasCliamed)
    self.imgOpened.gameObject:SetActive(state == CommonDailyGiftState.HasCliamed)
    self.textClaimed.gameObject:SetActive(state == CommonDailyGiftState.HasCliamed)
end

function CommonDailyGift:GetReddotNode()
    return self.child_reddot_default.CSComponent.gameObject
end

return CommonDailyGift
