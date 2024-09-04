---
--- Created by wupei. DateTime: 2022/2/17
---

local Behavior = require("Behavior")

---@class ModelHide:Behavior
---@field super Behavior
local ModelHide = class("ModelHide", Behavior)

---@param self ModelHide
---@param ... any
---@return void
function ModelHide:ctor(...)
    ModelHide.super.ctor(self, ...)

    ---@type skillclient.data.ModelHide
    self._skillData = self._data
end

---@param self ModelHide
---@return void
function ModelHide:OnStart()
    self._skillTarget:AddRendererInvisibleCount(1)
end

---@param self ModelHide
---@return void
function ModelHide:OnEnd()
    self._skillTarget:AddRendererInvisibleCount(-1)
end

return ModelHide
