---
--- Created by wupei. DateTime: 2022/3/1
---

local BuffBehavior = require("BuffBehavior")

---@class BuffScreenEffect:BuffBehavior
local BuffScreenEffect = class("BuffScreenEffect", BuffBehavior)

---@param self BuffScreenEffect
---@param ... any
---@return void
function BuffScreenEffect:ctor(...)
    BuffScreenEffect.super.ctor(self, ...)

    ---@type buffclient.data.ScreenEffect
    self._buffScreenEffect = self._data
end

return BuffScreenEffect
