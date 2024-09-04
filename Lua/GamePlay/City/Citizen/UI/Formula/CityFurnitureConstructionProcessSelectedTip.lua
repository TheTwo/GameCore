local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local UIHelper = require("UIHelper")
local TimeFormatter = require("TimeFormatter")
local ConfigTimeUtility = require("ConfigTimeUtility")

local BaseUIComponent = require("BaseUIComponent")

---@class CityFurnitureConstructionProcessSelectedTip:BaseUIComponent
---@field new fun():CityFurnitureConstructionProcessSelectedTip
---@field super BaseUIComponent
local CityFurnitureConstructionProcessSelectedTip = class('CityFurnitureConstructionProcessSelectedTip', BaseUIComponent)

function CityFurnitureConstructionProcessSelectedTip:ctor()
    BaseUIComponent.ctor(self)
    self._uiAnyPointEventAdd = false
    ---@type CityFurnitureConstructionProcessRequireTipsCell[]
    self._requireItemCells = {}
    self._host = nil
end

function CityFurnitureConstructionProcessSelectedTip:OnCreate(param)
    self._selfRect = self:RectTransform("")
    self._p_text_title = self:Text("p_text_title")
    self._p_text_cost = self:Text("p_text_cost")
    self._p_table_need = self:Transform("p_table_need")
    self._p_item_need = self:LuaBaseComponent("p_item_need")
    self._p_item_need:SetVisible(false)
    self._p_text_item_1 = self:Text("p_text_item_1", "equip_blueprint_own")
    self._p_text_content_1 = self:Text("p_text_content_1")
    self._p_text_item_2 = self:Text("p_text_item_2", "city_upgrade_time")
    self._p_text_content_2 = self:Text("p_text_content_2")
    ---@type BistateButton
    self._child_comp_btn_b = self:LuaObject("child_comp_btn_b")
end

---@param data CityFurnitureConstructionProcessFormulaCellParameter
function CityFurnitureConstructionProcessSelectedTip:OnFeedData(data)
    self._data = data
    self._host = data.host
    ---@type BistateButtonParameter
    local btnData = {}
    btnData.onClick = Delegate.GetOrCreate(self, self.OnClickBtn)
    btnData.buttonText = I18N.Get("city_process_composite")
    self._child_comp_btn_b:FeedData(btnData)
    local hostHasFreeSlot = false
    if self._host._queueCellsData then
        for i = 1, #self._host._queueCellsData do
            local cell = self._host._queueCellsData[i]
            if cell and not cell.tempSelected and cell.status == 0 then
                hostHasFreeSlot = true
                break
            end
        end
    end
    self._child_comp_btn_b:SetEnabled(not data.isLocked and hostHasFreeSlot)

    local outputItem = data.process:Output(1)
    local outputItemConfig = ConfigRefer.Item:Find(outputItem:ItemId())
    self._p_text_title.text = I18N.GetWithParams("city_product_need", I18N.Get(outputItemConfig:NameKey()))
    local count = data.process:CostLength()
    local cellCount = #self._requireItemCells
    for i = cellCount, count + 1, -1 do
        self._requireItemCells[i]:SetVisible(false)
    end
    self._p_item_need:SetVisible(true)
    for _ = cellCount + 1, count do
        local cell = UIHelper.DuplicateUIComponent(self._p_item_need, self._p_table_need).Lua
        table.insert(self._requireItemCells, cell)
    end
    self._p_item_need:SetVisible(false)
    for i = 1, count do
        local cell = self._requireItemCells[i]
        local costItem = data.process:Cost(i)
        cell:SetVisible(true)
        cell:FeedData(costItem)
    end
    self._p_text_content_1.text = tostring(ModuleRefer.InventoryModule:GetAmountByConfigId(outputItem:ItemId()))
    self._p_text_content_2.text = TimeFormatter.SimpleFormatTimeWithoutZero(ConfigTimeUtility.NsToSeconds(data.process:Time()))
end

function CityFurnitureConstructionProcessSelectedTip:CheckLakeThenShowGetMore()
    if not self._data then
        return false
    end
    local data = self._data
    local lakeItems = {}
    for i = 1, data.process:CostLength() do
        local costItem = data.process:Cost(i)
        local hasNeedCount = ModuleRefer.InventoryModule:GetAmountByConfigId(costItem:ItemId())
        if hasNeedCount < costItem:Count() then
            table.insert(lakeItems, {id=costItem:ItemId(), num = costItem:Count() - hasNeedCount})
        end
    end
    if #lakeItems > 0 then
        ModuleRefer.InventoryModule:OpenExchangePanel(lakeItems)
        return false
    end
    return true 
end

function CityFurnitureConstructionProcessSelectedTip:OnClickBtn()
    if not self._host then
        return
    end
    if not self:CheckLakeThenShowGetMore() then
        return
    end
    local lock = {
        self._child_comp_btn_b.button.transform, 
        self._host._p_block_for_selectedTips.transform,
    }
    for i = 1, #self._requireItemCells do
        local cell = self._requireItemCells[i]
        if cell._p_btn_add and cell._p_btn_add:IsActive() then
            table.insert(lock, cell._p_btn_add.transform)
        end
    end
    local leftCount = self._host:SingleAddAndSend(self._data, lock)
    if leftCount <= 0 then
        self._host._p_block_for_selectedTips:SetVisible(false)
        self:SetVisible(false)
    end
end

function CityFurnitureConstructionProcessSelectedTip:OnClickBlocker()
    if not self._host then
        return
    end
    self._host._p_block_for_selectedTips:SetVisible(false)
    self:SetVisible(false)
end

return CityFurnitureConstructionProcessSelectedTip