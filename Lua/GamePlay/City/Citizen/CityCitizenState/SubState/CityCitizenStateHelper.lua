local CityWorkTargetType = require("CityWorkTargetType")
local CityWorkType = require("CityWorkType")

---@class CityCitizenStateHelper
---@field new fun():CityCitizenStateHelper
local CityCitizenStateHelper = sealedClass('CityCitizenStateHelper')

---@param citizenData CityCitizenData
function CityCitizenStateHelper.IsCurrentWorkValid(citizenData)
    if not citizenData then return false end
    local workData = citizenData:GetWorkData()
    return workData and workData:GetCurrentTargetIndexGoToTimeLeftTime() == 1
end

---@param targetInfo CityCitizenTargetInfo
---@param citizenData CityCitizenData
---@return CityCitizenTargetInfo
function CityCitizenStateHelper.ProcessFurnitureWorkTarget(targetInfo, citizenData)
    if targetInfo.type == CityWorkTargetType.Furniture then
        local eleMgr = citizenData._mgr.city.elementManager
        local furniture = citizenData._mgr.city.furnitureManager:GetFurnitureById(targetInfo.id)
        local castleFurniture = furniture and furniture:GetCastleFurniture()
        if castleFurniture and castleFurniture.WorkType2Id then
            for workType, workId in pairs(castleFurniture.WorkType2Id) do
                if workId == citizenData._workId then
                    if CityWorkType.FurnitureResCollect == workType then
                        local resourceQeue = castleFurniture.FurnitureCollectInfo
                        if resourceQeue then
                            for _, resInfo in ipairs(resourceQeue) do
                                if not resInfo.Finished
                                    and resInfo.CollectingResource ~= 0
                                    and eleMgr:GetElementById(resInfo.CollectingResource)
                                then
                                    ---@type CityCitizenTargetInfo
                                    local redirectInfo = {}
                                    redirectInfo.id = resInfo.CollectingResource
                                    redirectInfo.type = CityWorkTargetType.Resource
                                    return redirectInfo
                                end
                            end
                        end
                    end
                    break
                end
            end
        end
        -- local elementResourceTargetId = citizenData:GetCastleInProgressResourceByWorkId(citizenData._workId)
        -- if elementResourceTargetId then
        --     return { id= elementResourceTargetId, type=CityWorkTargetType.Resource}
        -- end
    end
    return targetInfo
end


---@param targetInfo CityCitizenTargetInfo
---@param citizenData CityCitizenData
---@return CityCitizenTargetInfo,CityCitizenTargetInfo
function CityCitizenStateHelper.GetRedirectWorkTargetByTargetInfo(targetInfo, citizenData)
    local selectWorkTargetRegisterRedirectTargetInfo = nil
    local oldType = targetInfo.type
    targetInfo = CityCitizenStateHelper.ProcessFurnitureWorkTarget(targetInfo, citizenData)
    if oldType == CityWorkTargetType.Furniture and targetInfo.type == CityWorkTargetType.Resource then
        selectWorkTargetRegisterRedirectTargetInfo = targetInfo
    end
    return targetInfo, selectWorkTargetRegisterRedirectTargetInfo
end

---@param targetInfo CityCitizenTargetInfo
---@param citizenData CityCitizenData
---@return CS.UnityEngine.Vector3,CityCitizenTargetInfo,CityCitizenTargetInfo
function CityCitizenStateHelper.GetWorkTargetPosByTargetInfo(targetInfo, citizenData)
    local selectWorkTargetRegisterRedirectTargetInfo = nil
    local oldType = targetInfo.type
    targetInfo = CityCitizenStateHelper.ProcessFurnitureWorkTarget(targetInfo, citizenData)
    if oldType == CityWorkTargetType.Furniture and targetInfo.type == CityWorkTargetType.Resource then
        selectWorkTargetRegisterRedirectTargetInfo = targetInfo
    end
    return citizenData:GetPositionById(targetInfo.id, targetInfo.type), targetInfo, selectWorkTargetRegisterRedirectTargetInfo
end

---@param targetInfo CityCitizenTargetInfo
---@param citizenData CityCitizenData
---@return CityInteractPoint_Impl,CityCitizenTargetInfo,CityCitizenTargetInfo
function CityCitizenStateHelper.AcquireWorkTargetInteractPointByTargetInfo(targetInfo, citizenData)
    local selectWorkTargetRegisterRedirectTargetInfo = nil
    local oldType = targetInfo.type
    targetInfo = CityCitizenStateHelper.ProcessFurnitureWorkTarget(targetInfo, citizenData)
    if oldType == CityWorkTargetType.Furniture and targetInfo.type == CityWorkTargetType.Resource then
        selectWorkTargetRegisterRedirectTargetInfo = targetInfo
        local city = citizenData._mgr.city
        ---这里快速检查没有交互点的elemet
        if city.cityInteractPointManager:FastCheckElementHasNoneInteractPoint(targetInfo.id) then
            return nil,targetInfo,selectWorkTargetRegisterRedirectTargetInfo
        end
    end
    return citizenData:AcquireInteractPointById(targetInfo.id, targetInfo.type), targetInfo, selectWorkTargetRegisterRedirectTargetInfo
end

---@param context CitizenBTContext
---@return CityCitizenTargetInfo, CityCitizenWorkData
function CityCitizenStateHelper.GetTargetInfo(context)
    local workData = context:GetCitizenData():GetWorkData()
    if workData then
        local targetId, targetType = workData:GetTarget()
        ---@type CityCitizenTargetInfo
        local ret = {}
        ret.id = targetId
        ret.type = targetType
        return ret, workData
    end
    return nil, nil
end

return CityCitizenStateHelper