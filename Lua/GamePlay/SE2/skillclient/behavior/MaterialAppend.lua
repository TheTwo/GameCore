---
--- Created by linxiao. DateTime: 2023-10-30 17:14:03
---

local Behavior = require("Behavior")

---@class MaterialAppend:Behavior
---@field super Behavior
local MaterialAppend = class("MaterialAppend", Behavior)

function MaterialAppend:ctor(...)
    Behavior.ctor(self, ...)

    ---@type skillclient.data.MaterialAppend
    self._skillData = self._data
	self._materialName = self._skillData.MaterialName
    self._needWaitOnCtrlValidForStart = false
end

function MaterialAppend:OnStart()
    if not self._target or not self._target:IsCtrlValid() then
        self._needWaitOnCtrlValidForStart = true
        return
    end
    self._needWaitOnCtrlValidForStart = false
    ---@type SEActor
    local actor = self._skillTarget:GetCtrl()
    actor:AppendMaterial(self._materialName)
end

function MaterialAppend:OnCtrlValid()
    if not self._needWaitOnCtrlValidForStart then return end
    self._needWaitOnCtrlValidForStart = false
    ---@type SEActor
    local actor = self._skillTarget:GetCtrl()
    actor:AppendMaterial(self._materialName)
end

function MaterialAppend:OnEnd()
    ---@type SEActor
    local actor = self._skillTarget:GetCtrl()
    actor:RemoveAppendedMaterial(self._materialName)
end

return MaterialAppend