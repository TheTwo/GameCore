local BaseUIComponent = require ('BaseUIComponent')
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local I18N = require("I18N")

---@class CityStoreroomUIGridComp:BaseUIComponent
local CityStoreroomUIGridComp = class('CityStoreroomUIGridComp', BaseUIComponent)

function CityStoreroomUIGridComp:OnCreate()
    self._root = self:Transform("")
    ---@type CityStoreroomUIGridItem
    self._p_item = self:LuaBaseComponent("p_item")
    self._item_pool = LuaReusedComponentPool.new(self._p_item, self._root)
end

---@param data CityStoreroomUIGridData
function CityStoreroomUIGridComp:OnFeedData(data)
    self._item_pool:HideAll()
    for i, v in ipairs(data:GetData()) do
        local item = self._item_pool:GetItem()
        item:FeedData(v)
    end
end

return CityStoreroomUIGridComp