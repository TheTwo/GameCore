---@class CityBuildingRepairBlockDatum
local CityBuildingRepairBlockDatum = class('CityBuildingRepairBlockDatum')

---@return ItemIconData[]
function CityBuildingRepairBlockDatum:GetCostItemIconData()
    if UNITY_DEBUG then
        error("override me!")
    end
    return nil
end

---@return CityRepairBlockBase
function CityBuildingRepairBlockDatum:GetRepairBlock()
    if UNITY_DEBUG then
        error("override me!")
    end
    return nil
end

---@return boolean @keepTriggerFlashEvent
function CityBuildingRepairBlockDatum:RequestCost(itemId)
    return false
end

function CityBuildingRepairBlockDatum:AddEventListener()
    
end

function CityBuildingRepairBlockDatum:RemoveEventListener()
    
end

---@param flag boolean
function CityBuildingRepairBlockDatum:TriggerFlashEvent(flag)
    
end

return CityBuildingRepairBlockDatum