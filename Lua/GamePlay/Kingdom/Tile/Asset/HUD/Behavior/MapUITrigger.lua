local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")

---@class MapUITrigger
---@field callback fun()
local MapUITrigger = class("MapUITrigger")

function MapUITrigger:SetEnable(enable)
    self.behaviour:GetComponent(typeof(CS.UnityEngine.Collider)).enabled = enable
end

---@param callback fun()
function MapUITrigger:SetTrigger(callback)
    self.callback = callback
end

function MapUITrigger:InvokeTrigger()
    if self.callback ~= nil then
        self.callback()
    end
end

function MapUITrigger:OnDisable()
    self.callback = nil
end

return MapUITrigger