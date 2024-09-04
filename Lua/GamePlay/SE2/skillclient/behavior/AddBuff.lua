---
--- Created by wupei. DateTime: 2022/1/21
---

local Behavior = require("Behavior")

---@class AddBuff:Behavior
---@field super Behavior
local AddBuff = class("AddBuff", Behavior)

---@param self AddBuff
---@param ... any
---@return void
function AddBuff:ctor(...)
    AddBuff.super.ctor(self, ...)
end

return AddBuff
