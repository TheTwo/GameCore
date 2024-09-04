local EmptyStep = require("EmptyStep")
---@class CheckStep:EmptyStep
---@field new fun():CheckStep
local CheckStep = class("CheckStep", EmptyStep)
local ModuleRefer = require("ModuleRefer")

function CheckStep:ctor(furTypeId)
    self.furTypeId = furTypeId
    self.city = ModuleRefer.CityModule:GetMyCity()
end

function CheckStep:TryExecuted()
    local furniture = self.city.furnitureManager:GetFurnitureByTypeCfgId(self.furTypeId)
    if furniture == nil then
        return false
    end

    if furniture:GetPetWorkSlotCount() == 0 then
        local castle = self.city:GetCastle()
        CS.UnityEngine.GUIUtility.systemCopyBuffer = FormatTable(castle)
        return true, true
    end

    return true, false
end

return CheckStep