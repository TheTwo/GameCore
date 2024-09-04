local CitizenBTDefine = require("CitizenBTDefine")

local CitizenBTNode = require("CitizenBTNode")

---@class CitizenBTPerformanceDecision:CitizenBTNode
---@field new fun():CitizenBTPerformanceDecision
---@field super CitizenBTNode
local CitizenBTPerformanceDecision = class('CitizenBTPerformanceDecision', CitizenBTNode)

function CitizenBTPerformanceDecision:ctor()
    CitizenBTPerformanceDecision.super.ctor(self)
    self._subGroupId = {}
end

---@param config CitizenBTNodeConfigCell
function CitizenBTPerformanceDecision:InitFromConfig(config)
    self._cdMin = config:IntParam(1)
    self._cdMax = config:IntParam(2)
    self._enterRate = config:IntParam(3)
end

function CitizenBTPerformanceDecision:SetupDecisionName(decisionName)
    self._decisionName = decisionName
end

---@param subGroups CitizenBTActionGroupSubGroup[]
function CitizenBTPerformanceDecision:SetupAllChildGroups(subGroups)
    if not subGroups then return end
    for _, value in pairs(subGroups) do
        self._subGroupId[value.config:Id()] = true
    end
end

function CitizenBTPerformanceDecision:Run(context, gContext)
    if context:Read(CitizenBTDefine.ContextKey.ForcePerformanceActionGroupId) then
        return true
    end
    local nextCheckAllowTimeKey = ("NextCheckTime_%s"):format(self._decisionName)
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local current = context:Read(CitizenBTDefine.ContextKey.CurrentKey)
    if current and current == self._decisionName then
        local lastFail = context:Read(CitizenBTDefine.ContextKey.LastFailAction)
        if lastFail then
            for actionGrouId, cdEndTime in pairs(lastFail) do
                if self._subGroupId[actionGrouId] and cdEndTime > nowTime then
                    context:Write(CitizenBTDefine.ContextKey.DecisionKey)
                    context:Write(CitizenBTDefine.ContextKey.DecisionPriority)
                    context:Write(CitizenBTDefine.ContextKey.CurrentKey)
                    context:Write(nextCheckAllowTimeKey, g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() + math.random(self._cdMin, self._cdMax))
                    return false
                end
            end
        end
        return true
    elseif not current or (current == CitizenBTDefine.BuiltInAction.CitizenBTActionIdle or current == CitizenBTDefine.BuiltInAction.CitizenBTActionWork) then
        local nextCheckAllowTime = context:Read(nextCheckAllowTimeKey)
        if not nextCheckAllowTime then
            context:Write(nextCheckAllowTimeKey, g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() + math.random(self._cdMin, self._cdMax))
            local lastFail = context:Read(CitizenBTDefine.ContextKey.LastFailAction)
            if lastFail then
                for actionGrouId, cdEndTime in pairs(lastFail) do
                    if self._subGroupId[actionGrouId] and cdEndTime > nowTime then
                        context:Write(CitizenBTDefine.ContextKey.DecisionKey, nil)
                        context:Write(CitizenBTDefine.ContextKey.DecisionPriority, nil)
                        return false
                    end
                end
            end
        elseif nextCheckAllowTime > nowTime then
            return false
        end
        return true
    end
    return false
end

return CitizenBTPerformanceDecision