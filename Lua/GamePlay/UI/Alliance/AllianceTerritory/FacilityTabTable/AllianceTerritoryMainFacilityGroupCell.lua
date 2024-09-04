local UIHelper = require("UIHelper")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTerritoryMainFacilityGroupCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryMainFacilityGroupCell
---@field super BaseTableViewProCell
local AllianceTerritoryMainFacilityGroupCell = class('AllianceTerritoryMainFacilityGroupCell', BaseTableViewProCell)

function AllianceTerritoryMainFacilityGroupCell:ctor()
    AllianceTerritoryMainFacilityGroupCell.super.ctor(self)
    ---@type CS.DragonReborn.UI.LuaBaseComponent[]
    self._cells = {}
end

function AllianceTerritoryMainFacilityGroupCell:OnCreate(param)
    self._p_group = self:Transform("p_group")
    ---@see AllianceTerritoryMainFacilityCell
    self._p_item_facility_template = self:LuaBaseComponent("p_item_facility")
    self._p_item_facility_template:SetVisible(false)
end

---@param data AllianceTerritoryMainFacilityCellData[]
function AllianceTerritoryMainFacilityGroupCell:OnFeedData(data)
    local oldCount = #self._cells
    local newCount = #data
    for i = oldCount, newCount + 1, -1 do
        local cell = table.remove(self._cells, i)
        UIHelper.DeleteUIComponent(cell)
    end
    if newCount > oldCount then
        self._p_item_facility_template:SetVisible(true)
        for i = oldCount + 1, newCount do
            local cell = UIHelper.DuplicateUIComponent(self._p_item_facility_template, self._p_group)
            self._cells[i] = cell
        end
        self._p_item_facility_template:SetVisible(false)
    end
    for i = 1, newCount do
        self._cells[i]:FeedData(data[i])
    end
end

function AllianceTerritoryMainFacilityGroupCell:OnRecycle()
    for i = 1, #self._cells do
        UIHelper.DeleteUIComponent(self._cells[i])
    end
    table.clear(self._cells)
end

return AllianceTerritoryMainFacilityGroupCell