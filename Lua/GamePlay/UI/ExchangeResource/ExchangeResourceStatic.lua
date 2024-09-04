local ConfigRefer = require("ConfigRefer")
local Utils = require("Utils")
local ExchangeResourceStatic = {}

---@class ItemSupplyInfo
---@field id number
---@field supplyNum number
---@field inventory number

ExchangeResourceStatic.CellType = {
    Supply = 1,
    Pay = 2,
    OneKeySupply = 3,
    PayAndUse = 4,
    Harvest = 5,
}

ExchangeResourceStatic.DirectExchangePanelType = {
    Default = 1,
    Supply = 2,
    SpeedUp = 3,
    PayAndUse = 4,
}

---@param supplyInfos ItemSupplyInfo[]
---@param targetNum number
function ExchangeResourceStatic.GetOneKeySupplyCost(supplyInfos, targetNum)
    local infos = Utils.DeepCopy(supplyInfos)
    targetNum = math.max(math.floor(targetNum / 60), 1)
    table.sort(infos, function(a, b)
        return a.supplyNum < b.supplyNum
    end)
    ---@type ExchangeResourceMediatorItemInfo[]
    local result = {}

    local keys = {}
    local supplyMap = {}
    for _, supplyInfo in ipairs(infos) do
        supplyMap[supplyInfo.id] = supplyInfo
        supplyMap[supplyInfo.id].supplyNum = supplyInfo.supplyNum // 60
    end

    for _, supplyInfo in ipairs(infos) do
        keys[#keys + 1] = supplyInfo.id
    end

    ---@class ExchangeResourceStatus
    ---@field useMap table<number, number>
    ---@field value number

    local dp = {}
    dp[0] = {}
    dp[0][0] = {useMap = {}, value = 0}
    for i = 1, #keys do
        dp[i] = {}
        dp[i][0] = {useMap = {}, value = 0}
    end

    for i = 1, targetNum do
        dp[0][i] = {useMap = {}, value = 0}
    end

    for i = 1, #keys do
        for j = 1, targetNum do
            local supplyInfo = supplyMap[keys[i]]
            local supplyNum = supplyInfo.supplyNum
            local supplyId = supplyInfo.id
            local supplyInventory = supplyInfo.inventory
            local need = math.min(math.ceil(j / supplyNum), supplyInventory)
            -- 缺省状态为全部使用道具i
            dp[i][j] = {useMap = {}, value = need * supplyNum}
            dp[i][j].useMap[supplyId] = need
            -- 如果前i-1个物品已经满足了j的需求, 且总供给小于当前状态，转移至i-1
            if dp[i - 1][j].value >= j and dp[i - 1][j].value < dp[i][j].value then
                dp[i][j] = {}
                dp[i][j].value = dp[i - 1][j].value
                dp[i][j].useMap = {}
                for k, v in pairs(dp[i - 1][j].useMap) do
                    dp[i][j].useMap[k] = v
                end
            -- 如果前i-1个物品没有满足j的需求, 则使用第i个物品
            elseif dp[i - 1][j].value < j then
                local remain = j - dp[i - 1][j].value
                local remainNeed = math.ceil(remain / supplyNum)
                local remainValue = remainNeed * supplyNum
                -- 第i个物品的库存不足
                if remainNeed > supplyInventory then
                    remainValue = supplyInventory * supplyNum
                    -- 不足时取两个状态的最大值进行转移
                    -- (这个判断条件应该一定会为true..)
                    if dp[i - 1][j - remainValue].value + remainValue > dp[i][j].value then
                        dp[i][j].value = dp[i - 1][j - remainValue].value + remainValue
                        dp[i][j].useMap = {}
                        for k, v in pairs(dp[i - 1][j - remainValue].useMap) do
                            dp[i][j].useMap[k] = v
                        end
                        dp[i][j].useMap[supplyId] = supplyInventory
                    end
                else
                    -- 满足时取两个状态的最小值进行转移
                    local k = math.max(j - remainValue, 0)
                    if dp[i][j].value < j or dp[i - 1][k].value + remainValue < dp[i][j].value then
                        dp[i][j].value = dp[i - 1][k].value + remainValue
                        dp[i][j].useMap = {}
                        for key, v in pairs(dp[i - 1][k].useMap) do
                            dp[i][j].useMap[key] = v
                        end
                        dp[i][j].useMap[supplyId] = remainNeed
                    end
                end
            end
        end
    end

    local useMap = dp[#keys][targetNum].useMap
    for k, v in pairs(useMap) do
        result[#result + 1] = {id = k, num = v, supplyNum = supplyMap[k].supplyNum * 60}
    end

    table.sort(result, function(a, b)
        return a.id < b.id
    end)

    return result
end

---@param itemCfgId number
---@return number
---@return number
function ExchangeResourceStatic.GetExchangeCurrencyItemIdAndSingleNum(itemCfgId)
    local itemCfg = ConfigRefer.Item:Find(itemCfgId)
    if not itemCfg then return 0, 0 end
    local getMoreCfg = ConfigRefer.GetMore:Find(itemCfg:GetMoreConfig())
    if not getMoreCfg then return 0, 0 end
    local exchange = getMoreCfg:Exchange()
    if not exchange then return 0, 0 end
    return exchange:Currency(), exchange:CurrencyCount()
end

return ExchangeResourceStatic