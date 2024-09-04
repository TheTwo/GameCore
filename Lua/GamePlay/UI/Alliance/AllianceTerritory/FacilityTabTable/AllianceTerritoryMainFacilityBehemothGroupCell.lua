
local UIHelper = require("UIHelper")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTerritoryMainFacilityBehemothGroupCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryMainFacilityBehemothGroupCell
---@field super BaseTableViewProCell
local AllianceTerritoryMainFacilityBehemothGroupCell = class('AllianceTerritoryMainFacilityBehemothGroupCell', BaseTableViewProCell)

function AllianceTerritoryMainFacilityBehemothGroupCell:ctor()
    AllianceTerritoryMainFacilityBehemothGroupCell.super.ctor(self)
    ---@type CS.DragonReborn.UI.LuaBaseComponent[]
    self._cells = {}
end

function AllianceTerritoryMainFacilityBehemothGroupCell:OnCreate(param)
    self._p_group = self:Transform("p_group")
    ---@see AllianceTerritoryMainFacilityBehemothCell
    self._p_item_facility_template = self:LuaBaseComponent("p_item_facility_behemoth")
    self._p_item_facility_template:SetVisible(false)
end

---@param data AllianceTerritoryMainFacilityCellData[]
function AllianceTerritoryMainFacilityBehemothGroupCell:OnFeedData(data)
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

function AllianceTerritoryMainFacilityBehemothGroupCell:OnRecycle()
    for i = 1, #self._cells do
        UIHelper.DeleteUIComponent(self._cells[i])
    end
    table.clear(self._cells)
end

return AllianceTerritoryMainFacilityBehemothGroupCell