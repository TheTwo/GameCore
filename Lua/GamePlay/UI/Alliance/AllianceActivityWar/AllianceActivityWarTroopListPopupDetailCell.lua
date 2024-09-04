local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceActivityWarTroopListPopupDetailCell:BaseTableViewProCell
---@field new fun():AllianceActivityWarTroopListPopupDetailCell
---@field super BaseTableViewProCell
local AllianceActivityWarTroopListPopupDetailCell = class('AllianceActivityWarTroopListPopupDetailCell', BaseTableViewProCell)

function AllianceActivityWarTroopListPopupDetailCell:OnCreate(param)
    self._p_table_troop_detail = self:TableViewPro("p_table_troop_detail")
end

---@param data wds.TroopCreateParam[]
function AllianceActivityWarTroopListPopupDetailCell:OnFeedData(data)
    self._p_table_troop_detail:Clear()
    for i = 1, #data do
        self._p_table_troop_detail:AppendData(data[i])
    end
end

return AllianceActivityWarTroopListPopupDetailCell