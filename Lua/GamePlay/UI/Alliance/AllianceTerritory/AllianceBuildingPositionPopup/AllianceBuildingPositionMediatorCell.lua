local Delegate = require("Delegate")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceBuildingPositionMediatorCellData
---@field content string
---@field context any
---@field onclick fun(context:any)

---@class AllianceBuildingPositionMediatorCell:BaseTableViewProCell
---@field new fun():AllianceBuildingPositionMediatorCell
---@field super BaseTableViewProCell
local AllianceBuildingPositionMediatorCell = class('AllianceBuildingPositionMediatorCell', BaseTableViewProCell)

function AllianceBuildingPositionMediatorCell:OnCreate(param)
    self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickBtnGo))
    self._p_text_number = self:Text("p_text_number")
end

---@param data AllianceBuildingPositionMediatorCellData
function AllianceBuildingPositionMediatorCell:OnFeedData(data)
    self._data = data
    self._p_text_number.text = data.content
end

function AllianceBuildingPositionMediatorCell:OnClickBtnGo()
    if self._data and self._data.onclick then
        self._data.onclick(self._data.context)
    end
end

return AllianceBuildingPositionMediatorCell