local ConfigRefer = require("ConfigRefer")
local ItemGroupType = require("ItemGroupType")
local ItemGroupHelper = {}

---@param itemGroup ItemGroupConfigCell
---@param index number|nil @为空时默认为第一个
---@return boolean, ItemConfigCell
function ItemGroupHelper.GetItem(itemGroup, index)
    local idx = index or 1
    local length = itemGroup:ItemGroupInfoListLength()
    if length <= 0 then
        return false, nil
    end

    idx = math.clamp(idx, 1, length)
    local itemGroupInfo = itemGroup:ItemGroupInfoList(idx)
    local itemCfg = ConfigRefer.Item:Find(itemGroupInfo:Items())
    return itemCfg ~= nil, itemCfg
end

---@param itemGroup ItemGroupConfigCell
---@param index number|nil @为空时默认为第一个
function ItemGroupHelper.GetItemIcon(itemGroup, index)
    local flag, itemCfg = ItemGroupHelper.GetItem(itemGroup, index)
    if flag then
        return true, itemCfg:Icon()
    end
    return false, string.Empty
end

---@param itemGroup ItemGroupConfigCell
---@return {id:number, minCount:number, maxCount:number}[], table<number, {id:number, minCount:number, maxCount:number}> @注意，两者的元素引用的是相同的对象
function ItemGroupHelper.GetPossibleOutput(itemGroup)
    local orderList = {}
    local IdMap = {}
    if itemGroup == nil then
        return orderList, IdMap
    end

    local groupType = itemGroup:Type()
    if groupType == ItemGroupType.OneByOne then
        for i = 1, math.min(itemGroup:ItemNum(), itemGroup:ItemGroupInfoListLength()) do
            local itemInfo = itemGroup:ItemGroupInfoList(i)
            local itemId = itemInfo:Items()
            if IdMap[itemId] then
                IdMap[itemId].minCount = IdMap[itemId].minCount + itemInfo:Nums()
                IdMap[itemId].maxCount = IdMap[itemId].maxCount + itemInfo:Nums()
            else
                local itemInfo = {id = itemId, minCount = itemInfo:Nums(), maxCount = itemInfo:Nums()}
                IdMap[itemId] = itemInfo
                table.insert(orderList, itemInfo)
            end
        end
    elseif groupType == ItemGroupType.RandomAndBack or groupType == ItemGroupType.RandomNoBack then
        for i = 1, itemGroup:ItemGroupInfoListLength() do
            local itemInfo = itemGroup:ItemGroupInfoList(i)
            local itemId = itemInfo:Items()
            local count = itemInfo:Nums()
            if IdMap[itemId] then
                IdMap[itemId].minCount = math.min(IdMap[itemId].minCount, count)
                IdMap[itemId].maxCount = math.max(IdMap[itemId].maxCount, count)
                IdMap[itemId].showUp = IdMap[itemId].showup + 1
            else
                local itemInfo = {id = itemId, minCount = count, maxCount = count, showUp = 1}
                IdMap[itemId] = itemInfo
            end
        end

        local randomTimes = itemGroup:ItemNum()
        if randomTimes > itemGroup:ItemGroupInfoListLength() then
            randomTimes = itemGroup:ItemGroupInfoListLength()
        end

        --- 拿起放回时，只要有任意一个不同的材料，就会导致最小值为0
        if groupType == ItemGroupType.RandomAndBack then
            ---@param v {id:number, minCount:number, maxCount:number, showUp:number}
            for id, v in pairs(IdMap) do
                if v.showUp < randomTimes then
                    v.minCount = 0
                end
                v.showUp = nil
                table.insert(orderList, v)
            end
        else
        --- 拿起不放回则当材料出现次数大于 把其他iteminfo全部拿起的次数 就能保证最小值不为0
            local chance = itemGroup:ItemGroupInfoListLength()
            for id, v in pairs(IdMap) do
                local other = chance - v.showUp
                if other >= randomTimes then
                    v.minCount = 0
                end
                v.showUp = nil
                table.insert(orderList, v)
            end
        end
    end
    return orderList, IdMap
end

return ItemGroupHelper