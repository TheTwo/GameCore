local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local UseItemParameter = require("UseItemParameter")
---@class SupplyItemDataProvider
local SupplyItemDataProvider = class("SupplyItemDataProvider")

---@param itemCfgId number
---@param transform CS.UnityEngine.Transform
function SupplyItemDataProvider:ctor(itemCfgId, transform)
    self.itemCfgId = itemCfgId
    self.itemCfg = ConfigRefer.Item:Find(itemCfgId)
end

---@return ItemConfigCell
function SupplyItemDataProvider:GetItemCfg()
    return self.itemCfg
end

---@return number
function SupplyItemDataProvider:GetSupplyQuantity()
    local randomBoxCfg = ConfigRefer.RandomBox:Find(self.itemCfg:BoxParam())
    if not randomBoxCfg then return 0 end
    local itemGroupCfg = ConfigRefer.ItemGroup:Find(randomBoxCfg:GroupInfo(1):Groups())
    if not itemGroupCfg then return 0 end
    return itemGroupCfg:ItemGroupInfoList(1):Nums()
end

---@return number
function SupplyItemDataProvider:GetInventoryQuantity()
    return ModuleRefer.InventoryModule:GetAmountByConfigId(self.itemCfgId)
end

---@param usageCount number
---@param callback fun()
function SupplyItemDataProvider:Use(usageCount, callback)
    local num = ModuleRefer.InventoryModule:GetAmountByConfigId(self.itemCfgId)
    if num < usageCount then
        return
    end
    local compId = ModuleRefer.InventoryModule:GetUidByConfigId(self.itemCfgId)
    if not compId then
        return
    end
    local parameter = UseItemParameter.new()
    parameter.args.ComponentID = compId
    parameter.args.Num = usageCount
    parameter:SendOnceCallback(self.transform, nil, nil, function(_, isSuccess)
        if isSuccess and callback then
            callback()
        end
    end)
end

return SupplyItemDataProvider