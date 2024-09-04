local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")

local BaseUIComponent = require("BaseUIComponent")

---@class CityFurnitureConstructionProcessDragCell:BaseUIComponent
---@field new fun():CityFurnitureConstructionProcessDragCell
---@field super BaseUIComponent
local CityFurnitureConstructionProcessDragCell = class('CityFurnitureConstructionProcessDragCell', BaseUIComponent)

function CityFurnitureConstructionProcessDragCell:OnCreate(param)
    self.SelfTrans = self:RectTransform("")
    ---@type BaseCircleItemIcon
    self._p_output_item = self:LuaObject("p_output_item")
end

---@param data CityFurnitureConstructionProcessFormulaCellParameter
function CityFurnitureConstructionProcessDragCell:FeedData(data)
    ---@type ItemIconData
    local itemData = {}
    itemData.configCell = ConfigRefer.Item:Find(data.process:Output(1):ItemId())
    itemData.showCount = false
    self._p_output_item:FeedData(itemData)
    self._p_output_item:SetGray(false)
end

function CityFurnitureConstructionProcessDragCell:SetGray()
    self._p_output_item:SetGray(true)
end

return CityFurnitureConstructionProcessDragCell