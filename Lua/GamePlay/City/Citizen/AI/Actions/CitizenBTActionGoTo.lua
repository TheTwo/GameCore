local CitizenBTDefine = require("CitizenBTDefine")

local CitizenBTActionNode = require("CitizenBTActionNode")

---@class CitizenBTActionGoToContextParam
---@field targetPos CS.UnityEngine.Vector3
---@field exitDir CS.UnityEngine.Quaternion|nil
---@field exitTurnTo CS.UnityEngine.Vector3|nil
---@field useRun boolean
---@field limitTime number|nil

---@class CitizenBTActionGoTo:CitizenBTActionNode
---@field new fun():CitizenBTActionGoTo
---@field super CitizenBTActionNode
local CitizenBTActionGoTo = class('CitizenBTActionGoTo', CitizenBTActionNode)

function CitizenBTActionGoTo:Enter(context, gContext)
    self._exitDir = nil
    self._exitTurnTo = nil
    self._limitRuntime = nil
    ---@type CitizenBTActionGoToContextParam
    local targetInfo = context:Read(CitizenBTDefine.ContextKey.GotoTargetInfo)
    if not targetInfo then
        return
    end
    self._exitDir = targetInfo.exitDir
    self._exitTurnTo = targetInfo.exitTurnTo
    local citizen = context:GetCitizen()
    citizen:StopMove()
    if citizen._moveAgent._currentPosition then
        local targetDistance = (targetInfo.targetPos - citizen._moveAgent._currentPosition).sqrMagnitude
        if targetDistance <= citizen._moveAgent.MoveEpsilon then
            return
        end
    end
    citizen:SetIsRunning(targetInfo.useRun)
    citizen:MoveToTargetPos(targetInfo.targetPos, targetInfo.useRun, nil, targetInfo.limitTime)
end

function CitizenBTActionGoTo:Run(context, gContext)
    ---@type CitizenBTActionGoToContextParam
    local targetInfo = context:Read(CitizenBTDefine.ContextKey.GotoTargetInfo)
    if not targetInfo then
        return false
    end
    return CitizenBTActionGoTo.super.Run(self, context, gContext)
end

function CitizenBTActionGoTo:Tick(dt, nowTime, context, gContext)
    return not context:CitizenHasTargetPos()
end

function CitizenBTActionGoTo:Exit(context, gContext)
    context:GetCitizen():StopMove()
    context:GetCitizen():RemovePathLine()
    if self._exitDir then
        context:GetCitizen()._moveAgent:StopMoveTurnToRotation(self._exitDir)
    elseif self._exitTurnTo then
        context:GetCitizen()._moveAgent:StopMoveTurnToPos(self._exitTurnTo)
    end
    self._exitDir = nil
    self._exitTurnTo = nil
end

return CitizenBTActionGoTo