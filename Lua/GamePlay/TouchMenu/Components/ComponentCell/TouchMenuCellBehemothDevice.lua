local Delegate = require("Delegate")

local BaseUIComponent = require("BaseUIComponent")

---@class TouchMenuCellBehemothDevice:BaseUIComponent
---@field new fun():TouchMenuCellBehemothDevice
---@field super BaseUIComponent
local TouchMenuCellBehemothDevice = class('TouchMenuCellBehemothDevice', BaseUIComponent)

function TouchMenuCellBehemothDevice:OnCreate(param)
    self._p_text_behemoth_now = self:Text("p_text_behemoth_now")
    ---@type AllianceBehemothHeadCell
    self._child_behemoth_head = self:LuaObject("child_behemoth_head")
    self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickGoto))
end

---@param data TouchMenuCellBehemothDeviceDatum
function TouchMenuCellBehemothDevice:OnFeedData(data)
    ---@type TouchMenuCellBehemothDeviceDatum
    self._data = data
    self._p_text_behemoth_now.text = data:GetLabel()
    self._child_behemoth_head:FeedData(data:GetBehemothHeadCellData())
    self._p_btn_goto:SetVisible(data:HasCallback())
end

function TouchMenuCellBehemothDevice:OnClickGoto()
    if self._data:OnClickGoto() then
        local mediator = self:GetParentBaseUIMediator()
        if mediator then
            mediator:CloseSelf()
        end
    end
end

return TouchMenuCellBehemothDevice