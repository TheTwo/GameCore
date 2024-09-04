local BaseUIComponent = require('BaseUIComponent')
local ConfigRefer = require("ConfigRefer")
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')

---@class SEClimbTowerSectionRewardTipsItemData
---@field chapterId number
---@field section number
---@field starIndex number

---@class SEClimbTowerSectionRewardTipsItem:BaseUIComponent
---@field new fun():SEClimbTowerSectionRewardTipsItem
---@field super BaseUIComponent
local SEClimbTowerSectionRewardTipsItem = class('SEClimbTowerSectionRewardTipsItem', BaseUIComponent)

function SEClimbTowerSectionRewardTipsItem:OnCreate()
    self.txtDesc = self:Text('p_text_rewards')
    self.table = self:TableViewPro('p_table_reward')
    self.imgStar = self:Image('p_icon_star')
end

---@param data SEClimbTowerSectionRewardTipsItemData
function SEClimbTowerSectionRewardTipsItem:OnFeedData(data)
    ---@type ClimbTowerSectionConfigCell
    local sectionConfigCell = ModuleRefer.SEClimbTowerModule:GetSectionConfigCell(data.chapterId, data.section)
    local starEvent = sectionConfigCell:StarEvent(data.starIndex)
    self.txtDesc.text = ModuleRefer.SEClimbTowerModule:GetStartEventDesc(starEvent)

    self.imgStar:SetVisible(ModuleRefer.SEClimbTowerModule:IsSectionStarAchieved(sectionConfigCell:Id(), data.starIndex))

    local itemGroupId = sectionConfigCell:StarReward(data.starIndex)
    local items = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(itemGroupId)
    self.table:Clear()
    for _, itemIconData in ipairs(items) do
        ---@type SEClimbTowerSectionRewardTipsCellData
        local cellData = {}
        cellData.itemIconData = itemIconData
        self.table:AppendData(cellData)
    end
end

function SEClimbTowerSectionRewardTipsItem:OnCloseClick()
    self:SetVisible(false)
end

return SEClimbTowerSectionRewardTipsItem