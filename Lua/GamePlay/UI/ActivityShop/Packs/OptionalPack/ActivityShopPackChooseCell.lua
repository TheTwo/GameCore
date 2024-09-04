local BaseTableViewProCell = require("BaseTableViewProCell")
local Delegate = require("Delegate")
local ConfigRefer = require('ConfigRefer')
local EventConst = require('EventConst')
---@class ActivityShopPackChooseCell : BaseTableViewProCell
local ActivityShopPackChooseCell = class("ActivityShopPackChooseCell", BaseTableViewProCell)

function ActivityShopPackChooseCell:OnCreate()
    self.textName = self:Text('p_text_item_name')
    self.iconChose = self:GameObject('p_icon_chose')
    self.iconItem = self:LuaObject('child_item_standard_s')

    self:PointerClick('base', Delegate.GetOrCreate(self, self.OnClick))
    self:PointerClick('p_text_item_name', Delegate.GetOrCreate(self, self.OnClick))
    self:PointerClick('p_icon_chose', Delegate.GetOrCreate(self, self.OnClick))
end

function ActivityShopPackChooseCell:OnFeedData(param)
    if not param then
        return
    end
    self.count = param.count
    self.configCell = param.configCell
    self.slotIndex = param.slotIndex
    self.packIndex = param.packIndex
    self.groupId = param.groupId
    local itemData = {
        configCell = self.configCell,
        count = self.count,
        showTips = true,
        showCount = true,
    }
    self.iconItem:FeedData(itemData)
    self.textName.text = param.name
    self.isSelected = param.isSelected
    self.iconChose.gameObject:SetActive(self.isSelected)
end

-- function ActivityShopPackChooseCell:OnSelectCustomItem(param)
--     local isSelfSelected = self.configCell:Id() == param.itemId
--     if isSelfSelected or not self.isSelected then
--         return
--     end
--     self.isSelected = false
--     self.iconChose.gameObject:SetActive(self.isSelected)
--     local data = {
--         isSelected = self.isSelected,
--         itemId = self.configCell:Id(),
--         count = self.count,
--         slotIndex = self.slotIndex
--     }
--     g_Game.EventManager:TriggerEvent(EventConst.ON_SELECT_CUSTOM_ITEM, data)
-- end

function ActivityShopPackChooseCell:OnClick()
    self.isSelected = not self.isSelected
    self.iconChose.gameObject:SetActive(self.isSelected)
    local param = {
        isSelected = self.isSelected,
        itemId = self.groupId,
        count = self.count,
        slotIndex = self.slotIndex,
        packIndex = self.packIndex,
    }
    g_Game.EventManager:TriggerEvent(EventConst.ON_SELECT_CUSTOM_ITEM, param)
end

return ActivityShopPackChooseCell