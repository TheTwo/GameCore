local BaseUIComponent = require ('BaseUIComponent')
local LuaReusedComponentPool = require('LuaReusedComponentPool')
local ConfigRefer = require('ConfigRefer')
local CityLegoI18N = require("CityLegoI18N")

---@class CityLegoBuffRouteMapUILevelGroup:BaseUIComponent
local CityLegoBuffRouteMapUILevelGroup = class('CityLegoBuffRouteMapUILevelGroup', BaseUIComponent)

---@class CityLegoBuffRouteMapUILevelGroupData
---@field roomLvCfg RoomLevelInfoConfigCell
---@field legoBuilding CityLegoBuilding

function CityLegoBuffRouteMapUILevelGroup:OnCreate()
    self._p_text_score = self:Text("p_text_score", CityLegoI18N.UI_HintBuffRouteMapLevel)
    self._p_text_score_num = self:Text("p_text_score_num")

    self._p_columns = self:Transform("p_columns")
    self._p_container_lv2 = self:LuaBaseComponent("p_container_lv2")
    self._column_pool = LuaReusedComponentPool.new(self._p_container_lv2, self._p_columns)
end

---@param data CityLegoBuffRouteMapUILevelGroupData
function CityLegoBuffRouteMapUILevelGroup:OnFeedData(data)
    self.data = data
    self._p_text_score_num.text = tostring(data.roomLvCfg:Level())

    self._column_pool:HideAll()
    local lvCfg = ConfigRefer.RoomTagBuffUILevel:Find(data.roomLvCfg:UILevel())
    if lvCfg == nil then return end

    for i = 1, lvCfg:ColumnsLength() do
        local columnCfgId = lvCfg:Columns(i)
        local columnCfg = ConfigRefer.RoomTagBuffUIColumn:Find(columnCfgId)
        if columnCfg then
            ---@type CityLegoBuffRouteMapUILevelColumnData
            local columnData = {cfg = columnCfg, legoBuilding = data.legoBuilding, level = data.roomLvCfg:Level()}
            local column = self._column_pool:GetItem()
            column:FeedData(columnData)
        end
    end
end

return CityLegoBuffRouteMapUILevelGroup