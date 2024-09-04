local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class KingdomConstructionModeUITabCellData
---@field buildingType number FlexibleMapBuildingType

---@class KingdomConstructionModeUITabCell:BaseTableViewProCell
---@field new fun():KingdomConstructionModeUITabCell
---@field super BaseTableViewProCell
local KingdomConstructionModeUITabCell = class('KingdomConstructionModeUITabCell', BaseTableViewProCell)

function KingdomConstructionModeUITabCell:OnCreate(param)
    self._selfBtn = self:Button("", Delegate.GetOrCreate(self, self.OnClickSelf))
    self._p_status_n = self:GameObject("p_status_n")
    self._p_txt_tab_n = self:Text("p_txt_tab_n")
    self._p_status_select = self:GameObject("p_status_select")
    self._p_txt_tab_select = self:Text("p_txt_tab_select")

    self._p_status_n:SetVisible(true)
    self._p_status_select:SetVisible(false)
end

---@param data KingdomConstructionModeUITabCellData
function KingdomConstructionModeUITabCell:OnFeedData(data)
    local has, limit = ModuleRefer.KingdomConstructionModule:GetBuildingTypeCountAndLimitCount(data.buildingType)
    local contentText = ModuleRefer.KingdomConstructionModule:GetNameAndCountByBuildingType(data.buildingType, has, limit)
    self._p_txt_tab_n.text = contentText
    self._p_txt_tab_select.text = contentText
end

function KingdomConstructionModeUITabCell:Select()
    self._p_status_n:SetVisible(false)
    self._p_status_select:SetVisible(true)
end

function KingdomConstructionModeUITabCell:UnSelect()
    self._p_status_n:SetVisible(true)
    self._p_status_select:SetVisible(false)
end

function KingdomConstructionModeUITabCell:OnClickSelf()
    self:SelectSelf()
end

return KingdomConstructionModeUITabCell