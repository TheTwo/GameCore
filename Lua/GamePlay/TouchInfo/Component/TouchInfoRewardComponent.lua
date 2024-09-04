local BaseUIComponent = require('BaseUIComponent')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
local KingdomTouchInfoContext = require("KingdomTouchInfoContext")
local I18N = require("I18N")

---@class TouchInfoRewardCompData
---@field title string
---@field rewards ItemIconData[]
---@field showTip fun():string

---@class TouchInfoRewardComponent : BaseUIComponent
---@field data TouchInfoRewardCompData
local TouchInfoRewardComponent = class("TouchInfoRewardComponent", BaseUIComponent)

function TouchInfoRewardComponent:OnCreate()
    self._p_text_reward = self:Text("p_text_reward")
    self._p_table_reward = self:TableViewPro("p_table_reward")
    self._p_text_tip = self:Text("p_text_tip")
end

function TouchInfoRewardComponent:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.TOUCH_INFO_REWARD_SELECTED, Delegate.GetOrCreate(self, self.OnRewardSelected))
end

function TouchInfoRewardComponent:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.TOUCH_INFO_REWARD_SELECTED, Delegate.GetOrCreate(self, self.OnRewardSelected))
    KingdomTouchInfoContext.selectedItemConfig = nil
end

---@param data TouchInfoRewardCompData
function TouchInfoRewardComponent:OnFeedData(data)
    self.data = data
    self._p_text_reward.text = data.title or ""
    self._p_table_reward:Clear()
    for _, itemData in ipairs(data.rewards) do
        self._p_table_reward:AppendData(itemData)
    end
    self._p_table_reward:RefreshAllShownItem()
end

function TouchInfoRewardComponent:OnRewardSelected(itemConfig)
    if not self.data then
        return
    end
    
    for _, itemData in ipairs(self.data.rewards) do
        itemData.showSelect = itemData.configCell:Id() == itemConfig:Id()
    end
    KingdomTouchInfoContext.selectedItemConfig = itemConfig
    self:OnFeedData(self.data)
    
    self._p_text_tip.text = self.data.showTip()
    
end

return TouchInfoRewardComponent