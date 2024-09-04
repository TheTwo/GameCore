local CityFurnitureHelper = {}

function CityFurnitureHelper.GetPlaceHudNotifyName()
    return "HUD_FURNITURE_PLACE"
end

function CityFurnitureHelper.GetPlaceUIAllToggleNotifyName()
    return ("UI_FURNITURE_PLACE_TOGGLE_ALL")
end

function CityFurnitureHelper.GetPlaceUIToggleNotifyName(category)
    return ("[%d]UI_FURNITURE_PLACE_TOGGLE"):format(category)
end

function CityFurnitureHelper.GetPlaceUINodeNotifyName(lvCfgId)
    return ("[%d]UI_FURNITURE_PLACE_NODE"):format(lvCfgId)
end

---@param l CityProcessConfigCell
---@param r CityProcessConfigCell
function CityFurnitureHelper.SortByPriority(l, r)
    return l:Index() > r:Index()
end

---@param lvCfg CityFurnitureLevelConfigCell
---@return number, number, boolean @WorkCfgId, ProcessId, NeedFreeCitizen
function CityFurnitureHelper.GetAutoStartProduceInfo(lvCfg)
    if lvCfg == nil then return 0, 0, false end
    local ConfigRefer = require("ConfigRefer")
    local CityWorkType = require("CityWorkType")
    ---@type CityWorkConfigCell
    local produceWork = nil
    for i = 1, lvCfg:WorkListLength() do
        local workCfg = ConfigRefer.CityWork:Find(lvCfg:WorkList(i))
        if workCfg:Type() == CityWorkType.ResourceGenerate then
            produceWork = workCfg
            break
        end
    end

    if produceWork == nil then
        return 0, 0, false
    end

    local needCitizen = not produceWork:AllowNoCitizen()
    local CityWorkHelper = require("CityWorkHelper")
    local recipeOrderList = {}
    for i = 1, produceWork:GenerateResListLength() do
        local processCfg = ConfigRefer.CityProcess:Find(produceWork:GenerateResList(i))
        if CityWorkHelper.IsProcessEffective(processCfg) then
            table.insert(recipeOrderList, processCfg)
        end
    end
    if #recipeOrderList > 0 then
        table.sort(recipeOrderList, CityFurnitureHelper.SortByPriority)
        return produceWork:Id(), recipeOrderList[1]:Id(), needCitizen
    end
    return 0, 0, false
end

---@param lvCfg CityFurnitureLevelConfigCell
---@return number, number, boolean @WorkCfgId, ProcessId, NeedFreeCitizen
function CityFurnitureHelper.GetAutoStartProcessInfo(lvCfg)
    if lvCfg == nil then return 0, 0, false end
    local ConfigRefer = require("ConfigRefer")
    local CityWorkType = require("CityWorkType")
    ---@type CityWorkConfigCell
    local processWork = nil
    for i = 1, lvCfg:WorkListLength() do
        local workCfg = ConfigRefer.CityWork:Find(lvCfg:WorkList(i))
        if workCfg:Type() == CityWorkType.Process then
            processWork = workCfg
            break
        end
    end

    if processWork == nil then
        return 0, 0, false
    end

    local needCitizen = not processWork:AllowNoCitizen()
    local CityWorkHelper = require("CityWorkHelper")
    local recipeOrderList = {}
    for i = 1, processWork:ProcessListLength() do
        local processCfg = ConfigRefer.CityProcess:Find(processWork:ProcessList(i))
        if CityWorkHelper.IsProcessEffective(processCfg) then
            table.insert(recipeOrderList, processCfg)
        end
    end

    if #recipeOrderList > 0 then
        table.sort(recipeOrderList, CityFurnitureHelper.SortByPriority)
        return processWork:Id(), recipeOrderList[1]:Id(), needCitizen
    end
    return 0, 0, false
end

---@param lvCfg CityFurnitureLevelConfigCell
---@return number, number, boolean @WorkCfgId, ProcessId, NeedFreeCitizen
function CityFurnitureHelper.GetAutoStartFurnitureCollect(lvCfg)
    if lvCfg == nil then return 0, 0, false end
    local ConfigRefer = require("ConfigRefer")
    local CityWorkType = require("CityWorkType")
    ---@type CityWorkConfigCell
    local collectWork = nil
    for i = 1, lvCfg:WorkListLength() do
        local workCfg = ConfigRefer.CityWork:Find(lvCfg:WorkList(i))
        if workCfg:Type() == CityWorkType.FurnitureResCollect then
            collectWork = workCfg
            break
        end
    end

    if collectWork == nil then
        return 0, 0, false
    end

    local needCitizen = not collectWork:AllowNoCitizen()
    local CityWorkHelper = require("CityWorkHelper")
    local recipeOrderList = {}
    for i = 1, collectWork:CollectResListLength() do
        local processCfg = ConfigRefer.CityProcess:Find(collectWork:CollectResList(i))
        if CityWorkHelper.IsProcessEffective(processCfg) then
            table.insert(recipeOrderList, processCfg)
        end
    end
    
    if #recipeOrderList > 0 then
        table.sort(recipeOrderList, CityFurnitureHelper.SortByPriority)
        return collectWork:Id(), recipeOrderList[1]:Id(), needCitizen
    end
    return 0, 0, false
end

return CityFurnitureHelper