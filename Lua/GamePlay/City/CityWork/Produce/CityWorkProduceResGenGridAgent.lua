---@class CityWorkProduceResGenGridAgent
---@field new fun():CityWorkProduceResGenGridAgent
local CityWorkProduceResGenGridAgent = class("CityWorkProduceResGenGridAgent")
local ConfigRefer = require("ConfigRefer")
local CityWorkProduceResGenUnit = require("CityWorkProduceResGenUnit")
local CityWorkProduceResGenUnitStatus = require("CityWorkProduceResGenUnitStatus")

---@param city City
function CityWorkProduceResGenGridAgent:ctor(id, city)
    self.city = city
    self.furnitureId = id
    self.generating = CityWorkProduceResGenUnit.new(self)
end

function CityWorkProduceResGenGridAgent:Clear()    
    self.generating:Clear()
end

---@param data wds.CastleResourceGenerateInfo
function CityWorkProduceResGenGridAgent:FillData(data)
    local temp = CityWorkProduceResGenUnit.new(self)
    if data.GeneratePlan:Count() > 0 then
        temp:FillDataByGeneratePlan(data.GeneratePlan[1])
    end

    if not temp:Equals(self.generating) then
        self.generating:Exchange(temp)
        return temp, self.generating
    end
    return nil, nil
end

---@return boolean
function CityWorkProduceResGenGridAgent:IsGenerating()
    return self.generating:IsGenerating()
end

return CityWorkProduceResGenGridAgent