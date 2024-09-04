local CityWorkTargetType = require("CityWorkTargetType")
local CityWorkType = require("CityWorkType")
local UIMediatorNames = require("UIMediatorNames")
local NumberFormatter = require("NumberFormatter")
local ModuleRefer = require("ModuleRefer")

local CityWorkType2TargetTypeMap = {}
CityWorkType2TargetTypeMap[CityWorkType.Process] = CityWorkTargetType.Furniture
CityWorkType2TargetTypeMap[CityWorkType.FurnitureLevelUp] = CityWorkTargetType.Furniture
CityWorkType2TargetTypeMap[CityWorkType.ResourceCollect] = CityWorkTargetType.Resource

local ConfigRefer = require("ConfigRefer")
local CityWorkHelper = {}
function CityWorkHelper.GetWorkTargetType(workCfgId)
    local workCfg = ConfigRefer.CityWork:Find(workCfgId)
    return CityWorkHelper.GetWorkTargetTypeByCfg(workCfg)
end

---@param workCfg CityWorkConfigCell
function CityWorkHelper.GetWorkTargetTypeByCfg(workCfg)
    local workType = workCfg:Type()
    return CityWorkType2TargetTypeMap[workType] or CityWorkTargetType.Unknown
end

function CityWorkHelper.IsRelativeUiOpened()
    local uiManager = g_Game.UIManager
    return uiManager:IsOpenedByName(UIMediatorNames.CityLegoBuildingUIMediator)
end

---@param total number @总值
---@param withoutCizizen number @去掉了居民的人
---@return string, string @1:去掉了居民后的值, 2:居民的值
function CityWorkHelper.GetBuffPercentItemDescString(total, withoutCizizen)
    local sub = total - withoutCizizen
    local mainText = withoutCizizen ~= 0 and NumberFormatter.PercentWithSignSymbol(withoutCizizen) or "0%"
    local subText = sub ~= 0 and NumberFormatter.PercentWithSignSymbol(sub) or "0%"
    return mainText, subText
end

function CityWorkHelper.GetBuffPercentItemDescStringForI18NParams(total, withoutCizizen)
    local sub = total - withoutCizizen
    local totalText = total ~= 0 and NumberFormatter.PercentWithSignSymbol(total) or "0%"
    local otherText = withoutCizizen ~= 0 and NumberFormatter.PercentWithSignSymbol(withoutCizizen) or "0%"
    local citizenText = sub ~= 0 and NumberFormatter.PercentWithSignSymbol(sub) or "0%"
    return ("%s%%"):format(totalText), ("%s%%"):format(otherText), ("%s%%"):format(citizenText)
end

function CityWorkHelper.GetNotifyRootName()
    return "HUD_FURNITURE_OVERVIEW"
end

function CityWorkHelper.GetFreeNotifyRootName()
    return "HUD_FURNITURE_LEVEL_UP_FREE"
end

function CityWorkHelper.GetLevelUpFreeNotifyName()
    return "FURNITURE_OVERVIEW_LEVEL_UP_FREE"
end

function CityWorkHelper.GetLevelUpNotifyName(furnitureId)
    return ("[%d]FURNITURE_OVERVIEW_LEVEL_UP"):format(furnitureId)
end

function CityWorkHelper.GetProcessNotifyName(furnitureId)
    return ("[%d]FURNITURE_OVERVIEW_PROCESS"):format(furnitureId)
end

function CityWorkHelper.GetCollectNotifyName(furnitureId)
    return ("[%d]FURNITURE_OVERVIEW_COLLECT"):format(furnitureId)
end

function CityWorkHelper.GetProduceNotifyName(furnitureId)
    return ("[%d]FURNITURE_OVERVIEW_PRODUCE"):format(furnitureId)
end

function CityWorkHelper.HasTargetTypeWorkCfg(lvCfgId, workType)
    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
    if lvCfg == nil then return false end

    for i = 1, lvCfg:WorkListLength() do
        local workCfg = ConfigRefer.CityWork:Find(lvCfg:WorkList(i))
        if workCfg and workCfg:Type() == workType then
            return true
        end
    end
    return false
end

---@param castleFurniture wds.CastleFurniture
function CityWorkHelper.NeedShowLevelUpNotifyNode(castleFurniture)
    return castleFurniture.LevelUpInfo.Working and castleFurniture.WorkType2Id[CityWorkType.FurnitureLevelUp] == nil
end

---@param castleFurniture wds.CastleFurniture
function CityWorkHelper.NeedShowProcessNotifyNode(castleFurniture)
    --- 被打断时显示红点
    if castleFurniture.ProcessInfo:Count() > 0 and castleFurniture.WorkType2Id[CityWorkType.Process] == nil then
        return true
    end

    --- 自动暂停时显示红点
    if castleFurniture.ProcessInfo:Count() > 0 then
        local process = castleFurniture.ProcessInfo[1]
        if process.Auto and not process.Working then
            return true
        end
    end
    return false
end

---@param castleFurniture wds.CastleFurniture
function CityWorkHelper.NeedShowResCollectNotifyNode(castleFurniture)
    --- 打断时显示红点
    if castleFurniture.FurnitureCollectInfo:Count() > 0 and castleFurniture.WorkType2Id[CityWorkType.FurnitureResCollect] == nil then
        return true
    end

    --- 自动暂停时显示红点
    if castleFurniture.FurnitureCollectInfo:Count() > 0 then
        local v = castleFurniture.FurnitureCollectInfo[1]
        if v.Auto and v.CollectingResource == 0 then
            return true
        end
    end
    return false
end

---@param castleFurniture wds.CastleFurniture
function CityWorkHelper.NeedShowProduceNotifyNode(castleFurniture)
    return false
end

---@param processCfg CityProcessConfigCell
function CityWorkHelper.IsProcessEffective(processCfg)
    local ModuleRefer = require("ModuleRefer")
    local questModule = ModuleRefer.QuestModule
    for i = 1, processCfg:EffectiveConditionLength() do
        local taskId = processCfg:EffectiveCondition(i)
        local status = questModule:GetQuestFinishedStateLocalCache(taskId)
        if status ~= wds.TaskState.TaskStateFinished and status ~= wds.TaskState.TaskStateCanFinish then
            return false
        end
    end

    return true
end

return CityWorkHelper