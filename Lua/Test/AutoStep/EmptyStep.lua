---@class EmptyStep
---@field new fun():EmptyStep
local EmptyStep = class("EmptyStep")

---@param sequence SequenceForPetSlot
function EmptyStep:SetSequence(sequence)
    self.sequence = sequence
    return self
end

function EmptyStep:IsFirstExecuted()
    if not self.executed then
        self.executed = true
        return true
    end
    return false
end

function EmptyStep:Start()
    
end

function EmptyStep:End()
    
end

function EmptyStep:TryExecuted()
    return true
end

return EmptyStep