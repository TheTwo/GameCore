local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local Utils = require('Utils')

---@class TMCellRewardCellItem:BaseTableViewProCell
local TMCellRewardCellItem = class('TMCellRewardCellItem', BaseTableViewProCell)

function TMCellRewardCellItem:OnCreate()
    self._child_item_standard_s = self:LuaBaseComponent("child_item_standard_s")
    self._p_icon_recomment = self:GameObject("p_icon_recomment")
end

---@param data ItemIconData
function TMCellRewardCellItem:OnFeedData(data)
    self._child_item_standard_s:FeedData(data)
    if not Utils.IsNullOrEmpty(self._p_icon_recomment) then
        if data.customData ~= nil and data.customData.isRecommend then
            self._p_icon_recomment:SetActive(true)
        else
            self._p_icon_recomment:SetActive(false)
        end
    end
end

return TMCellRewardCellItem