local BaseUIComponent = require('BaseUIComponent')
local ConfigRefer = require('ConfigRefer')
local TurnTableConst = require('TurnTableConst')
local UIHelper = require('UIHelper')
local TimerUtility = require('TimerUtility')
---@class TurnTableItem : BaseUIComponent
local TurnTableItem = class('TurnTableItem', BaseUIComponent)

local REWARD_STATUS = TurnTableConst.REWARD_STATUS

local QUALITY_IMG = {
    [true] = {
        'sp_activity_turntable_img_01_light',
        'sp_activity_turntable_img_01_light',
        'sp_activity_turntable_img_02_light',
        'sp_activity_turntable_img_03_light',
        'sp_activity_turntable_img_04_light',
    },
    [false] = {
        'sp_activity_turntable_img_01_n',
        'sp_activity_turntable_img_01_n',
        'sp_activity_turntable_img_02_n',
        'sp_activity_turntable_img_03_n',
        'sp_activity_turntable_img_04_n',
    }
}

function TurnTableItem:OnCreate()
    self.goStatusGet = self:GameObject('p_status_get')
    self.goStatusGray = self:GameObject('p_status_grey')
    self.item = self:LuaBaseComponent('child_item_standard_s')

    self.imgBaseNormal = self:Image('p_base_frame_normal')
    self.imgBaseSelect = self:Image('p_base_frame_select')

    self.status = {}
    self.status[REWARD_STATUS.GET] = self.goStatusGet
    self.status[REWARD_STATUS.GRAY] = self.goStatusGray

    self.vxTrigger = self:AnimTrigger('vx_item_trigger')
end

function TurnTableItem:OnFeedData(param)
    if not param then
        return
    end
    self.itemId = param.itemId
    self.type = param.type
    local configCell = ConfigRefer.Item:Find(self.itemId)
    local iconData = {
        configCell = configCell,
        count = param.count,
        showTips = true,
    }
    self.item:FeedData(iconData)
    local quality = configCell:Quality()
    if self.type == TurnTableConst.ITEM_TYPE.HIGH then
        g_Game.SpriteManager:LoadSprite(QUALITY_IMG[false][quality], self.imgBaseNormal)
        g_Game.SpriteManager:LoadSprite(QUALITY_IMG[true][quality], self.imgBaseSelect)
        self:SetSelect(false)
    end
end

function TurnTableItem:OnHide()
    if self.delayedTimer then
        TimerUtility.StopAndRecycle(self.delayedTimer)
        self.delayedTimer = nil
    end
end

function TurnTableItem:SetStatus(status)
    for k, v in pairs(self.status) do
        v:SetActive(k == status)
    end
end

function TurnTableItem:SetGetDisplay(shouldDisplay)
    self.goStatusGet:SetActive(shouldDisplay)
end

function TurnTableItem:SetGrayDisplay(shouldDisplay)
    self.goStatusGray:SetActive(shouldDisplay)
end

function TurnTableItem:SetSelect(isSelect)
    self.imgBaseNormal.gameObject:SetActive(not isSelect)
    self.imgBaseSelect.gameObject:SetActive(isSelect)
end

function TurnTableItem:PlayNormalRewardAnim(callback)
    self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2, callback)
end

function TurnTableItem:PlayNormalRewardReceivedAnim(callback)
    self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1, callback)
end

function TurnTableItem:PlayAdvancedRewardAnim(callback)
    self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3) -- 这个动效是一个纯粒子效果，直接用接口的回调会有问题
    self.delayedTimer = TimerUtility.DelayExecute(function()
        callback()
    end, 2)
end

return TurnTableItem