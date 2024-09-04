---
--- Created by wupei. DateTime: 2022/3/1
---

local BuffBehavior = require("BuffBehavior")
local I18N = require("I18N")

---@class BuffUI:BuffBehavior
local BuffBuffUI = class("BuffBuffUI", BuffBehavior)

---@param self BuffUI
---@param ... any
---@return void
function BuffBuffUI:ctor(...)
    BuffBuffUI.super.ctor(self, ...)

    ---@type buffclient.data.BuffUI
    self._dataUI = self._data
end

local gen = require("BuffClientGen")

---@param self BuffUI
---@return void
function BuffBuffUI:OnStart()
    if self._dataUI.BuffUIType == gen.BuffUIType.Icon then
       self._target:AddBuffIcon(self._dataUI.IconPath)
    elseif self._dataUI.BuffUIType == gen.BuffUIType.Text then
       self._target:AddBuffText(I18N.Get(self._dataUI.BuffText))
    end
end

---@param self BuffUI
---@return void
function BuffBuffUI:OnEnd()

end

return BuffBuffUI
