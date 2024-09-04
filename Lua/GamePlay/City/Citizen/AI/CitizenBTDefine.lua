local CitizenEnvironmentalIndicatorOperator = require("CitizenEnvironmentalIndicatorOperator")

---@class CitizenBTDefine
local CitizenBTDefine = {}

CitizenBTDefine.ContextKey = {}

CitizenBTDefine.ContextKey.ClearFlag = "ClearFlag"

CitizenBTDefine.ContextKey.CurrentKey = "CurrentKey"
CitizenBTDefine.ContextKey.CurrentNode = "CurrentNode"
CitizenBTDefine.ContextKey.CurrentPriority = "CurrentPriority"

CitizenBTDefine.ContextKey.DecisionKey = "DecisionKey"
CitizenBTDefine.ContextKey.DecisionPriority = "DecisionPriority"

CitizenBTDefine.ContextKey.WorkTargetInfo = "WorkTargetInfo"
CitizenBTDefine.ContextKey.GotoTargetInfo = "GotoTargetInfo"
CitizenBTDefine.ContextKey.PlayClipInfo = "PlayClipInfo"
CitizenBTDefine.ContextKey.PreferRun = "PreferRun"
CitizenBTDefine.ContextKey.LastFailAction = "LastFailAction"
CitizenBTDefine.ContextKey.CurrentActionGroupId = "CurrentActionGroupId"

CitizenBTDefine.G_ContextKey = {}
CitizenBTDefine.G_ContextKey.cityFurnitureUpgrade = "city_furniture_upgrade"
CitizenBTDefine.G_ContextKey.cityWorkTargetChange = "city_WorkTargetChange"

CitizenBTDefine.ContextKey.OverrideTagsMask = "OverrideTags"
CitizenBTDefine.ContextKey.InteractPointSearchParam = "InteractPointSearchParam"
CitizenBTDefine.ContextKey.IndicatorKey = "IndicatorKey_%d"
CitizenBTDefine.ContextKey.IndicatorKeyDic = {}

CitizenBTDefine.ContextKey.GlobalWaitInteractCitizenId = "GlobalWaitInteractCitizenId"

CitizenBTDefine.BuiltInAction = {
    CitizenBTActionFainting = "CitizenBTActionFainting",
    CitizenBTActionWork = "CitizenBTActionWork",
    CitizenBTActionEscape = "CitizenBTActionEscape",
    CitizenBTActionIdle = "CitizenBTActionIdle",
    CitizenBTActionInteractTask = "CitizenBTActionInteractTask",
}

CitizenBTDefine.ContextKey.ForcePerformanceActionGroupId = "ForcePerformanceActionGroup"

---@param p CitizenBTActionGoToContextParam
function CitizenBTDefine.DumpGotoInfo(p)
    if not p then
        return "nil"
    end
    return string.format("{toPos:%s, useRun:%s}", p.targetPos and p.targetPos.ToString and p.targetPos:ToString() or nil, p.useRun or false)
end

---@param p CitizenBTActionPlayClipContextParam
function CitizenBTDefine.DumpWorkInfo(p)
    if not p then
        return "nil"
    end
    return string.format("{clipName:%s, soundId:%s, leftTime:%s}", p.clipName, p.soundId, p.leftTime)
end

---@param p CitizenBTActionFindPerformanceTargetContextParam
function CitizenBTDefine.DumpPointSearchParam(p)
    if not p then
        return "nil"
    end
    return string.format("{pointType:%s, tagsMask:%s}", p.pointType, p.tagsMask)
end

function CitizenBTDefine.GetIndicatorKey(id)
    local key = CitizenBTDefine.ContextKey.IndicatorKeyDic[id]
    if not key then
        key = CitizenBTDefine.ContextKey.IndicatorKey:format(id)
        CitizenBTDefine.ContextKey.IndicatorKeyDic[id] = key
    end
    return key
end

function CitizenBTDefine.FloatEqual(a, b)
    return math.abs(a - b) < 0.01
end

function CitizenBTDefine.OpIndicatorValue(currentValue, op, targetValue)
    if op == CitizenEnvironmentalIndicatorOperator.Equal then
        return CitizenBTDefine.FloatEqual(currentValue, targetValue)
    elseif op == CitizenEnvironmentalIndicatorOperator.Greater then
        return currentValue > targetValue
    elseif op == CitizenEnvironmentalIndicatorOperator.Less then
        return currentValue < targetValue
    elseif op == CitizenEnvironmentalIndicatorOperator.GEqual then
        return currentValue > targetValue or CitizenBTDefine.FloatEqual(currentValue, targetValue)
    elseif op == CitizenEnvironmentalIndicatorOperator.LEqual then
        return currentValue <= targetValue or CitizenBTDefine.FloatEqual(currentValue, targetValue)
    elseif op == CitizenEnvironmentalIndicatorOperator.NotEqual then
        return not CitizenBTDefine.FloatEqual(currentValue, targetValue)
    end
    return false
end

return CitizenBTDefine