local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceVillageOccupationGainDetailRankRewardCell:BaseUIComponent
---@field new fun():AllianceVillageOccupationGainDetailRankRewardCell
---@field super BaseUIComponent
local AllianceVillageOccupationGainDetailRankRewardCell = class('AllianceVillageOccupationGainDetailRankRewardCell', BaseUIComponent)

function AllianceVillageOccupationGainDetailRankRewardCell:OnCreate(param)
    self._p_text_lv = self:Text("p_text_lv")
    ---@type BaseItemIcon[]
    self._itemIcons = {}
    self._itemIcons[1] = self:LuaObject("child_item_standard_s")
    self._itemIcons[2] = self:LuaObject("child_item_standard_s_1")
    self._itemIcons[3] = self:LuaObject("child_item_standard_s_2")
end

---@param data {rangeStart:number, to:number ,reward:ItemGroupConfigCell}
function AllianceVillageOccupationGainDetailRankRewardCell:OnFeedData(data)
    local count = data.to - data.rangeStart
    if count <= 0 then
        self._p_text_lv.text = I18N.GetWithParams("village_info_Ranked_Num", data.to)
    else
        self._p_text_lv.text = ("%s-%s"):format(data.rangeStart, data.to)
    end
    local rewardCount = data.reward:ItemGroupInfoListLength()
    local ItemConfig = ConfigRefer.Item
    for i = #self._itemIcons,1,-1  do
        if i > rewardCount then
            self._itemIcons[i]:SetVisible(false)
        else
            self._itemIcons[i]:SetVisible(true)
            local itemInfo = data.reward:ItemGroupInfoList(i)
            ---@type ItemIconData
            local iconData = {}
            iconData.configCell = ItemConfig:Find(itemInfo:Items())
            iconData.count = itemInfo:Nums()
            iconData.countUseBigNumber = true
            self._itemIcons[i]:FeedData(iconData)
        end
    end
end

return AllianceVillageOccupationGainDetailRankRewardCell