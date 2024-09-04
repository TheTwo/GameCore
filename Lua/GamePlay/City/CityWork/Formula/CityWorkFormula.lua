local CityWorkFormula = {}
local ModuleRefer = require("ModuleRefer")
local CityAttrType = require("CityAttrType")
local ItemGroupHelper = require("ItemGroupHelper")
local CityWorkType = require("CityWorkType")
local ConfigRefer = require("ConfigRefer")
CityWorkFormula.EnableLog = false

function CityWorkFormula.Protect(value)
    if value <= 0 then
        g_Logger.Error("参数错误，不能小于等于0")
        return 1
    end
    return value
end

function CityWorkFormula.EnableLogSwitch(value)
    CityWorkFormula.EnableLog = value
end

---@param workCfg CityWorkConfigCell
function CityWorkFormula.GetWorkEfficiency(workCfg, buildingId, furnitureId, citizenId, skipGlobal)
    return 0
end

---@param workCfg CityWorkConfigCell
function CityWorkFormula.GetWorkPower(workCfg, buildingId, furnitureId, citizenId, skipGlobal)
    return 0
end

---@param workCfg CityWorkConfigCell
function CityWorkFormula.GetCostDecrease(workCfg, buildingId, furnitureId, citizenId, skipGlobal)
    if workCfg:Type() == CityWorkType.FurnitureLevelUp then
        return ModuleRefer.CastleAttrModule:GetAttrValue(CityAttrType.FurUpdateCost, buildingId, furnitureId, citizenId, skipGlobal)
    else
        return 0
    end
end

---@param workCfg CityWorkConfigCell
function CityWorkFormula.GetOutputIncrease(workCfg, buildingId, furnitureId, citizenId, skipGlobal)
    return 0
end

---@param workCfg CityWorkConfigCell
function CityWorkFormula.GetQueueCapacity(workCfg, buildingId, furnitureId, citizenId, skipGlobal)
    return 0
end

---@param workCfg CityWorkConfigCell
function CityWorkFormula.GetQueueCount(workCfg, buildingId, furnitureId, citizenId, skipGlobal)
    return 0
end

---@param workCfg CityWorkConfigCell
function CityWorkFormula.GetMilitiaTrainSpeed(workCfg, buildingId, furnitureId, citizenId, skipGlobal)
    return 0
end

---@param workCfg CityWorkConfigCell
function CityWorkFormula.GetResGenMaxCount(workCfg, buildingId, furnitureId, citizenId, skipGlobal)
    return 0
end

---@param workCfg CityWorkConfigCell
function CityWorkFormula.GetTypeMaxQueueCount(workCfg, buildingId, furnitureId, citizenId, skipGlobal)
    return 0
end

function CityWorkFormula.GetTypeMaxQueueCountByWorkType(workType, buildingId, furnitureId, citizenId, skipGlobal)
    return 0
end

function CityWorkFormula.CalculateTimeCostDecrease(workCfg, originDifficulty, buildingId, furnitureId, citizenId, skipGlobal)
    if CityWorkFormula.EnableLog then
        g_Logger.LogChannel("CityWorkFormula", "开始计算工作[%d]的TimeCostDescrease属性", workCfg:Id())
    end
    local efficiency = CityWorkFormula.GetWorkEfficiency(workCfg, buildingId, furnitureId, citizenId, skipGlobal) + 1
    local power = CityWorkFormula.GetWorkPower(workCfg, buildingId, furnitureId, citizenId, skipGlobal)
    if CityWorkFormula.EnableLog then
        g_Logger.LogChannel("CityWorkFormula", "TimeCostDescrease属性值 ([power] %.2f + [difficulty] %.2f + 100) / ([efficiency] %.2f * 2 * ([power] %.2f + 50)) = %.2f", power, originDifficulty, efficiency, power, (power + originDifficulty + 100) / (efficiency * 2 * (power + 50)))
    end
    return (power + originDifficulty + 100) / (CityWorkFormula.Protect(efficiency * 2 * (power + 50)))
end

---@return number 计算最终产出耗时
function CityWorkFormula.CalculateFinalTimeCost(workCfg, originTime, originDifficulty, buildingId, furnitureId, citizenId, skipGlobal)
    local percent = CityWorkFormula.CalculateTimeCostDecrease(workCfg, originDifficulty, buildingId, furnitureId, citizenId, skipGlobal)
    return originTime * percent
