
local CitizenBTActionNode = require("CitizenBTActionNode")

---@class CitizenBTWriteContext:CitizenBTActionNode
---@field new fun(key:string, value:any):CitizenBTWriteContext
---@field super CitizenBTActionNode
local CitizenBTWriteContext = class('CitizenBTWriteContext', CitizenBTActionNode)

function CitizenBTWriteContext:ctor(key, value)
    CitizenBTWriteContext.super.ctor(self)
    self._key = key
    self._value = value
end

function CitizenBTWriteContext:Run(context, gContext)
    context:Write(self._key, self._value)
    return CitizenBTWriteContext.super.Run(self, context, gContext)
end

return CitizenBTWriteContext