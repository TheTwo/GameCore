local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local SelectResolveItemCell = class('SelectResolveItemCell',BaseTableViewProCell)

function SelectResolveItemCell:OnCreate(param)
    self.compChildItemStandardS = self:LuaBaseComponent('child_item_standard_s')
end

function SelectResolveItemCell:OnBtnDeleteClicked()
    local equipResolveUIMediator = g_Game.UIManager:FindUIMediatorByName(require('UIMediatorNames').HeroEquipResolveUIMediator)
    equipResolveUIMediator:RemoveSelectItem(self.data.ID)
end

function SelectResolveItemCell:OnIconClick()
    local equipResolveUIMediator = g_Game.UIManager:FindUIMediatorByName(require('UIMediatorNames').HeroEquipResolveUIMediator)
    equipResolveUIMediator:ShowItemDetails(self.data)
end

function SelectResolveItemCell:OnFeedData(data)
    self.data = data
    local itemData = {}
    itemData.configCell = ConfigRefer.Item:Find(data.ConfigId)
    itemData.showCount = false
    itemData.showRightCount = data.EquipInfo.StrengthenLevel > 0
    itemData.count = data.EquipInfo.StrengthenLevel
    itemData.onClick = function()
        self:OnIconClick()
    end
    itemData.onDelBtnClick = function()
        self:OnBtnDeleteClicked()
    end
    itemData.showDelBtn = true
    self.compChildItemStandardS:FeedData(itemData)
end

return SelectResolveItemCell
