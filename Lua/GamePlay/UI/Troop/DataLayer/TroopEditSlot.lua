local TroopEditUnit = require("TroopEditUnit")
local I18N = require("I18N")
---@class TroopEditSlot
local TroopEditSlot = class('TroopEditSlot')

local Names = {
    "troop_con_front",
    "troop_con_middle",
    "troop_con_back"
}

function TroopEditSlot:ctor(index, presetIndex)
    self.index = index
    ---@type TroopEditUnit
    self.unit = nil

    self.presetIndex = presetIndex
end

function TroopEditSlot:Release()
    self:RemoveUnit()
end

function TroopEditSlot:GetIndex()
    return self.index
end

function TroopEditSlot:GetName()
    return I18N.Get(Names[self.index])
end

function TroopEditSlot:AddUnit(id)
end

function TroopEditSlot:RemoveUnit()
    if self.unit then
        self.unit:Release()
        self.unit = nil
    end
end

---@return TroopEditUnit
function TroopEditSlot:GetUnit()
    return self.unit
end

---@return boolean
function TroopEditSlot:IsEmpty()
    return self.unit == nil
end

---@return boolean
function TroopEditSlot:IsLocked()
    return false
end

function TroopEditSlot:GetUnlockCondStr()
    return string.Empty
end

function TroopEditSlot:GetType()
    return -1
end

return TroopEditSlot