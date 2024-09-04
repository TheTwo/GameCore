---
--- Created by linxiao. DateTime: 2023-10-30 16:09:08
---

local BuffBehavior = require("BuffBehavior")

---@class BuffMaterialAppend:BuffBehavior
local BuffMaterialAppend = class("BuffMaterialAppend", BuffBehavior)

function BuffMaterialAppend:ctor(...)
    BuffBehavior.ctor(self, ...)

    ---@type buffclient.data.MaterialAppend
    self._buffData = self._data
	self._materialName = self._buffData.MaterialName
    self._needWaitOnCtrlValidForStart = false
end

function BuffMaterialAppend:OnStart()
    if not self._target or not self._target:IsCtrlFbxValid() then
        self._needWaitOnCtrlValidForStart = true
        return
    end
    self._needWaitOnCtrlValidForStart = false
    ---@type SEActor
    local actor = self._target:GetCtrl()
    actor:AppendMaterial(self._materialName)
end

function BuffMaterialAppend:OnCtrlValid()
    if not self._needWaitOnCtrlValidForStart then return end
    self._needWaitOnCtrlValidForStart = false
    ---@type SEActor
    local actor = self._target:GetCtrl()
    actor:AppendMaterial(self._materialName)
end

function BuffMaterialAppend:OnEnd()
    ---@type SEActor
    local actor = self._target:GetCtrl()
    actor:RemoveAppendedMaterial(self._materialName)
end

return BuffMaterialAppend