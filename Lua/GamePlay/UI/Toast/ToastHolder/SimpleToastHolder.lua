---@class SimpleToastHolder
local SimpleToastHolder = class('SimpleToastHolder')

---@param mediator BaseUIMediator
function SimpleToastHolder:ctor(mediator)
    self.mediator = mediator
    self.runtimeId = mediator.runtimeId

    self.trans = mediator:Transform("")
end

function SimpleToastHolder:IsAlive()
    return g_Game.UIManager:FindUIMediator(self.runtimeId) ~= nil
end

function SimpleToastHolder:Release()
    if self:IsAlive() then
        self.mediator:CloseSelf()
    end
    self.mediator = nil
    self.trans = nil
end

function SimpleToastHolder:MoveUp()
    self.trans:DOLocalMoveY(70, 0.2)
end

return SimpleToastHolder