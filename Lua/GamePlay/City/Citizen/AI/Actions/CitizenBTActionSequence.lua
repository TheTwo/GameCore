local CitizenBTDefine = require("CitizenBTDefine")

local CitizenBTActionNode = require("CitizenBTActionNode")

---@class CitizenBTActionSequence:CitizenBTActionNode
---@field new fun(loop:boolean):CitizenBTActionSequence
---@field super CitizenBTActionNode
local CitizenBTActionSequence = class('CitizenBTActionSequence', CitizenBTActionNode)

function CitizenBTActionSequence:ctor(loop)
    CitizenBTActionSequence.super.ctor(self)
    ---@type CitizenBTActionNode[]
    self._actionSequence = {}
    self._loop = loop or false
    self._currentEnter = false
    self._currentIndex = 1
end

---@param actionNode CitizenBTActionNode
function CitizenBTActionSequence:AddAction(actionNode)
    table.insert(self._actionSequence, actionNode)
end

function CitizenBTActionSequence:Clear()
    self._currentIndex = 1
    table.clear(self._actionSequence)
end

function CitizenBTActionSequence:Enter(context, gContext)
    self._currentEnter = false
    self._currentIndex = 1
    local node = self._actionSequence[self._currentIndex]
    if node and node:Run(context, gContext) then
        node:Enter(context, gContext)
        self._currentEnter = true
    end
end

function CitizenBTActionSequence:Run(context, gContext)
    if #self._actionSequence > 0 then
        return CitizenBTActionSequence.super.Run(self, context, gContext)
    end
    return false, nil
end

function CitizenBTActionSequence:Exit(context, gContext)
    if not self._currentEnter then return end
    local node = self._actionSequence[self._currentIndex]
    self._currentIndex = 1
    if node then node:Exit(context, gContext) end
end

---@param node CitizenBTActionNode
---@param dt number
---@param nowTime number
---@param context CitizenBTContext
---@param gContext CitizenBTContext
---@return boolean @isExit
function CitizenBTActionSequence:DoNodeTick(node, dt, nowTime, context, gContext, limit)
    limit = limit - 1
    if node:Tick(dt, nowTime, context, gContext) then
        self._currentIndex = self._currentIndex + 1
        if self._currentEnter then
            node:Exit(context, gContext)
        end
        self._currentEnter = false
        if self._loop then
            if self._currentIndex > #self._actionSequence then
                self._currentIndex = 1
            end
        end
        node = self._actionSequence[self._currentIndex]
        if not node then
            return true
        end
        if limit > 0 then
            if node:Run(context, gContext) then
                node:Enter(context, gContext)
                self._currentEnter = true
            else
                local currentActionGroupId = context:Read(CitizenBTDefine.ContextKey.CurrentActionGroupId)
                if currentActionGroupId then
                    ---@type table<number, number>
                    local failAction = context:Read(CitizenBTDefine.ContextKey.LastFailAction) or {}
                    local cdEndTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() + 5
                    failAction[currentActionGroupId] = cdEndTime
                    context:Write(CitizenBTDefine.ContextKey.LastFailAction, failAction)
                    g_Logger.Warn("action group:%s fail, padding cd to:%s", currentActionGroupId, cdEndTime)
                end
                return true
            end
            return self:DoNodeTick(node, dt, nowTime, context, gContext, limit)
        end
    end
end

function CitizenBTActionSequence:Tick(dt, nowTime, context, gContext)
    local node = self._actionSequence[self._currentIndex]
    if not node then
        return true
    end
    return self:DoNodeTick(node, dt, nowTime, context, gContext, #self._actionSequence)
end

return CitizenBTActionSequence