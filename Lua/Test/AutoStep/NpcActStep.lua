local EmptyStep = require("EmptyStep")
---@class NpcActStep:EmptyStep
---@field new fun():NpcActStep
local NpcActStep = class("NpcActStep", EmptyStep)
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
NpcActStep.ActionEnum = {
    CheckExist = 1,
    Interact = 2,
}

function NpcActStep:ctor(elementNpcId, actionType, msgId)
    self.elementNpcId = elementNpcId
    self.actionType = actionType
    self.msgId = msgId
    self.city = ModuleRefer.CityModule:GetMyCity()
end

function NpcActStep:Start()
    if self.msgId then
        g_Game.ServiceManager:AddResponseCallback(self.msgId, Delegate.GetOrCreate(self, self.OnResponse))
    end
end

function NpcActStep:End()
    if self.msgId then
        g_Game.ServiceManager:RemoveResponseCallback(self.msgId, Delegate.GetOrCreate(self, self.OnResponse))
    end
end

function NpcActStep:TryExecuted(lastReturn)
    if self.actionType == NpcActStep.ActionEnum.CheckExist then
        local npc = self.city.elementManager:GetElementById(self.elementNpcId)
        return npc ~= nil, npc
    elseif self.actionType == NpcActStep.ActionEnum.Interact then
        ---@type CityElementNpc
        local element = lastReturn
        if not element then return false end

        local tile = self.city.gridView:GetCellTile(element.x, element.y)
        if not tile then return false end

        local state = self.city.stateMachine.currentState
        if not state then return false end
        if not state.OnClickCellTile then return false end
        state:OnClickCellTile(tile)
        return self.msgId == nil
    end
end

function NpcActStep:OnResponse(isSuccess, reply, rpc)
    if isSuccess then
        self.sequence:MoveNext()
    end
end

return NpcActStep