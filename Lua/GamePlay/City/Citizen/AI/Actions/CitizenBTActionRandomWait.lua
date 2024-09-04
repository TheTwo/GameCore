local CityCitizenDefine = require("CityCitizenDefine")

local CitizenBTActionNode = require("CitizenBTActionNode")

---@class CitizenBTActionRandomWait:CitizenBTActionNode
---@field new fun():CitizenBTActionRandomWait
---@field super CitizenBTActionNode
local CitizenBTActionRandomWait = class('CitizenBTActionRandomWait', CitizenBTActionNode)

function CitizenBTActionRandomWait:ctor(thresholds, min, max)
    CitizenBTActionRandomWait.super.ctor(self)
    self._enterThresholds = thresholds or 0.5
    self._waitTimeMin = min or 1
    self._waitTimeMax = max or 3.5
end

function CitizenBTActionRandomWait:Run(context, gContext)
    if self._enterThresholds and self._enterThresholds >= 1 then
        return false
    end
    return CitizenBTActionRandomWait.super.Run(self, context, gContext)
end

function CitizenBTActionRandomWait:Enter(context, gContext)
    self._wait = math.random() > self._enterThresholds
    if not self._wait then
        return
    end
    local citizen = context:GetCitizen()
    citizen:StopMove()
    citizen:ChangeAnimatorState(CityCitizenDefine.AniClip.Idle)
    self._waitTime = self._waitTimeMin + math.random() * (self._waitTimeMax - self._waitTimeMin)
end

function CitizenBTActionRandomWait:Tick(dt, nowTime, context, gContext)
    if not self._wait then
        return true
    end
    self._waitTime = self._waitTime - dt
    if self._waitTime <= 0 then
        return true
    end
end

return CitizenBTActionRandomWait