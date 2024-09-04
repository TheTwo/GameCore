---@class CityLegoBuffUnit
---@field new fun(buffCfg):CityLegoBuffUnit
local CityLegoBuffUnit = class("CityLegoBuffUnit")

---@param buffCfg RoomTagBuffConfigCell
function CityLegoBuffUnit:ctor(buffCfg)
    self.buffCfg = buffCfg
    self.needTagMap = {}
    self.lackTagMap = {}
end

---@param calculator CityLegoBuffCalculatorWds
function CityLegoBuffUnit:UpdateValidState(calculator)
    self.valid = true
    table.clear(self.needTagMap)
    table.clear(self.lackTagMap)
    for i = 1, self.buffCfg:RoomTagListLength() do
        local tagId = self.buffCfg:RoomTagList(i)
        self.needTagMap[tagId] = (self.needTagMap[tagId] or 0) + 1
    end

    for tagId, need in pairs(self.needTagMap) do
        local has = calculator:GetTagCount(tagId)
        if has < need then
            self.valid = false
            self.lackTagMap[tagId] = need - has
        end
    end

    return self.valid
end

function CityLegoBuffUnit:GetLackTagCount()
    if self.valid then return 0 end
    if not self.lackTagMap then return 0 end
    local count = 0
    for tagId, lack in pairs(self.lackTagMap) do
        count = count + lack
    end
    return count
end

return CityLegoBuffUnit