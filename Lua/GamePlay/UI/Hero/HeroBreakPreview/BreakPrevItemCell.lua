local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
---@class BreakPrevItemCell : BaseTableViewProCell
---@field baseIcon BaseItemIcon
local BreakPrevItemCell = class('BreakPrevItemCell',BaseTableViewProCell)

function BreakPrevItemCell:OnCreate(param)
    self.compChildItemStandardS = self:LuaBaseComponent('child_item_standard_s')
    self.compChildItemStandardS1 = self:LuaBaseComponent('child_item_standard_s_1')
    self.goIconFinish = self:GameObject('p_icon_finish')
    self.textLevel = self:Text('p_text_level')
    self.itemSlots = {self.compChildItemStandardS, self.compChildItemStandardS1}
end

function BreakPrevItemCell:OnFeedData(data)
    self.goIconFinish:SetActive(data.isBroken)
    self.textLevel.text =  I18N.Get("hero_level") .. " " .. data.lv
    local itemGroupConfig = ConfigRefer.ItemGroup:Find(data.breakConfig:CostItemGroupCfgId())
    local items = {}
    for i = 1, itemGroupConfig:ItemGroupInfoListLength() do
        local info = itemGroupConfig:ItemGroupInfoList(i)
        local itemId = info:Items()
        local itemConfig = ConfigRefer.Item:Find(itemId)
        if data.isBroken then
            local itemData = {
                showCount = false,
                configCell = itemConfig,
                onClick = function() self:ClickItem(itemId) end,}
            items[#items + 1] = itemData
        else
            local itemData = {
                configCell = itemConfig,
                count = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId),
                addCount = info:Nums(),
                showNumPair = true,
                onClick = function() self:ClickItem(itemId) end,}
            items[#items + 1] = itemData
        end
    end
    for index, itemSlot in ipairs(self.itemSlots) do
        itemSlot.gameObject:SetActive(items[index] ~= nil)
        if items[index] then
            itemSlot:FeedData(items[index])
        end
    end
end


function BreakPrevItemCell:ClickItem(itemId)
    ModuleRefer.InventoryModule:OpenExchangePanel({{id = itemId}})
end


return BreakPrevItemCell
