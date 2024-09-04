local CitizenBTNode = require("CitizenBTNode")

---@class CitizenBTCheckContext:CitizenBTNode
---@field new fun(key:string, value:any, op:string):CitizenBTCheckContext
---@field super CitizenBTNode
local CitizenBTCheckContext = class('CitizenBTCheckContext', CitizenBTNode)

function CitizenBTCheckContext:ctor(key, value, op)
    CitizenBTCheckContext.super.ctor(self)
    self._key = key
    self._value = value
    self._op = op
end

function CitizenBTCheckContext:Run(context, gContext)
    local value = context:Read(self._key)
    if self._op == "==" then
        return self._value == value
    elseif self._op == ">" then
        return self._value > value
    elseif self._op == "<" then
        return self._value < value
    elseif self._op == ">=" then
        return self._value >= value
    elseif self._op == "<=" then
        return self._value <= value
    elseif self._op == "~=" then
        return self._value ~= value
    end
    return false
end

return CitizenBTCheckContext