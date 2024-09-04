local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local InventoryUIHelper = {}

---@param info ItemGroupInfo
---@return ItemIconData
function InventoryUIHelper.GetItemIconDataFromItemGroupInfo(info, showOwned)
    local itemCell = ConfigRefer.Item:Find(info:Items())
    if showOwned then
        return {configCell = itemCell, addCount = info:Nums(), count = ModuleRefer.InventoryModule:GetAmountByConfigId(itemCell:Id())}
    else
        return {configCell = itemCell, count = ModuleRefer.InventoryModule:GetAmountByConfigId(itemCell:Id())}
    end
end

---@param itemGroup ItemGroupConfigCell
---@return ItemIconData[]
function InventoryUIHelper.GetItemIconDataArrayFromItemGroup(itemGroup, showOwned)
    local ret = {}
    if itemGroup then
        for i = 1, itemGroup:ItemGroupInfoListLength() do
            local info = itemGroup:ItemGroupInfoList(i)
            table.insert(ret, InventoryUIHelper.GetItemIconDataFromItemGroupInfo(info, showOwned))
        end
    end
    return ret
end

return InventoryUIHelper