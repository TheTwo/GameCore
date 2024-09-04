--- Created by hao.wu.ss. DateTime: 2023/3/31

local Behavior = require("Behavior")

---@class MoveY:Behavior
---@field super Behavior
local MoveY = class("MoveY", Behavior)
local SkillClientUtils = require("SkillClientUtils")
local Utils = require("Utils")

---@param self MoveY
---@param ... any
---@return void
function MoveY:ctor(...)
    MoveY.super.ctor(self, ...)

    ---@type skillclient.data.MoveY
    self._dataMoveY = self._data
	self._startTime = 0
	self._trans = nil
	self._curve = nil
	self._valid = false
	self._duration = 0
end

---@param self MoveY
---@return void
function MoveY:OnStart()
    local ctrl = self._skillTarget:GetCtrl()
    if ctrl and ctrl:IsValid() then
        self._curve = SkillClientUtils.GetCurve(self._dataMoveY.Curve)
		self._trans = ctrl:GetFbxTransform()
		if (self._curve and Utils.IsNotNull(self._trans)) then
			self._startTime = g_Game.Time.time
			self._valid = true
		end
    end
end

function MoveY:OnUpdate()
	if (not self._valid) then return end
	local elapsedTime = g_Game.Time.time - self._startTime
	local rate = self._curve:Evaluate(elapsedTime / self._dataMoveY.Time)
	self._trans.localPosition = CS.UnityEngine.Vector3.up * rate * self._dataMoveY.MaxDistance
end

function MoveY:OnEnd()
	if (not self._valid) then return end
	self._trans.localPosition = CS.UnityEngine.Vector3.zero
end

return MoveY
