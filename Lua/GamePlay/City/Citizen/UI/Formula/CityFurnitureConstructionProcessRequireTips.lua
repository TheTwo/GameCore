local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local TimeFormatter = require("TimeFormatter")
local ConfigTimeUtility = require("ConfigTimeUtility")
local UIHelper = require("UIHelper")

local BaseUIComponent = require("BaseUIComponent")

---@class CityFurnitureConstructionProcessRequireTips:BaseUIComponent
---@field new fun():CityFurnitureConstructionProcessRequireTips
---@field super BaseUIComponent
local CityFurnitureConstructionProcessRequireTips = class('CityFurnitureConstructionProcessRequireTips', BaseUIComponent)

function CityFurnitureConstructionProcessRequireTips:ctor()
    BaseUIComponent.ctor(self)
    ---@type CityFurnitureConstructionProcessRequireTipsCell[]
    self._requireItemCells = {}
end

function CityFurnitureConstructionProcessRequireTips:OnCreate(_)
    self.SelfTrans = self:RectTransform("")
    self._p_text_title = self:Text("p_text_title")
    self._p_item_need = self:LuaBaseComponent("p_item_need")
    self._p_table_need = self:Transform("p_table_need")
    self._p_text_item_1 = self:Text("p_text_item_1", "equip_blueprint_own")
    self._p_text_content_1 = self:Text("p_text_content_1")
    self._p_text_item_2 = self:Text("p_text_item_2", "city_upgrade_time")
    self._p_text_content_2 = self:Text("p_text_content_2")

    self._p_item_need:SetVisible(false)
end

---@param data CityFurnitureConstructionProcessFormulaCellParameter
function CityFurnitureConstructionProcessRequireTips:FeedData(data)
    local outputItem = data.process:Output(1)
    local outputItemConfig = ConfigRefer.Item:Find(outputItem:ItemId())
    self._p_text_title.text = I18N.GetWithParams("city_product_need", I18N.Get(outputItemConfig:NameKey()))
    local count = data.process:CostLength()
    local cellCount = #self._requireItemCells
    for i = cellCount, count + 1, -1 do
        self._requireItemCells[i]:SetVisible(false)
    end
    for _ = cellCount + 1, count do
        local cell = UIHelper.DuplicateUIComponent(self._p_item_need, self._p_table_need).Lua
        table.insert(self._requireItemCells, cell)
    end
    for i = 1, count do
        local cell = self._requireItemCells[i]
        local costItem = data.process:Cost(i)
        cell:SetVisible(true)
        cell:FeedData(costItem)
    end
    self._p_text_content_1.text = tostring(ModuleRefer.InventoryModule:GetAmountByConfigId(outputItem:ItemId()))
    self._p_text_content_2.text = TimeFormatter.SimpleFormatTimeWithoutZero(ConfigTimeUtility.NsToSeconds(data.process:Time()))
end

return CityFurnitureConstructionProcessRequireTips