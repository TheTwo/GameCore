local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")
local CHAT_ITEM_INDEX_INVALID = -1
local CHAT_ITEM_INDEX_OTHER = 0
local CHAT_ITEM_INDEX_SELF = 1
local CHAT_ITEM_INDEX_HINT = 2
local CHAT_ITEM_INDEX_LOADING = 3

---@class UIChatSizeProvider:BaseUIComponent
local UIChatSizeProvider = class('UIChatSizeProvider', BaseUIComponent)

function UIChatSizeProvider:OnCreate()
    self._p_item_chat_l = self:LuaBaseComponent("p_item_chat_l")
    self._p_item_chat_hint = self:LuaBaseComponent("p_item_chat_hint")
    self._p_item_chat_r = self:LuaBaseComponent("p_item_chat_r")
end

function UIChatSizeProvider:GetSize(data, index)
    local width, height = 0, 0
    if index == CHAT_ITEM_INDEX_OTHER then
        self._p_item_chat_l:FeedData(data)
        width, height = CS.AutoCellSizeCalculator.CalculateCellSize(self._p_item_chat_l.transform)
    elseif index == CHAT_ITEM_INDEX_SELF then
        self._p_item_chat_r:FeedData(data)
        width, height = CS.AutoCellSizeCalculator.CalculateCellSize(self._p_item_chat_r.transform)
    elseif index == CHAT_ITEM_INDEX_HINT then
        self._p_item_chat_hint:FeedData(data)
        width, height = CS.AutoCellSizeCalculator.CalculateCellSize(self._p_item_chat_hint.transform)
    elseif index == CHAT_ITEM_INDEX_LOADING then
        width, height = 939, 60
    end
    return width, height
end

return UIChatSizeProvider