local BaseTableViewProCell = require ('BaseTableViewProCell')
local LuaReusedComponentPool = require("LuaReusedComponentPool")

---@class CityLegoExtraInfoCell:BaseTableViewProCell
local CityLegoExtraInfoCell = class('CityLegoExtraInfoCell', BaseTableViewProCell)

function CityLegoExtraInfoCell:OnCreate()
    self._p_unlock_title = self:Text("p_unlock_title")
    
    self._layout_grid = self:Transform("layout_grid")
    self._p_unlock_content = self:Text("p_unlock_content")
    self._pool = LuaReusedComponentPool.new(self._p_unlock_content, self._layout_grid)
end

---@param data {title:string, dataList:string[]}
function CityLegoExtraInfoCell:OnFeedData(data)
    self._pool:HideAll()
    
    self._p_unlock_title.text = data.title
    for i, v in ipairs(data.dataList) do
        local item = self._pool:GetItem()
        item.text = v
    end
end

return CityLegoExtraInfoCell