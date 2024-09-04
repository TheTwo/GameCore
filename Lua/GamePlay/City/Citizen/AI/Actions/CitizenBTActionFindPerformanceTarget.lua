local CitizenBTDefine = require("CitizenBTDefine")

local CitizenBTActionNode = require("CitizenBTActionNode")

---@class CitizenBTActionFindPerformanceTargetContextParam
---@field pointType number @CityInteractionPointType
---@field tagsMask number

---@class CitizenBTActionFindPerformanceTarget:CitizenBTActionNode
---@field new fun():CitizenBTActionFindPerformanceTarget
---@field super CitizenBTActionNode
local CitizenBTActionFindPerformanceTarget = class('CitizenBTActionFindPerformanceTarget', CitizenBTActionNode)

function CitizenBTActionFindPerformanceTarget:Run(context, gContext)
    ---@type CitizenBTActionFindPerformanceTargetContextParam
    local param = context:Read(CitizenBTDefine.ContextKey.InteractPointSearchParam)
    if not param then
        return false
    end
    local overrideTags = context:Read(CitizenBTDefine.ContextKey.OverrideTagsMask)
    local tagMask = overrideTags or param.tagsMask or 0
    local city = context:GetCity()
    local point = city.cityInteractPointManager:AcquireInteractPoint(param.pointType, tagMask)
    context:Write(CitizenBTDefine.ContextKey.GotoTargetInfo, nil)
    if not point then
        return false
    end
    context:BindInteractPoint(point)
    ---@type CitizenBTActionGoToContextParam
    local gotoParam = {}
    gotoParam.targetPos = point:GetWorldPos()
    gotoParam.exitDir = CS.UnityEngine.Quaternion.LookRotation(point.worldRotation)
    gotoParam.useRun = context:Read(CitizenBTDefine.ContextKey.PreferRun)
    gotoParam.dumpStr = CitizenBTDefine.DumpGotoInfo
    context:Write(CitizenBTDefine.ContextKey.GotoTargetInfo, gotoParam)
    return CitizenBTActionFindPerformanceTarget.super.Run(self, context, gContext)
end

return CitizenBTActionFindPerformanceTarget