end

---@return {id:number, count:number}[] 计算最终消耗道具数量
---@param workCfg CityWorkConfigCell
---@param itemGroup ItemGroupConfigCell
function CityWorkFormula.CalculateInput(workCfg, itemGroup, buildingId, furnitureId, citizenId, skipGlobal)
    local ret = {}
    if itemGroup == nil then
        return ret
    end
    local cache = {}
    for i = 1, itemGroup:ItemGroupInfoListLength() do
        local itemInfo = itemGroup:ItemGroupInfoList(i)
        local itemId = itemInfo:Items()
        if cache[itemId] then
            cache[itemId].count = cache[itemId].count + itemInfo:Nums()
        else
            local itemInfo = {id = itemId, count = itemInfo:Nums()}
            cache[itemId] = itemInfo
            table.insert(ret, itemInfo)
        end
    end

    local decrease = CityWorkFormula.GetCostDecrease(workCfg, buildingId, furnitureId, citizenId, skipGlobal)
    for k, v in pairs(cache) do
        v.count = v.count * math.max(0, 1 - decrease)
    end
    return ret
end

---@return {id:number, minCount:number, maxCount:number}[] 计算最终产出道具数量
---@param workCfg CityWorkConfigCell
---@param itemGroup ItemGroupConfigCell
function CityWorkFormula.CalculateOutput(workCfg, itemGroup, buildingId, furnitureId, citizenId, skipGlobal)
    local ret, cache = ItemGroupHelper.GetPossibleOutput(itemGroup)
    local increase = CityWorkFormula.GetOutputIncrease(workCfg, buildingId, furnitureId, citizenId, skipGlobal)
    for k, v in pairs(cache) do
        v.minCount = v.minCount * (1 + increase)
        v.maxCount = v.maxCount * (1 + increase)
    end
    return ret
end

---@param workCfg CityWorkConfigCell
function CityWorkFormula.GetResAutoCollectMaxCount(workCfg, buildingId, furnitureId, citizenId, skipGlobal)
    if workCfg:ResAutoCollectMaxCountAttrLength() == 0 then
        return workCfg:ResAutoCollectMaxCountOverride()
    else
        local baseValue, multiValue, pointValue = 0, 0, 0
        CityWorkFormula.SwitchLog(true)
        for i = 1, workCfg:ResAutoCollectMaxCountAttrLength() do
            local attrType = workCfg:ResAutoCollectMaxCountAttr(i)
            if attrType ~= CityAttrType.None then
                local a, b, c = ModuleRefer.CastleAttrModule:GetAttrValue(attrType, buildingId, furnitureId, citizenId, skipGlobal)
                baseValue = baseValue + a
                multiValue = multiValue + b
                pointValue = pointValue + c
            end
        end
        CityWorkFormula.SwitchLog(false)
        return baseValue * (1 + multiValue) + pointValue
    end
end

---@param workCfg CityWorkConfigCell
function CityWorkFormula.GetAutoProcessMaxCount(workCfg, buildingId, furnitureId, citizenId, skipGlobal)
    if workCfg:AutoProcessMaxCountAttrLength() == 0 then
        return workCfg:AutoProcessMaxCountOverride()
    else
        local baseValue, multiValue, pointValue = 0, 0, 0
        CityWorkFormula.SwitchLog(true)
        for i = 1, workCfg:AutoProcessMaxCountAttrLength() do
            local attrType = workCfg:AutoProcessMaxCountAttr(i)
            if attrType ~= CityAttrType.None then
                local a, b, c = ModuleRefer.CastleAttrModule:GetAttrValue(attrType, buildingId, furnitureId, citizenId, skipGlobal)
                baseValue = baseValue + a
                multiValue = multiValue + b
                pointValue = pointValue + c
            end
        end
        CityWorkFormula.SwitchLog(false)
        return baseValue * (1 + multiValue) + pointValue
    end
end

function CityWorkFormula.SwitchLog(value)
    if CityWorkFormula.EnableLog then
        ModuleRefer.CastleAttrModule:SwitchLog(value)
    end
end

return CityWorkFormula