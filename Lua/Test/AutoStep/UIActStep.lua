local EmptyStep = require("EmptyStep")
---@class UIActStep:EmptyStep
---@field new fun():UIActStep
local UIActStep = class("UIActStep", EmptyStep)
local Utils = require("Utils")

UIActStep.ActionEnum = {
    IndexLuaComp = 1,
    CheckOrWaitUI = 2,
    SimCall = 3,
    IndexComp = 4,
    IndexTableViewCell = 5,
    CloseUI = 6,
}

function UIActStep:ctor(uiName, stepType, params)
    self.uiName = uiName
    self.stepType = stepType
    self.params = params
end

function UIActStep:Start()
    
end

function UIActStep:End()
    
end

function UIActStep:TryExecuted(lastReturn)
    if self.stepType == UIActStep.ActionEnum.CheckOrWaitUI then
        if self.params[1] <= 0 then
            return true, true
        end

        self.params[1] = self.params[1] - 1
        if g_Game.UIManager:IsOpenedByName(self.uiName) then
            local mediator = g_Game.UIManager:FindUIMediatorByName(self.uiName)
            return mediator ~= nil, mediator
        end
    elseif self.stepType == UIActStep.ActionEnum.IndexLuaComp then
        if lastReturn == true then
            return true, true
        end

        local mediator = lastReturn
        if mediator == nil then return false end
        local comp = mediator
        local index = 1
        while(index <= #self.params) do
            comp = comp[self.params[index]]
            if not comp then
                return false
            end
            index = index + 1
        end
        if Utils.IsNull(comp) then
            return false
        end

        return true, comp.Lua
    elseif self.stepType == UIActStep.ActionEnum.SimCall then
        if lastReturn == true then
            return true, true
        end

        local comp = lastReturn
        local func = comp[self.params[1]]
        if not func then
            return false
        end
        func(comp)
        return true
    elseif self.stepType == UIActStep.ActionEnum.IndexComp then
        if lastReturn == true then
            return true, true
        end

        local luaComp = lastReturn
        local compType = self.params[1]
        local comp = luaComp
        local index = 2
        while(index <= #self.params) do
            comp = comp[self.params[index]]
            if not comp then
                return false
            end
            index = index + 1
        end

        if Utils.IsNull(comp) then
            return false
        end

        if comp:GetType() ~= compType then
            return false
        end

        return true, comp
    elseif self.stepType == UIActStep.ActionEnum.IndexTableViewCell then
        if lastReturn == true then
            return true, true
        end

        local tableViewPro = lastReturn
        if tableViewPro == nil then return false end
        if tableViewPro._shownCellList.Count == 0 then return false end

        local cell = tableViewPro._shownCellList[math.max(0, self.params[1] - 1)]
        if Utils.IsNull(cell) then return false end

        return true, cell.Lua
    elseif self.stepType == UIActStep.ActionEnum.CloseUI then
        local mediator = lastReturn
        if type(mediator) ~= "table" then
            local uiMediator = g_Game.UIManager:FindUIMediatorByName(self.uiName)
            if uiMediator then
                uiMediator:CloseSelf()
                return true
            end
            return false
        end
        mediator:CloseSelf()
        return true
    end
end

return UIActStep