local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local CitizenEmojiTriggerType = require("CitizenEmojiTriggerType")

---@class CityCitizenIndicatorTrigger
---@field new fun():CityCitizenIndicatorTrigger
local CityCitizenIndicatorTrigger = class('CityCitizenIndicatorTrigger')

function CityCitizenIndicatorTrigger:ctor()
    self._endTime = nil
    ---@type CitizenEmojiTriggerConfigCell
    self._config = nil
end

---@param config CitizenEmojiTriggerConfigCell
function CityCitizenIndicatorTrigger:InitWithConfig(config, probability)
    self._config = config
    self._type = config:Type()
    self._probability = probability
    self._actionGroup = config:ActionGroup()
end

---@param context {enterAction:table<number, number>,exitAction:table<number, number>}
---@param lastTrigger CityCitizenIndicatorTrigger
---@return boolean
function CityCitizenIndicatorTrigger:Check(context, lastTrigger, citizen)
    local triggerType = self._type
    if triggerType == CitizenEmojiTriggerType.Circle then
        return self:CheckProbability()
    elseif context.enterAction and triggerType == CitizenEmojiTriggerType.ActionStart then
        if context.enterAction[self._actionGroup] then
            return self:CheckProbability()
        end
    elseif context.exitAction and triggerType == CitizenEmojiTriggerType.ActionEnd then
        if context.exitAction[self._actionGroup] then
            return self:CheckProbability()
        end
    end
    return false
end

function CityCitizenIndicatorTrigger:CheckProbability()
    return math.random(1, 100) < self._probability
end

---@return boolean
function CityCitizenIndicatorTrigger:Tick(dt, nowTime)
    if self._endTime then
        if  self._endTime <= nowTime then
            return true
        end
    end
end

function CityCitizenIndicatorTrigger:GetExitTime()
    if self._config:TimeMinLength() > 1 then
        return math.random(self._config:TimeMin(1), self._config:TimeMin(2))
    end
    return self._config:TimeMin(1)
end

function CityCitizenIndicatorTrigger:GetCoolDownTime()
    if self._config:CDLength() > 1 then
        return math.random(self._config:CD(1), self._config:CD(2))
    end
    return self._config:CD(1)
end

---@param citizen CityUnitCitizen
function CityCitizenIndicatorTrigger:Enter(nowTime, citizen)
    self._endTime = nowTime + self:GetExitTime()
    citizen._citizenBubble._emoji = {icon=self._config:Icon()}
end

---@param citizen CityUnitCitizen
---@return number
function CityCitizenIndicatorTrigger:Exit(nowTime, citizen)
    citizen._citizenBubble._emoji = nil
    return nowTime + self:GetCoolDownTime()
end

return CityCitizenIndicatorTrigger