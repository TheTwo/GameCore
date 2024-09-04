local UIHelper = require("UIHelper")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTerritoryMainCityGroupCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryMainCityGroupCell
---@field super BaseTableViewProCell
local AllianceTerritoryMainCityGroupCell = class('AllianceTerritoryMainCityGroupCell', BaseTableViewProCell)

function AllianceTerritoryMainCityGroupCell:ctor()
    ---@type {go:CS.UnityEngine.GameObject,cell: CS.DragonReborn.UI.LuaBaseComponent}[]
    self._createdCells = {}
end

function AllianceTerritoryMainCityGroupCell:OnCreate(param)
    self._p_table_city_item = self:TableViewPro("p_table_city_item")
    self._p_group = self:Transform("p_group")
    ---@see AllianceTerritoryMainCityTabCell
    self._p_item_city_template = self:LuaBaseComponent("p_item_city_template")
end

---@param data AllianceTerritoryMainCityTabCellData[]
function AllianceTerritoryMainCityGroupCell:OnFeedData(data)
    local newCount = #data
    local oldCount = #self._createdCells
    self._p_item_city_template:SetVisible(true)
    for i = oldCount + 1, newCount do
        local cellCs = UIHelper.DuplicateUIComponent(self._p_item_city_template, self._p_group )
        self._createdCells[i] = {go = cellCs.gameObject, cell = cellCs}
        cellCs:FeedData(data[i])
    end
    self._p_item_city_template:SetVisible(false)
    for i = newCount + 1, oldCount do
        self._createdCells[i].go:SetVisible(false)
    end
    for i = 1, math.min(oldCount, newCount) do
        self._createdCells[i].cell:FeedData(data[i])
    end
end

function AllianceTerritoryMainCityGroupCell:OnRecycle()
    for i = 1, #self._createdCells do
        UIHelper.DeleteUIComponent(self._createdCells[i].cell)
    end
    table.clear(self._createdCells)
end

return AllianceTerritoryMainCityGroupCell