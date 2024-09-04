---@class ItemTableMergeHelper
local ItemTableMergeHelper = {}

---@param items ItemIconData[]
---@return ItemIconData[]
function ItemTableMergeHelper.MergeItemDataByItemCfgId(items)
    ---@type table<number, ItemIconData>
    local mergedData = {}
    local id2Index = {}
    for _, item in ipairs(items) do
        local itemId = item.configCell:Id()
        local index = id2Index[itemId]
        if mergedData[index or 0] then
            mergedData[index].count = (mergedData[index].count or 0) + (item.count or 0)
        else
            table.insert(mergedData, item)
            id2Index[itemId] = #mergedData
        end
    end
    return mergedData
end

return ItemTableMergeHelper