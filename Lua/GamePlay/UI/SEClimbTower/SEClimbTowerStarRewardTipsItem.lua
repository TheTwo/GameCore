local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local SEClimbTowerStarRewardState = require('SEClimbTowerStarRewardState')
local ModuleRefer = require('ModuleRefer')
local EventConst = require('EventConst')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')

---@class SEClimbTowerStarRewardTipsItemData
---@field chapterId number
---@field index number

---@class SEClimbTowerStarRewardTipsItem:BaseUIComponent
---@field new fun():SEClimbTowerStarRewardTipsItem
---@field super BaseUIComponent
local SEClimbTowerStarRewardTipsItem = class('SEClimbTowerStarRewardTipsItem', BaseUIComponent)

function SEClimbTowerStarRewardTipsItem:OnCreate()
    self.txtCount = self:Text('p_text_quantity')
    self.btnBox = self:Button('p_btn_box', Delegate.GetOrCreate(self, self.OnBoxClick))
    self.vxTrigger = self:AnimTrigger('vx_trigger_star')
end

---@param data SEClimbTowerStarRewardTipsItemData
function SEClimbTowerStarRewardTipsItem:OnFeedData(data)
    self.chapterId = data.chapterId
    self.index = data.index
    self.state = ModuleRefer.SEClimbTowerModule:GetStarRewardBoxState(self.chapterId, self.index)

    ---@type ClimbTowerChapterStarRewardConfigCell
    local starRewardConfigCell = ModuleRefer.SEClimbTowerModule:GetStarRewardConfigCell(self.chapterId, self.index)
    local starNum = starRewardConfigCell:StarNum()
    self.txtCount.text = tostring(starNum)

    if self.state == SEClimbTowerStarRewardState.NotReach then
        self.vxTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
    elseif self.state == SEClimbTowerStarRewardState.CanCliam then
        self.vxTrigger:PlayAll(FpAnimTriggerEvent.Custom2)
    elseif self.state == SEClimbTowerStarRewardState.HasCliamed then
        self.vxTrigger:PlayAll(FpAnimTriggerEvent.Custom4)
    end
end

function SEClimbTowerStarRewardTipsItem:OnCloseClick()
    self:SetVisible(false)
end

function SEClimbTowerStarRewardTipsItem:OnBoxClick()
    if self.state == SEClimbTowerStarRewardState.CanCliam then
        local starRewardReq = require('RewardClimbTowerParameter').new()
        starRewardReq.args.ChapterCfgId = self.chapterId
        starRewardReq.args.Indexes:Add(self.index - 1)  -- lua适配go的数组习惯，所以减一
        starRewardReq:Send()

        self.vxTrigger:PlayAll(FpAnimTriggerEvent.Custom3)
        return
    end

    g_Game.EventManager:TriggerEvent(EventConst.SE_CLIMB_TOWER_STAR_REWARD_BOX_SHOW_TIPS, self.chapterId, self.index) 
end

function SEClimbTowerStarRewardTipsItem:GetClickTrans()
    return self.btnBox.transform
end

return SEClimbTowerStarRewardTipsItem