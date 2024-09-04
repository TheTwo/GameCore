local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local ItemGroupHelper = require("ItemGroupHelper")
local FunctionClass = require("FunctionClass")
local CityWorkType = require("CityWorkType")
local CityProcessUtils = {}

---@param processCfg CityWorkProcessConfigCell
function CityProcessUtils.IsRecipeVisible(processCfg)
    for i = 1, processCfg:VisibleConditionLength() do
        local taskId = processCfg:VisibleCondition(i)
        local state = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId)
        if state ~= wds.TaskState.TaskStateCanFinish and state ~= wds.TaskState.TaskStateFinished then
            return false
        end
    end
    return true
end

---@param processCfg CityWorkProcessConfigCell
function CityProcessUtils.IsRecipeUnlocked(processCfg)
    for i = 1, processCfg:EffectiveConditionLength() do
        local taskId = processCfg:EffectiveCondition(i)
        local state = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId)
        if state ~= wds.TaskState.TaskStateCanFinish and state ~= wds.TaskState.TaskStateFinished then
            return false
        end
    end
    return true
end

---@param processCfg CityWorkProcessConfigCell
function CityProcessUtils.IsFurnitureRecipe(processCfg)
    local outputItemCfg = ConfigRefer.Item:Find(processCfg:Output())
    return outputItemCfg ~= nil and outputItemCfg:FunctionClass() == FunctionClass.AddFurnitureCount and outputItemCfg:UseParamLength() == 1
end

---@param processCfg CityWorkProcessConfigCell
function CityProcessUtils.GetCostEnoughTimes(processCfg)
    local itemGroup = ConfigRefer.ItemGroup:Find(processCfg:Cost())
    local costArray = ItemGroupHelper.GetPossibleOutput(itemGroup)
    local ret = nil
    for i, v in ipairs(costArray) do
        if v.minCount ~= v.maxCount then goto continue end

        local own = ModuleRefer.InventoryModule:GetAmountByConfigId(v.id)
        if ret == nil or ret > own // v.minCount then
            ret = own // v.minCount
        end
        ::continue::
    end

    if ret == nil then
        ret = 0
    end
    return ret
end

---@param convertProcessCfg CityWorkMatConvertProcessConfigCell
function CityProcessUtils.IsConvertRecipeVisible(convertProcessCfg)
    for j = 1, convertProcessCfg:RecipesLength() do
        local recipeId = convertProcessCfg:Recipes(j)
        local processCfg = ConfigRefer.CityWorkProcess:Find(recipeId)
        if CityProcessUtils.IsRecipeVisible(processCfg) then
            return true
        end
    end
    return false
end

---@param convertProcessCfg CityWorkMatConvertProcessConfigCell
function CityProcessUtils.IsConvertRecipeUnlocked(convertProcessCfg)
    for j = 1, convertProcessCfg:RecipesLength() do
        local recipeId = convertProcessCfg:Recipes(j)
        local processCfg = ConfigRefer.CityWorkProcess:Find(recipeId)
        if CityProcessUtils.IsRecipeUnlocked(processCfg) then
            return true
        end
    end
    return false
end

function CityProcessUtils.GetProcessOutputFurnitureLvCfg(processCfg)
    if not CityProcessUtils.IsFurnitureRecipe(processCfg) then
        return nil
    end

    local output = ConfigRefer.Item:Find(processCfg:Output())
    local lvCfgId = checknumber(output:UseParam(1))
    return ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
end

---@param city City
---@param processCfg CityWorkProcessConfigCell
function CityProcessUtils.GetFurnitureProcessCountLimit(city, processCfg)
    local lvCfg = CityProcessUtils.GetProcessOutputFurnitureLvCfg(processCfg)
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
    return city.furnitureManager:GetFurnitureMaxOwnCount(typCfg:Id())
end

function CityProcessUtils.GetRecipeIdFromFurnitureTypeCfgId(workCfgId, typCfgId)
    local workCfg = ConfigRefer.CityWork:Find(workCfgId)
    if workCfg == nil or workCfg:Type() ~= CityWorkType.Process then
        return nil
    end

    for i = 1, workCfg:ProcessCfgLength() do
        local processCfg = ConfigRefer.CityWorkProcess:Find(workCfg:ProcessCfg(i))
        if CityProcessUtils.IsFurnitureRecipe(processCfg) then
            local lvCfg = CityProcessUtils.GetProcessOutputFurnitureLvCfg(processCfg)
            if lvCfg:Type() == typCfgId then
                return processCfg:Id()
            end
        end
    end

    return nil
end

return CityProcessUtils