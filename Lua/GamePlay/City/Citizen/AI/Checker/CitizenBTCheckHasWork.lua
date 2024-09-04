local CityCitizenStateHelper = require("CityCitizenStateHelper")
local CityWorkTargetType = require("CityWorkTargetType")
local CityWorkType = require("CityWorkType")

local CitizenBTNode = require("CitizenBTNode")

---@class CitizenBTCheckHasWork:CitizenBTNode
---@field new fun():CitizenBTCheckHasWork
---@field super CitizenBTNode
local CitizenBTCheckHasWork = class('CitizenBTCheckHasWork', CitizenBTNode)

function CitizenBTCheckHasWork:Run(context, gContext)
    if not context:GetCitizenData():HasWork() then
        return false, nil
    end
    local targetInfo, _ = CityCitizenStateHelper.GetTargetInfo(context)
    if targetInfo.type == CityWorkTargetType.Furniture then
        local city = context:GetCity()
        local furnitureMgr = city.furnitureManager
        local castleFurniture = furnitureMgr:GetCastleFurniture(targetInfo.id)
        if castleFurniture.WorkType2Id[CityWorkType.FurnitureResCollect] then
            local _,redirectTarget = CityCitizenStateHelper.GetRedirectWorkTargetByTargetInfo(targetInfo, context:GetCitizenData())
            if not redirectTarget then
                return false,nil
            end
            if redirectTarget.type == CityWorkTargetType.Resource then
                if city.cityInteractPointManager:FastCheckElementHasNoneInteractPoint(redirectTarget.id) then
                    return false, nil
                end
            end
        end
    elseif targetInfo.type == CityWorkTargetType.Resource then
        local city = context:GetCity()
        if city.cityInteractPointManager:FastCheckElementHasNoneInteractPoint(targetInfo.id) then
            return false, nil
        end
    end
    return true, nil
end

return CitizenBTCheckHasWork