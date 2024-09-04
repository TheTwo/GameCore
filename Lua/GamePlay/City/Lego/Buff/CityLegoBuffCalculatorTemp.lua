local CityLegoBuffCalculatorBase = require("CityLegoBuffCalculatorBase")
---@class CityLegoBuffCalculatorTemp:CityLegoBuffCalculatorBase
---@field new fun():CityLegoBuffCalculatorTemp
local CityLegoBuffCalculatorTemp = class("CityLegoBuffCalculatorTemp", CityLegoBuffCalculatorBase)

function CityLegoBuffCalculatorTemp:ctor()
    ---@type table<CityLegoBuffProvider, CityLegoBuffProvider>
    self.providers = {}
end

function CityLegoBuffCalculatorTemp:AppendProvider(provider)
    self.providers[provider] = provider
end

function CityLegoBuffCalculatorTemp:RemoveProvider(provider)
    self.providers[provider] = nil
end

function CityLegoBuffCalculatorTemp:GetTagCount(tagId)
    local count = 0
    for k, v in pairs(self.providers) do
        count = count + v:GetTagCount(tagId)
    end
    return count
end

---@param buffCfg RoomTagBuffConfigCell
---@return table<number, CityLegoBuffProvider> @key:buffCfg第几个tag, value:对应的provider, 为空表示没有对应的provider
function CityLegoBuffCalculatorTemp:GetTagProviderMap(buffCfg)
    local providerMap = {}
    if buffCfg:RoomTagListLength() == 0 then
        return providerMap
    end

    local tags2Providers = {}
    for _, provider in pairs(self.providers) do
        for tagCfgId, count in pairs(provider.tagMap) do
            tags2Providers[tagCfgId] = tags2Providers[tagCfgId] or {}
            for i = 1, count do
                table.insert(tags2Providers[tagCfgId], provider)
            end
        end
    end

    for i = 1, buffCfg:RoomTagListLength() do
        local tagCfgId = buffCfg:RoomTagList(i)
        if providerMap[tagCfgId] and #providerMap[tagCfgId] > 0 then
            local provider = table.remove(providerMap[tagCfgId], 1)
            providerMap[i] = provider
        end
    end

    return providerMap
end

function CityLegoBuffCalculatorTemp:GetAllPrividers()
    local ret = {}
    for k, v in pairs(self.providers) do
        table.insert(ret, v)
    end
    return ret
end

return CityLegoBuffCalculatorTemp