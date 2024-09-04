local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local CitizenBTDefine = require("CitizenBTDefine")

local CitizenBTPerformanceDecision = require("CitizenBTPerformanceDecision")

---@class CitizenBTCheckFurnitureUpgrade:CitizenBTPerformanceDecision
---@field new fun():CitizenBTCheckFurnitureUpgrade
---@field super CitizenBTPerformanceDecision
local CitizenBTCheckFurnitureUpgrade = class('CitizenBTCheckFurnitureUpgrade', CitizenBTPerformanceDecision)

---@param config CitizenBTNodeConfigCell
function CitizenBTCheckFurnitureUpgrade:InitFromConfig(config)
    self._cdMin = config:IntParam(1)
    self._cdMax = config:IntParam(2)
    self._enterRate = config:IntParam(3)
    self._furnitureTypeId = config:IntParam(4)
    self._minLevel = 0
    self._maxLevel = 9999
    if config:IntParamLength() > 5 then
        self._minLevel = config:IntParam(5)
    end
    if config:IntParamLength() > 6 then
        self._maxLevel = config:IntParam(6)
    end
end

function CitizenBTCheckFurnitureUpgrade:SetupDecisionName(decisionName)
    self._decisionName = decisionName
end

function CitizenBTCheckFurnitureUpgrade:Run(context, gContext)
    if context:Read(CitizenBTDefine.ContextKey.ForcePerformanceActionGroupId) then
        return true
    end
    local current = context:Read(CitizenBTDefine.ContextKey.CurrentKey)
    if current and current == self._decisionName then
        return true
    elseif not current or (current == CitizenBTDefine.BuiltInAction.CitizenBTActionIdle or current == CitizenBTDefine.BuiltInAction.CitizenBTActionWork) then
        local nextCheckAllowTimeKey = ("NextCheckTime_%s"):format(self._decisionName)
        local nextCheckAllowTime = context:Read(nextCheckAllowTimeKey)
        local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
        if not nextCheckAllowTime then
            context:Write(nextCheckAllowTimeKey, g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() + math.random(self._cdMin, self._cdMax))
        elseif nextCheckAllowTime > nowTime then
            return false
        end
        local lastFurnitureUpgrade = gContext:Read(CitizenBTDefine.G_ContextKey.cityFurnitureUpgrade)
        local level = lastFurnitureUpgrade and lastFurnitureUpgrade[self._furnitureTypeId]
        if not level then return false end
        return (level >= self._minLevel and level <= self._maxLevel) or false
    end
    return false
end

return CitizenBTCheckFurnitureUpgrade