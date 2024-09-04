local BaseUIComponent = require('BaseUIComponent')
local ConfigRefer = require("ConfigRefer")
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')

---@class SEClimbTowerSectionRewardTipsData
---@field chapterId number
---@field index number

---@class SEClimbTowerSectionRewardTips:BaseUIComponent
---@field new fun():SEClimbTowerSectionRewardTips
---@field super BaseUIComponent
local SEClimbTowerSectionRewardTips = class('SEClimbTowerSectionRewardTips', BaseUIComponent)

function SEClimbTowerSectionRewardTips:OnCreate()
    self.btnClose = self:Button('p_btn_empty_rewards', Delegate.GetOrCreate(self, self.OnCloseClick))

    self.txtTitle = self:Text('p_text_title_rewards')
    self.txtDesc = self:Text('p_text_hint', 'setower_tips_starreward')

    ---@type SEClimbTowerSectionRewardTipsItem
    self.rewardItem1 = self:LuaObject('p_rewards_1')
    self.rewardItem2 = self:LuaObject('p_rewards_2')
    self.rewardItem3 = self:LuaObject('p_rewards_3')

    self.rewardItems = {}
    table.insert(self.rewardItems, self.rewardItem1)
    table.insert(self.rewardItems, self.rewardItem2)
    table.insert(self.rewardItems, self.rewardItem3)
end

---@param data SEClimbTowerSectionRewardTipsData
function SEClimbTowerSectionRewardTips:OnFeedData(data)
    self.chapterId = data.chapterId
    self.index = data.index
    self.sectionConfigCell = ModuleRefer.SEClimbTowerModule:GetSectionConfigCell(self.chapterId, self.index)
    self.mapInstanceConfigCell = ConfigRefer.MapInstance:Find(self.sectionConfigCell:MapInstanceId())

    self:UpdateUI()
end

function SEClimbTowerSectionRewardTips:UpdateUI()
    -- 场景名
    self.txtTitle.text = I18N.Get(self.mapInstanceConfigCell:Name())

    for i = 1, 3 do
        ---@type SEClimbTowerSectionRewardTipsItem
        local rewardItem = self.rewardItems[i]

        ---@type SEClimbTowerSectionRewardTipsItemData
        local data = {}
        data.chapterId = self.chapterId
        data.section = self.index
        data.starIndex = i

        rewardItem:FeedData(data)
    end
end

function SEClimbTowerSectionRewardTips:OnCloseClick()
    self:SetVisible(false)
end

return SEClimbTowerSectionRewardTips