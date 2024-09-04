local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local UIMediatorNames = require("UIMediatorNames")
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local ScienceUnlockItemCell = class('ScienceUnlockItemCell',BaseTableViewProCell)

function ScienceUnlockItemCell:OnCreate(param)
    self.itemResources = self:LuaBaseComponent('p_item_resources')
end

function ScienceUnlockItemCell:OnFeedData(itemId)
    self.itemId = itemId
    local itemData = {}
    itemData.showCount = false
    itemData.configCell = ConfigRefer.Item:Find(self.itemId)
    itemData.onClick = function()
        self:OnBtnDetailClicked()
    end
    self.itemResources:FeedData(itemData)

end

function ScienceUnlockItemCell:OnBtnDetailClicked()
    local param = {
        itemId = self.itemId,
        itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM,
        clickTransform = self.itemResources.transform
    }
    g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
end

return ScienceUnlockItemCell
