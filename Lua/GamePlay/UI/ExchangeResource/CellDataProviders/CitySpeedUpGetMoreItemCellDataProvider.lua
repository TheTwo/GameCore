local GetMoreItemCellDataProvider = require("GetMoreItemCellDataProvider")
local I18N = require("I18N")
---@class CitySpeedUpGetMoreItemCellDataProvider : BaseGetMoreCellDataProvider
local CitySpeedUpGetMoreItemCellDataProvider = class("CitySpeedUpGetMoreItemCellDataProvider", GetMoreItemCellDataProvider)

function CitySpeedUpGetMoreItemCellDataProvider:GetStatusIndex()
    if self:GetItemInventory() > 0 then
        return 2
    else
        return 3
    end
end

function CitySpeedUpGetMoreItemCellDataProvider:GetNeededNum()
    if not self.holder then
        return 0
    end
    return self.holder:GetExpectCount(self.itemId)
end

function CitySpeedUpGetMoreItemCellDataProvider:GetBubbleText()
    if not self.holder then
        return string.Empty
    end
    return self.holder:GetBubbleText(self.itemId)
end

function CitySpeedUpGetMoreItemCellDataProvider:GetPayButtonText()
    return I18N.Get("getmore_name_buyanduse")
end

function CitySpeedUpGetMoreItemCellDataProvider:ShowBubble()
    return self:GetItemInventory() > 0
end

function CitySpeedUpGetMoreItemCellDataProvider:OnBubbleClick()
    if self.holder then
        self.holder:UseItemSpeedUp(self.itemId, self.holder:GetCount(self.itemId))
    end
end

function CitySpeedUpGetMoreItemCellDataProvider:OnUse()
    if self.holder then
        self.holder:UseItemSpeedUp(self.itemId, 1)
    end
end

function CitySpeedUpGetMoreItemCellDataProvider:OnGoto()
    if self.holder then
        self.holder:UseItemSpeedUp(self.itemId, 1)
    end
end

return CitySpeedUpGetMoreItemCellDataProvider