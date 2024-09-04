local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local OnChangeHelper = require("OnChangeHelper")
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local Utils = require("Utils")

local BaseUIComponent = require("BaseUIComponent")

---@class CityFurnitureConstructionProcessRequireTipsCell:BaseTableViewProCell
---@field new fun():CityFurnitureConstructionProcessRequireTipsCell
---@field super BaseUIComponent
local CityFurnitureConstructionProcessRequireTipsCell = class('CityFurnitureConstructionProcessRequireTipsCell', BaseUIComponent)

function CityFurnitureConstructionProcessRequireTipsCell:ctor()
    BaseUIComponent.ctor(self)
    self._eventAdd = false
    self._needItemId = nil
    self._lakeItemData = nil
end

function CityFurnitureConstructionProcessRequireTipsCell:OnCreate(_)
    ---@type CommonPairsQuantity
    self._child_common_quantity = self:LuaObject("child_common_quantity")
    self._p_btn_add = self:Button("p_btn_add", Delegate.GetOrCreate(self, self.OnClickAddBtn))
end

function CityFurnitureConstructionProcessRequireTipsCell:OnShow(_)
    self:SetupEvents(true)
end

function CityFurnitureConstructionProcessRequireTipsCell:OnHide(_)
    self._needItemId = nil
    self:SetupEvents(false)
end

---@param data ItemInfo
function CityFurnitureConstructionProcessRequireTipsCell:OnFeedData(data)
    self._data = data
    self._needItemId = data:ItemId()
    self:DoRefreshItem()
end

function CityFurnitureConstructionProcessRequireTipsCell:OnClose(_)
    self._needItemId = nil
    self:SetupEvents(false)
end

function CityFurnitureConstructionProcessRequireTipsCell:SetupEvents(add)
    if add and not self._eventAdd then
        g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Bag.KItems.MsgPath, Delegate.GetOrCreate(self, self.OnItemDataChanged))
    elseif not add and self._eventAdd then
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Bag.KItems.MsgPath, Delegate.GetOrCreate(self, self.OnItemDataChanged))
    end
    self._eventAdd = add
end

---@param entity wds.CastleBrief
---@param changedData table
function CityFurnitureConstructionProcessRequireTipsCell:OnItemDataChanged(entity, changedData)
    if not self._needItemId then
        return
    end
    if entity.ID ~= ModuleRefer.PlayerModule:GetCastle().ID then
        return
    end
    local add,remove,changed = OnChangeHelper.GenerateMapFieldChangeMap(changedData)
    if add then
        for _, v in pairs(add) do
            if v.ConfigId == self._needItemId then
                self:DoRefreshItem()
                return
            end
        end
    end
    if remove then
        for _, v in pairs(remove) do
            if v.ConfigId == self._needItemId then
                self:DoRefreshItem()
                return
            end
        end
    end
    if changed then
        for _, v in pairs(changed) do
            if v[1].ConfigId == self._needItemId or v[2].ConfigId == self._needItemId then
                self:DoRefreshItem()
                return
            end
        end
    end
end

function CityFurnitureConstructionProcessRequireTipsCell:DoRefreshItem()
    self._lakeItemData = nil
    local itemId = self._data:ItemId()
    local needCount = self._data:Count()
    local hasNeedCount = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)
    ---@type CommonPairsQuantityParameter
    local parameter = {}
    parameter.itemId = itemId
    parameter.num2 = needCount
    parameter.num1 = hasNeedCount
    parameter.compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST
    self._child_common_quantity:FeedData(parameter)
    if Utils.IsNotNull(self._p_btn_add) then
        self._p_btn_add:SetVisible(needCount > hasNeedCount)
    end
    if needCount > hasNeedCount then
        self._lakeItemData = {id = itemId, num = needCount - hasNeedCount}
    end
end

function CityFurnitureConstructionProcessRequireTipsCell:OnClickAddBtn()
    if not self._lakeItemData then
        return
    end
    ModuleRefer.InventoryModule:OpenExchangePanel({self._lakeItemData})
end

return CityFurnitureConstructionProcessRequireTipsCell