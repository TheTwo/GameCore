local BaseUIComponent = require ('BaseUIComponent')

---@class TouchMenuCellPairTime:BaseUIComponent
local TouchMenuCellPairTime = class('TouchMenuCellPairTime', BaseUIComponent)

function TouchMenuCellPairTime:OnCreate()
    self._p_text_item_name = self:Text("p_text_item_name")
    self._child_time = self:LuaBaseComponent("child_time")
end

---@param data TouchMenuCellPairTimeDatum
function TouchMenuCellPairTime:OnFeedData(data)
    self.data = data
    self:UpdateLabel(self.data.label)
    self:FeedCommonTimer(self.data.commonTimerData)
end

function TouchMenuCellPairTime:OnClose()
    self.data = nil
end

function TouchMenuCellPairTime:UpdateLabel(label)
    self._p_text_item_name.text = label
end

---@param data CommonTimerData
function TouchMenuCellPairTime:FeedCommonTimer(data)
    self._child_time:FeedData(data)
end

return TouchMenuCellPairTime