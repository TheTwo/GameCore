---@class CityLegoBuffCalculatorBase
---@field new fun():CityLegoBuffCalculatorBase
local CityLegoBuffCalculatorBase = class("CityLegoBuffCalculatorBase")

function CityLegoBuffCalculatorBase:GetTagCount(tagId)
    return 0
end

---@param buffCfg RoomTagBuffConfigCell
---@return table<number, CityLegoBuffProvider> @key:buffCfg第几个tag, value:对应的provider, 为空表示没有对应的provider
function CityLegoBuffCalculatorBase:GetTagProviderMap(buffCfg)
    return {}
end

---@return CityLegoBuffProvider[]
function CityLegoBuffCalculatorBase:GetAllPrividers()
    return {}
end

return CityLegoBuffCalculatorBase