local BaseUIMediator = require('BaseUIMediator')
---@class ActivityShopPackRewardPopupMediator : BaseUIMediator
local ActivityShopPackRewardPopupMediator = class('ActivityShopPackRewardPopupMediator', BaseUIMediator)

---@class RewardPopupParams
---@field itemArray table<number, ItemIconData>
---@field icon string

function ActivityShopPackRewardPopupMediator:OnCreate()
    self.goPackIcon = self:GameObject('p_group_pack')
    self.textSubTitle = self:Text('p_text_subtitle', 'get_top-up_item_title')
    self.imgIcon = self:Image('p_icon_pack')
    self.tableReward = self:TableViewPro('p_table_reward')
    self.textTap2Continue = self:Text('p_text_tap', 'get_top-up_item_closed_tips')
end

---@param params RewardPopupParams
function ActivityShopPackRewardPopupMediator:OnOpened(params)
    if not params then
        return
    end
    self.itemArray = params.itemArray
    table.sort(self.itemArray, self.QualityComparator)
    self.tableReward:Clear()
    for _, item in ipairs(self.itemArray) do
        self.tableReward:AppendData(item)
    end
    self.goPackIcon:SetActive(params.icon ~= nil)
    if params.icon then
        g_Game.SpriteManager:LoadSprite(params.icon, self.imgIcon)
    end
end

---@param a ItemIconData
---@param b ItemIconData
function ActivityShopPackRewardPopupMediator.QualityComparator(a, b)
    return a.configCell:Quality() > b.configCell:Quality()
end

return ActivityShopPackRewardPopupMediator