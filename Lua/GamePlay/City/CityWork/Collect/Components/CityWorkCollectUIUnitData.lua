---@class CityWorkCollectUIUnitData
---@field new fun(furniture:CityFurniture):CityWorkCollectUIUnitData
local CityWorkCollectUIUnitData = class("CityWorkCollectUIUnitData")
local CityWorkProcessUIUnitStatus = require("CityWorkProcessUIUnitStatus")

---@param furniture CityFurniture
function CityWorkCollectUIUnitData:ctor(furniture, uiMediator)
    self.furniture = furniture
    self.uiMediator = uiMediator
    self.status = CityWorkProcessUIUnitStatus.Free
end

---@param info wds.CastleFurnitureCollectInfo
function CityWorkCollectUIUnitData:SetInQueue(info)
    self.status = CityWorkProcessUIUnitStatus.InQueue
    self.info = info
end

---@param info wds.CastleFurnitureCollectInfo
function CityWorkCollectUIUnitData:SetFinished(info)
    self.status = CityWorkProcessUIUnitStatus.Collect
    self.info = info
end

---@param info wds.CastleFurnitureCollectInfo
function CityWorkCollectUIUnitData:SetWorking(info)
    self.status = CityWorkProcessUIUnitStatus.Working
    self.info = info
end

function CityWorkCollectUIUnitData:SetFree()
    self.status = CityWorkProcessUIUnitStatus.Free
    self.info = nil
end

function CityWorkCollectUIUnitData:SetForbid()
    self.status = CityWorkProcessUIUnitStatus.Forbid
    self.info = nil
end

return CityWorkCollectUIUnitData