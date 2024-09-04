local BaseUIComponent = require ('BaseUIComponent')
local ConfigRefer = require('ConfigRefer')
local UIHelper = require("UIHelper")
local Utils = require("Utils")

---@class CityLegoBuffRouteMapUILevelColumn:BaseUIComponent
local CityLegoBuffRouteMapUILevelColumn = class('CityLegoBuffRouteMapUILevelColumn', BaseUIComponent)

---@class CityLegoBuffRouteMapUILevelColumnData
---@field cfg RoomTagBuffUIColumnConfigCell
---@field legoBuilding CityLegoBuilding
---@field level number

function CityLegoBuffRouteMapUILevelColumn:OnCreate()
    self.transform = self:Transform("")

    self._p_templates = self:Transform("p_templates")
    self._p_item_formula = self:LuaBaseComponent("p_item_formula")
    self._p_item_column_space = self:LuaBaseComponent("p_item_column_space")

    self._p_item_formula:SetVisible(false)
    self._p_item_column_space:SetVisible(false)
end

---@param data CityLegoBuffRouteMapUILevelColumnData
function CityLegoBuffRouteMapUILevelColumn:OnFeedData(data)
    self.data = data

    for i = self.transform.childCount - 1, 0, -1 do
        local child = self.transform:GetChild(i)
        if Utils.IsNotNull(child) and child ~= self._p_templates then
            UIHelper.DeleteUIGameObject(child.gameObject)
        end
    end

    ---@type table<number, CityLegoBuffRouteMapUISingleBuffData>
    local dataList = {}
    local maxRow = 0
    for i = 1, self.data.cfg:RowsLength() do
        local rowCfgId = self.data.cfg:Rows(i)
        local rowCfg = ConfigRefer.RoomTagBuffUIRow:Find(rowCfgId)
        if rowCfg and rowCfg:Row() > 0 then
            ---@type CityLegoBuffRouteMapUISingleBuffData
            local data = {cfg = rowCfg, legoBuilding = data.legoBuilding, level = data.level}
            dataList[rowCfg:Row()] = data
            maxRow = math.max(maxRow, rowCfg:Row())
        end
    end

    if maxRow == 0 then return end
    
    for i = 1, maxRow do
        local data = dataList[i]
        if data then
            if data.cfg:IsLine() or data.cfg:BuffCfgId() == 0 then
                local space = UIHelper.DuplicateUIComponent(self._p_item_column_space, self.transform)
                space:SetVisible(true)
                space:FeedData({showLine = data.cfg:IsLine()})
            else
                local item = UIHelper.DuplicateUIComponent(self._p_item_formula, self.transform)
                item:SetVisible(true)
                item:FeedData(data)
            end
        else
            local space = UIHelper.DuplicateUIComponent(self._p_item_column_space, self.transform)
            space:SetVisible(true)
            space:FeedData({showLine = false})
        end
    end
end

return CityLegoBuffRouteMapUILevelColumn